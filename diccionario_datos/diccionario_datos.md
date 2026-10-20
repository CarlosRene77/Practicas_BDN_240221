# Diccionario de datos — db_test

> Fuente: `respaldo-20-1-10-2026.sql`. Extracción estructural; INSERT omitidos.

## Índice
- [Descripción general](#descripción-general)
- [Tablas y columnas](#tablas-y-columnas)
- [Vistas](#vistas)
- [Triggers](#triggers)
- [Procedimientos](#procedimientos)
- [Dominios y convenciones](#dominios-y-convenciones)
- [Calidad y pendientes](#calidad-y-pendientes)
- [Leyendas](#leyendas)

## Descripción general

El esquema db_test documenta componentes de una aplicación de comercio electrónico (inferido), con usuarios, productos, carritos, pedidos, pagos y trazabilidad (inferido). Los prefijos tb_, tbc_ y tbd_ sugieren entidades principales, catálogos y tablas de detalle (inferido). El dump declara MySQL 8.0.36; motor y collation se documentan por objeto cuando aparecen en CREATE TABLE. Las reglas explícitas consideradas son PK, UK, FK, CHECK, valores predeterminados y columnas generadas halladas en el DDL. Los vínculos comerciales descritos abajo se limitan a relaciones SQL declaradas; objetos esperados pero ausentes constan como pendientes.

## Tablas y columnas

### tb_cart_addresses

**Descripción:** entidad correspondiente a tb_cart_addresses (inferido). **Motor:** InnoDB. **Notación:** `tb_cart_addresses = @ID + cart_ID + street_address + city + state + postal_code + country + creation_date`.

**Restricciones e índices:**
- PK: ID.
- UK: cart_ID.
- FK fk_cart_addresses_cart: cart_ID → tb_carts.ID; ON DELETE CASCADE; ON UPDATE CASCADE.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | cart_ID | int unsigned | No especificado | No | No especificado | No especificado | UK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | street_address | varchar(255) | 255 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(255); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | city | varchar(100) | 100 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | state | varchar(100) | 100 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | postal_code | varchar(20) | 20 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(20); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | country | varchar(100) | 100 | No | 'MÃ©xico' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_cart_items

**Descripción:** entidad correspondiente a tb_cart_items (inferido). **Motor:** InnoDB. **Notación:** `tb_cart_items = @ID + #cart_ID + #product_ID + quantity + unit_price + added_date`.

**Restricciones e índices:**
- PK: ID.
- FK fk_cart_items_cart: cart_ID → tb_carts.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- FK fk_cart_items_product: product_ID → tb_products.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- Índice: `KEY `fk_cart_items_cart_idx` (`cart_ID`)`
- Índice: `KEY `fk_cart_items_product_idx` (`product_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | cart_ID | int unsigned | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | product_ID | int unsigned | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | quantity | int unsigned | No especificado | No | '1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | unit_price | decimal(10,2) | 10,2 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa continua | decimal(10,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | added_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_cart_status

**Descripción:** entidad correspondiente a tb_cart_status (inferido). **Motor:** InnoDB. **Notación:** `tb_cart_status = @ID + cart_ID + status + last_change`.

**Restricciones e índices:**
- PK: ID.
- UK: cart_ID.
- FK fk_cart_status_cart: cart_ID → tb_carts.ID; ON DELETE CASCADE; ON UPDATE CASCADE.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | cart_ID | int unsigned | No especificado | No | No especificado | No especificado | UK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | status | enum('Active','Abandoned','Converted','Cancelled') | 'Active','Abandoned','Converted','Cancelled' | No | 'Active' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | enum('Active','Abandoned','Converted','Cancelled') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | last_change | datetime | No especificado | No | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_carts

**Descripción:** entidad correspondiente a tb_carts (inferido). **Motor:** InnoDB. **Notación:** `tb_carts = @ID + user_ID + creation_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- UK: user_ID.
- FK fk_cart_user: user_ID → tb_users.ID; ON DELETE CASCADE; ON UPDATE CASCADE.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | user_ID | int | No especificado | No | No especificado | No especificado | UK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | last_update | datetime | No especificado | Sí | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_logs

**Descripción:** entidad correspondiente a tb_logs (inferido). **Motor:** InnoDB. **Notación:** `tb_logs = @ID + table_name + operation + db_user + description + operation_date + operation_status`.

**Restricciones e índices:**
- PK: ID.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | table_name | varchar(100) | 100 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | operation | enum('Create','Read','Update','Delete') | 'Create','Read','Update','Delete' | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa temporal | enum('Create','Read','Update','Delete') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | db_user | varchar(80) | 80 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(80); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | description | text | No especificado | Sí | No especificado | No especificado | No | Monovalor (contiene datos compuestos) | Almacenado | Opcional | Cuantitativa discreta | text; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | operation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | operation_status | varchar(20) | 20 | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | varchar(20); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_payments

**Descripción:** entidad correspondiente a tb_payments (inferido). **Motor:** InnoDB. **Notación:** `tb_payments = @ID + #order_ID + amount + currency + payment_method + provider + provider_reference + payment_status + creation_date + paid_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- UK: provider, provider_reference.
- FK fk_payment_order: order_ID → tbb_orders.ID; ON DELETE RESTRICT; ON UPDATE CASCADE.
- CHECK: `CONSTRAINT `chk_payment_amount` CHECK ((`amount` > 0))`
- Índice: `KEY `fk_payment_order_idx` (`order_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | order_ID | int unsigned | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | amount | decimal(12,2) | 12,2 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa continua | decimal(12,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | currency | char(3) | 3 | No | 'MXN' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | char(3); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | payment_method | enum('Card','SPEI','Transfer','Cash') | 'Card','SPEI','Transfer','Cash' | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cualitativa nominal | enum('Card','SPEI','Transfer','Cash') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | provider | varchar(50) | 50 | Sí | NULL | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(50); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | provider_reference | varchar(150) | 150 | Sí | NULL | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(150); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | payment_status | enum('Pending','Authorized','Paid','Failed','Refunded','PartiallyRefunded') | 'Pending','Authorized','Paid','Failed','Refunded','PartiallyRefunded' | No | 'Pending' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | enum('Pending','Authorized','Paid','Failed','Refunded','PartiallyRefunded') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 9 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 10 | paid_date | datetime | No especificado | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 11 | last_update | datetime | No especificado | Sí | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_products

**Descripción:** entidad correspondiente a tb_products (inferido). **Motor:** InnoDB. **Notación:** `tb_products = @ID + SKU + name + description + current_price + current_stock + status + creation_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- UK: SKU.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | SKU | varchar(50) | 50 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(50); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | name | varchar(250) | 250 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(250); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | description | text | No especificado | Sí | No especificado | No especificado | No | Monovalor (contiene datos compuestos) | Almacenado | Opcional | Cuantitativa discreta | text; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | current_price | decimal(10,2) | 10,2 | No | '0.00' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa continua | decimal(10,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | current_stock | int unsigned | No especificado | No | '0' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | status | bit(1) | 1 | Sí | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 9 | last_update | datetime | No especificado | No | No especificado | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_seller_orders

**Descripción:** entidad correspondiente a tb_seller_orders (inferido). **Motor:** InnoDB. **Notación:** `tb_seller_orders = @ID + order_ID + seller_ID + subtotal + shipping_cost + fulfillment_status + creation_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- UK: order_ID, seller_ID.
- FK fk_seller_order_order: order_ID → tbb_orders.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- FK fk_seller_order_seller: seller_ID → tb_users.ID; ON DELETE RESTRICT; ON UPDATE CASCADE.
- CHECK: `CONSTRAINT `chk_shipping_positive` CHECK ((`shipping_cost` >= 0))`
- CHECK: `CONSTRAINT `chk_subtotal_positive` CHECK ((`subtotal` >= 0))`
- Índice: `KEY `fk_seller_order_seller_idx` (`seller_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | order_ID | int unsigned | No especificado | No | No especificado | No especificado | UK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | seller_ID | int | No especificado | No | No especificado | No especificado | UK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | subtotal | decimal(12,2) | 12,2 | No | '0.00' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa continua | decimal(12,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | shipping_cost | decimal(12,2) | 12,2 | No | '0.00' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa continua | decimal(12,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | fulfillment_status | enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') | 'Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned' | No | 'Pending' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | last_update | datetime | No especificado | Sí | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_user_addresses

**Descripción:** entidad correspondiente a tb_user_addresses (inferido). **Motor:** InnoDB. **Notación:** `tb_user_addresses = @ID + #user_ID + address_label + recipient_name + recipient_phone + delivery_instructions + latitude + longitude + is_default + status + creation_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- FK fk_addresses_users: user_ID → tb_users.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- CHECK: `CONSTRAINT `chk_coordinates` CHECK ((((`latitude` is null) and (`longitude` is null)) or ((`latitude` is not null) and (`longitude` is not null))))`
- CHECK: `CONSTRAINT `chk_latitude` CHECK ((`latitude` between -(90) and 90))`
- CHECK: `CONSTRAINT `chk_longitude` CHECK ((`longitude` between -(180) and 180))`
- Índice: `KEY `idx_user_addresses` (`user_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | bigint unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | bigint unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | user_ID | int | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | address_label | varchar(100) | 100 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | recipient_name | varchar(150) | 150 | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(150); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | recipient_phone | varchar(25) | 25 | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(25); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | delivery_instructions | varchar(500) | 500 | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(500); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | latitude | decimal(10,7) | 10,7 | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa continua | decimal(10,7); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | longitude | decimal(10,7) | 10,7 | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa continua | decimal(10,7); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 9 | is_default | tinyint(1) | 1 | No | '0' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | tinyint(1); dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 10 | status | bit(1) | 1 | No | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 11 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 12 | last_update | datetime | No especificado | Sí | NULL | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tb_users

**Descripción:** entidad correspondiente a tb_users (inferido). **Motor:** InnoDB. **Notación:** `tb_users = @ID + email + nickname + password + creation_date + last_update + last_login + status`.

**Restricciones e índices:**
- PK: ID.
- UK: email.
- UK: nickname.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | email | varchar(80) | 80 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(80); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | nickname | varchar(100) | 100 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | password | varchar(255) | 255 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(255); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | last_update | datetime | No especificado | Sí | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | last_login | datetime | No especificado | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | status | bit(1) | 1 | No | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbb_orders

**Descripción:** entidad correspondiente a tbb_orders (inferido). **Motor:** InnoDB. **Notación:** `tbb_orders = @ID + key + #user_ID + total_products + total_cost + status_string + status + creation_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- FK fk_user_2: user_ID → tb_users.ID; ON DELETE RESTRICT; ON UPDATE CASCADE.
- Índice: `KEY `fk_user_2_idx` (`user_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | key | varchar(40) | 40 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(40); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | user_ID | int | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | total_products | int | No especificado | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | total_cost | decimal(10,3) | 10,3 | No | '0.000' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa continua | decimal(10,3); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | status_string | enum('Registered','Wishlist','Payed','Canceled','Delivered','Devolved','Attended','Sended') | 'Registered','Wishlist','Payed','Canceled','Delivered','Devolved','Attended','Sended' | No | 'Registered' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | enum('Registered','Wishlist','Payed','Canceled','Delivered','Devolved','Attended','Sended') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | status | bit(1) | 1 | Sí | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 9 | last_update | datetime | No especificado | Sí | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbc_categories

**Descripción:** entidad correspondiente a tbc_categories (inferido). **Motor:** InnoDB. **Notación:** `tbc_categories = @ID + name + description + #sup_id_category + status + creation_date + last_update`.

**Restricciones e índices:**
- PK: ID.
- UK: name.
- FK fk_superior_category: sup_id_category → tbc_categories.ID; ON DELETE No especificado; ON UPDATE No especificado.
- Índice: `KEY `fk_superior_category` (`sup_id_category`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | name | varchar(120) | 120 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(120); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | description | text | No especificado | Sí | No especificado | No especificado | No | Monovalor (contiene datos compuestos) | Almacenado | Opcional | Cuantitativa discreta | text; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | sup_id_category | int unsigned | No especificado | Sí | NULL | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | status | bit(1) | 1 | No | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | last_update | datetime | No especificado | No | No especificado | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbc_payment_methods_types

**Descripción:** entidad correspondiente a tbc_payment_methods_types (inferido). **Motor:** InnoDB. **Notación:** `tbc_payment_methods_types = @id + code + description`.

**Restricciones e índices:**
- PK: id.
- UK: code.

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | id | int | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | code | varchar(50) | 50 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(50); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | description | varchar(255) | 255 | Sí | NULL | No especificado | No | Monovalor (contiene datos compuestos) | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | varchar(255); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbd_cart_items

**Descripción:** entidad correspondiente a tbd_cart_items (inferido). **Motor:** InnoDB. **Notación:** `tbd_cart_items = @cart_ID + @product_offer_ID + quantity + creation_date`.

**Restricciones e índices:**
- PK: cart_ID, product_offer_ID.
- FK fk_cart_item_cart: cart_ID → tb_carts.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- CHECK: `CONSTRAINT `chk_cart_quantity` CHECK ((`quantity` > 0))`
- Índice: `KEY `fk_cart_item_offer_idx` (`product_offer_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | cart_ID | int unsigned | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | product_offer_ID | int unsigned | No especificado | No | No especificado | No especificado | PK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | quantity | int unsigned | No especificado | No | '1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbd_order_items

**Descripción:** entidad correspondiente a tbd_order_items (inferido). **Motor:** InnoDB. **Notación:** `tbd_order_items = @ID + #seller_order_ID + product_offer_ID + product_name + quantity + unit_price + subtotal + creation_date`.

**Restricciones e índices:**
- PK: ID.
- FK fk_order_item_seller_order: seller_order_ID → tb_seller_orders.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- CHECK: `CONSTRAINT `chk_item_quantity` CHECK ((`quantity` > 0))`
- CHECK: `CONSTRAINT `chk_item_unit_price` CHECK ((`unit_price` >= 0))`
- Índice: `KEY `fk_order_item_seller_order_idx` (`seller_order_ID`)`
- Índice: `KEY `fk_order_item_offer_idx` (`product_offer_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ID | int unsigned | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | seller_order_ID | int unsigned | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | product_offer_ID | int unsigned | No especificado | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | product_name | varchar(255) | 255 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(255); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | quantity | int unsigned | No especificado | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | unit_price | decimal(12,2) | 12,2 | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa continua | decimal(12,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | subtotal | decimal(12,2) | 12,2 | Sí | No especificado | GENERATED | No | Monovalor | Derivado | Opcional | Cuantitativa continua | decimal(12,2); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 8 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbd_products_categories

**Descripción:** entidad correspondiente a tbd_products_categories (inferido). **Motor:** InnoDB. **Notación:** `tbd_products_categories = @category_ID + @product_ID + status + creation_date + last_update`.

**Restricciones e índices:**
- PK: category_ID, product_ID.
- FK fb_category: category_ID → tbc_categories.ID; ON DELETE No especificado; ON UPDATE No especificado.
- FK fk_product: product_ID → tb_products.ID; ON DELETE No especificado; ON UPDATE No especificado.
- Índice: `KEY `fk_product` (`product_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | category_ID | int unsigned | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | product_ID | int unsigned | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | status | bit(1) | 1 | No | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | last_update | datetime | No especificado | No | No especificado | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbd_products_users_providers

**Descripción:** entidad correspondiente a tbd_products_users_providers (inferido). **Motor:** InnoDB. **Notación:** `tbd_products_users_providers = @user_ID + @product_ID + type_ownership + status + available_date + creation_date + last_update`.

**Restricciones e índices:**
- PK: user_ID, product_ID.
- FK fk_products2: product_ID → tb_products.ID; ON DELETE No especificado; ON UPDATE No especificado.
- FK fk_user1: user_ID → tb_users.ID; ON DELETE No especificado; ON UPDATE No especificado.
- Índice: `KEY `fk_products2` (`product_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | user_ID | int | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | product_ID | int unsigned | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | type_ownership | enum('Owner','Reseller','Distributor') | 'Owner','Reseller','Distributor' | Sí | NULL | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | enum('Owner','Reseller','Distributor') | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | status | bit(1) | 1 | No | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | available_date | datetime | No especificado | No | No especificado | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 7 | last_update | datetime | No especificado | No | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbd_user_payment_methods

**Descripción:** entidad correspondiente a tbd_user_payment_methods (inferido). **Motor:** InnoDB. **Notación:** `tbd_user_payment_methods = @id + #user_ID + #payment_method_type_ID + provider + provider_method_ref + created_at`.

**Restricciones e índices:**
- PK: id.
- UK: provider, provider_method_ref.
- FK tbd_user_payment_methods_ibfk_1: user_ID → tb_users.ID; ON DELETE CASCADE; ON UPDATE CASCADE.
- FK tbd_user_payment_methods_ibfk_2: payment_method_type_ID → tbc_payment_methods_types.id; ON DELETE RESTRICT; ON UPDATE CASCADE.
- Índice: `KEY `tbd_user_payment_methods_ibfk_1` (`user_ID`)`
- Índice: `KEY `tbd_user_payment_methods_ibfk_2` (`payment_method_type_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | id | int | No especificado | No | No especificado | AUTO_INCREMENT | PK | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | user_ID | int | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | payment_method_type_ID | int | No especificado | No | No especificado | No especificado | FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cualitativa nominal | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | provider | varchar(100) | 100 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | varchar(100); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | provider_method_ref | varchar(255) | 255 | No | No especificado | No especificado | UK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cualitativa nominal | varchar(255); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 6 | created_at | timestamp | No especificado | Sí | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | timestamp; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

### tbd_users_wishlist_products

**Descripción:** entidad correspondiente a tbd_users_wishlist_products (inferido). **Motor:** InnoDB. **Notación:** `tbd_users_wishlist_products = @user_ID + @product_ID + status + creation_date + last_update`.

**Restricciones e índices:**
- PK: user_ID, product_ID.
- FK fk_products3: product_ID → tb_products.ID; ON DELETE No especificado; ON UPDATE No especificado.
- FK fk_user2: user_ID → tb_users.ID; ON DELETE No especificado; ON UPDATE No especificado.
- Índice: `KEY `fk_products3` (`product_ID`)`

| # | Nombre | Tipo | Longitud/precisión | NULL | Default | Extras | Llave | Valor | Origen | Obligatoriedad | Naturaleza | Dominio | Composición | Descripción |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | user_ID | int | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 2 | product_ID | int unsigned | No especificado | No | No especificado | No especificado | PK/FK | Monovalor | Almacenado | Obligatorio (provisto por el usuario) | Cuantitativa discreta | int unsigned; dominio exacto no acotado por SQL | {dígito} | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 3 | status | bit(1) | 1 | No | b'1' | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cualitativa nominal | bit(1); dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 4 | creation_date | datetime | No especificado | No | CURRENT_TIMESTAMP | No especificado | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |
| 5 | last_update | datetime | No especificado | No | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | No | Monovalor | Almacenado | Obligatorio (provisto por el sistema) | Cuantitativa temporal | datetime; dominio exacto no acotado por SQL | Valor atómico del tipo declarado | No especificado en el SQL; función documentada según el nombre del atributo (inferido). |

## Vistas

No hay definiciones CREATE VIEW en el dump; el inventario solicitado de 18 vistas no se pudo documentar.

## Triggers

| Nombre | Tabla | Evento | Momento | Trazabilidad tb_logs |
|---|---|---|---|---|
| No detectado | No especificado | No especificado | No especificado | No especificado |

## Procedimientos

### sp_restore_product

**Parámetros:** `(IN p_product_id INT UNSIGNED)`. **Lógica:** 1. Comprueba que el producto exista; si no, emite error SQL. 2. Rechaza el producto ya activo (status=b'1'). 3. Actualiza `tb_products.status` a b'1'. **Ejemplo:** `CALL sp_restore_product(1);`.

### sp_soft_delete_product

**Parámetros:** `(IN p_product_id INT UNSIGNED)`. **Lógica:** 1. Comprueba que el producto exista; si no, emite error SQL. 2. Rechaza el producto ya inactivo (status=b'0'). 3. Actualiza `tb_products.status` a b'0'. **Ejemplo:** `CALL sp_soft_delete_product(1);`.

### sp_soft_delete_user

**Parámetros:** `(
    IN p_user_id INT UNSIGNED
)`. **Lógica:** 1. Obtiene el usuario de conexión y valida roles autorizados en `mysql.role_edges`. 2. Valida que el ID sea distinto de NULL/0. 3. Busca existencia y estado en `tb_users`; rechaza usuario inexistente, inactivo o con estado NULL. 4. Cambia status a b'0', exige exactamente una fila afectada y devuelve confirmación con ID, ejecutor y fecha. Afecta `tb_users`; consulta `mysql.role_edges`. **Ejemplo:** `CALL sp_soft_delete_user(1);`.

### Diferencia frente al inventario solicitado

`sp_soft_delete` no aparece en el DDL; el dump contiene `sp_restore_product` adicional. Los nombres y parámetros anteriores reflejan exclusivamente los procedimientos encontrados.

## Dominios y convenciones

Los dominios ENUM y status se listan desde las columnas tipadas en `estructura.json`; el volcado solo contiene los objetos realmente hallados. Prefijos tb_, tbc_, tbd_, vw_, trg_, sp_, fk_, uk_ y chk_ son convenciones observadas o solicitadas (inferido), no garantizan por sí mismos semántica. creation_date, last_update y status siguen documentándose por tabla cuando existan; no se asume obligatoriedad común.

## Calidad y pendientes

Conteos observados: {'tables': 19, 'views': 0, 'triggers': 0, 'procedures': 3}; conteos esperados por requisito: {'tables': 20, 'views': 18, 'triggers': 57, 'procedures': 3}.
El archivo fuente no coincide con el inventario solicitado: faltan objetos y aparecen otros nombres. No es posible certificar los conteos esperados, 57 triggers o 18 vistas desde este dump.

- Tablas solicitadas ausentes: tb_buyer_orders, tb_orders, tbd_address_components, tbd_carts_items, tbd_order_details, tbc_payment_methods, tbd_wishlist.
- Tablas adicionales en fuente: tb_cart_addresses, tb_cart_items, tb_cart_status, tb_seller_orders, tbb_orders, tbd_cart_items.
- Referencias huérfanas en DDL: Verificado: sin referencias huérfanas.

### Hallazgos técnicos (limitados a los objetos disponibles)

| Severidad | Hallazgo | Propuesta técnica |
|---|---|---|
| Baja | `tbd_products_categories.category_ID` sí tiene FK `fb_category` hacia `tbc_categories.ID`; por lo tanto, la hipótesis de falta de FK no se confirma en este dump. | Mantener la FK existente; considerar renombrar `fb_category` a `fk_category` para seguir la convención si se aprueba una migración de nomenclatura. |
| Media | La duplicidad solicitada no se puede comparar: no están `tb_orders`, `tbd_order_details` ni `tbd_wishlist`; el origen sí define `tbb_orders`, `tb_seller_orders`, `tbd_order_items` y `tbd_users_wishlist_products`. También existen `tb_cart_items` y `tbd_cart_items`. | Confirmar qué modelo es vigente; documentar cardinalidades y consolidar roles antes de migrar. No eliminar tablas solo por similitud de nombres. |
| Baja | No se confirma la falta de identidad del comprador: `tbb_orders.user_ID` referencia `tb_users.ID`, mientras `tb_seller_orders.seller_ID` refiere al vendedor. | Aclarar nombres buyer/seller en el modelo y conservar las dos identidades mediante relaciones explícitas. |
| Media | `tbd_cart_items` y `tbd_order_items` tienen `product_offer_ID`, pero no FK a `tbd_products_users_providers`; esta última tiene PK compuesta `(user_ID, product_ID)` y FKs individuales a usuarios y productos. No se observa constraint compuesta que ate una oferta a ese par. | Si el identificador de oferta representa esa combinación, guardar ambas columnas y declarar FK compuesta; de lo contrario, usar un ID de oferta único con FK propia. |
| Media | `tbd_products_users_providers.user_ID` y `tb_users.ID` son INT con signo, pero `product_ID` es INT UNSIGNED en la tabla puente y la definición de `tb_products.ID` debe cotejarse. `status` visible en varias tablas es BIT(1), frente a `tbb_orders.status` BIT(1); no hay diferencia bit/tinyint en esos casos concretos. | Alinear tipos de cada par FK (incluido signo) y documentar semántica de BIT(1); revisar tabla por tabla cualquier Tinyint restante. |
| Baja | Verificado: sin referencias huérfanas.
| Baja | `tbd_order_items.subtotal` es GENERATED (derivado); se detectan cuatro PK compuestas y se listan en la evidencia. | Conservar fórmula generada y asegurar que cambios de precio/cantidad mantengan la regla de negocio definida en SQL. |

- Pendiente bloqueante: obtener el dump correcto para documentar las 18 vistas, 57 triggers y las 20 tablas pedidas.
- Pendientes por confirmar (inferido): el esquema representa comercio electrónico; tb_/tbc_/tbd_ distinguen entidad/catálogo/detalle; descripciones funcionales inferidas del nombre de tabla/columna.

## Leyendas

DeMarco/Yourdon: `=` se compone de, `+` y, `[a | b]` alternativa, `{x}` repetición, `(x)` opcional; `@` PK y `#` FK. Monovalor/multivalor se clasifica según atomicidad observable; derivado únicamente si hay GENERATED declarado; naturalezas se asignan por tipo SQL, y los casos ambiguos se señalan como inferidos.

### Evidencia final

```text
Tablas: 19 (esperadas 20) | Vistas: 0 (esperadas 18) | Triggers: 0 (esperados 57) | Procedimientos: 3 (esperados 3)
Columnas sin metadata: 0 / 131 (metadatos técnicos y clasificatorios poblados; descripción funcional inferida si no aparece en SQL)
Columnas derivadas: tbd_order_items.subtotal
PK compuestas: tbd_cart_items:cart_ID,product_offer_ID, tbd_products_categories:category_ID,product_ID, tbd_products_users_providers:user_ID,product_ID, tbd_users_wishlist_products:user_ID,product_ID
Inferencias exactas: dominio comercio electrónico en descripción general; semántica de tb_/tbc_/tbd_; descripciones de tablas/columnas basadas en nombres; estructura atómica genérica de los campos.
Idioma: español; identificadores originales preservados.
```

### Catálogo global de ENUM y status

| Tabla | Columna | Dominio/tipo SQL |
|---|---|---|
| tb_cart_status | status | enum('Active','Abandoned','Converted','Cancelled') |
| tb_logs | operation | enum('Create','Read','Update','Delete') |
| tb_payments | payment_method | enum('Card','SPEI','Transfer','Cash') |
| tb_payments | payment_status | enum('Pending','Authorized','Paid','Failed','Refunded','PartiallyRefunded') |
| tb_products | status | bit(1) |
| tb_seller_orders | fulfillment_status | enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') |
| tb_user_addresses | status | bit(1) |
| tb_users | status | bit(1) |
| tbb_orders | status_string | enum('Registered','Wishlist','Payed','Canceled','Delivered','Devolved','Attended','Sended') |
| tbb_orders | status | bit(1) |
| tbc_categories | status | bit(1) |
| tbd_products_categories | status | bit(1) |
| tbd_products_users_providers | type_ownership | enum('Owner','Reseller','Distributor') |
| tbd_products_users_providers | status | bit(1) |
| tbd_users_wishlist_products | status | bit(1) |

Clasificación visible: BIT(1), TINYINT y ENUM se conservan como tipos SQL distintos; el dominio semántico de status es No especificado salvo CHECK/ENUM/DEFAULT en la definición correspondiente.