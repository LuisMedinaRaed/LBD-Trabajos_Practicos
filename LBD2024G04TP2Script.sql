-- Año: 2024
-- Grupo Nro: 4
-- Integrantes: Lozano Iñaki Fernando, Medina Raed Luis Eugenio
-- Tema: Gestión de stock y distribución de bebidas gaseosas
-- Nombre del Esquema LBD2024G04
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL 8.0.30
-- GitHub Repositorio: LBD2024G04
-- GitHub Usuario: InakiLozano01, LuisMedinaRaed

-- -----------------------------------------------------
-- OBSERVACION IMPORTANTE: SE REALIZARON ACTUALIZACIONES EN EL TP1 (MAYOR CANTIDAD DE INSERCIONES)
-- -----------------------------------------------------

-- -----------------------------------------------------
-- TRABAJO PRACTICO Nº2
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Consulta Nº1
-- 1. Dado un producto, listar todos sus pedidos (mostrar el nombre del producto, fecha del pedido, nombre, email y teléfono del cliente del pedido).
-- -----------------------------------------------------

-- Variables para los parámetros de entrada (ejemplo)
SET @nombreProducto = 'Secco Tradicional 500ml';

SELECT 
    pr.producto,
    p.fecha AS fecha_pedido,
    c.cliente,
    c.email AS email_cliente,
    c.telefono AS telefono_cliente
FROM 
    Pedidos p
INNER JOIN 
    LineasPedido lp ON p.idPedido = lp.idPedido AND p.idCliente = lp.idCliente
INNER JOIN 
    Clientes c ON p.idCliente = c.idCliente
INNER JOIN 
    Productos pr ON lp.idProducto = pr.idProducto
WHERE 
    pr.producto = @nombreProducto
ORDER BY 
    p.fecha, c.cliente, c.email, c.telefono;

-- 1. Variables de entrada:
-- Definimos una variable @nombreProducto para el nombre del producto.

-- 2. FROM y JOIN:
-- FROM Pedidos: Comenzamos desde Pedidos porque queremos listar los pedidos que incluyen un producto específico.
-- INNER JOIN LineasPedido: Unimos Pedidos con LineasPedido usando la clave completa (idPedido, idCliente) para obtener los detalles de los productos en cada pedido. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.
-- INNER JOIN Clientes: Unimos Pedidos con Clientes usando idCliente para obtener la información del cliente. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.
-- INNER JOIN Productos: Unimos LineasPedido con Productos usando idProducto para obtener la información del producto. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. WHERE:
-- Filtramos los resultados para que solo incluyan el producto específico cuyo nombre se pasa como parámetro (@nombreProducto).

-- 4. ORDER BY:
-- Ordenamos los resultados por la fecha del pedido (p.fecha), el nombre del cliente (c.cliente), el email del cliente (c.email) y el teléfono del cliente (c.telefono).
-- - Primero por la fecha del pedido para ver la cronología de los pedidos.
-- - Luego por el nombre del cliente, su email y su teléfono para facilitar la identificación y contacto del cliente en el contexto de cada pedido.

    
-- -----------------------------------------------------
-- Consulta Nº2
-- 2. Realizar un listado de pedidos agrupados por cliente (mostrar nombre del cliente, idpedido y fecha del pedido).
-- -----------------------------------------------------

-- No es necesario definir variables de entrada para esta consulta específica

SELECT 
    c.cliente,
    p.idPedido,
    p.fecha AS fecha_pedido
FROM 
    Clientes c
INNER JOIN 
    Pedidos p ON c.idCliente = p.idCliente
ORDER BY 
    c.cliente, p.fecha, p.idPedido;

-- 1. Variables de entrada:
-- No se definen variables de entrada porque la consulta no requiere parámetros específicos.

