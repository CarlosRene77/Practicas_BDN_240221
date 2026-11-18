/* =====================================================================
   04 · Usuarios, roles y permisos (modelo final de db_test)
   Ejecutar con una cuenta administradora (root o superadmin).

   Se puede ejecutar varias veces sin problema:
   - CREATE USER IF NOT EXISTS no cambia la contraseña de un usuario que
     ya existe. Las contraseñas de este archivo son de ejemplo: cámbialas
     antes de crear los usuarios en un servidor nuevo.
   - Los permisos de los roles de la aplicación se limpian y se vuelven a
     otorgar, así no quedan permisos viejos (por ejemplo, sobre
     tbd_buyer_orders, tabla que ya no existe).

   Reparto de responsabilidades (según los casos de prueba):
   - user_not_registered : registrarse y consultar el catálogo
   - buyer               : todo lo que hace el CLIENTE en los casos
                           (carrito, orden, domicilio, método de pago,
                           pagos, cancelación y reclamación)
   - seller              : catálogo propio y envíos
   - support             : atención de devoluciones y cancelaciones
   - admin / superadmin  : operaciones del SISTEMA (banco, procesar la
                           orden, reembolsos) y administración
   Los triggers escriben en tb_logs con los permisos de su DEFINER, por eso
   ningún rol de la app necesita permisos sobre tb_logs.
   ===================================================================== */

/* ---------------------------------------------------------------------
   1. Usuarios (contraseñas de ejemplo)
   --------------------------------------------------------------------- */
CREATE USER IF NOT EXISTS 'carlos.morales'@'%'   IDENTIFIED BY 'Cambiar#Superadmin1';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%'    IDENTIFIED BY 'Cambiar#Admin1';
CREATE USER IF NOT EXISTS 'jonhy.neri'@'%'       IDENTIFIED BY 'Cambiar#Admin2';
CREATE USER IF NOT EXISTS 'uriel.valenzuela'@'%' IDENTIFIED BY 'Cambiar#Usuario1';
CREATE USER IF NOT EXISTS 'adrian.rios'@'%'      IDENTIFIED BY 'Cambiar#Soporte1';
CREATE USER IF NOT EXISTS 'pablo.reyes'@'%'      IDENTIFIED BY 'Cambiar#Vendedor1';
CREATE USER IF NOT EXISTS 'saul.barrios'@'%'     IDENTIFIED BY 'Cambiar#Vendedor2';
CREATE USER IF NOT EXISTS 'luis.cazares'@'%'     IDENTIFIED BY 'Cambiar#Usuario2';
CREATE USER IF NOT EXISTS 'app_web'@'%'          IDENTIFIED BY 'Cambiar#AppWeb1';
CREATE USER IF NOT EXISTS 'app_movil'@'%'        IDENTIFIED BY 'Cambiar#AppMovil1';

/* ---------------------------------------------------------------------
   2. Roles
   --------------------------------------------------------------------- */
CREATE ROLE IF NOT EXISTS 'superadmin', 'admin', 'seller', 'buyer',
                          'common_user', 'user_not_registered', 'support';

/* ---------------------------------------------------------------------
   3. Limpieza de permisos de los roles de la aplicación
      (no afecta a qué usuarios tienen cada rol)
   --------------------------------------------------------------------- */
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'buyer';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'user_not_registered';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'common_user';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'seller';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'support';

/* ---------------------------------------------------------------------
   4. Permisos por rol
   --------------------------------------------------------------------- */
-- SUPERADMIN: acceso total
GRANT ALL PRIVILEGES ON *.* TO 'superadmin' WITH GRANT OPTION;

-- ADMIN: acceso total a la base de la aplicación
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- USER_NOT_REGISTERED: registrarse (cuenta + datos personales) y ver el catálogo
GRANT INSERT         ON db_test.tb_users                     TO 'user_not_registered';
GRANT INSERT         ON db_test.tb_people                    TO 'user_not_registered';
GRANT SELECT         ON db_test.tb_products                  TO 'user_not_registered';
GRANT SELECT         ON db_test.tbc_categories               TO 'user_not_registered';
GRANT SELECT         ON db_test.tbd_products_categories      TO 'user_not_registered';

-- COMMON_USER: solo consulta del catálogo
GRANT SELECT         ON db_test.tb_products                  TO 'common_user';
GRANT SELECT         ON db_test.tbc_categories               TO 'common_user';
GRANT SELECT         ON db_test.tbd_products_categories      TO 'common_user';

