# Diccionario de datos

Archivos generados desde `estructura.json` a partir de `respaldo-20-1-10-2026.sql`. El extractor `generar.py` solo captura bloques CREATE TABLE/VIEW/TRIGGER/PROCEDURE y descarta todas las demás líneas, incluidos INSERT.

## Contenido
- `estructura.json`: metadata de esquema y SQL de objetos DDL.
- `diccionario_datos.md`: documento navegable.
- `diccionario_datos.xlsx`: libro con hojas técnicas, filtros y encabezados.
- `diagrama_er.mmd`: ER Mermaid.
- `schema.dbml`: modelo DBML.
- `generar.py`: regenerador desde el dump (reconstruye JSON y todos los entregables).

## Regenerar
Desde la raíz del repositorio, ejecuta `py diccionario_datos/generar.py` (o `python diccionario_datos/generar.py`). Requiere Python 3; Excel se genera con `openpyxl` si está disponible o con la biblioteca estándar. El dump hallado no coincide con el inventario pedido; revisa la sección de calidad antes de usar el resultado como documentación definitiva.