-- 2. FROM y JOIN:
-- FROM Clientes: Comenzamos desde Clientes porque queremos listar los pedidos agrupados por cada cliente.
-- INNER JOIN Pedidos: Unimos Clientes con Pedidos usando idCliente para obtener la información de los pedidos realizados por cada cliente. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. ORDER BY:
-- Ordenamos los resultados por el nombre del cliente (c.cliente) y la fecha del pedido (p.fecha).
-- - Primero por el nombre del cliente para agrupar todos los pedidos de un mismo cliente juntos.
-- - Luego por la fecha del pedido para ver la cronología de los pedidos realizados por cada cliente.

-- -----------------------------------------------------
-- Consulta Nº3
-- 3. Dado un producto, realizar un listado de sus entradas entre un rango de fechas,
--  mostrando el nombre del producto, fecha de la entrada, nombre y correo del proveedor.
-- Ordenar por la fecha de entrada en orden cronológico inverso.
-- -----------------------------------------------------

-- Variables para los parámetros de entrada (ejemplo)
SET @nombreProducto = 'Secco Tradicional 500ml';
SET @fechaInicio = '2023-01-01';
SET @fechaFin = '2024-12-31';

SELECT 
    pr.producto AS nombre_producto,
    e.fecha AS fecha_entrada,
    p.proveedor AS nombre_proveedor,
    p.email AS email_proveedor
FROM 
    Productos pr
INNER JOIN 
    LineasEntrada le ON pr.idProducto = le.idProducto
INNER JOIN 
    Entradas e ON le.idEntrada = e.idEntrada AND le.idProveedor = e.idProveedor
INNER JOIN 
    Proveedores p ON e.idProveedor = p.idProveedor
WHERE 
    pr.producto = @nombreProducto
    AND e.fecha BETWEEN @fechaInicio AND @fechaFin
ORDER BY 
    e.fecha DESC, p.proveedor, p.email;

-- 1. Variables de entrada:
-- Definimos variables @nombreProducto, @fechaInicio y @fechaFin.

-- 2. FROM y JOIN:
-- FROM Productos: Comenzamos desde Productos porque queremos listar las entradas de un producto específico. 
-- INNER JOIN LineasEntrada: Unimos Productos con LineasEntrada usando idProducto para obtener los detalles de las entradas de productos.
-- INNER JOIN Entradas: Unimos LineasEntrada con Entradas usando la clave completa (idEntrada, idProveedor) para obtener la información de las entradas.
-- INNER JOIN Proveedores: Unimos Entradas con Proveedores usando idProveedor para obtener la información del proveedor. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. WHERE:
-- Filtramos los resultados para que solo incluyan el producto específico cuyo nombre se pasa como parámetro (@nombreProducto) y que las fechas de entrada estén dentro del rango especificado (@fechaInicio y @fechaFin).

-- 4. ORDER BY:
-- Ordenamos los resultados por la fecha de entrada (e.fecha) en orden cronológico inverso (DESC), seguido por el nombre del proveedor (p.proveedor) y el email del proveedor (p.email).
-- Este orden se selecciona para proporcionar una vista útil para el usuario, primero mostrando las entradas más recientes, y luego agrupando por el proveedor y su email.
    
-- -----------------------------------------------------
-- Consulta Nº4
-- 4. Hacer un ranking con las unidades de transporte que más viajes realizaron en un rango
-- de fechas. Mostrar la patente y la cantidad de viajes.
-- -----------------------------------------------------
    
-- Variables para los parámetros de entrada (ejemplo)
SET @fechaInicio = '2023-01-01';
SET @fechaFin = '2024-12-31';

SELECT 
    ut.patente,
    COUNT(v.idViaje) AS cantidad_viajes
FROM 
    Viajes v
INNER JOIN 
    UnidadesTransporte ut ON v.idUnidadTransporte = ut.idUnidadTransporte
WHERE 
    v.fecha BETWEEN @fechaInicio AND @fechaFin
GROUP BY 
    ut.patente
ORDER BY 
    cantidad_viajes DESC, ut.patente;

-- 1. Variables de entrada:
-- Definimos variables @fechaInicio y @fechaFin.

