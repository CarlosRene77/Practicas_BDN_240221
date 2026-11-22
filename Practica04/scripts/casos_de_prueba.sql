/* =====================================================================
   PRÁCTICA 04 · SCRIPT DE PRUEBAS DE LOS CASOS DE PRUEBA 1 A 5
   Base: db_test   |   Solo lectura (usa una tabla TEMPORAL que se
   destruye al cerrar la sesión; no modifica ninguna tabla de la base)

   Una prueba por cada operación del enunciado:
     CP1 = 11 operaciones   CP2 = 10   CP3 = 11   CP4 = 8   CP5 = 6
     Total: 46 pruebas

   Cada prueba registra: caso, número de operación, operación del
   enunciado, resultado esperado, resultado obtenido y OK / FALLA.

   Las órdenes de cada caso se detectan solas por sus características
   (si un caso se ejecutó varias veces, se toma la ejecución más reciente):
     CP1 → pago con tarjeta de débito (la primera orden)
     CP2 → plan de 6 mensualidades
     CP3 → cancelación parcial ('Items')
     CP4 → entrega en punto de recolección
     CP5 → cancelación por falta de inventario ('OUT_OF_STOCK')

   Ejecutar: Execute All (Ctrl+Shift+Enter). Al final se muestran el
   detalle de las 46 pruebas, un resumen por caso y el resultado global.
   ===================================================================== */
USE db_test;

DROP TEMPORARY TABLE IF EXISTS tmp_pruebas;
CREATE TEMPORARY TABLE tmp_pruebas (
    caso       VARCHAR(4)    NOT NULL,
    operacion  TINYINT       NOT NULL,
    descripcion VARCHAR(160) NOT NULL,
    esperado   VARCHAR(255)  NULL,
    obtenido   VARCHAR(255)  NULL,
    resultado  VARCHAR(5)    NOT NULL,
    PRIMARY KEY (caso, operacion)
) DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

/* =====================================================================
   0. Identificación de las órdenes de cada caso
   ===================================================================== */
SET @cp1 = (SELECT MIN(p.order_ID) FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID
            JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
            JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
            WHERE t.code = 'DEBIT_CARD');
SET @cp2 = (SELECT MAX(order_ID) FROM tb_payments WHERE installments_total = 6);
SET @cp3 = (SELECT MAX(order_ID) FROM tb_order_cancellations WHERE cancellation_scope = 'Items');
SET @cp4 = (SELECT MAX(order_ID) FROM tb_shipments WHERE pickup_point_name IS NOT NULL);
SET @cp5 = (SELECT MAX(order_ID) FROM tb_order_cancellations WHERE reason_code = 'OUT_OF_STOCK');

SELECT @cp1 AS orden_cp1, @cp2 AS orden_cp2, @cp3 AS orden_cp3, @cp4 AS orden_cp4, @cp5 AS orden_cp5;

-- Datos de apoyo por caso: cliente y carrito
SELECT user_ID, cart_ID INTO @cp1_user, @cp1_cart FROM tb_orders WHERE ID = @cp1;
SELECT user_ID, cart_ID INTO @cp2_user, @cp2_cart FROM tb_orders WHERE ID = @cp2;
SELECT user_ID, cart_ID INTO @cp3_user, @cp3_cart FROM tb_orders WHERE ID = @cp3;
SELECT user_ID, cart_ID INTO @cp4_user, @cp4_cart FROM tb_orders WHERE ID = @cp4;
SELECT user_ID, cart_ID INTO @cp5_user, @cp5_cart FROM tb_orders WHERE ID = @cp5;

