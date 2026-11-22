# Práctica 04 · Procesos de Simulación de Compra — `db_test`

Base de datos de un ecommerce en **MySQL 8.0**:
- 25 tablas;
- bitácora `tb_logs`;
- 72 triggers de auditoría (3 por tabla: `after_insert`, `after_update` y `after_delete`; `tb_logs` no lleva);
- una vista de trazabilidad por tabla;
- una vista de trazabilidad por cada caso de prueba (5).

Los casos de prueba se resuelven **solo con SQL básico**: `INSERT`, `UPDATE`, `SELECT` y transacciones, sin procedimientos almacenados.

## Requisitos para revisar

- **MySQL 8.0.16 o superior.** Se usan restricciones `CHECK`, columnas JSON, columnas generadas y `WITH RECURSIVE`.
- **Importar el respaldo con `root`** o con un usuario administrador. Los triggers y las vistas tienen `DEFINER=root@localhost`.
- Los **usuarios y roles de MySQL** no viajan dentro de `db_test`. Para crearlos en otro servidor se usa `04_usuarios_roles_permisos.sql`.

## Cómo revisar

1. Importar el respaldo `db_test.sql`. Ya contiene los 5 casos ejecutados.
2. Ejecutar `pruebas_casos_prueba.sql`. Tiene **una prueba por cada operación del enunciado**: CP1 = 11, CP2 = 10, CP3 = 11, CP4 = 8 y CP5 = 6, en total 46. Al final muestra el detalle, un resumen por caso y el resultado global. Es de solo lectura.
3. Ejecutar `validacion_casos_prueba.sql`, que revisa los requisitos de cada caso (38 validaciones `OK` / `FALLA`).
4. Ejecutar `verificar_triggers_vistas.sql`. Debe dar 24 tablas auditadas, 72 triggers y 24 vistas de trazabilidad.
5. Consultar el resumen de las órdenes y los saldos:
   ```sql
   SELECT * FROM db_test.vw_seguimiento_ordenes ORDER BY order_ID;
   SELECT * FROM db_test.vw_cuentas_por_cobrar  ORDER BY order_ID;
   ```
6. Consultar el rastro completo de cada caso en orden cronológico:
   ```sql
   SELECT * FROM db_test.vw_trazabilidad_caso_1 ORDER BY fecha, log_ID;   -- ... hasta vw_trazabilidad_caso_5
   ```
7. Consultar la trazabilidad de cualquier registro. Por ejemplo:
   ```sql
   SELECT * FROM db_test.vw_trazabilidad_tb_shipments WHERE record_ID = '<ID del envío>';
   ```

## Orden de ejecución de los scripts

| # | Script | Usuario | Qué hace |
|---|---|---|---|
| 1 | `01_relaciones_carrito_orden.sql` | superadmin | Relación **carrito → orden de compra**: un carrito activo por usuario y, al comprar, el carrito pasa a `Converted`. Liga el detalle, los envíos, las devoluciones y las cancelaciones directo con `tb_orders`. Liga cada pago con el instrumento del usuario. Deja las 25 tablas del diagrama. |
| 2 | `02_auditoria_triggers_vistas.sql` | superadmin | Agrega a `tb_logs` el registro afectado, los roles del usuario y los valores de antes y después (JSON). Genera los 72 triggers, las vistas de trazabilidad y la vista de seguimiento. |
| — | Caso de Prueba 1 | app_web / superadmin | Compra exitosa sin modificaciones. |
| 3 | `03_modelo_final.sql` | superadmin | Corrige fechas inválidas, los envíos duplicados del Caso 1, las rutinas rotas y las vistas repetidas. Agrega los catálogos de pago y lo que necesitan los Casos 2 a 5 (ver abajo). Deja los montos en `DECIMAL(12,2)`, regenera los triggers afectados y crea las vistas finales. |
| 4 | `04_usuarios_roles_permisos.sql` | root / superadmin | Usuarios, roles y permisos. Las contraseñas son de ejemplo. Se puede ejecutar varias veces. |
| 5 | `cp2_01_compra_reclamacion_reenvio.sql` | superadmin | Caso 2. |
| 6 | `cp3_01_cancelacion_parcial_reembolso.sql` | superadmin | Caso 3. |
| 7 | `cp4_01_entrega_punto_recoleccion.sql` | superadmin | Caso 4. |
| 8 | `cp5_01_compra_fallida_inventario.sql` | superadmin | Caso 5. |
| 9 | `06_correccion_domicilio_caso1.sql` | superadmin | Elimina la copia duplicada de los 7 componentes del domicilio del Caso 1. Cada eliminación queda en la bitácora. |
| 10 | `05_vistas_trazabilidad_casos.sql` | superadmin | Crea una vista de trazabilidad por caso (`vw_trazabilidad_caso_1` a `vw_trazabilidad_caso_5`). Se puede ejecutar varias veces. |