-- 2. FROM y JOIN:
-- FROM Viajes: Comenzamos desde Viajes porque queremos listar los viajes realizados por las unidades de transporte en un rango de fechas.
-- INNER JOIN UnidadesTransporte: Unimos Viajes con UnidadesTransporte usando idUnidadTransporte para obtener la información de las unidades de transporte. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. WHERE:
-- Filtramos los resultados para que solo incluyan los viajes cuya fecha esté dentro del rango especificado (@fechaInicio y @fechaFin). 

-- 4. GROUP BY:
-- Agrupamos los resultados por la patente de la unidad de transporte (ut.patente) para contar la cantidad de viajes realizados por cada unidad.

-- 5. ORDER BY:
-- Ordenamos los resultados por la cantidad de viajes (cantidad_viajes) en orden descendente (DESC) para que las unidades de transporte con más viajes aparezcan primero. Luego ordenamos por la patente (ut.patente) para diferenciar las unidades con la misma cantidad de viajes.

-- -----------------------------------------------------
-- Consulta Nº5
-- 5. Hacer un ranking con los 10 clientes que más pedidos realizaron (por cantidad) entre un
-- rago de fechas. Mostrar el nombre del cliente y el total de pedidos.
-- -----------------------------------------------------

-- Variables para los parámetros de entrada (ejemplo)
SET @fechaInicio = '2023-01-01';
SET @fechaFin = '2024-12-31';

SELECT 
    c.cliente,
    COUNT(p.idPedido) AS total_pedidos
FROM 
    Pedidos p
INNER JOIN 
    Clientes c ON p.idCliente = c.idCliente
WHERE 
    p.fecha BETWEEN @fechaInicio AND @fechaFin
GROUP BY 
    c.cliente
ORDER BY 
    total_pedidos DESC, c.cliente
LIMIT 10;

-- 1. Variables de entrada:
-- Definimos variables @fechaInicio y @fechaFin.

-- 2. FROM y JOIN:
-- FROM Pedidos: Comenzamos desde Pedidos porque queremos listar los pedidos realizados por los clientes en un rango de fechas.
-- INNER JOIN Clientes: Unimos Pedidos con Clientes usando idCliente para obtener la información del cliente. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. WHERE:
-- Filtramos los resultados para que solo incluyan los pedidos cuya fecha esté dentro del rango especificado (@fechaInicio y @fechaFin).

-- 4. GROUP BY:
-- Agrupamos los resultados por el nombre del cliente (c.cliente) para contar la cantidad de pedidos realizados por cada cliente.

-- 5. ORDER BY:
-- Ordenamos los resultados por la cantidad de pedidos (total_pedidos) en orden descendente (DESC) para que los clientes con más pedidos aparezcan primero. Luego ordenamos por el nombre del cliente (c.cliente) para diferenciar los clientes con la misma cantidad de pedidos.

-- 6. LIMIT:
-- Limitamos los resultados a los 10 principales clientes (LIMIT 10) para obtener el ranking deseado.

-- -----------------------------------------------------
-- Consulta Nº6
-- 6. Hacer un ranking con los 10 clientes que más pedidos realizaron (por precio) entre un
-- rago de fechas. Mostrar el nombre del cliente y el importe de los pedidos.
-- -----------------------------------------------------

-- Variables para los parámetros de entrada (ejemplo)
SET @fechaInicio = '2024-01-01';
SET @fechaFin = '2024-12-31';

SELECT 
    c.cliente,
    SUM(lp.cantidad * lp.precio) AS importe_total_pedidos
FROM 
    Pedidos p
INNER JOIN 
    Clientes c ON p.idCliente = c.idCliente
INNER JOIN 
    LineasPedido lp ON p.idPedido = lp.idPedido AND p.idCliente = lp.idCliente
WHERE 
    p.fecha BETWEEN @fechaInicio AND @fechaFin
GROUP BY 
    c.cliente
ORDER BY 
    importe_total_pedidos DESC, c.cliente
LIMIT 10;

-- 1. Variables de entrada:
-- Definimos variables @fechaInicio y @fechaFin.