-- BUYER: operaciones del cliente en los casos de prueba
--   catálogo y catálogos de pago
GRANT SELECT         ON db_test.tb_products                  TO 'buyer';
GRANT SELECT         ON db_test.tbc_categories               TO 'buyer';
GRANT SELECT         ON db_test.tbd_products_categories      TO 'buyer';
GRANT SELECT         ON db_test.tbd_products_users_providers TO 'buyer';
GRANT SELECT         ON db_test.tb_payment_methods           TO 'buyer';
GRANT SELECT         ON db_test.tbc_payment_methods_types    TO 'buyer';
--   lista de deseos y carrito
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_users_wishlist_products TO 'buyer';
GRANT SELECT, INSERT, UPDATE         ON db_test.tb_carts                    TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_cart_items              TO 'buyer';
--   orden de compra: la crea, elige domicilio y aparta existencias
GRANT SELECT, INSERT ON db_test.tb_orders       TO 'buyer';
GRANT UPDATE (shipping_address_ID) ON db_test.tb_orders   TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_order_items TO 'buyer';
GRANT UPDATE (current_stock)       ON db_test.tb_products TO 'buyer';
--   domicilio y método de pago
GRANT SELECT, INSERT, UPDATE ON db_test.tb_user_addresses        TO 'buyer';
GRANT SELECT, INSERT         ON db_test.tbd_address_components   TO 'buyer';
GRANT SELECT, INSERT         ON db_test.tbd_user_payment_methods TO 'buyer';
--   pagos (la autorización la registra el sistema)
GRANT SELECT, INSERT ON db_test.tb_payments            TO 'buyer';
GRANT SELECT         ON db_test.tb_payment_transaction TO 'buyer';
--   cancelaciones, reclamaciones y consulta de envíos y reembolsos
GRANT SELECT, INSERT ON db_test.tb_order_cancellations TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_cancellation_items TO 'buyer';
GRANT SELECT, INSERT ON db_test.tb_returns             TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_return_items       TO 'buyer';
GRANT SELECT         ON db_test.tb_shipments           TO 'buyer';
GRANT SELECT         ON db_test.tb_refunds             TO 'buyer';

-- SELLER: su catálogo y los envíos de sus ventas
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products                  TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_users_providers TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories      TO 'seller';
GRANT SELECT                 ON db_test.tbc_categories               TO 'seller';
GRANT SELECT                 ON db_test.tb_orders                    TO 'seller';
GRANT SELECT                 ON db_test.tbd_order_items              TO 'seller';
GRANT SELECT                 ON db_test.tb_user_addresses            TO 'seller';
GRANT SELECT                 ON db_test.tbd_address_components       TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_shipments                 TO 'seller';

-- SUPPORT: atención a clientes, devoluciones y cancelaciones
GRANT SELECT, UPDATE         ON db_test.tb_users                TO 'support';
GRANT SELECT, UPDATE         ON db_test.tb_products             TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories          TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT SELECT                 ON db_test.tb_orders               TO 'support';
GRANT SELECT                 ON db_test.tbd_order_items         TO 'support';
GRANT SELECT                 ON db_test.tb_shipments            TO 'support';
GRANT SELECT, UPDATE         ON db_test.tb_returns              TO 'support';
GRANT SELECT, UPDATE         ON db_test.tbd_return_items        TO 'support';
GRANT SELECT, UPDATE         ON db_test.tb_order_cancellations  TO 'support';
GRANT SELECT                 ON db_test.vw_seguimiento_ordenes  TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user          TO 'support';

/* ---------------------------------------------------------------------
   5. Roles de cada usuario
   --------------------------------------------------------------------- */
GRANT 'superadmin'          TO 'carlos.morales'@'%';
GRANT 'admin'               TO 'marco.ramirez'@'%', 'jonhy.neri'@'%';
GRANT 'support'             TO 'adrian.rios'@'%';
GRANT 'seller'              TO 'pablo.reyes'@'%', 'saul.barrios'@'%';
-- Conexiones de la aplicación: entran como no registrado y al pagar
-- activan 'buyer' con SET ROLE 'buyer';
GRANT 'user_not_registered', 'buyer' TO 'app_web'@'%', 'app_movil'@'%';

/* ---------------------------------------------------------------------
   6. Rol activo al conectarse
   --------------------------------------------------------------------- */
SET DEFAULT ROLE 'superadmin'          TO 'carlos.morales'@'%';
SET DEFAULT ROLE 'admin'               TO 'marco.ramirez'@'%', 'jonhy.neri'@'%';
SET DEFAULT ROLE 'support'             TO 'adrian.rios'@'%';
SET DEFAULT ROLE 'seller'              TO 'pablo.reyes'@'%', 'saul.barrios'@'%';
SET DEFAULT ROLE 'user_not_registered' TO 'app_web'@'%', 'app_movil'@'%';

/* ---------------------------------------------------------------------
   7. Verificación
   --------------------------------------------------------------------- */
SHOW GRANTS FOR 'buyer';
SHOW GRANTS FOR 'user_not_registered';
SHOW GRANTS FOR 'app_web'@'%' USING 'user_not_registered', 'buyer';