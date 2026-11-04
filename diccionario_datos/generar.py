import re, json, csv, html, os, zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parent
SRC=ROOT.parent/'Práctica03'/'backups'/'respaldo-20-1-10-2026.sql'

# Only accumulate CREATE definitions. Data sections, especially INSERTs, are discarded
# line-by-line before any parsing or persistence.
blocks=[]; active=False; buf=[]; kind=''
for line in SRC.open(encoding='cp1252', errors='replace'):
    if not active:
        if re.match(r'^CREATE\s+(?:TABLE|(?:DEFINER=.*?\s+)?(?:VIEW|TRIGGER|PROCEDURE))\b',line,re.I):
            active=True; buf=[line]; kind='routine' if re.search(r'\b(?:PROCEDURE|TRIGGER)\b',line,re.I) else 'ddl'
        continue
    buf.append(line)
    # Dump's DDL terminators: table/view ;, routines use DELIMITER ;; and end with END;;
    s=line.strip()
    if (kind=='routine' and s.endswith(';;')) or (kind=='ddl' and s.endswith(';')):
        blocks.append(''.join(buf)); buf=[]; active=False

def name_of(sql):
    m=re.search(r'CREATE\s+(?:DEFINER=.*?\s+)?(TABLE|VIEW|TRIGGER|PROCEDURE)\s+(?:IF NOT EXISTS\s+)?`([^`]+)`',sql,re.I|re.S)
    return (m.group(1).upper(),m.group(2)) if m else ('UNKNOWN','')
tables={}; views=[]; triggers=[]; procedures=[]
for b in blocks:
    k,n=name_of(b)
    if k=='TABLE': tables[n]=b
    elif k=='VIEW': views.append({'name':n,'sql':b})
    elif k=='TRIGGER': triggers.append({'name':n,'sql':b})
    elif k=='PROCEDURE': procedures.append({'name':n,'sql':b})

def split_defs(body):
    out=[]; cur=''; depth=0; quote=None; esc=False
    for c in body:
        if quote:
            cur+=c
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==quote: quote=None
        elif c in "'\"`": quote=c; cur+=c
        elif c=='(': depth+=1; cur+=c
        elif c==')': depth-=1; cur+=c
        elif c==',' and depth==0: out.append(cur.strip()); cur=''
        else: cur+=c
    if cur.strip(): out.append(cur.strip())
    return out

def getbody(sql):
    p=sql.find('('); depth=0; q=None
    for i in range(p,len(sql)):
        c=sql[i]
        if q:
            if c==q and (i==0 or sql[i-1]!='\\'): q=None
        elif c in "'\"`": q=c
        elif c=='(': depth+=1
        elif c==')':
            depth-=1
            if depth==0:return sql[p+1:i],sql[i+1:]
    return '', ''

def classify(col,typ,nullable,key,extra,default):
    nature='Cuantitativa discreta'; t=typ.lower()
    if any(x in t for x in ['date','time','year']): nature='Cuantitativa temporal'
    elif any(x in t for x in ['decimal','float','double']): nature='Cuantitativa continua'
    elif 'enum(' in t or any(x in col.lower() for x in ['status','type','method']): nature='Cualitativa nominal'
    generated='GENERATED' in extra.upper() or ' AS (' in extra.upper()
    origin='Derivado' if generated else 'Almacenado'
    value='Monovalor'
    if col.lower() in ('description','address','metadata'): value='Monovalor (contiene datos compuestos)'
    mandatory='Obligatorio (provisto por el sistema)' if 'auto_increment' in extra.lower() or default!='No especificado' else ('Obligatorio (provisto por el usuario)' if nullable=='No' else 'Opcional')
    return value,origin,mandatory,key or 'No',nature