Los scripts 1 a 4 se ejecutan **una sola vez**. Los scripts de los casos se pueden repetir, porque cada ejecución elige otro cliente y otros productos al azar. El script de pruebas siempre evalúa la ejecución más reciente de cada caso.

Todos los scripts desactivan el modo *Safe Updates* de Workbench al inicio y lo reactivan al final.

## Casos de prueba

| Caso | Resumen |
|---|---|
| 1 | Usuario nuevo registrado desde `app_web`. 5 productos con cantidades distintas, envío a casa, tarjeta de débito, pago único autorizado, orden atendida y entregada. |
| 2 | 10 productos aleatorios (1 a 5 piezas), envío a la oficina y tarjeta de crédito. 6 mensualidades: 5 aprobadas y la última rechazada por límite de crédito. Reclamación de un producto dañado y reenvío ligado a la devolución. |
| 3 | 3 productos de la misma categoría (1 a 10 piezas), envío a "Casa Papas", tarjeta digital Spin y pago único en efectivo. Cancelación de 1 producto, ajuste de la orden, reembolso parcial y envío. |
| 4 | 3 productos del mismo proveedor (1 a 3 piezas), envío a casa y un solo pago por SPEI. Entrega fallida y recolección en el punto de entrega con código. |
| 5 | 1 producto (1 a 5 piezas) pagado con cupón de regalo. Orden no atendida por falta de inventario, cancelación y reasignación del cupón. |

## Modelo final

### Formas de pago e instrumentos

- `tbc_payment_methods_types` es el catálogo de **instrumentos** que registra el cliente: débito, crédito, tarjeta digital, cuenta SPEI y cupón.
- `tb_payment_methods` es el catálogo de **formas de pago** de la tienda, es decir, cómo se cobra: `Card`, `SPEI`, `Transfer`, `Cash` y `GiftCoupon`.
- Cada pago (`tb_payments`) apunta a las dos tablas: al instrumento con `user_payment_method_ID` y a la forma de pago con `payment_method_ID`.
- Ejemplo del Caso 3: el instrumento es la tarjeta digital Spin y la forma de pago es efectivo.

### Estatus

- **Orden:** `Registered` → `Paid` → `Attended` → `Shipped` → `Delivered`. Los estatus alternos son `NotAttended`, `Canceled` y `Returned`.
- **Artículo de la orden:** `Active` o `Canceled`.
- **Envío:** `LabelCreated` → `InTransit` → `OutForDelivery` → `Delivered`. Si la entrega falla: `DeliveryFailed` → `AtPickupPoint` → `PickedUp`.
- **Instrumento del usuario:** `Active`, `Redeemed` (cupón usado) o `Inactive`.

### Reglas de negocio

- **Carrito → orden.** Un usuario tiene como máximo un carrito activo. Al comprar, en una sola transacción:
  - se validan las existencias;
  - se crea la orden ligada al carrito (relación 1 a 1);
  - se copia el detalle con el precio y el proveedor del momento;
  - se apartan las piezas;
  - el carrito queda `Converted`.