-- 2. FROM y JOIN:
-- FROM Pedidos: Comenzamos desde Pedidos porque queremos listar los pedidos realizados por los clientes en un rango de fechas.
-- INNER JOIN Clientes: Unimos Pedidos con Clientes usando idCliente para obtener la información del cliente. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.
-- INNER JOIN LineasPedido: Unimos Pedidos con LineasPedido usando la clave completa (idPedido, idCliente) para obtener los detalles y precios de cada línea de pedido. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. WHERE:
-- Filtramos los resultados para que solo incluyan los pedidos cuya fecha esté dentro del rango especificado (@fechaInicio y @fechaFin). 

-- 4. GROUP BY:
-- Agrupamos los resultados por el nombre del cliente (c.cliente) para calcular el importe total de pedidos realizados por cada cliente.

-- 5. ORDER BY:
-- Ordenamos los resultados por el importe total de los pedidos (importe_total_pedidos) en orden descendente (DESC) para que los clientes con los importes más altos aparezcan primero. Luego ordenamos por el nombre del cliente (c.cliente) para diferenciar los clientes con el mismo importe.

-- 6. LIMIT:
-- Limitamos los resultados a los 10 principales clientes (LIMIT 10) para obtener el ranking deseado.

-- -----------------------------------------------------
-- Consulta Nº7
-- 7. Hacer un ranking con las 10 zonas a donde se realizaron más viajes entre un rago de
-- fechas. Mostrar el nombre de la zona y la cantidad de viajes.
-- -----------------------------------------------------

-- Variables para los parámetros de entrada (ejemplo)
SET @fechaInicio = '2023-01-01';
SET @fechaFin = '2024-12-31';

SELECT 
    z.zona,
    COUNT(v.idViaje) AS cantidad_viajes
FROM 
    Viajes v
INNER JOIN 
    Zonas z ON v.idZona = z.idZona
WHERE 
    v.fecha BETWEEN @fechaInicio AND @fechaFin
GROUP BY 
    z.zona
ORDER BY 
    cantidad_viajes DESC, z.zona
LIMIT 10;

-- 1. Variables de entrada:
-- Definimos variables @fechaInicio y @fechaFin.

-- 2. FROM y JOIN:
-- FROM Viajes: Comenzamos desde Viajes porque queremos listar los viajes realizados en las diferentes zonas en un rango de fechas.
-- INNER JOIN Zonas: Unimos Viajes con Zonas usando idZona para obtener la información de la zona. Utilizamos INNER JOIN porque queremos incluir solo los registros que tienen relación en ambas tablas.

-- 3. WHERE:
-- Filtramos los resultados para que solo incluyan los viajes cuya fecha esté dentro del rango especificado (@fechaInicio y @fechaFin).

-- 4. GROUP BY:
-- Agrupamos los resultados por el nombre de la zona (z.zona) para contar la cantidad de viajes realizados en cada zona.

-- 5. ORDER BY:
-- Ordenamos los resultados por la cantidad de viajes (cantidad_viajes) en orden descendente (DESC) para que las zonas con más viajes aparezcan primero. Luego ordenamos por el nombre de la zona (z.zona) para diferenciar las zonas con la misma cantidad de viajes.

-- 6. LIMIT:
-- Limitamos los resultados a las 10 principales zonas (LIMIT 10) para obtener el ranking deseado.

-- -----------------------------------------------------
-- Consulta Nº8
-- 8. Crear una vista con la funcionalidad del apartado 4.
-- -----------------------------------------------------

CREATE VIEW RankingUnidadesTransporte2024 AS
SELECT 
    ut.patente,
    COUNT(v.idViaje) AS cantidad_viajes
FROM 
    Viajes v
INNER JOIN 
    UnidadesTransporte ut ON v.idUnidadTransporte = ut.idUnidadTransporte
WHERE 
    v.fecha BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY 
    ut.patente
ORDER BY 
    cantidad_viajes DESC, ut.patente;
    
SELECT * FROM rankingunidadestransporte2024;

