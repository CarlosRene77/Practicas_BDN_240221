/* =====================================================================
   Validación de los Casos de Prueba 1 a 5 contra el enunciado
   Base: db_test   |   Solo lectura
   Cada fila es un requisito: muestra lo esperado, lo obtenido y si se
   cumple (OK / FALLA). Si se vuelven a ejecutar los casos, ajusta los
   IDs de orden de las variables @cpN.
   ===================================================================== */
USE db_test;

SET @cp1 = 1, @cp2 = 2, @cp3 = 3, @cp4 = 4, @cp5 = 5;

-- Historial de estatus de una orden según la bitácora (para validar 'Attended' / 'NotAttended')
SELECT 'Caso' AS caso, 'Requisito' AS requisito, 'Esperado' AS esperado, 'Obtenido' AS obtenido, 'Resultado' AS resultado
FROM DUAL WHERE FALSE

/* ------------------------------ CASO 1 ------------------------------ */
UNION ALL SELECT 'CP1', 'Carrito convertido en orden', 'Converted',
       c.cart_status, IF(c.cart_status = 'Converted', 'OK', 'FALLA')
FROM tb_orders o JOIN tb_carts c ON c.ID = o.cart_ID WHERE o.ID = @cp1
UNION ALL SELECT 'CP1', '5 productos con cantidades diferentes', '5 productos / 5 cantidades distintas',
       CONCAT(COUNT(*), ' productos / ', COUNT(DISTINCT quantity), ' cantidades distintas'),
       IF(COUNT(*) = 5 AND COUNT(DISTINCT quantity) = 5, 'OK', 'FALLA')
