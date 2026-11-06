#!/usr/bin/env python3
"""Genera documentación relacional desde Practica04/backups/respaldo-04-11-2026.sql.

No se ejecuta SQL ni se conecta a un servidor: extrae DDL y cuenta filas en los
INSERT del dump. Los conteos representan filas insertadas en el archivo fuente.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "Practica04" / "backups" / "respaldo-06-11-2026.sql"
OUT = ROOT / "diccionario_datos"


def uncomment_mysql(sql: str) -> str:
    """Unwrap executable MySQL comments while retaining ordinary SQL comments."""
    sql = re.sub(r"/\*!\d*\s*(.*?)\s*\*/", r"\1", sql, flags=re.S)
    return sql


def split_top_level(text: str, separator: str = ",") -> list[str]:
    """Split a SQL fragment on separators outside strings and parentheses."""
    result, buf = [], []
    depth, quote, escaped = 0, None, False
    for ch in text:
        if quote:
            buf.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
        elif ch in "'\"`":
            quote = ch
            buf.append(ch)
        elif ch == "(":
            depth += 1
            buf.append(ch)
        elif ch == ")":
            depth = max(0, depth - 1)
            buf.append(ch)
        elif ch == separator and depth == 0:
            result.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    if buf or text:
        result.append("".join(buf).strip())
    return result


def matching_paren(text: str, start: int) -> int:
    depth, quote, escaped = 0, None, False
    for i in range(start, len(text)):
        ch = text[i]
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
        elif ch in "'\"`":
            quote = ch
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("Paréntesis sin cierre en una definición SQL")


def extract_objects(sql: str) -> tuple[dict[str, str], list[dict[str, str]]]:
    """Find CREATE TABLE blocks and all data-bearing INSERT statements."""
    clean = uncomment_mysql(sql)
    tables: dict[str, str] = {}
    for match in re.finditer(
        r"CREATE\s+(?:TEMPORARY\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`([^`]+)`\s*\(",
        clean, re.I,
    ):
        opening = clean.find("(", match.start())
        closing = matching_paren(clean, opening)
        tail_end = clean.find(";", closing)
        if tail_end < 0:
            tail_end = closing
        tables[match.group(1)] = clean[match.start():tail_end + 1]

    inserts = []
    # Statements may span lines and use optional explicit column lists.
    for match in re.finditer(
        r"\bINSERT\s+(?:IGNORE\s+)?INTO\s+`?([^`\s(]+)`?\s*(\([^;]*?\))?\s*VALUES\s*",
        clean, re.I,
    ):
        pos = match.end()
        tuples = 0
        while pos < len(clean):
            while pos < len(clean) and clean[pos].isspace():
                pos += 1
            if pos >= len(clean) or clean[pos] != "(":
                break
            pos = matching_paren(clean, pos) + 1
            tuples += 1
            while pos < len(clean) and clean[pos].isspace():
                pos += 1
            if pos < len(clean) and clean[pos] == ",":
                pos += 1
                continue
            break
        inserts.append({"table": match.group(1), "rows": tuples})
    return tables, inserts


def parse_table(name: str, ddl: str) -> dict[str, Any]:
    m = re.search(r"\bCREATE\s+(?:TEMPORARY\s+)?TABLE\b.*?\((.*)\)\s*(.*)$", ddl, re.I | re.S)
    if not m:
        raise ValueError(f"No se pudo interpretar CREATE TABLE {name}")
    definitions = split_top_level(m.group(1))
    columns, primary_keys, foreign_keys = [], [], []
    unique_keys, indexes = [], []
    for definition in definitions:
        col_match = re.match(r"\s*`([^`]+)`\s+(.+)$", definition, re.S)
        if col_match:
            col_name, rest = col_match.groups()
            type_match = re.match(r"([A-Za-z]+(?:\s+PRECISION)?(?:\s*\([^)]*\))?(?:\s+(?:UNSIGNED|ZEROFILL))*)\s*(.*)$", rest, re.I | re.S)
            sql_type, attrs = type_match.groups() if type_match else (rest.split()[0], rest[len(rest.split()[0]):])
            length = re.search(r"\((.*)\)", sql_type)
            default_match = re.search(r"\bDEFAULT\s+('(?:\\.|[^'])*'|\"(?:\\.|[^\"])*\"|NULL|[\w.+-]+(?:\(\))?)", attrs, re.I)
            extras = []
            for pattern, label in ((r"\bAUTO_INCREMENT\b", "AUTO_INCREMENT"),
                                   (r"\bON\s+UPDATE\s+CURRENT_TIMESTAMP(?:\(\d+\))?", "ON UPDATE CURRENT_TIMESTAMP"),
                                   (r"\bGENERATED\b", "GENERATED")):
                found = re.search(pattern, attrs, re.I)
                if found:
                    extras.append(found.group(0).upper() if label == "GENERATED" else label)
            columns.append({
                "position": len(columns) + 1, "name": col_name, "type": sql_type.strip(),
                "length": length.group(1) if length else "—",
                "nullable": "No" if re.search(r"\bNOT\s+NULL\b", attrs, re.I) else "Sí",
                "default": default_match.group(1) if default_match else "—",
                "extras": "; ".join(extras) or "—", "key": "No", "description": "—",
            })
            continue
        pk = re.match(r"\s*PRIMARY\s+KEY\s*\((.*?)\)", definition, re.I | re.S)
        fk = re.search(r"(?:CONSTRAINT\s+`([^`]+)`\s+)?FOREIGN\s+KEY\s*\((.*?)\)\s*REFERENCES\s+`([^`]+)`\s*\((.*?)\)(.*)", definition, re.I | re.S)
        uk = re.match(r"\s*(?:CONSTRAINT\s+`([^`]+)`\s+)?UNIQUE(?:\s+KEY|\s+INDEX)?\s*`?([^` (]*)`?\s*\((.*?)\)", definition, re.I | re.S)
        idx = re.match(r"\s*(?:KEY|INDEX)\s+`([^`]+)`\s*\((.*?)\)", definition, re.I | re.S)
        names = lambda s: re.findall(r"`([^`]+)`", s)
        if pk:
            primary_keys.extend(names(pk.group(1)))
        elif fk:
            foreign_keys.append({"name": fk.group(1) or "", "columns": names(fk.group(2)),
                                 "table": fk.group(3), "references": names(fk.group(4)),
                                 "on_delete": (re.search(r"ON\s+DELETE\s+(\w+(?:\s+\w+)?)", fk.group(5), re.I) or [None, "—"])[1],
                                 "on_update": (re.search(r"ON\s+UPDATE\s+(\w+(?:\s+\w+)?)", fk.group(5), re.I) or [None, "—"])[1]})
        elif uk:
            unique_keys.append({"name": uk.group(2), "columns": names(uk.group(3))})
        elif idx:
            indexes.append({"name": idx.group(1), "columns": names(idx.group(2))})
    for col in columns:
        if col["name"] in primary_keys:
            col["key"] = "PK"
        fk = next((f for f in foreign_keys if col["name"] in f["columns"]), None)
        if fk:
            col["key"] = (col["key"] + "/" if col["key"] != "No" else "") + f"FK → {fk['table']}"
        if any(col["name"] in u["columns"] for u in unique_keys) and col["key"] == "No":
            col["key"] = "UK"
    tail = m.group(2)
    engine = re.search(r"\bENGINE\s*=\s*(\w+)", tail, re.I)
    return {"name": name, "description": describe_table(name), "row_count": 0, "columns": columns, "primary_key": primary_keys,
            "foreign_keys": foreign_keys, "unique_keys": unique_keys, "indexes": indexes,
            "engine": engine.group(1) if engine else "—"}


def humanize_identifier(identifier: str) -> str:
    """Turn SQL identifiers into readable Spanish words for inferred descriptions."""
    value = re.sub(r"([a-záéíóú])([A-Z])", r"\1 \2", identifier)
    value = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", value)
    words = re.sub(r"[^A-Za-zÁÉÍÓÚáéíóúÑñ0-9]+", " ", value).strip().lower().split()
    ignored = {"tb", "tbc", "tbd", "vw", "id", "fk", "pk", "uk"}
    translated = {
        "user": "usuario", "users": "usuarios", "product": "producto", "products": "productos",
        "category": "categoría", "categories": "categorías", "order": "pedido", "orders": "pedidos",
        "cart": "carrito", "carts": "carritos", "item": "artículo", "items": "artículos",
        "payment": "pago", "payments": "pagos", "address": "dirección", "addresses": "direcciones",
        "log": "registro de actividad", "logs": "registros de actividad", "wishlist": "lista de deseos",
        "provider": "proveedor", "providers": "proveedores", "seller": "vendedor", "buyer": "comprador",
        "method": "método", "methods": "métodos", "type": "tipo", "detail": "detalle",
        "details": "detalles", "status": "estado", "date": "fecha", "name": "nombre",
        "description": "descripción", "price": "precio", "quantity": "cantidad", "stock": "inventario",
        "offer": "oferta", "offers": "ofertas", "review": "reseña", "reviews": "reseñas",
        "image": "imagen", "images": "imágenes", "component": "componente", "components": "componentes",
        "contact": "contacto", "phone": "teléfono", "email": "correo electrónico", "role": "rol",
        "permission": "permiso", "token": "token", "session": "sesión", "user": "usuario",
        "creation": "creación", "created": "creación", "update": "actualización", "last": "última",
        "first": "principal", "street": "calle", "city": "ciudad", "state": "estado",
        "postal": "postal", "code": "código", "country": "país", "subtotal": "subtotal",
        "total": "total", "discount": "descuento", "tax": "impuesto", "shipping": "envío",
        "color": "color", "size": "talla", "brand": "marca", "sku": "SKU", "url": "URL",
        "operation": "operación", "table": "tabla", "db": "base de datos", "user": "usuario",
        "rating": "calificación", "comment": "comentario", "content": "contenido", "title": "título",
    }
    return " ".join(translated.get(word, word) for word in words if word not in ignored) or identifier.replace("_", " ")


def describe_table(name: str) -> str:
    subject = humanize_identifier(name)
    return f"Almacena la información de {subject}, incluyendo los datos asociados que permiten gestionarlos dentro del sistema."


def describe_column(table_name: str, column_name: str, sql_type: str, key: str) -> str:
    name = column_name.lower()
    subject = humanize_identifier(column_name)
    table_subject = humanize_identifier(table_name)
    if "PK" in key:
        return f"Identificador único de {table_subject}; permite distinguir cada registro."
    if "FK" in key:
        target = key.split("→", 1)[-1].strip()
        return f"Referencia que vincula este registro con {humanize_identifier(target)}."
    if name in {"created_at", "creation_date", "created_date", "date_created"} or "creation date" in subject:
        return "Fecha y hora en que se creó el registro."
    if name in {"updated_at", "last_update", "update_date", "modified_at"} or "actualización" in subject:
        return "Fecha y hora de la última actualización del registro."
    if "status" in name or "estado" in subject:
        return "Estado actual del registro, usado para controlar su disponibilidad o ciclo de vida."
    if "email" in name:
        return "Dirección de correo electrónico asociada al registro."
    if "password" in name or "passwd" in name:
        return "Dato de autenticación asociado a la cuenta; debe almacenarse protegido."
    if "quantity" in name or "amount" in name or "stock" in name:
        return f"Cantidad registrada para {table_subject}."
    if "price" in name or "subtotal" in name or "total" in name or "cost" in name:
        return f"Valor monetario asociado a {table_subject}."
    if "description" in name or "comment" in name or "note" in name:
        return f"Texto descriptivo o nota relacionada con {table_subject}."
    if "name" in name or "title" in name:
        return f"Nombre o título legible de {table_subject}."
    if "date" in name or "time" in name:
        return f"Fecha u hora relevante para {table_subject}."
    if "FK" in key:
        return f"Campo de relación entre {table_subject} y otra entidad."
    return f"Dato de {subject} utilizado para describir o gestionar {table_subject} (tipo SQL: {sql_type})."


def scan_routines(sql: str) -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    clean = uncomment_mysql(sql)
    found: list[dict[str, str]] = []
    # MySQL dumps can wrap the CREATE keyword and DEFINER in executable comments.
    for kind in ("VIEW", "TRIGGER", "PROCEDURE", "FUNCTION"):
        pattern = rf"\bCREATE\s+(?:(?:OR\s+REPLACE)\s+)?(?:DEFINER\s*=\s*[^\s]+\s+)?(?:ALGORITHM\s*=\s*\w+\s+)?{kind}\s+`([^`]+)`"
        for m in re.finditer(pattern, clean, re.I):
            # Capture a useful definition window through its delimiter; routines may end with END;;.
            end = clean.find(";;", m.start()) if kind in ("TRIGGER", "PROCEDURE", "FUNCTION") else clean.find(";", m.start())
            if end < 0: end = len(clean) - 1
            found.append({"kind": kind.lower(), "name": m.group(1), "sql": clean[m.start():end + (2 if kind in ("TRIGGER", "PROCEDURE", "FUNCTION") else 1)].strip()})
    grouped = {k: [x for x in found if x["kind"] == k] for k in ("view", "trigger", "procedure", "function")}
    return grouped["view"], grouped["trigger"], grouped["procedure"], grouped["function"]


def write_excel(data: dict[str, Any]) -> None:
    try:
        from openpyxl import Workbook
        from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
        from openpyxl.utils import get_column_letter
    except ImportError:
        write_excel_stdlib(data)
        return
    wb = Workbook()
    ws = wb.active
    ws.title = "Dashboard"
    ws.sheet_view.showGridLines = False
    ws.merge_cells("A1:F1")
    ws["A1"] = "DICCIONARIO DE DATOS  /  MYSQL"
    ws["A1"].font = Font(name="Aptos Display", size=18, bold=True, color="FFFFFF")
    ws["A1"].fill = PatternFill("solid", fgColor="09090B")
    ws["A1"].alignment = Alignment(vertical="center")
    ws.row_dimensions[1].height = 38
    ws.merge_cells("A2:F2")
    ws["A2"] = f"Fuente: {data['source']}   ·   Filas contadas desde INSERT del respaldo"
    ws["A2"].font = Font(color="A1A1AA", italic=True, size=10)
    metrics = [("TABLAS", data["metrics"]["tables"]), ("REGISTROS", data["metrics"]["records"]),
               ("VISTAS", data["metrics"]["views"]), ("TRIGGERS", data["metrics"]["triggers"]),
               ("PROCEDIMIENTOS / FUNCIONES", data["metrics"]["routines"])]
    for i, (label, value) in enumerate(metrics):
        col = i + 1
        ws.cell(4, col, label).font = Font(color="A1A1AA", bold=True, size=9)
        ws.cell(5, col, value).font = Font(color="FFFFFF", bold=True, size=20)
        for row in (4, 5):
            ws.cell(row, col).fill = PatternFill("solid", fgColor="18181B")
            ws.cell(row, col).alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    ws.row_dimensions[4].height = 27
    ws.row_dimensions[5].height = 42
    ws.append([])
    headers = ["Tabla", "Descripción", "Registros", "Columnas", "Motor", "Llaves primarias"]
    ws.append(headers)
    for t in data["tables"]:
        ws.append([t["name"], t["description"], t["row_count"], len(t["columns"]), t["engine"], ", ".join(t["primary_key"]) or "—"])
    style_sheet(ws, header_row=7)
    ws.freeze_panes = "A8"
    for table in data["tables"]:
        sh = wb.create_sheet(safe_sheet_name(table["name"]))
        sh.sheet_view.showGridLines = False
        sh.merge_cells("A1:I1")
        sh["A1"] = table["name"]
        sh["A1"].font = Font(color="FFFFFF", bold=True, size=16)
        sh["A1"].fill = PatternFill("solid", fgColor="09090B")
        sh.merge_cells("A2:I2")
        sh["A2"] = f"{table['row_count']:,} registros   ·   {len(table['columns'])} columnas   ·   Motor: {table['engine']}"
        sh["A2"].font = Font(color="D4D4D8", bold=True, size=11)
        sh["A2"].fill = PatternFill("solid", fgColor="18181B")
        heads = ["#", "Nombre", "Tipo", "Longitud", "NULL", "Default", "Extras", "Llave", "Descripción"]
        sh.append(heads)
        for c in table["columns"]:
            sh.append([c[k] for k in ("position", "name", "type", "length", "nullable", "default", "extras", "key", "description")])
        style_sheet(sh, header_row=3)
        sh.freeze_panes = "A4"
        sh.auto_filter.ref = f"A3:I{max(3, sh.max_row)}"
        for row in sh.iter_rows(min_row=4):
            key = str(row[7].value or "")
            if "PK" in key:
                row[7].font = Font(color="FBBF24", bold=True)
            elif "FK" in key:
                row[7].font = Font(color="38BDF8", bold=True)
    OUT.mkdir(parents=True, exist_ok=True)
    wb.save(OUT / "diccionario_datos.xlsx")


def write_excel_stdlib(data: dict[str, Any]) -> None:
    """Fallback XLSX writer with dark fills, borders, filters and frozen headers."""
    from html import escape
    from zipfile import ZIP_DEFLATED, ZipFile
    sheets: list[tuple[str, list[list[Any]]]] = []
    dashboard = [["DICCIONARIO DE DATOS  /  MYSQL"], [f"Fuente: {data['source']} · Filas contadas desde INSERT"], [],
                 ["TABLAS", "REGISTROS", "VISTAS", "TRIGGERS", "PROCEDIMIENTOS / FUNCIONES"],
                 [data["metrics"]["tables"], data["metrics"]["records"], data["metrics"]["views"], data["metrics"]["triggers"], data["metrics"]["routines"]], [],
                 ["Tabla", "Descripción", "Registros", "Columnas", "Motor", "Llaves primarias"]]
    dashboard += [[t["name"], t["description"], t["row_count"], len(t["columns"]), t["engine"], ", ".join(t["primary_key"]) or "—"] for t in data["tables"]]
    sheets.append(("Dashboard", dashboard))
    for table in data["tables"]:
        rows = [[table["name"]], [f"{table['row_count']:,} registros · {len(table['columns'])} columnas · Motor: {table['engine']}"],
                ["#", "Nombre", "Tipo", "Longitud", "NULL", "Default", "Extras", "Llave", "Descripción"]]
        rows += [[c[k] for k in ("position", "name", "type", "length", "nullable", "default", "extras", "key", "description")] for c in table["columns"]]
        sheets.append((safe_sheet_name(table["name"]), rows))

    def colname(n: int) -> str:
        result = ""
        while n:
            n, rem = divmod(n - 1, 26)
            result = chr(65 + rem) + result
        return result

    def cell_xml(value: Any, ref: str, style: int) -> str:
        if value is None: value = ""
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            return f'<c r="{ref}" s="{style}"><v>{value}</v></c>'
        return f'<c r="{ref}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{escape(str(value))}</t></is></c>'

    with ZipFile(OUT / "diccionario_datos.xlsx", "w", ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' + ''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(1, len(sheets)+1)) + '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>')
        z.writestr("_rels/.rels", '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
        z.writestr("xl/workbook.xml", '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>' + ''.join(f'<sheet name="{escape(n)}" sheetId="{i}" r:id="rId{i}"/>' for i, (n, _) in enumerate(sheets, 1)) + '</sheets></workbook>')
        z.writestr("xl/_rels/workbook.xml.rels", '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + ''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>' for i in range(1, len(sheets)+1)) + f'<Relationship Id="rId{len(sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
        z.writestr("xl/styles.xml", '<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="10"/><color rgb="FFD4D4D8"/><name val="Aptos"/></font><font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Aptos"/></font></fonts><fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF09090B"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FF18181B"/></patternFill></fill></fills><borders count="2"><border/><border><bottom style="thin"><color rgb="FF27272A"/></bottom></border></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="4"><xf numFmtId="0" fontId="0" fillId="3" borderId="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="3" borderId="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="0" fillId="2" borderId="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf></cellXfs></styleSheet>')
        for i, (name, rows) in enumerate(sheets, 1):
            xml_rows = []
            for ri, row in enumerate(rows, 1):
                style = 1 if (name == "Dashboard" and ri in (1, 7)) or (name != "Dashboard" and ri in (1, 3)) else 3 if ri <= 2 else 0
                cells = ''.join(cell_xml(v, f"{colname(ci)}{ri}", style) for ci, v in enumerate(row, 1))
                xml_rows.append(f'<row r="{ri}">{cells}</row>')
            max_col = max((len(r) for r in rows), default=1)
            header = 7 if name == "Dashboard" else 3
            z.writestr(f"xl/worksheets/sheet{i}.xml", '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView showGridLines="0" workbookViewId="0"><pane ySplit="' + str(header) + '" topLeftCell="A' + str(header+1) + '" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight="20"/><cols>' + ''.join(f'<col min="{c}" max="{c}" width="22" customWidth="1"/>' for c in range(1, max_col+1)) + '</cols><sheetData>' + ''.join(xml_rows) + f'</sheetData><autoFilter ref="A{header}:{colname(max_col)}{max(len(rows), header)}"/></worksheet>')


def safe_sheet_name(name: str) -> str:
    return re.sub(r"[\\/*?:\[\]]", "_", name)[:31] or "Tabla"


def style_sheet(ws: Any, header_row: int) -> None:
    from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
    from openpyxl.utils import get_column_letter
    thin = Side(style="thin", color="27272A")
    for row in ws.iter_rows():
        for cell in row:
            cell.fill = PatternFill("solid", fgColor="09090B" if cell.row == 1 else "18181B" if cell.row in (2, 4, 5, header_row) else ("111113" if cell.row % 2 == 0 else "151518"))
            cell.font = Font(name="Aptos", color="FFFFFF" if cell.row == header_row or cell.row == 1 else "D4D4D8", bold=cell.row == header_row)
            cell.border = Border(bottom=thin)
            cell.alignment = Alignment(vertical="top", wrap_text=True)
    for cell in ws[header_row]:
        cell.fill = PatternFill("solid", fgColor="09090B")
        cell.font = Font(color="FFFFFF", bold=True)
    for col in ws.columns:
        vals = [len(str(c.value or "")) for c in list(col)[:100]]
        width = min(45, max(12, max(vals, default=12) + 2))
        ws.column_dimensions[get_column_letter(col[0].column)].width = width


def mermaid_type(sql_type: str) -> str:
    return re.sub(r"[^A-Za-z0-9_(),]", "_", sql_type).strip("_") or "unknown"


def quote_dbml(sql_type: str) -> str:
    return sql_type if re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*(?:\([^\n]*\))?(?:\s+(?:unsigned|zerofill))?", sql_type, re.I) else f'"{sql_type.replace(chr(34), chr(39))}"'


def generate() -> dict[str, Any]:
    if not SOURCE.is_file():
        raise FileNotFoundError(f"No existe el respaldo esperado: {SOURCE}")
    raw = SOURCE.read_text(encoding="utf-8-sig", errors="replace")
    definitions, inserts = extract_objects(raw)
    if not definitions:
        raise ValueError("No se encontraron definiciones CREATE TABLE en el respaldo")
    tables = [parse_table(name, ddl) for name, ddl in definitions.items()]
    for table in tables:
        for column in table["columns"]:
            column["description"] = describe_column(table["name"], column["name"], column["type"], column["key"])
    counts = Counter()
    for ins in inserts:
        counts[ins["table"]] += ins["rows"]
    for table in tables:
        table["row_count"] = counts[table["name"]]
    views, triggers, procedures, functions = scan_routines(raw)
    metrics = {"tables": len(tables), "records": sum(t["row_count"] for t in tables),
               "views": len(views), "triggers": len(triggers), "routines": len(procedures) + len(functions)}
    result = {"source": str(SOURCE.relative_to(ROOT)).replace("\\", "/"), "metrics": metrics,
              "tables": tables, "views": views, "triggers": triggers,
              "procedures": procedures, "functions": functions}
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "estructura.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    write_excel(result)
    write_mermaid(result)
    write_dbml(result)
    write_html(result)
    return result


def write_mermaid(data: dict[str, Any]) -> None:
    lines = ["%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#111', 'edgeLabelBackground':'#222'}}}%%", "erDiagram"]
    for table in data["tables"]:
        lines.append(f"  {table['name']} {{")
        for c in table["columns"]:
            marker = " PK" if c["name"] in table["primary_key"] else " FK" if "FK" in c["key"] else ""
            lines.append(f"    {mermaid_type(c['type'])} {c['name']}{marker}")
        lines.append("  }")
    # Mermaid cardinality: each FK row belongs to exactly one referenced row;
    # the referenced row may have zero or many referencing rows.
    for table in data["tables"]:
        for fk in table["foreign_keys"]:
            if fk["table"] in {t["name"] for t in data["tables"]}:
                label = ", ".join(fk["columns"])
                lines.append(f'  {fk["table"]} ||--o{{ {table["name"]} : "{label}"')
    (OUT / "diagrama_er.mmd").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_html(data: dict[str, Any]) -> None:
    """Create a self-contained dark schema browser; Mermaid is loaded via CDN."""
    from html import escape
    import json as json_module

    def e(value: Any) -> str:
        return escape(str(value if value is not None else "—"), quote=True)

    cards = "".join(
        f'<article class="metric"><div class="metric-label">{e(label)}</div><div class="metric-value">{e(value)}</div></article>'
        for label, value in (("Tablas", data["metrics"]["tables"]), ("Registros", f"{data['metrics']['records']:,}"),
                             ("Vistas", data["metrics"]["views"]), ("Triggers", data["metrics"]["triggers"]),
                             ("Procedimientos / funciones", data["metrics"]["routines"]))
    )
    nav = "".join(f'<a class="nav-item" href="#table-{i}" title="{e(t["name"])}"><span class="nav-dot"></span>{e(t["name"])}</a>' for i, t in enumerate(data["tables"]))
    sections = []
    for i, table in enumerate(data["tables"]):
        rows = []
        for c in table["columns"]:
            key = c["key"]
            key_class = "pk" if "PK" in key else "fk" if "FK" in key else ""
            rows.append("<tr>" + "".join((
                f'<td class="muted">{e(c["position"])}</td>', f'<td class="column-name">{e(c["name"])}</td>',
                f'<td><code>{e(c["type"])}</code></td>', f'<td>{e(c["length"])}</td>',
                f'<td><span class="null-badge {"required" if c["nullable"] == "No" else "optional"}">{e(c["nullable"])}</span></td>',
                f'<td>{e(c["default"])}</td>', f'<td>{e(c["extras"])}</td>',
                f'<td><span class="key-badge {key_class}">{e(key)}</span></td>', f'<td class="description">{e(c["description"])}</td>'
            )) + "</tr>")
        fk_html = "".join(f'<span class="relation-chip">{e(", ".join(fk["columns"]))} <b>→</b> {e(fk["table"])}.{e(", ".join(fk["references"]))}</span>' for fk in table["foreign_keys"])
        sections.append(f'''<section class="table-card" id="table-{i}" data-table="{e(table["name"]).lower()}">
          <div class="table-heading"><div><div class="eyebrow">TABLA</div><h2>{e(table["name"])}</h2><p class="table-description">{e(table["description"])}</p></div>
          <div class="table-stats"><span class="row-count">{table["row_count"]:,}<small> registros</small></span><span class="column-count">{len(table["columns"])} columnas</span><span class="engine">{e(table["engine"])}</span></div></div>
          {f'<div class="relations">{fk_html}</div>' if fk_html else ''}
          <div class="table-scroll"><table><thead><tr><th>#</th><th>Nombre</th><th>Tipo</th><th>Longitud</th><th>NULL</th><th>Default</th><th>Extras</th><th>Llave</th><th>Descripción</th></tr></thead><tbody>{''.join(rows)}</tbody></table></div>
        </section>''')
    graph_cards = []
    graph_links = []
    table_index = {t["name"]: i for i, t in enumerate(data["tables"])}
    for table_i, table in enumerate(data["tables"]):
        field_rows = []
        for col_i, column in enumerate(table["columns"]):
            is_pk = "PK" in column["key"]
            is_fk = "FK" in column["key"]
            icon = "🔑" if is_pk else "↗" if is_fk else "·"
            badge = "PK" if is_pk and not is_fk else "PK · FK" if is_pk and is_fk else "FK" if is_fk else ""
            icon_class = "pk-icon" if is_pk else "fk-icon" if is_fk else "plain-icon"
            badge_class = "pk-key" if is_pk else "fk-key"
            key_badge = f'<span class="field-key {badge_class}">{badge}</span>' if badge else ""
            field_rows.append(f'<div class="erd-field" id="field-{table_i}-{col_i}" data-field="{e(column["name"])}"><span class="field-icon {icon_class}">{icon}</span><span class="field-name">{e(column["name"])}</span><span class="field-type">{e(column["type"])}</span>{key_badge}</div>')
        graph_cards.append(f'<article class="erd-card" id="entity-{table_i}" data-entity="{e(table["name"])}"><header class="erd-card-head"><span class="entity-icon">▤</span><strong>{e(table["name"])}</strong><span class="entity-count">{len(table["columns"])} cols</span></header><div class="erd-card-body">{"".join(field_rows)}</div><footer class="erd-card-foot">{table["row_count"]:,} registros <span>{e(table["engine"])}</span></footer></article>')
        for fk in table["foreign_keys"]:
            target_i = table_index.get(fk["table"])
            if target_i is None:
                continue
            target_table = data["tables"][target_i]
            for source_col, target_col in zip(fk["columns"], fk["references"]):
                source_i = next((i for i, c in enumerate(table["columns"]) if c["name"] == source_col), None)
                target_col_i = next((i for i, c in enumerate(target_table["columns"]) if c["name"] == target_col), None)
                if source_i is not None and target_col_i is not None:
                    graph_links.append({"from": f"field-{target_i}-{target_col_i}", "to": f"field-{table_i}-{source_i}",
                                        "label": f"{fk['table']}.{target_col} → {table['name']}.{source_col}"})
    links_json = json_module.dumps(graph_links, ensure_ascii=False).replace("</", "<\\/")
    html = f'''<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#09090b"><title>Diccionario de datos · {e(data["source"])}</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Mono:wght@400;500&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<style>
:root{{--bg:#09090b;--panel:#111113;--panel2:#18181b;--line:#27272a;--text:#f4f4f5;--muted:#a1a1aa;--subtle:#71717a;--amber:#fbbf24;--blue:#38bdf8;--green:#4ade80}}
*{{box-sizing:border-box}}html{{scroll-behavior:smooth;scroll-padding-top:90px}}body{{margin:0;background:var(--bg);color:var(--text);font-family:Manrope,system-ui,sans-serif;font-size:14px;line-height:1.55}}
a{{color:inherit;text-decoration:none}}button,input{{font:inherit}}.topbar{{height:64px;position:sticky;top:0;z-index:5;background:rgba(9,9,11,.9);backdrop-filter:blur(14px);border-bottom:1px solid var(--line);display:flex;align-items:center;justify-content:space-between;padding:0 28px}}
.brand{{display:flex;gap:11px;align-items:center;font-weight:800;letter-spacing:-.03em}}.brand-mark{{width:28px;height:28px;border-radius:8px;background:#f4f4f5;color:#09090b;display:grid;place-items:center;font-size:15px;font-weight:900}}.brand small{{display:block;color:var(--muted);font:10px 'DM Mono',monospace;letter-spacing:.08em}}
.top-meta{{color:var(--muted);font:11px 'DM Mono',monospace}}.layout{{display:grid;grid-template-columns:250px minmax(0,1fr);max-width:1680px;margin:auto;min-height:calc(100vh - 64px)}}.sidebar{{border-right:1px solid var(--line);padding:25px 15px;position:sticky;top:64px;height:calc(100vh - 64px);overflow:auto}}.side-label,.eyebrow{{color:var(--subtle);font:10px 'DM Mono',monospace;letter-spacing:.13em;text-transform:uppercase}}.side-label{{padding:0 11px 12px}}.nav-item{{display:flex;align-items:center;gap:10px;padding:8px 11px;color:#a1a1aa;font-size:12px;border-radius:7px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}}.nav-item:hover{{background:var(--panel2);color:#fff}}.nav-dot{{width:5px;height:5px;border-radius:50%;background:#52525b;flex:none}}
main{{padding:44px clamp(20px,4vw,64px) 80px;min-width:0}}.hero{{display:flex;align-items:flex-end;justify-content:space-between;gap:25px;margin-bottom:32px}}.hero h1{{font-size:clamp(28px,4vw,43px);line-height:1.08;letter-spacing:-.055em;margin:10px 0 10px}}.hero p{{color:var(--muted);margin:0;font-size:13px}}.source-chip{{border:1px solid var(--line);background:var(--panel);padding:9px 12px;border-radius:7px;color:#d4d4d8;font:11px 'DM Mono',monospace;white-space:nowrap}}
.metrics{{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px;margin-bottom:48px}}.metric{{background:linear-gradient(145deg,#18181b,#111113);border:1px solid var(--line);border-radius:10px;padding:17px 18px;min-height:106px}}.metric-label{{color:var(--muted);font-size:10px;font-weight:700;letter-spacing:.1em;text-transform:uppercase}}.metric-value{{font-size:30px;font-weight:700;letter-spacing:-.05em;margin-top:8px;font-variant-numeric:tabular-nums}}
.section-head{{display:flex;align-items:end;justify-content:space-between;gap:18px;margin:0 0 17px}}.section-head h2{{font-size:21px;letter-spacing:-.04em;margin:5px 0 0}}.search{{width:min(300px,45vw);background:#111113;border:1px solid var(--line);color:var(--text);border-radius:7px;padding:10px 12px;outline:none}}.search:focus{{border-color:#52525b}}.table-card{{border:1px solid var(--line);background:var(--panel);border-radius:10px;margin:0 0 15px;overflow:hidden;scroll-margin-top:82px}}.table-heading{{padding:17px 20px;display:flex;justify-content:space-between;align-items:center;gap:15px}}.table-heading h2{{font:500 18px 'DM Mono',monospace;letter-spacing:-.04em;margin:4px 0 0}}.table-stats{{display:flex;align-items:center;gap:13px;color:var(--muted);font-size:11px}}.row-count{{color:#fff;font-weight:700;font-size:17px;font-variant-numeric:tabular-nums}}.row-count small{{font-size:10px;color:var(--muted);font-weight:400}}.engine{{border:1px solid #3f3f46;border-radius:4px;padding:3px 7px;font:10px 'DM Mono',monospace}}.relations{{padding:0 20px 14px;display:flex;gap:7px;flex-wrap:wrap}}.relation-chip{{background:#0c1720;border:1px solid #164e63;color:#bae6fd;padding:4px 8px;border-radius:5px;font:10px 'DM Mono',monospace}}.relation-chip b{{color:var(--blue);padding:0 3px}}.table-scroll{{overflow:auto;border-top:1px solid var(--line)}}table{{border-collapse:collapse;width:100%;min-width:950px;text-align:left}}th{{background:#09090b;color:#a1a1aa;font:10px 'DM Mono',monospace;letter-spacing:.08em;text-transform:uppercase;padding:10px 12px;position:sticky;top:0}}td{{padding:10px 12px;border-top:1px solid #202023;color:#d4d4d8;font-size:11px;vertical-align:top}}tbody tr:hover{{background:#1b1b1f}}td code{{font:10px 'DM Mono',monospace;color:#c4b5fd}}.column-name{{color:#fafafa;font:11px 'DM Mono',monospace}}.muted{{color:var(--subtle)}}.null-badge,.key-badge{{display:inline-block;border-radius:4px;padding:2px 6px;font:10px 'DM Mono',monospace;white-space:nowrap}}.required{{color:#fca5a5;background:#2a1115}}.optional{{color:#a1a1aa;background:#222225}}.pk{{color:var(--amber);background:#29200c}}.fk{{color:var(--blue);background:#0c2029}}.key-badge:empty{{display:none}}.description{{color:var(--muted);min-width:120px}}
.table-description{{color:var(--muted);font-size:11px;margin:6px 0 0;max-width:720px}}.diagram-card{{border:1px solid var(--line);background:#050506;border-radius:10px;padding:22px;margin:14px 0 40px;overflow:hidden;position:relative}}.diagram-card.fullscreen{{position:fixed;inset:0;z-index:20;margin:0;border-radius:0;padding:22px 26px;display:flex;flex-direction:column;background:#050506}}.diagram-card h2{{font-size:20px;letter-spacing:-.04em;margin:0 0 4px}}.diagram-card p{{font-size:12px;color:var(--muted);margin:0 0 15px}}.diagram-tools{{position:absolute;right:20px;top:24px;display:flex;gap:8px;z-index:4}}.diagram-tools button{{background:#202023;border:1px solid #3f3f46;color:#e4e4e7;border-radius:6px;padding:7px 10px;cursor:pointer;font-size:11px}}.diagram-tools button:hover{{background:#303036}}#graph-viewport{{position:relative;width:100%;height:100vh;min-height:650px;overflow:hidden;background-color:#050506;background-image:radial-gradient(#202023 1px,transparent 1px);background-size:24px 24px;border:1px solid #202023;border-radius:8px;cursor:grab;touch-action:none}}#graph-viewport.is-panning{{cursor:grabbing}}.diagram-card.fullscreen #graph-viewport{{flex:1;height:auto;min-height:0;margin-top:8px;border-radius:0}}#graph-stage{{position:absolute;left:0;top:0;width:3200px;height:3200px;transform-origin:0 0}}#graph-lines{{position:absolute;left:0;top:0;width:100%;height:100%;overflow:visible;pointer-events:none}}.fk-link{{fill:none;stroke:#00f3ff;stroke-width:1.7;opacity:.64;marker-end:url(#fk-arrow);stroke-dasharray:8 9;animation:flow 2.6s linear infinite;filter:drop-shadow(0 0 3px rgba(0,243,255,.55))}}@keyframes flow{{to{{stroke-dashoffset:-34}}}}.erd-card{{position:absolute;left:0;top:0;width:340px;background:#111;border:1px solid #34343a;border-radius:8px;overflow:hidden;box-shadow:0 14px 35px rgba(0,0,0,.5);user-select:none;z-index:1}}.erd-card.is-dragging{{z-index:3;border-color:#00f3ff;box-shadow:0 16px 42px rgba(0,243,255,.13)}}.erd-card-head{{height:42px;background:linear-gradient(100deg,#242428,#171719);border-bottom:1px solid #3a3a40;display:flex;align-items:center;gap:9px;padding:0 12px;cursor:grab}}.erd-card-head:active{{cursor:grabbing}}.entity-icon{{font-size:14px;color:#00f3ff}}.erd-card-head strong{{font:600 12px 'DM Mono',monospace;color:#fafafa;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;flex:1}}.entity-count{{font:9px 'DM Mono',monospace;color:#8b8b95;background:#101012;border:1px solid #333338;border-radius:4px;padding:2px 5px;white-space:nowrap}}.erd-card-body{{padding:4px 0;overflow:visible}}.erd-field{{height:28px;display:flex;align-items:center;gap:7px;padding:0 9px;border-bottom:1px solid #1d1d20;white-space:nowrap}}.erd-field:last-child{{border-bottom:0}}.field-icon{{width:15px;text-align:center;flex:none;font-size:11px}}.pk-icon{{color:#fbbf24}}.fk-icon{{color:#22d3ee}}.plain-icon{{color:#52525b}}.field-name{{font:10px 'DM Mono',monospace;color:#e4e4e7;overflow:hidden;text-overflow:ellipsis;flex:1}}.field-type{{font:9px 'DM Mono',monospace;color:#92929d;max-width:100px;overflow:hidden;text-overflow:ellipsis}}.field-key{{font:8px 'DM Mono',monospace;border-radius:3px;padding:1px 4px}}.pk-key{{color:#fbbf24;background:#29200c}}.fk-key{{color:#67e8f9;background:#0c2029}}.erd-card-foot{{border-top:1px solid #2b2b30;padding:6px 10px;color:#777780;font:9px 'DM Mono',monospace;display:flex;justify-content:space-between}}.erd-card-foot span{{color:#595961}}.diagram-legend{{position:absolute;bottom:16px;left:16px;z-index:4;color:#a1a1aa;background:rgba(9,9,11,.92);border:1px solid #27272a;border-radius:6px;padding:8px 10px;font:10px 'DM Mono',monospace;pointer-events:none}}.diagram-legend b{{color:#00f3ff}}.footer{{border-top:1px solid var(--line);padding-top:18px;color:var(--subtle);font:10px 'DM Mono',monospace}}
@media(max-width:950px){{.layout{{grid-template-columns:190px minmax(0,1fr)}}.metrics{{grid-template-columns:repeat(3,1fr)}}.source-chip{{display:none}}}}
@media(max-width:650px){{.topbar{{padding:0 16px}}.top-meta{{display:none}}.layout{{display:block}}.sidebar{{position:static;height:auto;border-right:0;border-bottom:1px solid var(--line);padding:12px;display:flex;gap:4px;overflow:auto}}.side-label{{display:none}}.nav-item{{background:var(--panel);border:1px solid var(--line)}}main{{padding:28px 14px 55px}}.hero{{display:block}}.metrics{{grid-template-columns:repeat(2,1fr);gap:8px;margin-bottom:35px}}.metric{{padding:13px;min-height:90px}}.metric-value{{font-size:25px}}.section-head{{align-items:stretch;flex-direction:column}}.search{{width:100%}}.table-heading{{align-items:flex-start;flex-direction:column}}.table-stats{{flex-wrap:wrap}}}}
</style></head><body>
<header class="topbar"><a class="brand" href="#top"><span class="brand-mark">D</span><span>DATA / ATLAS<small>RELATIONAL SCHEMA BROWSER</small></span></a><div class="top-meta">MYSQL · DOCUMENTACIÓN TÉCNICA</div></header>
<div class="layout"><aside class="sidebar"><div class="side-label">Esquema · {len(data['tables'])} tablas</div>{nav}<a class="nav-item" href="#relational-diagram"><span class="nav-dot"></span>Diagrama relacional</a></aside>
<main id="top"><section class="hero"><div><div class="eyebrow">INVENTARIO DE BASE DE DATOS</div><h1>Diccionario de datos</h1><p>Vista técnica del esquema, sus relaciones y volumen de datos.</p></div><div class="source-chip">SOURCE&nbsp; / &nbsp;{e(data['source'])}</div></section>
<section class="metrics" aria-label="Métricas globales">{cards}</section>
<div class="section-head"><div><div class="eyebrow">CATÁLOGO</div><h2>Tablas y columnas</h2></div><input id="search" class="search" type="search" placeholder="Filtrar tablas por nombre…" aria-label="Filtrar tablas"></div>
{''.join(sections)}
<section class="diagram-card" id="relational-diagram"><div class="eyebrow">MAPA DEL ESQUEMA</div><h2>Diagrama entidad–relación</h2><p>Arrastra las cabeceras para mover tablas; rueda para zoom y arrastra el fondo para navegar. Las conexiones unen directamente la columna PK con su campo FK.</p><div class="diagram-tools"><button type="button" id="zoom-in" title="Acercar">＋ Zoom</button><button type="button" id="zoom-out" title="Alejar">－ Zoom</button><button type="button" id="zoom-reset" title="Ajustar grafo">⟲ Ajustar</button><button type="button" id="fullscreen" title="Alternar pantalla completa">⛶ Pantalla completa</button></div><div id="graph-viewport"><div id="graph-stage"><svg id="graph-lines" aria-hidden="true"><defs><marker id="fk-arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#00f3ff"/></marker></defs></svg><div id="graph-cards">{''.join(graph_cards)}</div></div><div class="diagram-legend"><b>━━➤</b> PK → FK · <span style="color:#fbbf24">🔑 PK</span> · <span style="color:#22d3ee">↗ FK</span></div></div></section>
<footer class="footer">GENERADO DESDE {e(data['source'])} · CONTEOS BASADOS EN INSERTS DEL DUMP</footer></main></div>
<!-- Grafo ER nativo: tarjetas HTML y conectores SVG para enlazar columnas exactas. -->
<script>
const graphLinks={links_json};const viewport=document.getElementById('graph-viewport');const stage=document.getElementById('graph-stage');const svg=document.getElementById('graph-lines');let scale=1,panX=0,panY=0;
function applyTransform(){{stage.style.transform=`translate(${{panX}}px,${{panY}}px) scale(${{scale}})`;}}
function layoutCards(){{const cards=[...document.querySelectorAll('.erd-card')],columns=5,gapX=150,gapY=105,margin=120;let y=margin;for(let start=0;start<cards.length;start+=columns){{const row=cards.slice(start,start+columns);let h=0;row.forEach((card,index)=>{{card.style.left=`${{margin+index*(340+gapX)}}px`;card.style.top=`${{y}}px`;h=Math.max(h,card.offsetHeight);}});y+=h+gapY;}}const w=margin*2+columns*(340+gapX),h=y+margin;stage.style.width=`${{w}}px`;stage.style.height=`${{h}}px`;svg.setAttribute('viewBox',`0 0 ${{w}} ${{h}}`);drawLinks();fitGraph();}}
function drawLinks(){{svg.querySelectorAll('.fk-link').forEach(p=>p.remove());for(const l of graphLinks){{const from=document.getElementById(l.from),to=document.getElementById(l.to);if(!from||!to)continue;const a=from.getBoundingClientRect(),b=to.getBoundingClientRect(),s=stage.getBoundingClientRect(),x1=(a.right-s.left)/scale,y1=(a.top+a.height/2-s.top)/scale,x2=(b.left-s.left)/scale,y2=(b.top+b.height/2-s.top)/scale,dx=Math.max(70,Math.abs(x2-x1)*.48),p=document.createElementNS('http://www.w3.org/2000/svg','path');p.setAttribute('class','fk-link');p.setAttribute('d',`M ${{x1}} ${{y1}} C ${{x1+dx}} ${{y1}}, ${{x2-dx}} ${{y2}}, ${{x2}} ${{y2}}`);p.setAttribute('marker-end','url(#fk-arrow)');p.setAttribute('aria-label',l.label);svg.appendChild(p);}}}}
function fitGraph(){{const w=parseFloat(stage.style.width),h=parseFloat(stage.style.height),vw=viewport.clientWidth,vh=viewport.clientHeight;scale=Math.min((vw-70)/w,(vh-70)/h,1);panX=(vw-w*scale)/2;panY=(vh-h*scale)/2;applyTransform();}}
document.querySelectorAll('.erd-card').forEach(card=>{{const head=card.querySelector('.erd-card-head');head.addEventListener('pointerdown',ev=>{{if(ev.button!==0)return;ev.preventDefault();ev.stopPropagation();card.classList.add('is-dragging');head.setPointerCapture(ev.pointerId);const sx=ev.clientX,sy=ev.clientY,l=card.offsetLeft,t=card.offsetTop;function move(e){{card.style.left=`${{l+(e.clientX-sx)/scale}}px`;card.style.top=`${{t+(e.clientY-sy)/scale}}px`;drawLinks();}}function end(){{card.classList.remove('is-dragging');head.removeEventListener('pointermove',move);head.removeEventListener('pointerup',end);head.removeEventListener('pointercancel',end);}}head.addEventListener('pointermove',move);head.addEventListener('pointerup',end);head.addEventListener('pointercancel',end);}});}});
let panning=false,lx=0,ly=0;viewport.addEventListener('pointerdown',e=>{{if(e.target.closest('.erd-card'))return;panning=true;lx=e.clientX;ly=e.clientY;viewport.classList.add('is-panning');viewport.setPointerCapture(e.pointerId);}});viewport.addEventListener('pointermove',e=>{{if(!panning)return;panX+=e.clientX-lx;panY+=e.clientY-ly;lx=e.clientX;ly=e.clientY;applyTransform();}});function stopPan(){{panning=false;viewport.classList.remove('is-panning');}}viewport.addEventListener('pointerup',stopPan);viewport.addEventListener('pointercancel',stopPan);
viewport.addEventListener('wheel',e=>{{e.preventDefault();const r=viewport.getBoundingClientRect(),mx=e.clientX-r.left,my=e.clientY-r.top,old=scale;scale=Math.min(2.5,Math.max(.12,scale*(e.deltaY<0?1.12:.89)));panX=mx-(mx-panX)*(scale/old);panY=my-(my-panY)*(scale/old);applyTransform();}},{{passive:false}});
document.getElementById('zoom-in').onclick=()=>{{scale=Math.min(2.5,scale*1.2);applyTransform();}};document.getElementById('zoom-out').onclick=()=>{{scale=Math.max(.12,scale/1.2);applyTransform();}};document.getElementById('zoom-reset').onclick=fitGraph;
const diagramCard=document.getElementById('relational-diagram');document.getElementById('fullscreen').addEventListener('click',()=>{{diagramCard.classList.toggle('fullscreen');document.getElementById('fullscreen').textContent=diagramCard.classList.contains('fullscreen')?'⛶ Salir de pantalla completa':'⛶ Pantalla completa';requestAnimationFrame(()=>{{fitGraph();drawLinks();}});}});document.addEventListener('keydown',e=>{{if(e.key==='Escape'&&diagramCard.classList.contains('fullscreen'))document.getElementById('fullscreen').click();}});window.addEventListener('resize',()=>{{if(!diagramCard.classList.contains('fullscreen'))fitGraph();}});requestAnimationFrame(layoutCards);
/*
  autoResize:true,interaction:{{hover:true,zoomView:true,dragView:true,dragNodes:true,hoverConnectedEdges:true,navigationButtons:false,keyboard:{{enabled:true}}}},
  physics:{{enabled:true,solver:'barnesHut',barnesHut:{{gravitationalConstant:-3000,centralGravity:0.1,springLength:250,springConstant:0.035,damping:0.5,avoidOverlap:1}},stabilization:{{enabled:true,iterations:1500,updateInterval:50,fit:true}},minVelocity:0.45}},
  nodes:{{shape:'box',shapeProperties:{{borderRadius:7}},margin:18,widthConstraint:{{minimum:190,maximum:280}},font:{{face:'Manrope',color:'#ffffff',size:16,bold:true}},color:{{background:'#1a1a1a',border:'#3f3f46',highlight:{{background:'#242424',border:'#00f3ff'}}}},borderWidth:1,borderWidthSelected:2,chosen:{{node:(values)=>{{values.borderColor='#00f3ff';values.borderWidth=2;}}}}}},
  edges:{{smooth:{{enabled:true,type:'dynamic',roundness:0.35}},arrows:{{to:{{enabled:true,scaleFactor:0.7}}}},font:{{align:'middle',background:'#09090b'}},selectionWidth:2}},
  configure:{{enabled:false}}
}});
network.once('stabilizationIterationsDone',()=>network.fit({{animation:{{duration:500,easingFunction:'easeInOutQuad'}}}}));
document.getElementById('zoom-in').onclick=()=>network.moveTo({{scale:network.getScale()*1.25,animation:true}});document.getElementById('zoom-out').onclick=()=>network.moveTo({{scale:network.getScale()/1.25,animation:true}});document.getElementById('zoom-reset').onclick=()=>network.fit({{animation:{{duration:500,easingFunction:'easeInOutQuad'}}}});
const diagramCard=document.getElementById('relational-diagram');document.getElementById('fullscreen').addEventListener('click',()=>{{diagramCard.classList.toggle('fullscreen');document.getElementById('fullscreen').textContent=diagramCard.classList.contains('fullscreen')?'⛶ Salir de pantalla completa':'⛶ Pantalla completa';requestAnimationFrame(()=>network.redraw());}});document.addEventListener('keydown',(event)=>{{if(event.key==='Escape'&&diagramCard.classList.contains('fullscreen'))document.getElementById('fullscreen').click();}});
*/
document.getElementById('search').addEventListener('input',(event)=>{{const query=event.target.value.trim().toLowerCase();document.querySelectorAll('.table-card').forEach((card)=>{{card.hidden=!card.dataset.table.includes(query);}});}});
</script></body></html>'''
    (OUT / "index.html").write_text(html, encoding="utf-8")


def write_dbml(data: dict[str, Any]) -> None:
    lines = []
    for table in data["tables"]:
        lines.append(f"Table {table['name']} {{")
        for c in table["columns"]:
            opts = []
            if c["name"] in table["primary_key"]: opts.append("pk")
            if c["nullable"] == "No": opts.append("not null")
            if c["extras"] != "—": opts.append(f"note: '{c['extras'].replace(chr(39), chr(39)*2)}'")
            suffix = f" [{', '.join(opts)}]" if opts else ""
            lines.append(f"  {c['name']} {quote_dbml(c['type'])}{suffix}")
        for key in table["unique_keys"]:
            if key["columns"]:
                lines.append(f"  indexes {{ ({', '.join(key['columns'])}) [unique, name: '{key['name']}'] }}")
        lines.append("}\n")
    for table in data["tables"]:
        for fk in table["foreign_keys"]:
            for source_col, target_col in zip(fk["columns"], fk["references"]):
                lines.append(f"Ref: {table['name']}.{source_col} > {fk['table']}.{target_col}")
    (OUT / "schema.dbml").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    try:
        report = generate()
    except Exception as error:
        print(f"Error al generar la documentación: {error}", file=sys.stderr)
        raise SystemExit(1)
    print(json.dumps(report["metrics"], ensure_ascii=False, indent=2))
    print(f"Archivos generados en: {OUT}")