-- 1. FROM y JOIN:
-- FROM Viajes: Comenzamos desde Viajes porque queremos contar los viajes realizados por las unidades de transporte.
-- INNER JOIN UnidadesTransporte: Unimos Viajes con UnidadesTransporte usando idUnidadTransporte para obtener la información de las unidades de transporte.

-- 2. WHERE:
-- Filtramos los resultados para incluir solo los viajes cuya fecha esté dentro del rango especificado ('2024-01-01' y '2024-12-31').

-- 3. GROUP BY:
-- Agrupamos los resultados por la patente de la unidad de transporte (ut.patente) para contar la cantidad de viajes realizados por cada unidad.

-- 4. ORDER BY:
-- Ordenamos los resultados por la cantidad de viajes (cantidad_viajes) en orden descendente (DESC) para que las unidades de transporte con más viajes aparezcan primero. Luego ordenamos por la patente (ut.patente) para diferenciar las unidades con la misma cantidad de viajes.

-- Nota extra:
-- Esta vista considera los viajes realizados durante el año 2024.

-- -----------------------------------------------------
-- Consulta Nº9
-- 9. Crear una copia de la tabla Productos, que además tenga una columna del tipo JSON
-- para guardar el detalle de los pedidos (LineasPedido y Pedidos). Llenar esta tabla con los
-- mismos datos del TP1 y resolver la consulta: dado un producto listar todos sus pedidos
-- (incluye cantidad, precio y fecha).
-- -----------------------------------------------------

CREATE TABLE ProductosConDetalles (
    idProducto INT AUTO_INCREMENT PRIMARY KEY,
    producto VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    precio DECIMAL(15, 2) NOT NULL,
    estado CHAR(1) NOT NULL,
    detalles_pedidos JSON,
    CHECK (estado IN ('A', 'B')),
    CHECK (precio >= 0),
    UNIQUE INDEX UI_producto(producto)
) ENGINE=INNODB;

-- Copiamos la estructura de la tabla Productos y agregamos una nueva columna JSON llamada detalles_pedidos para almacenar los detalles de los pedidos.

INSERT INTO ProductosConDetalles (idProducto, producto, descripcion, precio, estado, detalles_pedidos)
SELECT 
    p.idProducto, 
    p.producto, 
    p.descripcion, 
    p.precio, 
    p.estado, 
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'idPedido', lp.idPedido,
            'idCliente', lp.idCliente,
            'cantidad', lp.cantidad,
            'precio', lp.precio,
            'fecha', pe.fecha,
            'observaciones', pe.observaciones
        )
    ) AS detalles_pedidos
FROM 
    Productos p
    LEFT JOIN LineasPedido lp ON p.idProducto = lp.idProducto
    LEFT JOIN Pedidos pe ON lp.idPedido = pe.idPedido AND lp.idCliente = pe.idCliente
GROUP BY 
    p.idProducto;

-- 1. FROM y JOIN:
-- FROM Productos: Comenzamos desde Productos porque queremos copiar todos los productos y agregar los detalles de sus pedidos.
-- LEFT JOIN LineasPedido: Unimos Productos con LineasPedido usando idProducto para obtener los detalles de los pedidos relacionados con cada producto. Usamos LEFT JOIN para asegurar que todos los productos se incluyan, incluso si no tienen pedidos.
-- LEFT JOIN Pedidos: Unimos LineasPedido con Pedidos usando idPedido y idCliente para obtener la fecha del pedido y otros detalles relevantes.

-- 2. JSON_ARRAYAGG y JSON_OBJECT:
-- Utilizamos JSON_ARRAYAGG y JSON_OBJECT para construir la estructura JSON que almacena los detalles de los pedidos (idPedido, idCliente, cantidad, precio, fecha, observaciones).

-- 3. GROUP BY:
-- Agrupamos los resultados por idProducto para asegurar que cada producto tenga una entrada en la nueva tabla con sus detalles de pedidos agregados.

-- Variables para los parámetros de entrada (ejemplo)
SET @producto_nombre = 'Secco Tradicional 500ml';

SELECT 
    p.producto,
    jt.fecha,
    c.cliente,
    c.email,
    c.telefono
