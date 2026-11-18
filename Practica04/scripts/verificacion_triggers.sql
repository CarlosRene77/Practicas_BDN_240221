/* =====================================================================
   Verificación de auditoría: 3 triggers AFTER y 1 vista de
   trazabilidad por cada tabla (excepto tb_logs)
   Base: db_test   |   Solo lectura (la limpieza opcional va comentada al final)
   ===================================================================== */
USE db_test;

-- 1. Triggers y vista por tabla
SELECT t.TABLE_NAME AS tabla,
       SUM(tr.ACTION_TIMING='AFTER' AND tr.EVENT_MANIPULATION='INSERT') AS after_insert,
       SUM(tr.ACTION_TIMING='AFTER' AND tr.EVENT_MANIPULATION='UPDATE') AS after_update,
       SUM(tr.ACTION_TIMING='AFTER' AND tr.EVENT_MANIPULATION='DELETE') AS after_delete,
       COUNT(tr.TRIGGER_NAME) AS total_triggers,
       IF(EXISTS(SELECT 1 FROM information_schema.VIEWS v WHERE v.TABLE_SCHEMA='db_test' AND v.TABLE_NAME=CONCAT('vw_trazabilidad_',t.TABLE_NAME)),'SI','NO') AS vista
FROM information_schema.TABLES t
LEFT JOIN information_schema.TRIGGERS tr ON tr.EVENT_OBJECT_SCHEMA=t.TABLE_SCHEMA AND tr.EVENT_OBJECT_TABLE=t.TABLE_NAME
WHERE t.TABLE_SCHEMA='db_test' AND t.TABLE_TYPE='BASE TABLE'
GROUP BY t.TABLE_NAME ORDER BY t.TABLE_NAME;

-- 2. Resumen: debe dar 24 tablas, 72 triggers y 24 vistas
SELECT
  (SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = 'db_test' AND TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'tb_logs') AS tablas_auditadas,
  (SELECT COUNT(*) FROM information_schema.TRIGGERS
    WHERE TRIGGER_SCHEMA = 'db_test' AND ACTION_TIMING = 'AFTER') AS triggers_after,
  (SELECT COUNT(*) FROM information_schema.VIEWS v
    WHERE v.TABLE_SCHEMA = 'db_test'
      AND v.TABLE_NAME IN (SELECT CONCAT('vw_trazabilidad_', TABLE_NAME) FROM information_schema.TABLES
                            WHERE TABLE_SCHEMA = 'db_test' AND TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'tb_logs')) AS vistas_trazabilidad;

-- 3. Vistas que NO siguen la regla "una por tabla"
SELECT TABLE_NAME AS vista_fuera_de_la_regla
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'db_test'
  AND TABLE_NAME NOT IN (SELECT CONCAT('vw_trazabilidad_', TABLE_NAME) FROM information_schema.TABLES
                          WHERE TABLE_SCHEMA = 'db_test' AND TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'tb_logs');

-- Esperado en el punto 3: vw_seguimiento_ordenes, vw_cuentas_por_cobrar y
-- vw_total_products_by_category (no son de trazabilidad). Las vistas de
-- trazabilidad repetidas se eliminaron en 03_modelo_final.sql.