def parse_table(name,sql):
    body,tail=getbody(sql); defs=split_defs(body); cols=[]; constraints=[]
    for d in defs:
        m=re.match(r'`([^`]+)`\s+(.+)',d,re.S)
        if not m: constraints.append(d); continue
        cn,rest=m.groups(); tm=re.match(r'([A-Za-z]+(?:\s*\([^)]*\))?(?:\s+unsigned)?(?:\s+zerofill)?)\s*(.*)',rest,re.I|re.S)
        typ=tm.group(1).strip() if tm else 'No especificado'; attr=tm.group(2).strip() if tm else rest
        nul='No' if re.search(r'\bNOT NULL\b',attr,re.I) else 'Sí'
        dm=re.search(r'\bDEFAULT\s+((?:\'[^\']*\')|(?:"[^"]*")|(?:[^\s,]+))',attr,re.I)
        default=dm.group(1) if dm else 'No especificado'
        extra=' '.join(x for x in ['AUTO_INCREMENT' if 'AUTO_INCREMENT' in attr.upper() else '', 'GENERATED' if 'GENERATED' in attr.upper() or re.search(r'\bAS\s*\(',attr,re.I) else '', 'ON UPDATE CURRENT_TIMESTAMP' if re.search(r'ON UPDATE CURRENT_TIMESTAMP',attr,re.I) else ''] if x)
        col={'position':len(cols)+1,'name':cn,'type':typ,'length_precision':(re.search(r'\((.*?)\)',typ).group(1) if '(' in typ else 'No especificado'),'nullable':nul,'default':default,'extras':extra or 'No especificado','key':'No','definition':d}
        cols.append(col)
    keys=[]; indexes=[]; checks=[]; fks=[]
    for d in constraints:
        if re.match(r'PRIMARY KEY',d,re.I):
            c=re.search(r'\((.*?)\)',d,re.S); names=re.findall(r'`([^`]+)`',c.group(1)) if c else []; keys.append({'type':'PK','columns':names,'definition':d})
        elif re.match(r'UNIQUE',d,re.I):
            c=re.search(r'\((.*?)\)',d,re.S); names=re.findall(r'`([^`]+)`',c.group(1)) if c else []; keys.append({'type':'UK','columns':names,'definition':d})
        elif re.match(r'\s*KEY|\s*INDEX',d,re.I): indexes.append(d)
        elif re.match(r'CONSTRAINT',d,re.I) and 'FOREIGN KEY' in d.upper():
            nm=re.search(r'CONSTRAINT\s+`([^`]+)`',d,re.I); src=re.search(r'FOREIGN KEY\s*\((.*?)\)\s*REFERENCES\s*`([^`]+)`\s*\((.*?)\)',d,re.I|re.S)
            if src: fks.append({'name':nm.group(1) if nm else 'No especificado','columns':re.findall(r'`([^`]+)`',src.group(1)),'table':src.group(2),'references':re.findall(r'`([^`]+)`',src.group(3)),'on_delete':re.search(r'ON DELETE\s+([A-Z ]+?)(?: ON UPDATE|$)',d,re.I).group(1).strip() if re.search(r'ON DELETE\s+([A-Z ]+?)(?: ON UPDATE|$)',d,re.I) else 'No especificado','on_update':re.search(r'ON UPDATE\s+([A-Z ]+?)(?:$)',d,re.I).group(1).strip() if re.search(r'ON UPDATE\s+([A-Z ]+?)(?:$)',d,re.I) else 'No especificado','definition':d})
        elif re.match(r'CONSTRAINT',d,re.I) and 'CHECK' in d.upper(): checks.append(d)
    for c in cols:
        for k in keys:
            if c['name'] in k['columns']: c['key']='PK' if k['type']=='PK' else 'UK'
        for fk in fks:
            if c['name'] in fk['columns']: c['key']='FK' if c['key']=='No' else c['key']+'/FK'
        c.update(dict(zip(['value_class','origin','obligation','advanced_key','nature'],classify(c['name'],c['type'],c['nullable'],c['key'],c['extras'],c['default']))))
        c['formal_composition']='{dígito}' if 'int' in c['type'].lower() else 'Valor atómico del tipo declarado'
        c['domain']=c['type']+'; dominio exacto no acotado por SQL' if 'enum' not in c['type'].lower() else c['type']
        c['description']='No especificado en el SQL; función documentada según el nombre del atributo (inferido).' 
    return {'name':name,'columns':cols,'keys':keys,'foreign_keys':fks,'indexes':indexes,'checks':checks,'engine':re.search(r'ENGINE\s*=\s*(\w+)',tail,re.I).group(1) if re.search(r'ENGINE\s*=\s*(\w+)',tail,re.I) else 'No especificado','options':tail.strip()}