FROM 
    ProductosConDetalles p,
    JSON_TABLE(p.detalles_pedidos, '$[*]' 
        COLUMNS (
            idPedido INT PATH '$.idPedido',
            idCliente INT PATH '$.idCliente',
            cantidad INT PATH '$.cantidad',
            precio DECIMAL(15, 2) PATH '$.precio',
            fecha DATETIME PATH '$.fecha'
        )
    ) AS jt
JOIN Clientes c ON jt.idCliente = c.idCliente
WHERE 
    p.producto = @producto_nombre
ORDER BY 
    jt.fecha, c.cliente, c.email, c.telefono;

-- 1. Variables de entrada:
-- Definimos una variable @producto_nombre.

-- 2. FROM y JSON_TABLE:
-- FROM ProductosConDetalles: Consultamos la tabla ProductosConDetalles porque contiene la columna JSON con los detalles de los pedidos.
-- JSON_TABLE: Utilizamos JSON_TABLE para descomponer la columna JSON detalles_pedidos en columnas individuales (idPedido, idCliente, cantidad, precio, fecha).

-- 3. JOIN:
-- Unimos los resultados de JSON_TABLE con la tabla Clientes usando idCliente para obtener la información del cliente (nombre, email, teléfono).

-- 4. WHERE:
-- Filtramos los resultados para que solo incluyan el producto específico cuyo nombre se pasa como parámetro (@producto_nombre).

-- 5. ORDER BY:
-- Ordenamos los resultados por la fecha del pedido (jt.fecha), el nombre del cliente (c.cliente) y el ID del pedido (jt.idPedido).


-- -----------------------------------------------------
-- Consulta Nº10
-- 10. Realizar una vista que considere importante para su modelo. También dejar escrito el
-- enunciado de la misma.
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Enunciado: Crear una vista que liste el stock actual disponible para cada producto, 
-- mostrando el nombre del producto, la cantidad en stock y su precio. 
-- -----------------------------------------------------

CREATE VIEW StockActualPorProducto AS
SELECT 
    p.producto,
    IFNULL(SUM(le.cantidad), 0) - IFNULL(SUM(lp.cantidad), 0) AS stock_actual,
    p.precio
FROM 
    Productos p
    LEFT JOIN LineasEntrada le ON p.idProducto = le.idProducto
    LEFT JOIN LineasPedido lp ON p.idProducto = lp.idProducto
GROUP BY 
    p.idProducto,
    p.producto,
    p.precio
ORDER BY 
    stock_actual DESC, p.producto;
    
SELECT * FROM stockactualporproducto;

-- 1. FROM y JOIN:
-- FROM Productos: Comenzamos desde Productos porque queremos listar el stock actual de cada producto.
-- LEFT JOIN LineasEntrada: Unimos Productos con LineasEntrada usando idProducto para obtener la cantidad de productos ingresados. Usamos LEFT JOIN para incluir productos que pueden no tener entradas.
-- LEFT JOIN LineasPedido: Unimos Productos con LineasPedido usando idProducto para obtener la cantidad de productos pedidos. Usamos LEFT JOIN para incluir productos que pueden no tener pedidos.

-- 2. IFNULL:
-- Utilizamos IFNULL para manejar casos donde no hay entradas o pedidos, asegurando que se utilice 0 en esos casos.

-- 3. GROUP BY:
-- Agrupamos los resultados por idProducto, producto y precio para asegurar que cada producto tenga una entrada en la vista con su stock actual calculado.

-- 4. ORDER BY:
-- Ordenamos los resultados por stock_actual en orden descendente para mostrar primero los productos con mayor stock disponible, seguido por el nombre del producto.

-- -----------------------------------------------------
-- Enunciado: Crear una vista que liste los productos más vendidos, mostrando el nombre del producto, la cantidad vendida y el total recaudado. 
-- -----------------------------------------------------

CREATE VIEW ProductosMasVendidos AS
SELECT 
    p.producto,
    SUM(lp.cantidad) AS cantidad_vendida,
    SUM(lp.cantidad * lp.precio) AS total_recaudado
