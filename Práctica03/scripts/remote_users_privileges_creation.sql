/* CREACION DE USUARIOS REMOTOS (Seguro si ya existen) */

CREATE USER IF NOT EXISTS 'carlos.morales'@'%' IDENTIFIED BY '240221';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%' IDENTIFIED BY '240485';
CREATE USER IF NOT EXISTS 'adrian.rios'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'pablo.reyes'@'%' IDENTIFIED BY '240148';
CREATE USER IF NOT EXISTS 'jonhy.neri'@'%' IDENTIFIED BY '240598';
CREATE USER IF NOT EXISTS 'luis.cazares'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%' IDENTIFIED BY '240196';

/* ASIGNACION DE PRIVILEGIOS DEL SUPER USUARIO */
GRANT ALL PRIVILEGES ON *.* TO 'carlos.morales'@'%' WITH GRANT OPTION;

/* CREACION DE ROLES PARA LOS USUARIOS DE LA PLATAFORMA DE ECOMMERCE */
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

/* ASIGNACION DE PRIVILEGIOS A LOS ROLES DE LA PLATAFORMA ECOMMERCE */
-- ADMIN
/* SUPERADMIN*/
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';
GRANT SELECT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT ON db_test.tbc_categories TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.* TO 'jonhy.neri'@'%';


GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories to 'support';

/* SELLER */
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';

GRANT SELECT ON db_test.tbc_categories TO 'seller';


/* ASIGNAR EL ROL AL USUARIO */
/* Super admin*/
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';
GRANT 'superadmin' TO 'carlos.morales'@'%'; -- <--- ¡ESTA LÍNEA FALTABA!
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'uriel.valenzuela'@'%';
GRANT 'seller' TO 'pablo.reyes'@'%';
GRANT 'seller' TO 'saul.barrios'@'%';

/* Esto permite que el rol se active automaticamente cuando el usuario inicia sesion */
SET DEFAULT ROLE 'superadmin' TO 'carlos.morales'@'%';
SET DEFAULT ROLE 'admin' TO 'marco.ramirez'@'%';
SET DEFAULT ROLE 'support' TO 'uriel.valenzuela'@'%';
SET DEFAULT ROLE 'seller' TO 'pablo.reyes'@'%';
SET DEFAULT ROLE 'seller' TO 'saul.barrios'@'%';

-- 7. REFRESCAR PRIVILEGIOS Y MENSAJE DE CONFIRMACION
FLUSH PRIVILEGES;

SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;