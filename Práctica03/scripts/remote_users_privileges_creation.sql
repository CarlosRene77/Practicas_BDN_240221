/* =========================================================
   1. CREACIÓN DE USUARIOS REMOTOS
   ========================================================= */
CREATE USER IF NOT EXISTS 'carlos.morales'@'%' IDENTIFIED BY '240221';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%' IDENTIFIED BY '240485';
CREATE USER IF NOT EXISTS 'adrian.rios'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'pablo.reyes'@'%' IDENTIFIED BY '240148';
CREATE USER IF NOT EXISTS 'jonhy.neri'@'%' IDENTIFIED BY '240598';
CREATE USER IF NOT EXISTS 'luis.cazares'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196';

/* =========================================================
   2. CREACIÓN DE ROLES ECOMMERCE
   ========================================================= */
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

/* =========================================================
   3. ASIGNACIÓN DE PRIVILEGIOS A LOS ROLES
   ========================================================= */
-- SUPERADMIN (Acceso total)
GRANT ALL PRIVILEGES ON *.* TO 'superadmin' WITH GRANT OPTION;

-- ADMIN (Acceso total a la base de datos de la app)
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- SUPPORT (Lectura/escritura en tablas clave de atención)
GRANT SELECT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user TO 'support'@'%';

-- SELLER (Gestión de catálogo)
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT ON db_test.tbc_categories TO 'seller';

/* =========================================================
   4. ASIGNACIÓN DE ROLES A LOS USUARIOS
   ========================================================= */
GRANT 'superadmin' TO 'carlos.morales'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'seller' TO 'pablo.reyes'@'%', 'saul.barrios'@'%';

/* =========================================================
   5. ACTIVACIÓN DE ROLES POR DEFECTO
   ========================================================= */
SET DEFAULT ROLE 'superadmin' TO 'carlos.morales'@'%';
SET DEFAULT ROLE 'admin' TO 'marco.ramirez'@'%', 'jonhy.neri'@'%';
SET DEFAULT ROLE 'support' TO 'adrian.rios'@'%';
SET DEFAULT ROLE 'seller' TO 'pablo.reyes'@'%', 'saul.barrios'@'%';

/* =========================================================
   6. FINALIZACIÓN
   ========================================================= */
FLUSH PRIVILEGES;

SELECT "Los usuarios, roles y privilegios han sido creados y asignados correctamente" AS mensaje;