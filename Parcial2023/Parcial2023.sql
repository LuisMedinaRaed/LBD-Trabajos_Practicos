-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2023
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2023

-- ------------------------------------------------------------------------------------------------------- --

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
--  Apartado 1: Creación de la Base de datos y sus Constraints
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

--
-- ER/Studio Data Architect SQL Code Generation
-- Project :      DATA MODEL
--
-- Date Created : Monday, June 17, 2024 18:57:04
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2023;
CREATE DATABASE IF NOT EXISTS Parcial2023;
USE Parcial2023;

DROP TABLE IF EXISTS BandasHorarias;

CREATE TABLE IF NOT EXISTS BandasHorarias(
    idBandaHoraria    INT         NOT NULL,
    nombre            CHAR(13)    NOT NULL,
    PRIMARY KEY (idBandaHoraria),
    UNIQUE INDEX UI_nombreBandasHorarias(nombre)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Clientes;

CREATE TABLE IF NOT EXISTS Clientes(
    idCliente    INT             NOT NULL,
    apellidos    VARCHAR(50)     NOT NULL,
    nombres      VARCHAR(50)     NOT NULL,
    dni          VARCHAR(10)     NOT NULL,
    domicilio    VARCHAR(100)    NOT NULL,
    PRIMARY KEY (idCliente),
    UNIQUE INDEX UI_dniClientes(dni)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Pedidos;

CREATE TABLE IF NOT EXISTS Pedidos(
    idPedido     INT         NOT NULL,
    idCliente    INT         NOT NULL,
    fecha        DATETIME    NOT NULL,
    PRIMARY KEY (idPedido),
    INDEX IX_idClientePedidos(idCliente),
    FOREIGN KEY (idCliente)
    REFERENCES Clientes(idCliente)
)ENGINE=INNODB
;

-- SHOW INDEX FROM Pedidos;

DROP TABLE IF EXISTS Sucursales;

CREATE TABLE IF NOT EXISTS Sucursales(
    idSucursal    INT             NOT NULL,
    nombre        VARCHAR(100)    NOT NULL,
    domicilio     VARCHAR(100)    NOT NULL,
    PRIMARY KEY (idSucursal),
    UNIQUE INDEX UI_nombreSucursales(nombre),
    UNIQUE INDEX UI_domicilioSucursales(domicilio)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Entregas;

CREATE TABLE IF NOT EXISTS Entregas(
    idEntrega         INT         NOT NULL,
    idSucursal        INT         NOT NULL,
    idPedido          INT         NOT NULL,
    fecha             DATETIME    NOT NULL,
    idBandaHoraria    INT         NOT NULL,
    PRIMARY KEY (idEntrega),
    INDEX IX_idPedidoEntregas(idPedido),
    INDEX IX_idSucursalEntregas(idSucursal),
    INDEX IX_idBandaHorariaEntregas(idBandaHoraria),
    FOREIGN KEY (idPedido)
    REFERENCES Pedidos(idPedido),
    FOREIGN KEY (idSucursal)
    REFERENCES Sucursales(idSucursal),
    FOREIGN KEY (idBandaHoraria)
    REFERENCES BandasHorarias(idBandaHoraria)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Productos;

CREATE TABLE IF NOT EXISTS Productos(
    idProducto    INT             NOT NULL,
    nombre        VARCHAR(150)    NOT NULL,
    precio        FLOAT    NOT NULL CHECK (precio > 0),
    PRIMARY KEY (idProducto),
    UNIQUE INDEX UI_nombreProductos(nombre)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS ProductoDelPedido;

CREATE TABLE IF NOT EXISTS ProductoDelPedido(
    idPedido      INT            NOT NULL,
    idProducto    INT            NOT NULL,
    cantidad      FLOAT    NOT NULL,
    precio        FLOAT   NOT NULL CHECK (precio > 0),
    PRIMARY KEY (idPedido, idProducto),
    INDEX IX_idPedidoProductoDelPedido(idPedido),
    INDEX IX_idProductoProductoDelPedido(idProducto),
    FOREIGN KEY (idPedido)
    REFERENCES Pedidos(idPedido),
    FOREIGN KEY (idProducto)
    REFERENCES Productos(idProducto)
)ENGINE=INNODB
;

-- En MySQL, cuando se define una clave foránea (FK)
-- se crea automáticamente un índice para esa columna si no existe uno.
-- Por lo tanto, las líneas que crean explícitamente los índices
-- IX_idPedidoProductoDelPedido y IX_idProductoProductoDelPedido podrían ser omitidas
-- ya que MySQL creará automáticamente estos índices debido a las definiciones de las claves foráneas.

-- SHOW INDEX FROM ProductoDelPedido;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear una vista llamada VEntregas que muestre por cada sucursal su nombre, el
-- identificador del pedido que entregó, la fecha en la que se hizo el pedido, la fecha en la que
-- fue entregado junto con la banda horaria, y el cliente que hizo el pedido. La salida, mostrada
-- en la siguiente tabla, deberá estar ordenada ascendentemente según el nombre de la
-- sucursal, fecha del pedido y fecha de entrega (tener en cuenta las sucursales que pudieran
-- no tener entregas). Incluir el código con la consulta a la vista.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminamos la vista VEntregas si ya existe
DROP VIEW IF EXISTS VEntregas;

-- Creamos la vista VEntregas
CREATE VIEW VEntregas AS
SELECT
    S.nombre AS 'Sucursal', -- Nombre de la sucursal
    E.idPedido AS 'Pedido', -- Identificador del pedido
    DATE(P.fecha) AS 'F. pedido', -- Fecha en la que se hizo el pedido (solo fecha, sin hora)
    DATE(E.fecha) AS 'F. entrega', -- Fecha en la que fue entregado (solo fecha, sin hora)
    BH.nombre AS 'Banda', -- Banda horaria de la entrega
    CONCAT(C.apellidos, ', ', C.nombres, ' (', C.dni, ')') AS 'Cliente' -- Cliente que hizo el pedido con DNI entre paréntesis
FROM
    Sucursales S
LEFT OUTER JOIN
    Entregas E ON S.idSucursal = E.idSucursal -- Unimos con la tabla Entregas
LEFT OUTER JOIN
    Pedidos P ON E.idPedido = P.idPedido -- Unimos con la tabla Pedidos
LEFT OUTER JOIN
    BandasHorarias BH ON E.idBandaHoraria = BH.idBandaHoraria -- Unimos con la tabla BandasHorarias
LEFT OUTER JOIN
    Clientes C ON P.idCliente = C.idCliente -- Unimos con la tabla Clientes
ORDER BY
    S.nombre ASC, -- Ordenamos por nombre de la sucursal
    P.fecha ASC, -- Luego por fecha del pedido
    E.fecha ASC; -- Finalmente por fecha de entrega

-- Consultamos la vista VEntregas
SELECT * FROM VEntregas;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado NuevoProducto para dar de alta un
-- producto, incluyendo el control de errores lógicos y mensajes de error necesarios
-- (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
-- código con la llamada al procedimiento probando todos los casos con datos incorrectos y
-- uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminar el procedimiento almacenado si ya existe
DROP PROCEDURE IF EXISTS NuevoProducto;

DELIMITER //
CREATE PROCEDURE NuevoProducto(IN p_nombreProducto VARCHAR(150), IN p_precioProducto FLOAT, OUT mensaje VARCHAR(255))
proc: BEGIN
    -- Declarar una variable para almacenar el nuevo idProducto
    DECLARE v_idProducto INT;

    -- Comprobar si el nombreProducto es NULL
    IF p_nombreProducto IS NULL THEN
        SET mensaje = 'El nombreProducto no puede ser NULL';
        LEAVE proc;
    END IF;

    -- Comprobar si el nombreProducto es una cadena vacía
    IF p_nombreProducto = '' THEN
        SET mensaje = 'El nombreProducto no puede ser una cadena vacía';
        LEAVE proc;
    END IF;

    -- Comprobar si el nombreProducto ya existe
    IF EXISTS (SELECT 1 FROM Productos WHERE nombre = p_nombreProducto) THEN
        SET mensaje = 'El nombreProducto ya existe';
        LEAVE proc;
    END IF;

    -- Comprobar si el precioProducto es NULL
    IF p_precioProducto IS NULL THEN
        SET mensaje = 'El precioProducto no puede ser NULL';
        LEAVE proc;
    END IF;

    -- Comprobar si el precioProducto es mayor que cero
    IF p_precioProducto <= 0 THEN
        SET mensaje = 'El precioProducto debe ser mayor que cero';
        LEAVE proc;
    END IF;

    -- Obtener el último idProducto insertado y agregarle 1
    SELECT COALESCE(MAX(idProducto), 0) + 1 INTO v_idProducto FROM Productos;

    -- Intentar insertar el nuevo producto
    INSERT INTO Productos(idProducto, nombre, precio) VALUES (v_idProducto, p_nombreProducto, p_precioProducto);
    -- Si la inserción es exitosa, establecer el mensaje de salida
    SET mensaje = 'Producto agregado exitosamente';
END //
DELIMITER ;

-- Prueba 1: Intentar agregar un producto con un nombreProducto que es NULL
CALL NuevoProducto(NULL, 100.0, @mensaje);
SELECT @mensaje; -- Debería mostrar 'El nombreProducto no puede ser NULL'

-- Prueba 2: Intentar agregar un producto con un nombreProducto que es una cadena vacía
CALL NuevoProducto('', 100.0, @mensaje);
SELECT @mensaje; -- Debería mostrar 'El nombreProducto no puede ser una cadena vacía'

-- Prueba 3: Intentar agregar un producto con un nombreProducto que ya existe
CALL NuevoProducto('iPhone 12', 100.0, @mensaje);
SELECT @mensaje; -- Debería mostrar 'El nombreProducto ya existe'

-- Prueba 4: Intentar agregar un producto con un precioProducto que es NULL
CALL NuevoProducto('Producto nuevo', NULL, @mensaje);
SELECT @mensaje; -- Debería mostrar 'El precioProducto no puede ser NULL'

-- Prueba 5: Intentar agregar un producto con un precioProducto que es menor o igual a cero
CALL NuevoProducto('Producto nuevo', 0, @mensaje);
SELECT @mensaje; -- Debería mostrar 'El precioProducto debe ser mayor que cero'

-- Prueba 6: Agregar un producto con datos correctos
CALL NuevoProducto('Producto nuevo', 100.0, @mensaje);
SELECT @mensaje; -- Debería mostrar 'Producto agregado exitosamente'


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado BuscarPedidos que reciba el
-- identificador de un pedido y muestre los datos del mismo. Por cada pedido mostrará el
-- identificador del producto, nombre, precio de lista, cantidad, precio de venta y total. Además
-- en la última fila mostrará los datos del pedido (fecha, cliente y total del pedido). La salida,
-- mostrada en la siguiente tabla, deberá estar ordenada alfabéticamente según el nombre del
-- producto. Incluir en el código la llamada al procedimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminar el procedimiento almacenado si ya existe
DROP PROCEDURE IF EXISTS BuscarPedidos;

DELIMITER //
CREATE PROCEDURE BuscarPedidos(IN p_idPedido INT)
BEGIN
    -- Declarar una variable para almacenar el total del pedido
    DECLARE totalPedido FLOAT;
    DECLARE fechaPedido DATETIME;
    DECLARE clientePedido VARCHAR(255);

    -- Calcular el total del pedido
    SELECT SUM(precio * cantidad) INTO totalPedido
    FROM ProductoDelPedido
    WHERE idPedido = p_idPedido;

    -- Obtener la fecha y el cliente del pedido
    SELECT Ped.fecha, CONCAT(C.apellidos, ', ', C.nombres)
    INTO fechaPedido, clientePedido
    FROM Pedidos Ped
    INNER JOIN Clientes C ON Ped.idCliente = C.idCliente
    WHERE Ped.idPedido = p_idPedido;

    -- Crear una tabla temporal para almacenar los datos del pedido
    CREATE TEMPORARY TABLE IF NOT EXISTS TempPedido AS
    SELECT
        P.idProducto AS 'idProducto',
        Prod.nombre AS 'Nombre',
        Prod.precio AS 'precio lista',
        P.cantidad AS 'cantidad',
        P.precio AS 'precio venta',
        P.precio * P.cantidad AS 'total'
    FROM
        ProductoDelPedido P
    INNER JOIN
        Productos Prod ON P.idProducto = Prod.idProducto
    WHERE
        P.idPedido = p_idPedido
    ORDER BY
        Prod.nombre;

    -- Seleccionar los datos del pedido y unirlos con los datos del pedido
    SELECT * FROM TempPedido
    UNION ALL
    SELECT
        'Fecha:' AS 'idProducto',
        DATE(fechaPedido) AS 'Nombre',
        'Cliente:' AS 'precio lista',
        clientePedido AS 'cantidad',
        'Total:' AS 'precio venta',
        totalPedido AS 'total';

    -- Eliminar la tabla temporal
    DROP TABLE TempPedido;
END //
DELIMITER ;

CALL BuscarPedidos(1);

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- VARIANTE PUNTO 4 CON ROLLUP
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS BuscarPedidosROLLUP;

DELIMITER //
CREATE PROCEDURE BuscarPedidosROLLUP(IN p_idPedido INT)
BEGIN
    -- Declarar una variable para almacenar el total del pedido
    DECLARE totalPedido FLOAT;
    DECLARE fechaPedido DATETIME;
    DECLARE clientePedido VARCHAR(255);

    -- Calcular el total del pedido
    SELECT SUM(precio * cantidad) INTO totalPedido
    FROM ProductoDelPedido
    WHERE idPedido = p_idPedido;

    -- Obtener la fecha y el cliente del pedido
    SELECT Ped.fecha, CONCAT(C.apellidos, ', ', C.nombres)
    INTO fechaPedido, clientePedido
    FROM Pedidos Ped
    INNER JOIN Clientes C ON Ped.idCliente = C.idCliente
    WHERE Ped.idPedido = p_idPedido;

    -- Seleccionar los datos del pedido y unirlos con los datos del pedido
    SELECT
        CASE WHEN GROUPING(P.idProducto) = 1 THEN 'Fecha:' ELSE P.idProducto END AS 'idProducto',
        CASE WHEN GROUPING(P.idProducto) = 1 THEN DATE(fechaPedido) ELSE Prod.nombre END AS 'Nombre',
        CASE WHEN GROUPING(P.idProducto) = 1 THEN 'Cliente:' ELSE Prod.precio END AS 'precio lista',
        CASE WHEN GROUPING(P.idProducto) = 1 THEN clientePedido ELSE P.cantidad END AS 'cantidad',
        CASE WHEN GROUPING(P.idProducto) = 1 THEN 'Total:' ELSE P.precio END AS 'precio venta',
        CASE WHEN GROUPING(P.idProducto) = 1 THEN totalPedido ELSE P.precio * P.cantidad END AS 'total'
    FROM
        ProductoDelPedido P
    INNER JOIN
        Productos Prod ON P.idProducto = Prod.idProducto
    WHERE
        P.idPedido = p_idPedido
    GROUP BY
        P.idProducto WITH ROLLUP
    ORDER BY
        Prod.nombre;
END //
DELIMITER ;

CALL BuscarPedidosROLLUP(1);

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Utilizando triggers, implementar la lógica para que en caso que se quiera borrar un
-- producto incluido en un pedido se informe mediante un mensaje de error que no se puede.
-- Incluir el código con los borrados de un producto no incluido en ningún pedido, y otro de uno
-- que sí.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS NoBorrarProductoEnPedido;

DELIMITER //
CREATE TRIGGER NoBorrarProductoEnPedido BEFORE DELETE ON Productos
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM ProductoDelPedido WHERE idProducto = OLD.idProducto) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar un producto que está incluido en un pedido';
    END IF;
END //
DELIMITER ;

-- Agregamos un producto con datos correctos y sin pedidos
CALL NuevoProducto(912, 'Producto sin pedidos', 100.0, @mensaje);
SELECT @mensaje; -- Debería mostrar 'Producto agregado exitosamente'

-- Intentar eliminar un producto que no está incluido en ningún pedido
DELETE FROM Productos WHERE idProducto = 912;

-- Intentar eliminar un producto que está incluido en un pedido
DELETE FROM Productos WHERE idProducto = 1;