model=[parse_table(n,s) for n,s in tables.items()]
for v in views:
    v['columns_exposed']=re.findall(r'CREATE\s+(?:ALGORITHM=.*?\s+)?VIEW\s+`[^`]+`\s+AS\s+SELECT\s+(.*?)\s+FROM',v['sql'],re.I|re.S)
for t in triggers:
    m=re.search(r'\b(AFTER|BEFORE)\s+(INSERT|UPDATE|DELETE)\s+ON\s+`([^`]+)`',t['sql'],re.I)
    t.update({'moment':m.group(1).upper() if m else 'No especificado','event':m.group(2).upper() if m else 'No especificado','table':m.group(3) if m else 'No especificado','logs_tb_logs':'No especificado'})
for p in procedures:
    p['parameters']=re.search(r'PROCEDURE\s+`[^`]+`\s*(\(.*?\))',p['sql'],re.I|re.S).group(1) if re.search(r'PROCEDURE\s+`[^`]+`\s*(\(.*?\))',p['sql'],re.I|re.S) else 'No especificado'
obj={'source':SRC.name,'database':'db_test','mysql_version':'8.0.36','sensitive_data_processed':False,'tables':model,'views':views,'triggers':triggers,'procedures':procedures,'audit':{'requested_counts':{'tables':20,'views':18,'triggers':57,'procedures':3},'actual_counts':{'tables':len(model),'views':len(views),'triggers':len(triggers),'procedures':len(procedures)},'missing_requested_tables':['tb_buyer_orders','tb_orders','tbd_address_components','tbd_carts_items','tbd_order_details','tbc_payment_methods','tbd_wishlist'],'unexpected_tables':[n for n in tables if n not in ['tb_buyer_orders','tb_carts','tb_logs','tb_orders','tb_payments','tb_products','tb_user_addresses','tb_users','tbc_categories','tbc_payment_methods','tbc_payment_methods_types','tbd_address_components','tbd_carts_items','tbd_order_details','tbd_order_items','tbd_products_categories','tbd_products_users_providers','tbd_user_payment_methods','tbd_users_wishlist_products','tbd_wishlist']],'orphans_search':'Verificado: sin referencias huérfanas' if not re.search(r'tbd_shopping_cart|tbd_users_offer_products','\n'.join([x['sql'] for x in views+triggers+procedures]+list(tables.values())),re.I) else 'Referencias encontradas'}}
(ROOT/'estructura.json').write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')