FROM tbd_order_items WHERE order_ID = @cp1
UNION ALL SELECT 'CP1', 'Método de pago tarjeta de débito (16 dígitos)', 'DEBIT_CARD / 16',
       CONCAT(t.code, ' / ', CHAR_LENGTH(m.provider_method_ref)),
       IF(t.code = 'DEBIT_CARD' AND CHAR_LENGTH(m.provider_method_ref) = 16, 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID WHERE p.order_ID = @cp1
UNION ALL SELECT 'CP1', 'Pago único autorizado', '1 pago Paid',
       CONCAT(COUNT(*), ' pago(s) ', GROUP_CONCAT(payment_status)),
       IF(COUNT(*) = 1 AND MIN(payment_status) = 'Paid', 'OK', 'FALLA')
FROM tb_payments WHERE order_ID = @cp1
UNION ALL SELECT 'CP1', 'Pedido entregado', 'Delivered',
       status_string, IF(status_string = 'Delivered', 'OK', 'FALLA')
FROM tb_orders WHERE ID = @cp1
UNION ALL SELECT 'CP1', 'Un solo registro de envío', '1 envío',
       CONCAT(COUNT(*), ' envíos'), IF(COUNT(*) = 1, 'OK', 'FALLA')
FROM tb_shipments WHERE order_ID = @cp1

/* ------------------------------ CASO 2 ------------------------------ */
UNION ALL SELECT 'CP2', 'Carrito de 10 productos, 1 a 5 piezas', '10 productos, piezas 1-5',
       CONCAT(COUNT(*), ' productos, piezas ', MIN(quantity), '-', MAX(quantity)),
       IF(COUNT(*) = 10 AND MIN(quantity) >= 1 AND MAX(quantity) <= 5, 'OK', 'FALLA')
FROM tbd_order_items WHERE order_ID = @cp2
UNION ALL SELECT 'CP2', 'Domicilio que no es su hogar', 'no predeterminado',
       CONCAT(a.address_label, ' / predeterminado=', a.is_default),
       IF(a.is_default = 0, 'OK', 'FALLA')
FROM tb_orders o JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID WHERE o.ID = @cp2
UNION ALL SELECT 'CP2', 'Tarjeta de crédito (16 dígitos)', 'CREDIT_CARD / 16',
       CONCAT(t.code, ' / ', CHAR_LENGTH(m.provider_method_ref)),
       IF(t.code = 'CREDIT_CARD' AND CHAR_LENGTH(m.provider_method_ref) = 16, 'OK', 'FALLA')
FROM tbd_user_payment_methods m JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID
WHERE m.id = (SELECT MIN(user_payment_method_ID) FROM tb_payments WHERE order_ID = @cp2)
UNION ALL SELECT 'CP2', '6 pagos mensuales: 5 aprobados, 1 rechazado', '6 / 5 Paid / 1 Failed',
       CONCAT(COUNT(*), ' / ', SUM(payment_status = 'Paid'), ' Paid / ', SUM(payment_status = 'Failed'), ' Failed'),
       IF(COUNT(*) = 6 AND SUM(payment_status = 'Paid') = 5 AND SUM(payment_status = 'Failed') = 1, 'OK', 'FALLA')
FROM tb_payments WHERE order_ID = @cp2
UNION ALL SELECT 'CP2', 'El rechazado es el último, por límite de crédito', 'mensualidad 6 / límite excedido',
       CONCAT('mensualidad ', p.installment_number, ' / ', t.response_message),
       IF(p.installment_number = 6 AND t.response_message LIKE '%límite%', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_ID = @cp2 AND t.transaction_status = 'Failed'
UNION ALL SELECT 'CP2', 'Las mensualidades suman el total', CAST(ROUND(o.total_cost, 2) AS CHAR),
       CAST(SUM(p.amount) AS CHAR), IF(SUM(p.amount) = ROUND(o.total_cost, 2), 'OK', 'FALLA')
FROM tb_orders o JOIN tb_payments p ON p.order_ID = o.ID WHERE o.ID = @cp2 GROUP BY o.total_cost
UNION ALL SELECT 'CP2', 'Reclamación de un producto dañado', '1 devolución Damaged',
       CONCAT(COUNT(DISTINCT r.ID), ' devolución(es) ', GROUP_CONCAT(ri.item_condition)),
       IF(COUNT(DISTINCT r.ID) = 1 AND MIN(ri.item_condition) = 'Damaged', 'OK', 'FALLA')
FROM tb_returns r JOIN tbd_return_items ri ON ri.return_ID = r.ID WHERE r.order_ID = @cp2
UNION ALL SELECT 'CP2', 'Reenvío ligado a la devolución y entregado', 'Replacement Delivered',
       COALESCE(GROUP_CONCAT(CONCAT(s.shipment_type, ' ', s.shipment_status)), 'sin reenvío'),
       IF(COUNT(*) = 1 AND MIN(s.shipment_status) = 'Delivered', 'OK', 'FALLA')
FROM tb_shipments s WHERE s.order_ID = @cp2 AND s.shipment_type = 'Replacement' AND s.return_ID IS NOT NULL

/* ------------------------------ CASO 3 ------------------------------ */
UNION ALL SELECT 'CP3', 'Carrito de 3 productos, 1 a 10 piezas', '3 productos, piezas 1-10',
       CONCAT(COUNT(*), ' productos, piezas ', MIN(quantity), '-', MAX(quantity)),
       IF(COUNT(*) = 3 AND MIN(quantity) >= 1 AND MAX(quantity) <= 10, 'OK', 'FALLA')
FROM tbd_order_items WHERE order_ID = @cp3
UNION ALL SELECT 'CP3', 'Los 3 productos son de la misma categoría', 'al menos 1 categoría común',
       CONCAT(COUNT(*), ' categoría(s) común(es)'), IF(COUNT(*) >= 1, 'OK', 'FALLA')
FROM (SELECT pc.category_ID FROM tbd_order_items oi
      JOIN tbd_products_categories pc ON pc.product_ID = oi.product_offer_ID
      WHERE oi.order_ID = @cp3 GROUP BY pc.category_ID HAVING COUNT(DISTINCT oi.product_offer_ID) = 3) x
UNION ALL SELECT 'CP3', 'Domicilio "Casa Papas" (no es su hogar)', 'Casa Papas / no predeterminado',
       CONCAT(a.address_label, ' / predeterminado=', a.is_default),
       IF(a.address_label = 'Casa Papas' AND a.is_default = 0, 'OK', 'FALLA')
FROM tb_orders o JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID WHERE o.ID = @cp3
UNION ALL SELECT 'CP3', 'Tarjeta digital Spin + pago único en efectivo', 'DIGITAL_CARD / 1 pago Cash',
       CONCAT(t.code, ' / ', COUNT(*), ' pago ', MIN(pm.name)),
       IF(t.code = 'DIGITAL_CARD' AND COUNT(*) = 1 AND MIN(pm.name) = 'Cash', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID WHERE p.order_ID = @cp3 GROUP BY t.code
UNION ALL SELECT 'CP3', 'Cancelación de 1 producto', '1 cancelado',
       CONCAT(SUM(item_status = 'Canceled'), ' cancelado(s)'),
       IF(SUM(item_status = 'Canceled') = 1, 'OK', 'FALLA')
FROM tbd_order_items WHERE order_ID = @cp3
UNION ALL SELECT 'CP3', 'Orden actualizada (total = artículos activos)', CAST(ROUND(o.total_cost, 2) AS CHAR),
       CAST(SUM(IF(oi.item_status = 'Active', oi.subtotal, 0)) AS CHAR),
       IF(ROUND(o.total_cost, 2) = SUM(IF(oi.item_status = 'Active', oi.subtotal, 0)), 'OK', 'FALLA')
FROM tb_orders o JOIN tbd_order_items oi ON oi.order_ID = o.ID WHERE o.ID = @cp3 GROUP BY o.total_cost
UNION ALL SELECT 'CP3', 'Reembolso = monto del producto cancelado',
       (SELECT CAST(SUM(subtotal) AS CHAR) FROM tbd_order_items WHERE order_ID = @cp3 AND item_status = 'Canceled'),
       CAST(SUM(rf.amount) AS CHAR),
       IF(SUM(rf.amount) = (SELECT SUM(subtotal) FROM tbd_order_items WHERE order_ID = @cp3 AND item_status = 'Canceled')
          AND MIN(rf.refund_status) = 'Succeeded', 'OK', 'FALLA')
FROM tb_refunds rf JOIN tb_payments p ON p.ID = rf.payment_ID WHERE p.order_ID = @cp3
UNION ALL SELECT 'CP3', 'Pedido enviado y entregado', 'Delivered',
       CONCAT(o.status_string, ' / envío ', s.shipment_status),
       IF(o.status_string = 'Delivered' AND s.shipment_status = 'Delivered', 'OK', 'FALLA')
FROM tb_orders o JOIN tb_shipments s ON s.order_ID = o.ID WHERE o.ID = @cp3

/* ------------------------------ CASO 4 ------------------------------ */
UNION ALL SELECT 'CP4', '3 productos del mismo proveedor, 1 a 3 piezas', '3 productos / 1 proveedor / piezas 1-3',
       CONCAT(COUNT(*), ' productos / ', COUNT(DISTINCT seller_ID), ' proveedor / piezas ', MIN(quantity), '-', MAX(quantity)),
       IF(COUNT(*) = 3 AND COUNT(DISTINCT seller_ID) = 1 AND MIN(quantity) >= 1 AND MAX(quantity) <= 3, 'OK', 'FALLA')
FROM tbd_order_items WHERE order_ID = @cp4
UNION ALL SELECT 'CP4', 'Domicilio de su hogar', 'predeterminado',
       CONCAT(a.address_label, ' / predeterminado=', a.is_default), IF(a.is_default = 1, 'OK', 'FALLA')
FROM tb_orders o JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID WHERE o.ID = @cp4
UNION ALL SELECT 'CP4', 'Transferencia SPEI (16 dígitos), pago único', 'SPEI_TRANSFER / 16 / 1 pago SPEI Paid',
       CONCAT(t.code, ' / ', CHAR_LENGTH(m.provider_method_ref), ' / ', COUNT(*), ' pago ', MIN(pm.name), ' ', MIN(p.payment_status)),
       IF(t.code = 'SPEI_TRANSFER' AND CHAR_LENGTH(m.provider_method_ref) = 16 AND COUNT(*) = 1
          AND MIN(pm.name) = 'SPEI' AND MIN(p.payment_status) = 'Paid', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID WHERE p.order_ID = @cp4
GROUP BY t.code, m.provider_method_ref
UNION ALL SELECT 'CP4', 'Entrega fallida registrada en bitácora', 'DeliveryFailed',
       IF(COUNT(*) > 0, 'DeliveryFailed', 'no registrado'), IF(COUNT(*) > 0, 'OK', 'FALLA')
FROM tb_logs l JOIN tb_shipments s ON l.table_name = 'tb_shipments'
  AND l.record_ID = CAST(s.ID AS CHAR) COLLATE utf8mb4_unicode_ci
WHERE s.order_ID = @cp4 AND JSON_UNQUOTE(JSON_EXTRACT(l.new_values, '$.shipment_status')) = 'DeliveryFailed'
UNION ALL SELECT 'CP4', 'Recogido en punto de recolección', 'PickedUp con punto y código',
       CONCAT(s.shipment_status, ' / ', COALESCE(s.pickup_point_name, 'sin punto'), ' / ', COALESCE(s.pickup_code, 'sin código')),
       IF(s.shipment_status = 'PickedUp' AND s.pickup_point_name IS NOT NULL AND s.pickup_code IS NOT NULL, 'OK', 'FALLA')
FROM tb_shipments s WHERE s.order_ID = @cp4

/* ------------------------------ CASO 5 ------------------------------ */
UNION ALL SELECT 'CP5', '1 producto, 1 a 5 piezas', '1 producto, piezas 1-5',
       CONCAT(COUNT(*), ' producto, piezas ', MIN(quantity)),
       IF(COUNT(*) = 1 AND MIN(quantity) BETWEEN 1 AND 5, 'OK', 'FALLA')
FROM tbd_order_items WHERE order_ID = @cp5
UNION ALL SELECT 'CP5', 'Domicilio de su hogar', 'predeterminado',
       CONCAT(a.address_label, ' / predeterminado=', a.is_default), IF(a.is_default = 1, 'OK', 'FALLA')
FROM tb_orders o JOIN tb_user_addresses a ON a.ID = o.shipping_address_ID WHERE o.ID = @cp5
UNION ALL SELECT 'CP5', 'Pago con cupón de regalo', 'GIFT_COUPON / GiftCoupon',
       CONCAT(t.code, ' / ', pm.name),
       IF(t.code = 'GIFT_COUPON' AND pm.name = 'GiftCoupon', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.id = m.payment_method_type_ID WHERE p.order_ID = @cp5
UNION ALL SELECT 'CP5', 'Orden marcada como no atendida (bitácora)', 'NotAttended',
       IF(COUNT(*) > 0, 'NotAttended', 'no registrado'), IF(COUNT(*) > 0, 'OK', 'FALLA')
FROM tb_logs WHERE table_name = 'tb_orders' AND record_ID = CAST(@cp5 AS CHAR) COLLATE utf8mb4_unicode_ci
  AND JSON_UNQUOTE(JSON_EXTRACT(new_values, '$.status_string')) = 'NotAttended'
UNION ALL SELECT 'CP5', 'Orden cancelada por falta de inventario', 'Canceled / OUT_OF_STOCK / Completed',
       CONCAT(o.status_string, ' / ', oc.reason_code, ' / ', oc.cancellation_status),
       IF(o.status_string = 'Canceled' AND oc.reason_code = 'OUT_OF_STOCK' AND oc.cancellation_status = 'Completed', 'OK', 'FALLA')
FROM tb_orders o JOIN tb_order_cancellations oc ON oc.order_ID = o.ID WHERE o.ID = @cp5
UNION ALL SELECT 'CP5', 'Sin envío generado', '0 envíos',
       CONCAT(COUNT(*), ' envíos'), IF(COUNT(*) = 0, 'OK', 'FALLA')
FROM tb_shipments WHERE order_ID = @cp5
UNION ALL SELECT 'CP5', 'Cupón reasignado (saldo completo y disponible)', 'Active / saldo restituido',
       CONCAT(m.method_status, ' / saldo ', m.balance, ' / reembolso ', rf.amount),
       IF(m.method_status = 'Active' AND rf.refund_status = 'Succeeded' AND p.payment_status = 'Refunded', 'OK', 'FALLA')
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID JOIN tbd_user_payment_methods m ON m.id = p.user_payment_method_ID
JOIN tb_refunds rf ON rf.payment_ID = p.ID WHERE p.order_ID = @cp5

/* --------------------------- GENERAL / BITÁCORA --------------------------- */
UNION ALL SELECT 'GEN', 'Órdenes 2-5 pasaron por "Attended" o "NotAttended"', '4 órdenes',
       CONCAT(COUNT(DISTINCT record_ID), ' órdenes'), IF(COUNT(DISTINCT record_ID) = 4, 'OK', 'FALLA')
FROM tb_logs WHERE table_name = 'tb_orders'
  AND record_ID IN ('2','3','4','5')
  AND JSON_UNQUOTE(JSON_EXTRACT(new_values, '$.status_string')) IN ('Attended','NotAttended')
UNION ALL SELECT 'GEN', 'Cada carrito convertido tiene su orden', '0 carritos huérfanos',
       CONCAT(COUNT(*), ' carritos huérfanos'), IF(COUNT(*) = 0, 'OK', 'FALLA')
FROM tb_carts c WHERE c.cart_status = 'Converted' AND NOT EXISTS (SELECT 1 FROM tb_orders o WHERE o.cart_ID = c.ID)
UNION ALL SELECT 'GEN', 'Triggers AFTER (3 por tabla, sin tb_logs)', '72',
       CAST(COUNT(*) AS CHAR), IF(COUNT(*) = 72, 'OK', 'FALLA')
FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = 'db_test' AND ACTION_TIMING = 'AFTER'
UNION ALL SELECT 'GEN', 'Registros de bitácora con estatus normalizado', 'todos = 1',
       CONCAT(SUM(operation_status <> 1), ' distintos de 1'), IF(SUM(operation_status <> 1) = 0, 'OK', 'FALLA')
FROM tb_logs;