-- IDs como texto en la collation de tb_logs (para buscar en la bitácora)
SET @cp2_txt = CONVERT(CAST(@cp2 AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci;
SET @cp3_txt = CONVERT(CAST(@cp3 AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci;
SET @cp4_txt = CONVERT(CAST(@cp4 AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci;
SET @cp5_txt = CONVERT(CAST(@cp5 AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci;


/* =====================================================================
   CASO DE PRUEBA 1 · "Compra exitosa, sin modificaciones" (11 operaciones)
   ===================================================================== */

-- CP1 · Op 01 · Usuario nuevo registrado desde la conexión de la app, con datos personales y de cuenta
INSERT INTO tmp_pruebas
SELECT 'CP1', 1, 'Usuario nuevo se registra (AppWeb/AppMobile) con datos personales y de cuenta',
       'usuario + persona + alta hecha por app_web/app_movil',
       CONCAT('usuario=', COUNT(DISTINCT u.ID), ', persona=', COUNT(DISTINCT pe.person_ID),
              ', alta por=', COALESCE(MAX(l.db_user), 'sin registro')),
       IF(COUNT(DISTINCT u.ID) = 1 AND COUNT(DISTINCT pe.person_ID) = 1
          AND MAX(l.db_user) REGEXP '^app_(web|movil|mobile)@', 'OK', 'FALLA')
FROM tb_users u
LEFT JOIN tb_people pe ON pe.user_ID = u.ID
LEFT JOIN tb_logs l    ON l.table_name = 'tb_users' AND l.operation = 'Create'
                      AND l.record_ID = CONVERT(CAST(u.ID AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci
WHERE u.ID = @cp1_user;

-- CP1 · Op 02 · Selección de 5 productos disponibles (estatus activo)
INSERT INTO tmp_pruebas
SELECT 'CP1', 2, 'Selecciona 5 productos disponibles verificando su estatus',
       '5 productos, todos activos y con precio',
       CONCAT(COUNT(*), ' productos, ', SUM(pr.status = b'1' AND pr.current_price > 0), ' activos'),
       IF(COUNT(*) = 5 AND SUM(pr.status = b'1' AND pr.current_price > 0) = 5, 'OK', 'FALLA')
FROM tbd_cart_items ci JOIN tb_products pr ON pr.ID = ci.product_offer_ID
WHERE ci.cart_ID = @cp1_cart;

-- CP1 · Op 03 · Crea 1 carrito de compra
INSERT INTO tmp_pruebas
SELECT 'CP1', 3, 'Crea 1 carrito de compra',
       '1 carrito del cliente',
       CONCAT(COUNT(*), ' carrito(s)'),
       IF(COUNT(*) = 1, 'OK', 'FALLA')
FROM tb_carts WHERE user_ID = @cp1_user;

-- CP1 · Op 04 · Agrega 5 productos con diferentes cantidades
INSERT INTO tmp_pruebas
SELECT 'CP1', 4, 'Agrega 5 productos con diferentes cantidades al carrito',
       '5 productos / 5 cantidades distintas',
       CONCAT(COUNT(*), ' productos / ', COUNT(DISTINCT quantity), ' cantidades distintas'),
       IF(COUNT(*) = 5 AND COUNT(DISTINCT quantity) = 5, 'OK', 'FALLA')
FROM tbd_cart_items WHERE cart_ID = @cp1_cart;

-- CP1 · Op 05 · Realiza la orden de compra (el carrito se convierte en orden)
INSERT INTO tmp_pruebas
SELECT 'CP1', 5, 'Realiza la orden de compra a partir del carrito',
       'carrito Converted y orden = contenido del carrito',
       CONCAT('carrito ', c.cart_status, ', ',
              (SELECT COUNT(*) FROM tbd_order_items oi JOIN tbd_cart_items ci
                 ON ci.cart_ID = c.ID AND ci.product_offer_ID = oi.product_offer_ID AND ci.quantity = oi.quantity
               WHERE oi.order_ID = @cp1), ' de ',
              (SELECT COUNT(*) FROM tbd_cart_items WHERE cart_ID = c.ID), ' productos coinciden'),
       IF(c.cart_status = 'Converted'
          AND (SELECT COUNT(*) FROM tbd_order_items oi JOIN tbd_cart_items ci
                 ON ci.cart_ID = c.ID AND ci.product_offer_ID = oi.product_offer_ID AND ci.quantity = oi.quantity
               WHERE oi.order_ID = @cp1) = (SELECT COUNT(*) FROM tbd_cart_items WHERE cart_ID = c.ID), 'OK', 'FALLA')
FROM tb_carts c WHERE c.ID = @cp1_cart;

-- CP1 · Op 06 · Registra su domicilio para envío
INSERT INTO tmp_pruebas
SELECT 'CP1', 6, 'Registra su domicilio para envío',
       'domicilio del cliente ligado a la orden, con sus componentes',
       CONCAT(COALESCE(MAX(a.address_label), 'sin domicilio'), ', ', COUNT(ac.ID), ' componentes'),
       IF(MAX(a.user_ID) = @cp1_user AND COUNT(ac.ID) >= 5, 'OK', 'FALLA')
FROM tb_orders o
LEFT JOIN tb_user_addresses a       ON a.ID = o.shipping_address_ID
LEFT JOIN tbd_address_components ac ON ac.address_ID = a.ID
WHERE o.ID = @cp1;

-- CP1 · Op 07 · Método de pago: tarjeta de débito de 16 dígitos vinculada
INSERT INTO tmp_pruebas
SELECT 'CP1', 7, 'Registra tarjeta de débito simulada de 16 dígitos (vinculada)',
       'DEBIT_CARD / 16 dígitos / del cliente / ligada al pago',
       CONCAT(COALESCE(MAX(t.code), 'sin método'), ' / ', MAX(CHAR_LENGTH(m.provider_method_ref)), ' dígitos'),
       IF(MAX(t.code) = 'DEBIT_CARD' AND MAX(m.provider_method_ref REGEXP '^[0-9]{16}$') = 1
          AND MAX(m.user_ID) = @cp1_user, 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID
JOIN tbd_user_payment_methods m  ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
WHERE p.order_ID = @cp1;

-- CP1 · Op 08 · Pago único hecho desde la conexión de la app (rol buyer)
INSERT INTO tmp_pruebas
SELECT 'CP1', 8, 'Registra un pago único (la conexión de la app activa el rol buyer)',
       '1 pago por el total, registrado por app_web/app_movil',
       CONCAT(COUNT(*), ' pago(s) por ', COALESCE(SUM(p.amount), 0), ' de ', ROUND(MAX(o.total_cost), 2),
              ', registrado por ',
              COALESCE((SELECT MIN(l.db_user) FROM tb_logs l
                        WHERE l.table_name = 'tb_payments' AND l.operation = 'Create'
                          AND l.operation_date BETWEEN MAX(o.creation_date) AND MAX(o.creation_date) + INTERVAL 1 DAY), 'sin registro')),
       IF(COUNT(*) = 1 AND SUM(p.amount) = ROUND(MAX(o.total_cost), 2)
          AND (SELECT MIN(l.db_user) FROM tb_logs l
               WHERE l.table_name = 'tb_payments' AND l.operation = 'Create'
                 AND l.operation_date BETWEEN MAX(o.creation_date) AND MAX(o.creation_date) + INTERVAL 1 DAY)
              REGEXP '^app_(web|movil|mobile)@', 'OK', 'FALLA')
FROM tb_orders o JOIN tb_payments p ON p.order_ID = o.ID
WHERE o.ID = @cp1;

-- CP1 · Op 09 · El sistema registra la transacción bancaria y la autoriza
INSERT INTO tmp_pruebas
SELECT 'CP1', 9, 'El sistema registra la transacción bancaria y la autoriza',
       'transacciones aprobadas y pago Paid',
       CONCAT(COUNT(t.ID), ' transacción(es) ', GROUP_CONCAT(DISTINCT t.transaction_status), ', pago ', MAX(p.payment_status)),
       IF(COUNT(t.ID) >= 1 AND SUM(t.transaction_status <> 'Succeeded') = 0 AND MAX(p.payment_status) = 'Paid', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID LEFT JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_ID = @cp1;

-- CP1 · Op 10 · El sistema procesa la orden y la marca como atendida
INSERT INTO tmp_pruebas
SELECT 'CP1', 10, 'El sistema procesa la orden marcando como atendida',
       'orden procesada (Attended o posterior) por el sistema',
       CONCAT('estatus ', o.status_string, ', actualizaciones del sistema: ',
              (SELECT COUNT(*) FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.operation = 'Update'
                 AND l.db_user NOT REGEXP '^app_' AND l.operation_date BETWEEN o.creation_date AND o.creation_date + INTERVAL 1 DAY)),
       IF(o.status_string IN ('Attended','Shipped','Delivered')
          AND (SELECT COUNT(*) FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.operation = 'Update'
                 AND l.db_user NOT REGEXP '^app_' AND l.operation_date BETWEEN o.creation_date AND o.creation_date + INTERVAL 1 DAY) > 0,
          'OK', 'FALLA')
FROM tb_orders o WHERE o.ID = @cp1;

-- CP1 · Op 11 · El usuario recibe el producto en casa
INSERT INTO tmp_pruebas
SELECT 'CP1', 11, 'El usuario recibe el producto en casa',
       'orden Delivered, 1 envío Delivered a su domicilio predeterminado',
       CONCAT('orden ', MAX(o.status_string), ', ', COUNT(s.ID), ' envío(s) ', COALESCE(GROUP_CONCAT(s.shipment_status), '-'),
              ', domicilio predeterminado=', MAX(a.is_default)),
       IF(MAX(o.status_string) = 'Delivered' AND COUNT(s.ID) = 1 AND MAX(s.shipment_status) = 'Delivered'
          AND MAX(s.delivered_at) IS NOT NULL AND MAX(a.is_default) = 1, 'OK', 'FALLA')
FROM tb_orders o
JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID
LEFT JOIN tb_shipments s ON s.order_ID = o.ID
WHERE o.ID = @cp1;


/* =====================================================================
   CASO DE PRUEBA 2 · "Compra con detalles en el último pago y con
   reclamación y reenvío" (10 operaciones)
   ===================================================================== */

-- CP2 · Op 01 · Usuario ya registrado crea 1 carrito de 10 productos aleatorios (1 a 5 piezas)
INSERT INTO tmp_pruebas
SELECT 'CP2', 1, 'Usuario ya registrado crea 1 carrito de 10 productos (1 a 5 unidades)',
       'usuario previo al carrito / 10 productos / piezas 1-5',
       CONCAT('usuario previo=', IF(MAX(u.creation_date) < MAX(c.creation_date), 'sí', 'no'),
              ' / ', COUNT(ci.product_offer_ID), ' productos / piezas ', MIN(ci.quantity), '-', MAX(ci.quantity)),
       IF(MAX(u.creation_date) < MAX(c.creation_date) AND COUNT(ci.product_offer_ID) = 10
          AND MIN(ci.quantity) >= 1 AND MAX(ci.quantity) <= 5, 'OK', 'FALLA')
FROM tb_carts c
JOIN tb_users u ON u.ID = c.user_ID
LEFT JOIN tbd_cart_items ci ON ci.cart_ID = c.ID
WHERE c.ID = @cp2_cart;

-- CP2 · Op 02 · Realiza la orden de compra
INSERT INTO tmp_pruebas
SELECT 'CP2', 2, 'Realiza la orden de compra',
       'carrito Converted y 10 productos en la orden',
       CONCAT('carrito ', c.cart_status, ', ', (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp2), ' productos en la orden'),
       IF(c.cart_status = 'Converted' AND (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp2) = 10, 'OK', 'FALLA')
FROM tb_carts c WHERE c.ID = @cp2_cart;

-- CP2 · Op 03 · Domicilio de envío que no es su hogar (trabajo)
INSERT INTO tmp_pruebas
SELECT 'CP2', 3, 'Registra domicilio de envío que no es su hogar (trabajo)',
       'domicilio del cliente, NO predeterminado',
       CONCAT(COALESCE(MAX(a.address_label), 'sin domicilio'), ' / predeterminado=', MAX(a.is_default)),
       IF(MAX(a.user_ID) = @cp2_user AND MAX(a.is_default) = 0, 'OK', 'FALLA')
FROM tb_orders o LEFT JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID
WHERE o.ID = @cp2;

-- CP2 · Op 04 · Tarjeta de crédito de 16 dígitos vinculada
INSERT INTO tmp_pruebas
SELECT 'CP2', 4, 'Registra tarjeta de crédito simulada de 16 dígitos (vinculada)',
       'CREDIT_CARD / 16 dígitos / del cliente',
       CONCAT(COALESCE(MAX(t.code), 'sin método'), ' / ', MAX(CHAR_LENGTH(m.provider_method_ref)), ' dígitos'),
       IF(MAX(t.code) = 'CREDIT_CARD' AND MIN(t.code) = 'CREDIT_CARD'
          AND MAX(m.provider_method_ref REGEXP '^[0-9]{16}$') = 1 AND MAX(m.user_ID) = @cp2_user, 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID
JOIN tbd_user_payment_methods m  ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
WHERE p.order_ID = @cp2;

-- CP2 · Op 05 · Registra 6 pagos mensuales
INSERT INTO tmp_pruebas
SELECT 'CP2', 5, 'Registra 6 pagos mensuales',
       '6 mensualidades en 6 meses distintos que suman el total',
       CONCAT(COUNT(*), ' pagos, ', COUNT(DISTINCT DATE_FORMAT(due_date, '%Y-%m')), ' meses, suma ',
              SUM(amount), ' de ', (SELECT ROUND(total_cost, 2) FROM tb_orders WHERE ID = @cp2)),
       IF(COUNT(*) = 6 AND MAX(installments_total) = 6 AND COUNT(DISTINCT DATE_FORMAT(due_date, '%Y-%m')) = 6
          AND SUM(amount) = (SELECT ROUND(total_cost, 2) FROM tb_orders WHERE ID = @cp2), 'OK', 'FALLA')
FROM tb_payments WHERE order_ID = @cp2;

-- CP2 · Op 06 · El banco autoriza 5 y rechaza la última por límite de crédito
INSERT INTO tmp_pruebas
SELECT 'CP2', 6, 'El sistema autoriza 5 transacciones y rechaza la última por límite de crédito',
       '5 Succeeded / 1 Failed en la mensualidad 6 por límite de crédito',
       CONCAT(SUM(t.transaction_status = 'Succeeded'), ' Succeeded / ', SUM(t.transaction_status = 'Failed'),
              ' Failed en mensualidad ', COALESCE(MAX(IF(t.transaction_status = 'Failed', p.installment_number, NULL)), '-')),
       IF(SUM(t.transaction_status = 'Succeeded') = 5 AND SUM(t.transaction_status = 'Failed') = 1
          AND MAX(IF(t.transaction_status = 'Failed', p.installment_number, NULL)) = 6
          AND MAX(IF(t.transaction_status = 'Failed', t.response_message, NULL)) LIKE '%límite%', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_ID = @cp2;

-- CP2 · Op 07 · El sistema procesa la orden y la marca como atendida
INSERT INTO tmp_pruebas
SELECT 'CP2', 7, 'El sistema procesa la orden marcando como atendida',
       'cambio de estatus a Attended registrado en bitácora',
       IF(COUNT(*) > 0, CONCAT('Attended el ', MIN(operation_date)), 'sin registro'),
       IF(COUNT(*) > 0, 'OK', 'FALLA')
FROM tb_logs
WHERE table_name = 'tb_orders' AND record_ID = @cp2_txt
  AND JSON_UNQUOTE(JSON_EXTRACT(new_values, '$.status_string')) = 'Attended';

-- CP2 · Op 08 · El usuario recibe el producto
INSERT INTO tmp_pruebas
SELECT 'CP2', 8, 'El usuario recibe el producto',
       'envío original Delivered',
       CONCAT(COUNT(*), ' envío(s) original(es) ', COALESCE(GROUP_CONCAT(shipment_status), '-')),
       IF(COUNT(*) = 1 AND MAX(shipment_status) = 'Delivered' AND MAX(delivered_at) IS NOT NULL, 'OK', 'FALLA')
FROM tb_shipments WHERE order_ID = @cp2 AND shipment_type = 'Original';

-- CP2 · Op 09 · Reclama la devolución de un producto que llegó dañado
INSERT INTO tmp_pruebas
SELECT 'CP2', 9, 'El usuario reclama la devolución de un producto que llegó dañado',
       '1 devolución del cliente con artículo Damaged',
       CONCAT(COUNT(DISTINCT r.ID), ' devolución(es), condición ', COALESCE(GROUP_CONCAT(ri.item_condition), '-'),
              ', solicitada por el cliente=', IF(MAX(r.requested_by_user_ID) = @cp2_user, 'sí', 'no')),
       IF(COUNT(DISTINCT r.ID) = 1 AND MIN(ri.item_condition) = 'Damaged'
          AND MAX(r.requested_by_user_ID) = @cp2_user, 'OK', 'FALLA')
FROM tb_returns r LEFT JOIN tbd_return_items ri ON ri.return_ID = r.ID
WHERE r.order_ID = @cp2;

-- CP2 · Op 10 · El sistema reenvía el producto en buenas condiciones
INSERT INTO tmp_pruebas
SELECT 'CP2', 10, 'El sistema realiza el reenvío del producto en buenas condiciones',
       'envío Replacement ligado a la devolución, Delivered; devolución Closed',
       CONCAT(COUNT(s.ID), ' reenvío(s) ', COALESCE(GROUP_CONCAT(s.shipment_status), '-'),
              ', devolución ', COALESCE(MAX(r.return_status), '-'), ' (', COALESCE(MAX(r.resolution_type), '-'), ')'),
       IF(COUNT(s.ID) = 1 AND MAX(s.shipment_status) = 'Delivered' AND MAX(r.return_status) = 'Closed'
          AND MAX(r.resolution_type) = 'Replacement', 'OK', 'FALLA')
FROM tb_returns r LEFT JOIN tb_shipments s ON s.return_ID = r.ID AND s.shipment_type = 'Replacement'
WHERE r.order_ID = @cp2;


/* =====================================================================
   CASO DE PRUEBA 3 · "Compra exitosa con cancelación parcial, ajuste y
   reembolso parcial" (11 operaciones)
   ===================================================================== */

-- CP3 · Op 01 · Usuario ya registrado crea 1 carrito de 3 productos de la misma categoría (1 a 10)
INSERT INTO tmp_pruebas
SELECT 'CP3', 1, 'Usuario ya registrado crea 1 carrito de 3 productos de la misma categoría (1 a 10 unidades)',
       'usuario previo / 3 productos / piezas 1-10 / 1 categoría común',
       CONCAT('usuario previo=', IF(u.creation_date < c.creation_date, 'sí', 'no'),
              ' / ', (SELECT COUNT(*) FROM tbd_cart_items WHERE cart_ID = c.ID), ' productos / piezas ',
              (SELECT MIN(quantity) FROM tbd_cart_items WHERE cart_ID = c.ID), '-',
              (SELECT MAX(quantity) FROM tbd_cart_items WHERE cart_ID = c.ID), ' / categorías comunes ',
              (SELECT COUNT(*) FROM (SELECT pc.category_ID FROM tbd_cart_items ci
                 JOIN tbd_products_categories pc ON pc.product_ID = ci.product_offer_ID
                 WHERE ci.cart_ID = @cp3_cart GROUP BY pc.category_ID
                 HAVING COUNT(DISTINCT ci.product_offer_ID) = 3) x)),
       IF(u.creation_date < c.creation_date
          AND (SELECT COUNT(*) FROM tbd_cart_items WHERE cart_ID = c.ID) = 3
          AND (SELECT MIN(quantity) FROM tbd_cart_items WHERE cart_ID = c.ID) >= 1
          AND (SELECT MAX(quantity) FROM tbd_cart_items WHERE cart_ID = c.ID) <= 10
          AND (SELECT COUNT(*) FROM (SELECT pc.category_ID FROM tbd_cart_items ci
                 JOIN tbd_products_categories pc ON pc.product_ID = ci.product_offer_ID
                 WHERE ci.cart_ID = @cp3_cart GROUP BY pc.category_ID
                 HAVING COUNT(DISTINCT ci.product_offer_ID) = 3) x) >= 1, 'OK', 'FALLA')
FROM tb_carts c JOIN tb_users u ON u.ID = c.user_ID
WHERE c.ID = @cp3_cart;

-- CP3 · Op 02 · Realiza la orden de compra
INSERT INTO tmp_pruebas
SELECT 'CP3', 2, 'Realiza la orden de compra',
       'carrito Converted y 3 productos en la orden',
       CONCAT('carrito ', c.cart_status, ', ', (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp3), ' productos en la orden'),
       IF(c.cart_status = 'Converted' AND (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp3) = 3, 'OK', 'FALLA')
FROM tb_carts c WHERE c.ID = @cp3_cart;

-- CP3 · Op 03 · Domicilio "Casa Papas" (no es su hogar)
INSERT INTO tmp_pruebas
SELECT 'CP3', 3, 'Registra domicilio de envío "Casa Papas" (no es su hogar)',
       'Casa Papas / NO predeterminado',
       CONCAT(COALESCE(MAX(a.address_label), 'sin domicilio'), ' / predeterminado=', MAX(a.is_default)),
       IF(MAX(a.address_label) = 'Casa Papas' AND MAX(a.is_default) = 0 AND MAX(a.user_ID) = @cp3_user, 'OK', 'FALLA')
FROM tb_orders o LEFT JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID
WHERE o.ID = @cp3;

-- CP3 · Op 04 · Tarjeta digital Spin de 16 dígitos vinculada
INSERT INTO tmp_pruebas
SELECT 'CP3', 4, 'Registra tarjeta digital (Spin) simulada de 16 dígitos (vinculada)',
       'DIGITAL_CARD / 16 dígitos / del cliente',
       CONCAT(COALESCE(MAX(t.code), 'sin método'), ' / ', MAX(CHAR_LENGTH(m.provider_method_ref)), ' dígitos'),
       IF(MAX(t.code) = 'DIGITAL_CARD' AND MAX(m.provider_method_ref REGEXP '^[0-9]{16}$') = 1
          AND MAX(m.user_ID) = @cp3_user, 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID
JOIN tbd_user_payment_methods m  ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
WHERE p.order_ID = @cp3;

-- CP3 · Op 05 · Un solo pago en efectivo por el costo total de la compra
INSERT INTO tmp_pruebas
SELECT 'CP3', 5, 'Registra un solo pago en efectivo por el costo total',
       '1 pago Cash = total original de la compra',
       CONCAT(COUNT(*), ' pago(s) ', COALESCE(MAX(pm.name), '-'), ' por ', COALESCE(SUM(p.amount), 0),
              ' de ', (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = @cp3)),
       IF(COUNT(*) = 1 AND MAX(pm.name) = 'Cash'
          AND SUM(p.amount) = (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = @cp3), 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.order_ID = @cp3;

-- CP3 · Op 06 · El sistema procesa la orden y la marca como atendida
INSERT INTO tmp_pruebas
SELECT 'CP3', 6, 'El sistema procesa la orden marcando como atendida',
       'cambio de estatus a Attended registrado en bitácora',
       IF(COUNT(*) > 0, CONCAT('Attended el ', MIN(operation_date)), 'sin registro'),
       IF(COUNT(*) > 0, 'OK', 'FALLA')
FROM tb_logs
WHERE table_name = 'tb_orders' AND record_ID = @cp3_txt
  AND JSON_UNQUOTE(JSON_EXTRACT(new_values, '$.status_string')) = 'Attended';

-- CP3 · Op 07 · El usuario cancela un producto del pedido
INSERT INTO tmp_pruebas
SELECT 'CP3', 7, 'El usuario cancela un producto del pedido',
       '1 cancelación parcial (Items) del cliente con 1 artículo; artículo Canceled',
       CONCAT(COUNT(DISTINCT oc.ID), ' cancelación(es) ', COALESCE(MAX(oc.cancellation_scope), '-'),
              ', ', COUNT(ci.ID), ' artículo(s), artículos cancelados en la orden: ',
              (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp3 AND item_status = 'Canceled')),
       IF(COUNT(DISTINCT oc.ID) = 1 AND MAX(oc.cancellation_scope) = 'Items' AND COUNT(ci.ID) = 1
          AND MAX(oc.requested_by_user_ID) = @cp3_user
          AND (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp3 AND item_status = 'Canceled') = 1, 'OK', 'FALLA')
FROM tb_order_cancellations oc LEFT JOIN tbd_cancellation_items ci ON ci.cancellation_ID = oc.ID
WHERE oc.order_ID = @cp3;

-- CP3 · Op 08 · El sistema actualiza la orden de compra
INSERT INTO tmp_pruebas
SELECT 'CP3', 8, 'El sistema realiza la actualización de la orden de compra',
       'total y piezas = artículos activos; cambio de total en bitácora',
       CONCAT('total ', ROUND(o.total_cost, 2), ' vs activos ',
              (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = o.ID AND item_status = 'Active'),
              ', piezas ', o.total_products, ' vs ',
              (SELECT SUM(quantity) FROM tbd_order_items WHERE order_ID = o.ID AND item_status = 'Active')),
       IF(ROUND(o.total_cost, 2) = (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = o.ID AND item_status = 'Active')
          AND o.total_products = (SELECT SUM(quantity) FROM tbd_order_items WHERE order_ID = o.ID AND item_status = 'Active')
          AND EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.record_ID = @cp3_txt
                        AND JSON_EXTRACT(l.new_values, '$.total_cost') IS NOT NULL), 'OK', 'FALLA')
FROM tb_orders o WHERE o.ID = @cp3;

-- CP3 · Op 09 · El sistema reembolsa el monto de los productos cancelados
INSERT INTO tmp_pruebas
SELECT 'CP3', 9, 'El sistema realiza el reembolso del monto de los productos cancelados',
       'reembolso = monto cancelado, transacción Refund aprobada, pago PartiallyRefunded',
       CONCAT('reembolso ', COALESCE(SUM(rf.amount), 0), ' vs cancelado ',
              (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = @cp3 AND item_status = 'Canceled'),
              ', pago ', MAX(p.payment_status)),
       IF(SUM(rf.amount) = (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = @cp3 AND item_status = 'Canceled')
          AND MAX(rf.refund_status) = 'Succeeded' AND MAX(p.payment_status) = 'PartiallyRefunded'
          AND EXISTS (SELECT 1 FROM tb_payment_transaction t WHERE t.refund_ID = MAX(rf.ID)
                        AND t.transaction_type = 'Refund' AND t.transaction_status = 'Succeeded'), 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tb_refunds rf ON rf.payment_ID = p.ID
WHERE p.order_ID = @cp3;

-- CP3 · Op 10 · El sistema realiza el envío (después del ajuste)
INSERT INTO tmp_pruebas
SELECT 'CP3', 10, 'El sistema realiza el envío',
       '1 envío a "Casa Papas" enviado después de la cancelación',
       CONCAT(COUNT(s.ID), ' envío(s), enviado ', COALESCE(MAX(s.shipped_at), '-')),
       IF(COUNT(s.ID) = 1 AND MAX(s.shipped_at) IS NOT NULL AND MAX(s.address_ID) = MAX(o.shipping_address_ID)
          AND MAX(s.shipped_at) >= (SELECT MAX(completed_at) FROM tb_order_cancellations WHERE order_ID = @cp3), 'OK', 'FALLA')
FROM tb_orders o LEFT JOIN tb_shipments s ON s.order_ID = o.ID
WHERE o.ID = @cp3;

-- CP3 · Op 11 · El cliente recibe el pedido
INSERT INTO tmp_pruebas
SELECT 'CP3', 11, 'El cliente recibe el pedido',
       'orden Delivered y envío Delivered',
       CONCAT('orden ', MAX(o.status_string), ', envío ', COALESCE(MAX(s.shipment_status), '-')),
       IF(MAX(o.status_string) = 'Delivered' AND MAX(s.shipment_status) = 'Delivered' AND MAX(s.delivered_at) IS NOT NULL, 'OK', 'FALLA')
FROM tb_orders o LEFT JOIN tb_shipments s ON s.order_ID = o.ID
WHERE o.ID = @cp3;


/* =====================================================================
   CASO DE PRUEBA 4 · "Compra exitosa del mismo proveedor con entrega en
   el punto de recolección" (8 operaciones)
   ===================================================================== */

-- CP4 · Op 01 · Usuario ya registrado crea 1 carrito de 3 productos del mismo proveedor (1 a 3)
INSERT INTO tmp_pruebas
SELECT 'CP4', 1, 'Usuario ya registrado crea 1 carrito de 3 productos del mismo proveedor (1 a 3 unidades)',
       'usuario previo / 3 productos / 1 proveedor / piezas 1-3',
       CONCAT('usuario previo=', IF(MAX(u.creation_date) < MAX(c.creation_date), 'sí', 'no'),
              ' / ', COUNT(ci.product_offer_ID), ' productos / ',
              COUNT(DISTINCT pv.user_ID), ' proveedor(es) / piezas ', MIN(ci.quantity), '-', MAX(ci.quantity)),
       IF(MAX(u.creation_date) < MAX(c.creation_date) AND COUNT(DISTINCT ci.product_offer_ID) = 3
          AND COUNT(DISTINCT pv.user_ID) = 1 AND MIN(ci.quantity) >= 1 AND MAX(ci.quantity) <= 3, 'OK', 'FALLA')
FROM tb_carts c
JOIN tb_users u ON u.ID = c.user_ID
LEFT JOIN tbd_cart_items ci ON ci.cart_ID = c.ID
LEFT JOIN tbd_products_users_providers pv ON pv.product_ID = ci.product_offer_ID AND pv.status = b'1'
WHERE c.ID = @cp4_cart;

-- CP4 · Op 02 · Realiza la orden de compra
INSERT INTO tmp_pruebas
SELECT 'CP4', 2, 'Realiza la orden de compra',
       'carrito Converted, 3 productos de 1 solo proveedor en la orden',
       CONCAT('carrito ', c.cart_status, ', ', (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp4), ' productos, ',
              (SELECT COUNT(DISTINCT seller_ID) FROM tbd_order_items WHERE order_ID = @cp4), ' proveedor(es)'),
       IF(c.cart_status = 'Converted' AND (SELECT COUNT(*) FROM tbd_order_items WHERE order_ID = @cp4) = 3
          AND (SELECT COUNT(DISTINCT seller_ID) FROM tbd_order_items WHERE order_ID = @cp4) = 1, 'OK', 'FALLA')
FROM tb_carts c WHERE c.ID = @cp4_cart;

-- CP4 · Op 03 · Domicilio de envío: su hogar
INSERT INTO tmp_pruebas
SELECT 'CP4', 3, 'Registra domicilio de envío de su hogar',
       'domicilio del cliente, predeterminado',
       CONCAT(COALESCE(MAX(a.address_label), 'sin domicilio'), ' / predeterminado=', MAX(a.is_default)),
       IF(MAX(a.user_ID) = @cp4_user AND MAX(a.is_default) = 1, 'OK', 'FALLA')
FROM tb_orders o LEFT JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID
WHERE o.ID = @cp4;

-- CP4 · Op 04 · Método de pago: transferencia SPEI, cuenta de 16 dígitos vinculada
INSERT INTO tmp_pruebas
SELECT 'CP4', 4, 'Registra cuenta para transferencia SPEI de 16 dígitos (vinculada)',
       'SPEI_TRANSFER / 16 dígitos / del cliente',
       CONCAT(COALESCE(MAX(t.code), 'sin método'), ' / ', MAX(CHAR_LENGTH(m.provider_method_ref)), ' dígitos'),
       IF(MAX(t.code) = 'SPEI_TRANSFER' AND MAX(m.provider_method_ref REGEXP '^[0-9]{16}$') = 1
          AND MAX(m.user_ID) = @cp4_user, 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID
JOIN tbd_user_payment_methods m  ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
WHERE p.order_ID = @cp4;

-- CP4 · Op 05 · Un solo pago por el costo total (vía SPEI)
INSERT INTO tmp_pruebas
SELECT 'CP4', 5, 'Registra un solo pago por el costo total de la compra (SPEI)',
       '1 pago SPEI Paid = total, con transacción aprobada',
       CONCAT(COUNT(*), ' pago(s) ', COALESCE(MAX(pm.name), '-'), ' ', COALESCE(MAX(p.payment_status), '-'),
              ' por ', COALESCE(SUM(p.amount), 0), ' de ', (SELECT ROUND(total_cost, 2) FROM tb_orders WHERE ID = @cp4)),
       IF(COUNT(*) = 1 AND MAX(pm.name) = 'SPEI' AND MAX(p.payment_status) = 'Paid'
          AND SUM(p.amount) = (SELECT ROUND(total_cost, 2) FROM tb_orders WHERE ID = @cp4)
          AND EXISTS (SELECT 1 FROM tb_payment_transaction t WHERE t.payment_ID = MAX(p.ID)
                        AND t.transaction_status = 'Succeeded'), 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.order_ID = @cp4;

-- CP4 · Op 06 · El sistema procesa la orden y la marca como atendida
INSERT INTO tmp_pruebas
SELECT 'CP4', 6, 'El sistema procesa la orden marcando como atendida',
       'cambio de estatus a Attended registrado en bitácora',
       IF(COUNT(*) > 0, CONCAT('Attended el ', MIN(operation_date)), 'sin registro'),
       IF(COUNT(*) > 0, 'OK', 'FALLA')
FROM tb_logs
WHERE table_name = 'tb_orders' AND record_ID = @cp4_txt
  AND JSON_UNQUOTE(JSON_EXTRACT(new_values, '$.status_string')) = 'Attended';

-- CP4 · Op 07 · El sistema realiza el envío
INSERT INTO tmp_pruebas
SELECT 'CP4', 7, 'El sistema realiza el envío',
       '1 envío al domicilio, enviado (InTransit en bitácora)',
       CONCAT(COUNT(DISTINCT s.ID), ' envío(s), enviado ', COALESCE(MAX(s.shipped_at), '-')),
       IF(COUNT(DISTINCT s.ID) = 1 AND MAX(s.shipped_at) IS NOT NULL
          AND EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_shipments'
                        AND l.record_ID = CONVERT(CAST(MAX(s.ID) AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci
                        AND JSON_UNQUOTE(JSON_EXTRACT(l.new_values, '$.shipment_status')) = 'InTransit'), 'OK', 'FALLA')
FROM tb_shipments s WHERE s.order_ID = @cp4;

-- CP4 · Op 08 · Entrega fallida y el cliente recoge en el punto de recolección
INSERT INTO tmp_pruebas
SELECT 'CP4', 8, 'El cliente recoge el pedido en el punto de recolección (no hubo quien recibiera)',
       'DeliveryFailed en bitácora → PickedUp con punto y código',
       CONCAT('intentos ', MAX(s.delivery_attempts), ', estatus ', MAX(s.shipment_status),
              ', punto ', COALESCE(MAX(s.pickup_point_name), '-'), ', código ', COALESCE(MAX(s.pickup_code), '-')),
       IF(MAX(s.shipment_status) = 'PickedUp' AND MAX(s.pickup_point_name) IS NOT NULL AND MAX(s.pickup_code) IS NOT NULL
          AND MAX(s.picked_up_at) IS NOT NULL AND MAX(s.delivery_attempts) >= 1
          AND EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_shipments'
                        AND l.record_ID = CONVERT(CAST(MAX(s.ID) AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci
                        AND JSON_UNQUOTE(JSON_EXTRACT(l.new_values, '$.shipment_status')) = 'DeliveryFailed'), 'OK', 'FALLA')
FROM tb_shipments s WHERE s.order_ID = @cp4;


/* =====================================================================
   CASO DE PRUEBA 5 · "Compra fallida por falta de inventario"
   (6 operaciones)
   ===================================================================== */

-- CP5 · Op 01 · Usuario ya registrado crea 1 carrito de 1 producto (1 a 5 unidades)
INSERT INTO tmp_pruebas
SELECT 'CP5', 1, 'Usuario ya registrado crea 1 carrito de 1 producto del mismo proveedor (1 a 5 unidades)',
       'usuario previo / 1 producto / 1 proveedor / piezas 1-5',
       CONCAT('usuario previo=', IF(MAX(u.creation_date) < MAX(c.creation_date), 'sí', 'no'),
              ' / ', COUNT(ci.product_offer_ID), ' producto(s) / ', COUNT(DISTINCT pv.user_ID),
              ' proveedor / piezas ', COALESCE(MAX(ci.quantity), 0)),
       IF(MAX(u.creation_date) < MAX(c.creation_date) AND COUNT(DISTINCT ci.product_offer_ID) = 1
          AND COUNT(DISTINCT pv.user_ID) = 1 AND MAX(ci.quantity) BETWEEN 1 AND 5, 'OK', 'FALLA')
FROM tb_carts c
JOIN tb_users u ON u.ID = c.user_ID
LEFT JOIN tbd_cart_items ci ON ci.cart_ID = c.ID
LEFT JOIN tbd_products_users_providers pv ON pv.product_ID = ci.product_offer_ID AND pv.status = b'1'
WHERE c.ID = @cp5_cart;

-- CP5 · Op 02 · Realiza la orden de compra
INSERT INTO tmp_pruebas
SELECT 'CP5', 2, 'Realiza la orden de compra',
       'carrito Converted y orden creada (Registered en bitácora)',
       CONCAT('carrito ', c.cart_status, ', orden creada=',
              IF(EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.operation = 'Create'
                           AND l.record_ID = @cp5_txt), 'sí', 'no')),
       IF(c.cart_status = 'Converted'
          AND EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.operation = 'Create'
                        AND l.record_ID = @cp5_txt
                        AND JSON_UNQUOTE(JSON_EXTRACT(l.new_values, '$.status_string')) = 'Registered'), 'OK', 'FALLA')
FROM tb_carts c WHERE c.ID = @cp5_cart;

-- CP5 · Op 03 · Domicilio de envío: su hogar
INSERT INTO tmp_pruebas
SELECT 'CP5', 3, 'Registra domicilio de envío de su hogar',
       'domicilio del cliente, predeterminado',
       CONCAT(COALESCE(MAX(a.address_label), 'sin domicilio'), ' / predeterminado=', MAX(a.is_default)),
       IF(MAX(a.user_ID) = @cp5_user AND MAX(a.is_default) = 1, 'OK', 'FALLA')
FROM tb_orders o LEFT JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID
WHERE o.ID = @cp5;

-- CP5 · Op 04 · Método de pago: cupón de regalo
INSERT INTO tmp_pruebas
SELECT 'CP5', 4, 'Registra su método de pago: cupón de regalo',
       'GIFT_COUPON del cliente, usado en un pago GiftCoupon',
       CONCAT(COALESCE(MAX(t.code), 'sin método'), ' / pago ', COALESCE(MAX(pm.name), '-')),
       IF(MAX(t.code) = 'GIFT_COUPON' AND MAX(pm.name) = 'GiftCoupon' AND MAX(m.user_ID) = @cp5_user, 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID
JOIN tbd_user_payment_methods m  ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
WHERE p.order_ID = @cp5;

-- CP5 · Op 05 · El sistema marca la orden como no atendida por falta de inventario
INSERT INTO tmp_pruebas
SELECT 'CP5', 5, 'El sistema procesa la orden marcando como no atendida por falta de inventario',
       'NotAttended en bitácora, ajuste de inventario del producto, motivo OUT_OF_STOCK',
       CONCAT('NotAttended=',
              IF(EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.record_ID = @cp5_txt
                           AND JSON_UNQUOTE(JSON_EXTRACT(l.new_values, '$.status_string')) = 'NotAttended'), 'sí', 'no'),
              ', existencias actuales del producto=', MAX(pr.current_stock),
              ', motivo=', COALESCE((SELECT MAX(reason_code) FROM tb_order_cancellations WHERE order_ID = @cp5), '-')),
       IF(EXISTS (SELECT 1 FROM tb_logs l WHERE l.table_name = 'tb_orders' AND l.record_ID = @cp5_txt
                    AND JSON_UNQUOTE(JSON_EXTRACT(l.new_values, '$.status_string')) = 'NotAttended')
          AND MAX(pr.current_stock) < MAX(oi.quantity)
          AND (SELECT MAX(reason_code) FROM tb_order_cancellations WHERE order_ID = @cp5) = 'OUT_OF_STOCK', 'OK', 'FALLA')
FROM tbd_order_items oi JOIN tb_products pr ON pr.ID = oi.product_offer_ID
WHERE oi.order_ID = @cp5;

-- CP5 · Op 06 · El sistema cancela la orden y reasigna el cupón
INSERT INTO tmp_pruebas
SELECT 'CP5', 6, 'El sistema cancela la orden y se reasigna el cupón utilizado',
       'orden Canceled, sin envío, pago Refunded, cupón Active con su saldo original',
       CONCAT('orden ', MAX(o.status_string), ', envíos ', (SELECT COUNT(*) FROM tb_shipments WHERE order_ID = @cp5),
              ', pago ', MAX(p.payment_status), ', cupón ', MAX(m.method_status),
              ' saldo ', MAX(m.balance), ' (original ',
              COALESCE((SELECT JSON_EXTRACT(l.new_values, '$.balance') FROM tb_logs l
                        WHERE l.table_name = 'tbd_user_payment_methods' AND l.operation = 'Create'
                          AND l.record_ID = CONVERT(CAST(MAX(m.id) AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci
                        LIMIT 1), '-'), ')'),
       IF(MAX(o.status_string) = 'Canceled' AND (SELECT COUNT(*) FROM tb_shipments WHERE order_ID = @cp5) = 0
          AND MAX(p.payment_status) = 'Refunded' AND MAX(m.method_status) = 'Active'
          AND MAX(m.balance) = (SELECT JSON_EXTRACT(l.new_values, '$.balance') FROM tb_logs l
                                WHERE l.table_name = 'tbd_user_payment_methods' AND l.operation = 'Create'
                                  AND l.record_ID = CONVERT(CAST(MAX(m.id) AS CHAR) USING utf8mb4) COLLATE utf8mb4_unicode_ci
                                LIMIT 1), 'OK', 'FALLA')
FROM tb_orders o
JOIN tb_payments p ON p.order_ID = o.ID
JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
WHERE o.ID = @cp5;


/* =====================================================================
   RESULTADOS
   ===================================================================== */
-- 1. Detalle: una fila por operación
SELECT caso, operacion AS op, descripcion AS operacion_del_enunciado, esperado, obtenido, resultado
FROM tmp_pruebas
ORDER BY caso, operacion;

-- 2. Resumen por caso
SELECT caso,
       COUNT(*)                 AS pruebas,
       SUM(resultado = 'OK')    AS aprobadas,
       SUM(resultado = 'FALLA') AS fallidas,
       IF(SUM(resultado = 'FALLA') = 0, 'APROBADO', 'CON FALLAS') AS estado
FROM tmp_pruebas
GROUP BY caso
ORDER BY caso;

-- 3. Resultado global
SELECT COUNT(*)                 AS total_pruebas,
       SUM(resultado = 'OK')    AS aprobadas,
       SUM(resultado = 'FALLA') AS fallidas,
       CONCAT(ROUND(100 * SUM(resultado = 'OK') / COUNT(*), 1), ' %') AS porcentaje,
       IF(SUM(resultado = 'FALLA') = 0, 'TODOS LOS CASOS APROBADOS', 'REVISAR FALLAS') AS resultado_global
FROM tmp_pruebas;

DROP TEMPORARY TABLE IF EXISTS tmp_pruebas;