FROM 
    Productos p
JOIN 
    LineasPedido lp ON p.idProducto = lp.idProducto
GROUP BY 
    p.producto
ORDER BY 
    cantidad_vendida DESC, total_recaudado DESC, p.producto;

SELECT * FROM productosmasvendidos;

-- 1. FROM y JOIN:
-- FROM Productos: Comenzamos desde Productos porque queremos listar los productos más vendidos.
-- JOIN LineasPedido: Unimos Productos con LineasPedido usando idProducto para obtener la cantidad de productos pedidos.

-- 2. SUM y AS:
-- Utilizamos SUM para calcular la cantidad vendida y el total recaudado para cada producto.

-- 3. GROUP BY:
-- Agrupamos los resultados por producto para asegurar que cada producto tenga una entrada en la vista con la cantidad vendida y el total recaudado.

-- 4. ORDER BY:
-- Ordenamos los resultados por cantidad_vendida y total_recaudado en orden descendente para mostrar primero los productos más vendidos y más rentables, seguido por el nombre del producto.

-- -----------------------------------------------------
-- Enunciado: Crear una vista que liste todos los pedidos que han sido entregados, mostrando detalles del pedido, el cliente, la fecha de entrega y el estado. 
-- -----------------------------------------------------

CREATE VIEW PedidosEntregados AS
SELECT 
    pe.fecha,
    c.cliente,
    c.email,
    c.telefono,
    pe.observaciones,
    v.estado
FROM 
    Pedidos pe
    JOIN Clientes c ON pe.idCliente = c.idCliente
    JOIN Viajes v ON pe.idViaje = v.idViaje
WHERE 
    v.estado = 'D'
ORDER BY 
    pe.fecha, c.cliente;
    
SELECT * FROM pedidosentregados;

-- 1. FROM y JOIN:
-- FROM Pedidos: Comenzamos desde Pedidos porque queremos listar todos los pedidos entregados.
-- JOIN Clientes: Unimos Pedidos con Clientes usando idCliente para obtener la información del cliente.
-- JOIN Viajes: Unimos Pedidos con Viajes usando idViaje para obtener el estado de envío.

-- 2. WHERE:
-- Filtramos los resultados para incluir solo los pedidos cuyo estado de envío es 'D' (Distribuido).

-- 3. ORDER BY:
-- Ordenamos los resultados por la fecha del pedido (pe.fecha) y el nombre del cliente (c.cliente).

-- -----------------------------------------------------
-- Enunciado: Crear una vista que liste todos los pedidos que tienen un viaje asignado pero que aún no han sido distribuidos
-- , mostrando detalles del pedido, el cliente y el estado del viaje. 
-- -----------------------------------------------------

CREATE VIEW PedidosConViajesAsignadosPendientes AS
SELECT 
    pe.fecha,
    c.cliente,
    c.email,
    c.telefono,
    pe.observaciones,
    v.estado
FROM 
    Pedidos pe
JOIN 
    Clientes c ON pe.idCliente = c.idCliente
JOIN 
    Viajes v ON pe.idViaje = v.idViaje
WHERE 
    v.estado = 'A'
ORDER BY 
    pe.fecha, c.cliente;
    
SELECT * FROM pedidosconviajesasignadospendientes;

-- 1. FROM y JOIN:
-- FROM Pedidos: Comenzamos desde Pedidos porque queremos listar todos los pedidos que tienen viajes asignados.
-- JOIN Clientes: Unimos Pedidos con Clientes usando idCliente para obtener la información del cliente.
-- JOIN Viajes: Unimos Pedidos con Viajes usando idViaje para obtener el estado del viaje.

-- 2. WHERE:
-- Filtramos los resultados para incluir solo los pedidos cuyo viaje asignado tenga estado 'A' (Asignado), indicando que aún no han sido distribuidos.

-- 3. ORDER BY:
-- Ordenamos los resultados por la fecha del pedido (pe.fecha) y el nombre del cliente (c.cliente).