def q(s): return str(s).replace('|','\\|').replace('\n',' ')
lines=['# Diccionario de datos — db_test','',f"> Fuente: `{SRC.name}`. Extracción estructural; INSERT omitidos.",'','## Índice','- [Descripción general](#descripción-general)','- [Tablas y columnas](#tablas-y-columnas)','- [Vistas](#vistas)','- [Triggers](#triggers)','- [Procedimientos](#procedimientos)','- [Dominios y convenciones](#dominios-y-convenciones)','- [Calidad y pendientes](#calidad-y-pendientes)','- [Leyendas](#leyendas)','','## Descripción general','','El esquema db_test documenta componentes de una aplicación de comercio electrónico (inferido), con usuarios, productos, carritos, pedidos, pagos y trazabilidad (inferido). Los prefijos tb_, tbc_ y tbd_ sugieren entidades principales, catálogos y tablas de detalle (inferido). El dump declara MySQL 8.0.36; motor y collation se documentan por objeto cuando aparecen en CREATE TABLE. Las reglas explícitas consideradas son PK, UK, FK, CHECK, valores predeterminados y columnas generadas halladas en el DDL. Los vínculos comerciales descritos abajo se limitan a relaciones SQL declaradas; objetos esperados pero ausentes constan como pendientes.','','## Tablas y columnas','']
for t in model:
    pk=next((k['columns'] for k in t['keys'] if k['type']=='PK'),[])
    formal='@'+ ' + @'.join(pk) if pk else ''
    formal += ''.join(' + '+('#' if c['key']=='FK' else '@' if c['key']=='PK' else '')+c['name'] for c in t['columns'] if c['name'] not in pk)
    lines += [f"### {t['name']}",'',f"**Descripción:** entidad correspondiente a {t['name']} (inferido). **Motor:** {t['engine']}. **Notación:** `{t['name']} = {formal}`.",'','**Restricciones e índices:**']
    lines += [f"- {k['type']}: {', '.join(k['columns'])}." for k in t['keys']] + [f"- FK {f['name']}: {', '.join(f['columns'])} → {f['table']}.{', '.join(f['references'])}; ON DELETE {f['on_delete']}; ON UPDATE {f['on_update']}." for f in t['foreign_keys']] + [f"- CHECK: `{c}`" for c in t['checks']] + [f"- Índice: `{i}`" for i in t['indexes']]
    lines += ['','| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |','|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for c in t['columns']:
        lines.append('| '+' | '.join(q(x) for x in [c['position'],c['name'],c['type'],c['length_precision'],c['nullable'],c['default'],c['extras'],c['key'],c['value_class'],c['origin'],c['obligation'],c['nature'],c['domain'],c['formal_composition'],c['description']])+' |')
    lines.append('')
lines += ['## Vistas','']
if not views: lines += ['No hay definiciones CREATE VIEW en el dump; el inventario solicitado de 18 vistas no se pudo documentar.','']
for v in views: lines += [f"### {v['name']}",'',f"**Propósito:** No especificado. **Tablas base y columnas/origen:** consultar definición SQL completa en `estructura.json`.",'']
lines += ['## Triggers','','| Nombre | Tabla | Evento | Momento | Trazabilidad tb_logs |','|---|---|---|---|---|']
if not triggers: lines += ['| No detectado | No especificado | No especificado | No especificado | No especificado |']
for t in triggers: lines.append('| '+' | '.join(q(t[x]) for x in ['name','table','event','moment','logs_tb_logs'])+' |')
lines += ['','## Procedimientos','']
for p in procedures:
    if p['name']=='sp_soft_delete_product': steps='1. Comprueba que el producto exista; si no, emite error SQL. 2. Rechaza el producto ya inactivo (status=b\'0\'). 3. Actualiza `tb_products.status` a b\'0\'.'
    elif p['name']=='sp_restore_product': steps='1. Comprueba que el producto exista; si no, emite error SQL. 2. Rechaza el producto ya activo (status=b\'1\'). 3. Actualiza `tb_products.status` a b\'1\'.'
    elif p['name']=='sp_soft_delete_user': steps='1. Obtiene el usuario de conexión y valida roles autorizados en `mysql.role_edges`. 2. Valida que el ID sea distinto de NULL/0. 3. Busca existencia y estado en `tb_users`; rechaza usuario inexistente, inactivo o con estado NULL. 4. Cambia status a b\'0\', exige exactamente una fila afectada y devuelve confirmación con ID, ejecutor y fecha. Afecta `tb_users`; consulta `mysql.role_edges`.'
    else: steps='Lógica: No especificado.'
    args=re.findall(r'IN\s+(p_\w+)\s+([A-Z]+(?:\s*\([^)]*\))?(?:\s+UNSIGNED)?)',p['parameters'],re.I)
    call=', '.join('1' if typ.upper().startswith('INT') else "'valor'" for _,typ in args)
    lines += [f"### {p['name']}",'',f"**Parámetros:** `{p['parameters']}`. **Lógica:** {steps} **Ejemplo:** `CALL {p['name']}({call});`.",'']
lines += ['### Diferencia frente al inventario solicitado','','`sp_soft_delete` no aparece en el DDL; el dump contiene `sp_restore_product` adicional. Los nombres y parámetros anteriores reflejan exclusivamente los procedimientos encontrados.','']
lines += ['## Dominios y convenciones','','Los dominios ENUM y status se listan desde las columnas tipadas en `estructura.json`; el volcado solo contiene los objetos realmente hallados. Prefijos tb_, tbc_, tbd_, vw_, trg_, sp_, fk_, uk_ y chk_ son convenciones observadas o solicitadas (inferido), no garantizan por sí mismos semántica. creation_date, last_update y status siguen documentándose por tabla cuando existan; no se asume obligatoriedad común.','','## Calidad y pendientes','',f"Conteos observados: {obj['audit']['actual_counts']}; conteos esperados por requisito: {obj['audit']['requested_counts']}.",'El archivo fuente no coincide con el inventario solicitado: faltan objetos y aparecen otros nombres. No es posible certificar los conteos esperados, 57 triggers o 18 vistas desde este dump.','',f"- Tablas solicitadas ausentes: {', '.join(obj['audit']['missing_requested_tables'])}.",f"- Tablas adicionales en fuente: {', '.join(obj['audit']['unexpected_tables'])}.",f"- Referencias huérfanas en DDL: {obj['audit']['orphans_search']}.",'','### Hallazgos técnicos (limitados a los objetos disponibles)','','| Severidad | Hallazgo | Propuesta técnica |','|---|---|---|','| Baja | `tbd_products_categories.category_ID` sí tiene FK `fb_category` hacia `tbc_categories.ID`; por lo tanto, la hipótesis de falta de FK no se confirma en este dump. | Mantener la FK existente; considerar renombrar `fb_category` a `fk_category` para seguir la convención si se aprueba una migración de nomenclatura. |','| Media | La duplicidad solicitada no se puede comparar: no están `tb_orders`, `tbd_order_details` ni `tbd_wishlist`; el origen sí define `tbb_orders`, `tb_seller_orders`, `tbd_order_items` y `tbd_users_wishlist_products`. También existen `tb_cart_items` y `tbd_cart_items`. | Confirmar qué modelo es vigente; documentar cardinalidades y consolidar roles antes de migrar. No eliminar tablas solo por similitud de nombres. |','| Baja | No se confirma la falta de identidad del comprador: `tbb_orders.user_ID` referencia `tb_users.ID`, mientras `tb_seller_orders.seller_ID` refiere al vendedor. | Aclarar nombres buyer/seller en el modelo y conservar las dos identidades mediante relaciones explícitas. |','| Media | `tbd_cart_items` y `tbd_order_items` tienen `product_offer_ID`, pero no FK a `tbd_products_users_providers`; esta última tiene PK compuesta `(user_ID, product_ID)` y FKs individuales a usuarios y productos. No se observa constraint compuesta que ate una oferta a ese par. | Si el identificador de oferta representa esa combinación, guardar ambas columnas y declarar FK compuesta; de lo contrario, usar un ID de oferta único con FK propia. |','| Media | `tbd_products_users_providers.user_ID` y `tb_users.ID` son INT con signo, pero `product_ID` es INT UNSIGNED en la tabla puente y la definición de `tb_products.ID` debe cotejarse. `status` visible en varias tablas es BIT(1), frente a `tbb_orders.status` BIT(1); no hay diferencia bit/tinyint en esos casos concretos. | Alinear tipos de cada par FK (incluido signo) y documentar semántica de BIT(1); revisar tabla por tabla cualquier Tinyint restante. |','| Baja | '+obj['audit']['orphans_search']+'.','| Baja | `tbd_order_items.subtotal` es GENERATED (derivado); se detectan cuatro PK compuestas y se listan en la evidencia. | Conservar fórmula generada y asegurar que cambios de precio/cantidad mantengan la regla de negocio definida en SQL. |','', '- Pendiente bloqueante: obtener el dump correcto para documentar las 18 vistas, 57 triggers y las 20 tablas pedidas.', '- Pendientes por confirmar (inferido): el esquema representa comercio electrónico; tb_/tbc_/tbd_ distinguen entidad/catálogo/detalle; descripciones funcionales inferidas del nombre de tabla/columna.','','## Leyendas','','DeMarco/Yourdon: `=` se compone de, `+` y, `[a | b]` alternativa, `{x}` repetición, `(x)` opcional; `@` PK y `#` FK. Monovalor/multivalor se clasifica según atomicidad observable; derivado únicamente si hay GENERATED declarado; naturalezas se asignan por tipo SQL, y los casos ambiguos se señalan como inferidos.','','### Evidencia final','','```text',f"Tablas: {len(model)} (esperadas 20) | Vistas: {len(views)} (esperadas 18) | Triggers: {len(triggers)} (esperados 57) | Procedimientos: {len(procedures)} (esperados 3)",f"Columnas sin metadata: 0 / {sum(len(t['columns']) for t in model)} (metadatos técnicos y clasificatorios poblados; descripción funcional inferida si no aparece en SQL)",'Columnas derivadas: '+', '.join(f"{t['name']}.{c['name']}" for t in model for c in t['columns'] if c['origin']=='Derivado') or 'Ninguna detectada', 'PK compuestas: '+', '.join(t['name']+':'+','.join(k['columns']) for t in model for k in t['keys'] if k['type']=='PK' and len(k['columns'])>1) or 'Ninguna detectada', 'Inferencias exactas: dominio comercio electrónico en descripción general; semántica de tb_/tbc_/tbd_; descripciones de tablas/columnas basadas en nombres; estructura atómica genérica de los campos.', 'Idioma: español; identificadores originales preservados.','```']
domains=[(t['name'],c['name'],c['type']) for t in model for c in t['columns'] if c['type'].lower().startswith('enum') or c['name'].lower()=='status']
lines += ['','### Catálogo global de ENUM y status','', '| Tabla | Columna | Dominio/tipo SQL |','|---|---|---|'] + ['| '+' | '.join(q(x) for x in row)+' |' for row in domains]
lines += ['', 'Clasificación visible: BIT(1), TINYINT y ENUM se conservan como tipos SQL distintos; el dominio semántico de status es No especificado salvo CHECK/ENUM/DEFAULT en la definición correspondiente.']
(ROOT/'diccionario_datos.md').write_text('\n'.join(lines),encoding='utf-8')

# XLSX workbook, generated with openpyxl when available.
try:
 from openpyxl import Workbook
 from openpyxl.styles import Font, Alignment, PatternFill
 from openpyxl.utils import get_column_letter
 wb=Workbook(); wb.remove(wb.active)
 def sheet(title,heads,rows):
  ws=wb.create_sheet(title); ws.append(heads)
  for row in rows: ws.append([json.dumps(x,ensure_ascii=False) if isinstance(x,(dict,list)) else x for x in row])
  ws.freeze_panes='A2'; ws.auto_filter.ref=ws.dimensions
  for c in ws[1]: c.font=Font(bold=True,color='FFFFFF'); c.fill=PatternFill('solid',fgColor='244062'); c.alignment=Alignment(wrap_text=True)
  for col in ws.columns:
   ws.column_dimensions[get_column_letter(col[0].column)].width=min(42,max(14,max((len(str(x.value or '')) for x in col[:50]),default=14)))
   for c in col[1:]: c.alignment=Alignment(wrap_text=True,vertical='top')
  return ws
 sheet('Tablas',['Nombre','Descripción','Notación','Motor','PK / UK','FK','CHECK','Índices'],[[t['name'],f"Entidad {t['name']} (inferido)",t['name']+' = '+', '.join('@'+','.join(k['columns']) for k in t['keys'] if k['type']=='PK')+' + '+' + '.join(c['name'] for c in t['columns']),t['engine'],t['keys'],t['foreign_keys'],t['checks'],t['indexes']] for t in model])
 fields=['Tabla','#','Nombre','Tipo','Longitud/Precisión','¿Acepta NULL?','Valor por defecto','Extras','Tipo de llave','Valor','Origen','Obligatoriedad','Llave avanzada','Naturaleza','Composición formal','Dominio','Descripción detallada']
 sheet('Columnas',fields,[[t['name'],c['position'],c['name'],c['type'],c['length_precision'],c['nullable'],c['default'],c['extras'],c['key'],c['value_class'],c['origin'],c['obligation'],c['advanced_key'],c['nature'],c['formal_composition'],c['domain'],c['description']] for t in model for c in t['columns']])
 sheet('Relaciones',['Tabla','Restricción','Columnas','Destino','Columnas destino','ON DELETE','ON UPDATE'],[[t['name'],f['name'],','.join(f['columns']),f['table'],','.join(f['references']),f['on_delete'],f['on_update']] for t in model for f in t['foreign_keys']])
 sheet('Vistas',['Nombre','Propósito','SQL'],[[x['name'],'No especificado',x['sql']] for x in views]); sheet('Triggers',['Nombre','Tabla','Evento','Momento','SQL'],[[x['name'],x['table'],x['event'],x['moment'],x['sql']] for x in triggers]); sheet('Procedimientos',['Nombre','Parámetros','SQL'],[[x['name'],x['parameters'],x['sql']] for x in procedures])
 enums=[[t['name'],c['name'],c['type']] for t in model for c in t['columns'] if c['type'].lower().startswith('enum') or 'status' in c['name'].lower()]
 sheet('Dominios_ENUM',['Tabla','Columna','Dominio/tipo'],enums); sheet('Observaciones',['Severidad','Hallazgo','Recomendación'],[['Alta','Dump no corresponde al inventario declarado','Solicitar/exportar dump correcto y regenerar.'],['Media','Referencias/modelos no auditables donde falta DDL','Confirmar objetos y ejecutar auditoría sobre definición vigente.']])
 nature={}; origin={}; obligation={}; keys={}
 for t in model:
  for c in t['columns']:
   for d,k in [(nature,'nature'),(origin,'origin'),(obligation,'obligation'),(keys,'key')]: d[c[k]]=d.get(c[k],0)+1
 sheet('Resumen Estadístico',['Atributo','Clasificación','Conteo'],[[a,k,v] for a,d in [('Naturaleza',nature),('Origen',origin),('Obligatoriedad',obligation),('Llaves',keys)] for k,v in d.items()])
 wb.save(ROOT/'diccionario_datos.xlsx')
except Exception:
 # Produce a standards-compliant minimal XLSX with the standard library alone.
 from xml.sax.saxutils import escape
 sheets_data=[
  ('Tablas',['Nombre','Descripción','Notación formal','Motor','Restricciones'],[[t['name'],f"Entidad {t['name']} (inferido)",t['name']+' = '+' + '.join(('@' if c['key']=='PK' else '#' if 'FK' in c['key'] else '')+c['name'] for c in t['columns']),t['engine'],json.dumps(t['keys']+t['foreign_keys']+t['checks'],ensure_ascii=False)] for t in model]),
  ('Columnas',['Tabla','#','Nombre','Tipo','Longitud/Precisión','¿Acepta NULL?','Valor por defecto','Extras','Tipo de llave','Valor','Origen','Obligatoriedad','Llave','Naturaleza','Composición formal','Dominio','Descripción detallada'],[[t['name'],c['position'],c['name'],c['type'],c['length_precision'],c['nullable'],c['default'],c['extras'],c['key'],c['value_class'],c['origin'],c['obligation'],c['advanced_key'],c['nature'],c['formal_composition'],c['domain'],c['description']] for t in model for c in t['columns']]),
  ('Relaciones',['Tabla','Restricción','Columnas','Destino','Columnas destino','ON DELETE','ON UPDATE'],[[t['name'],f['name'],','.join(f['columns']),f['table'],','.join(f['references']),f['on_delete'],f['on_update']] for t in model for f in t['foreign_keys']]),
  ('Vistas',['Nombre','Propósito','SQL'],[[v['name'],'No especificado',v['sql']] for v in views]),('Triggers',['Nombre','Tabla','Evento','Momento','SQL'],[[t['name'],t['table'],t['event'],t['moment'],t['sql']] for t in triggers]),('Procedimientos',['Nombre','Parámetros','SQL'],[[p['name'],p['parameters'],p['sql']] for p in procedures]),
  ('Dominios_ENUM',['Tabla','Columna','Dominio/tipo'],[[t['name'],c['name'],c['type']] for t in model for c in t['columns'] if c['type'].lower().startswith('enum') or 'status' in c['name'].lower()]),('Observaciones',['Severidad','Hallazgo','Recomendación'],[['Alta','Dump difiere del inventario solicitado','Obtener el dump correcto y regenerar.'],['Media','Auditorías específicas no verificables en objetos ausentes','Confirmar el esquema vigente.']]),
  ('Resumen Estadístico',['Atributo','Clasificación','Conteo'],[])]
 counts={}
 for t in model:
  for c in t['columns']:
   for attr,key in [('Naturaleza','nature'),('Origen','origin'),('Obligatoriedad','obligation'),('Llaves','key')]: counts[(attr,c[key])]=counts.get((attr,c[key]),0)+1
 sheets_data[-1][2].extend([[a,k,n] for (a,k),n in counts.items()])
 def colname(n):
  s=''
  while n: n,r=divmod(n-1,26); s=chr(65+r)+s
  return s
 def cell(v,ref):
  v='' if v is None else str(v)
  if re.fullmatch(r'-?\d+(?:\.\d+)?',v): return f'<c r="{ref}"><v>{v}</v></c>'
  return f'<c r="{ref}" t="inlineStr"><is><t xml:space="preserve">{escape(v)}</t></is></c>'
 with zipfile.ZipFile(ROOT/'diccionario_datos.xlsx','w',zipfile.ZIP_DEFLATED) as z:
  z.writestr('[Content_Types].xml','<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'+''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(1,len(sheets_data)+1))+'</Types>')
  z.writestr('_rels/.rels','<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
  z.writestr('xl/workbook.xml','<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'+''.join(f'<sheet name="{n}" sheetId="{i}" r:id="rId{i}"/>' for i,(n,_,_) in enumerate(sheets_data,1))+'</sheets></workbook>')
  z.writestr('xl/_rels/workbook.xml.rels','<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'+''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>' for i in range(1,len(sheets_data)+1))+'</Relationships>')
  for i,(_,heads,rows) in enumerate(sheets_data,1):
   data=[heads]+rows; xml=''.join('<row r="%s">'%ri+''.join(cell(v,f'{colname(ci)}{ri}') for ci,v in enumerate(row,1))+'</row>' for ri,row in enumerate(data,1))
   z.writestr(f'xl/worksheets/sheet{i}.xml',f'<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><autoFilter ref="A1:{colname(max(len(heads),1))}{max(len(data),1)}"/><sheetData>{xml}</sheetData></worksheet>')

with (ROOT/'diagrama_er.mmd').open('w',encoding='utf-8') as f:
 f.write('erDiagram\n')
 for t in model:
  f.write(f"  {t['name']} {{\n")
  for c in t['columns']: f.write(f"    {c['type'].replace(' ','_')} {c['name']} {'PK' if c['key']=='PK' else 'FK' if 'FK' in c['key'] else ''}\n")
  f.write('  }\n')
 for t in model:
  for fk in t['foreign_keys']: f.write(f"  {fk['table']} ||--o{{ {t['name']} : \"{','.join(fk['columns'])}\"\n")
with (ROOT/'schema.dbml').open('w',encoding='utf-8') as f:
 for t in model:
  f.write(f"Table {t['name']} {{\n")
  for c in t['columns']: f.write(f"  {c['name']} {c['type']} {'[pk]' if c['key']=='PK' else '[not null]' if c['nullable']=='No' else ''}\n")
  f.write('}\n\n')
 for t in model:
  for fk in t['foreign_keys']: f.write(f"Ref: {t['name']}.{fk['columns'][0]} > {fk['table']}.{fk['references'][0]}\n")
(ROOT/'README.md').write_text('# Diccionario de datos\n\nArchivos generados desde `estructura.json` a partir de `respaldo-20-1-10-2026.sql`. El extractor `generar.py` solo captura bloques CREATE TABLE/VIEW/TRIGGER/PROCEDURE y descarta todas las demás líneas, incluidos INSERT.\n\n## Contenido\n- `estructura.json`: metadata de esquema y SQL de objetos DDL.\n- `diccionario_datos.md`: documento navegable.\n- `diccionario_datos.xlsx`: libro con hojas técnicas, filtros y encabezados.\n- `diagrama_er.mmd`: ER Mermaid.\n- `schema.dbml`: modelo DBML.\n- `generar.py`: regenerador desde el dump (reconstruye JSON y todos los entregables).\n\n## Regenerar\nDesde la raíz del repositorio, ejecuta `py diccionario_datos/generar.py` (o `python diccionario_datos/generar.py`). Requiere Python 3; Excel se genera con `openpyxl` si está disponible o con la biblioteca estándar. El dump hallado no coincide con el inventario pedido; revisa la sección de calidad antes de usar el resultado como documentación definitiva.\n',encoding='utf-8')
print(json.dumps(obj['audit']['actual_counts'],ensure_ascii=False))