- **Mensualidades.** Cada mensualidad es un registro en `tb_payments` (`installment_number` de `installments_total`).
- **Cancelación parcial.** El artículo no se borra: queda `Canceled`, sus piezas regresan al inventario y la orden se recalcula con los artículos activos. El monto se reembolsa.
- **Cancelación total.** La orden conserva su total original como historial y el dinero se devuelve con un reembolso.
- **Reclamación con reenvío.** La devolución indica si se resuelve con reembolso o con reenvío. El reenvío es un envío de tipo `Replacement` ligado a esa devolución.
- **Saldo pendiente.** `vw_cuentas_por_cobrar` calcula `total − (pagado − reembolsado)` para cada orden no cancelada. En el Caso 2 muestra el adeudo de la mensualidad rechazada.

### Permisos

- Las conexiones de la aplicación (`app_web` y `app_movil`) entran como `user_not_registered`. Al comprar activan `buyer` con `SET ROLE 'buyer'`.
- `buyer` puede hacer todo lo que hace el cliente en los casos.
- `buyer` **no puede**:
  - cambiar el estatus de una orden;
  - registrar transacciones bancarias;
  - marcar pagos como pagados;
  - cambiar precios;
  - leer o modificar la bitácora.
- Las operaciones del sistema (banco, procesar la orden, reembolsos) las hacen `admin` y `superadmin`.
- Los triggers escriben en `tb_logs` con los permisos de su `DEFINER`.

### Vistas de trazabilidad por caso

`vw_trazabilidad_caso_1` a `vw_trazabilidad_caso_5` muestran, en orden cronológico, **todos los movimientos de la bitácora de un caso**: usuario, carrito, orden, detalle, domicilio, método de pago, pagos, transacciones, cancelaciones, devoluciones, reembolsos, envíos e inventario.

- Columnas: `caso`, `orden`, `cliente`, `log_ID`, `fecha`, `entidad`, `tabla`, `registro`, `operacion`, `usuario_bd`, `roles_en_la_operacion`, `descripcion`, `valores_anteriores` y `valores_nuevos`.
- La orden de cada caso se identifica por sus características, igual que en el script de pruebas.
- El Caso 1 incluye registros del formato anterior de la bitácora, sin el ID del registro, y de tablas que ya se eliminaron. Esos registros se asocian por el periodo del caso y por los usuarios que lo operaron. También incluye los borrados de los envíos y de los componentes de domicilio duplicados.
- Ningún movimiento aparece en dos casos.

### Bitácora

- `tb_logs` es de **solo agregar**: no se borran ni se editan registros.
- Las correcciones, como los envíos y los componentes de domicilio duplicados del Caso 1, se hacen con operaciones nuevas, que también quedan registradas.
- Los cambios de nombre de estatus no reescriben el historial.

## Interpretaciones del enunciado

- **Caso 3:** el enunciado pide tarjeta digital Spin y pago en efectivo. Se modeló como efectivo depositado en tienda a la tarjeta Spin, así que el instrumento es Spin y la forma de pago es `Cash`. El reembolso regresa a esa tarjeta.
- **Caso 4:** se registró un único pago por transferencia SPEI.
- **Caso 5:** al crear la orden sí había existencias, y se apartaron. Al procesar la orden, el conteo físico del almacén no encontró piezas, así que se registró el ajuste de inventario y la orden quedó `NotAttended` y después `Canceled`. El saldo se devolvió al cupón, que volvió a quedar `Active`.
- **Catálogo:** todos los productos pertenecen hoy a un mismo proveedor. El Caso 4 valida que los 3 productos sean del mismo proveedor.

## Seguridad (simulación)

- El enunciado pide registrar una "cuenta simulada de 16 dígitos". Por eso `tbd_user_payment_methods.provider_method_ref` guarda el número simulado completo. En la bitácora siempre aparece enmascarado (`**** 1234`). En un sistema real se guardaría solo un *token* del procesador de pagos y los últimos 4 dígitos.
- Las contraseñas de `tb_users` están en MD5, heredado del generador de usuarios. En producción se usaría bcrypt o argon2.