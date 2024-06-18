DROP SCHEMA IF EXISTS DNI43364379;
CREATE SCHEMA IF NOT EXISTS DNI43364379;
USE DNI43364379;

DROP TABLE IF EXISTS Clientes;
CREATE TABLE IF NOT EXISTS Clientes
(
    idCliente INT          NOT NULL,
    apellidos VARCHAR(50)  NOT NULL,
    nombres   VARCHAR(50)  NOT NULL,
    dni       VARCHAR(10)  NOT NULL,
    domicilio VARCHAR(100) NOT NULL,
    PRIMARY KEY (idCliente),
    UNIQUE INDEX UI_dni (dni)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS Pedidos;
CREATE TABLE IF NOT EXISTS Pedidos
(
    idPedido  INT      NOT NULL,
    idCliente INT      NOT NULL,
    fecha     DATETIME NOT NULL,
    PRIMARY KEY (idPedido),
    CONSTRAINT FK_Clientes_23
        FOREIGN KEY (idCliente)
            REFERENCES Clientes (idCliente),
    INDEX IX_idCliente26 (idCliente)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS BandasHorarias;
CREATE TABLE IF NOT EXISTS BandasHorarias
(
    idBandaHoraria INT      NOT NULL,
    nombre         CHAR(13) NOT NULL,
    PRIMARY KEY (idBandaHoraria),
    UNIQUE INDEX UI_nombre (nombre)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS Sucursales;
CREATE TABLE IF NOT EXISTS Sucursales
(
    idSucursal INT          NOT NULL,
    nombre     VARCHAR(100) NOT NULL,
    domicilio  VARCHAR(100) NOT NULL,
    PRIMARY KEY (idSucursal),
    UNIQUE INDEX UI_nombre (nombre),
    UNIQUE INDEX UI_domicilio (domicilio)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS Entregas;
CREATE TABLE IF NOT EXISTS Entregas
(
    idEntrega      INT      NOT NULL,
    idSucursal     INT      NOT NULL,
    idPedido       INT      NOT NULL,
    fecha          DATETIME NOT NULL,
    idBandaHoraria INT      NOT NULL,
    PRIMARY KEY (idEntrega),
    CONSTRAINT FK_Sucursales_55
        FOREIGN KEY (idSucursal)
            REFERENCES Sucursales (idSucursal),
    INDEX IX_idSucursal58 (idSucursal),
    CONSTRAINT FK_Pedidos_59
        FOREIGN KEY (idPedido)
            REFERENCES Pedidos (idPedido),
    INDEX IX_idPedido62 (idPedido),
    CONSTRAINT FK_BandasHorarias_63
        FOREIGN KEY (idBandaHoraria)
            REFERENCES BandasHorarias (idBandaHoraria),
    INDEX IX_idBandaHoraria66 (idBandaHoraria)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS Productos;
CREATE TABLE IF NOT EXISTS Productos
(
    idProducto INT          NOT NULL,
    nombre     VARCHAR(150) NOT NULL,
    precio     FLOAT        NOT NULL CHECK (precio > 0),
    PRIMARY KEY (idProducto),
    UNIQUE INDEX UI_nombre (nombre)
) ENGINE = InnoDB;

DROP TABLE IF EXISTS ProductoDelPedido;
CREATE TABLE IF NOT EXISTS ProductoDelPedido
(
    idPedido   INT   NOT NULL,
    idProducto INT   NOT NULL,
    cantidad   FLOAT NOT NULL,
    precio     FLOAT NOT NULL CHECK (precio > 0),
    PRIMARY KEY (idPedido, idProducto),
    CONSTRAINT FK_Pedidos_86
        FOREIGN KEY (idPedido)
            REFERENCES Pedidos (idPedido),
    INDEX IX_idPedido89 (idPedido),
    CONSTRAINT FK_Productos_90
        FOREIGN KEY (idProducto)
            REFERENCES Productos (idProducto),
    INDEX IX_idProducto93 (idProducto)
) ENGINE = InnoDB;

-- -------------------------------------------------
-- 2) Crear una vista llamada VEntregas que muestre por cada sucursal su nombre, el
-- identificador del pedido que entregó, la fecha en la que se hizo el pedido, la fecha en la que
-- fue entregado junto con la banda horaria, y el cliente que hizo el pedido. La salida, mostrada
-- en la siguiente tabla, deberá estar ordenada ascendentemente según el nombre de la
-- sucursal, fecha del pedido y fecha de entrega (tener en cuenta las sucursales que pudieran
-- no tener entregas). Incluir el código con la consulta a la vista.
-- -------------------------------------------------

DROP VIEW IF EXISTS VEntregas;
CREATE VIEW VEntregas AS
SELECT S.nombre                                         AS Sucursal,
       E.idPedido,
       DATE(P.fecha)                                    AS 'F. pedido',
       DATE(E.fecha)                                    AS 'F. entrega',
       BH.nombre                                        AS Banda,
       CONCAT(apellidos, ', ', nombres, ' (', dni, ')') AS Cliente
FROM Sucursales S
         LEFT OUTER JOIN Entregas E ON S.idSucursal = E.idSucursal
         INNER JOIN Pedidos P ON E.idPedido = P.idPedido
         INNER JOIN BandasHorarias BH ON E.idBandaHoraria = BH.idBandaHoraria
         INNER JOIN Clientes C ON P.idCliente = C.idCliente
ORDER BY Sucursal, P.fecha, E.fecha;

-- Consulta
SELECT * FROM VEntregas;

-- -------------------------------------------------
-- 3) Realizar un procedimiento almacenado llamado NuevoProducto para dar de alta un
-- producto, incluyendo el control de errores lógicos y mensajes de error necesarios
-- (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
-- código con la llamada al procedimiento probando todos los casos con datos incorrectos y
-- uno con datos correctos.
-- -------------------------------------------------

DROP PROCEDURE IF EXISTS NuevoProducto;
DELIMITER //
CREATE PROCEDURE NuevoProducto(pNombre varchar(150), pPrecio float, OUT pMensaje varchar(100))
SALIR:
BEGIN
    -- Variable auxiliar
    DECLARE vUltimoIdInsertado int;

    -- Controlo si el nombre es nulo o cadena vacía
    IF pNombre IS NULL OR pNombre = '' THEN
        SET pMensaje = 'El nombre es obligatorio.';
        LEAVE SALIR;
    END IF;

    -- Controlo si el precio es nulo
    IF pPrecio IS NULL THEN
        SET pMensaje = 'El precio es obligatorio.';
        LEAVE SALIR;
    END IF;

    -- Controlo que el precio sea mayor que cero
    IF pPrecio <= 0 THEN
        SET pMensaje = 'El precio debe ser mayor que cero.';
        LEAVE SALIR;
    END IF;

    -- Controlo que el nombre del producto sea único
    IF EXISTS (SELECT idProducto FROM Productos WHERE nombre = pNombre) THEN
        SET pMensaje = 'Ya existe un producto con ese nombre, elija otro.';
        LEAVE SALIR;
    END IF;

    -- Averiguo el último id
    SET vUltimoIdInsertado = (SELECT MAX(COALESCE(idProducto, 0)) FROM Productos);

    -- Alta del producto
    INSERT INTO Productos (idProducto, nombre, precio) VALUES (vUltimoIdInsertado + 1, pNombre, pPrecio);

    -- Mensaje de éxito
    SET pMensaje = 'Producto dado de alta con éxito.';
END
//
DELIMITER ;

-- Llamadas al procedimiento
SET @mensaje = '';
CALL NuevoProducto('DELL Inspirion 15 3000', 1000, @mensaje); -- OK
SELECT @mensaje;
CALL NuevoProducto('DELL Inspirion 15 3000', 2000, @mensaje); -- Error: nombre repetido
SELECT @mensaje;
CALL NuevoProducto(null, 150, @mensaje); -- Error: nombre obligatorio
SELECT @mensaje;
CALL NuevoProducto('Motorola G8 plus', null, @mensaje); -- Error: precio obligatorio
SELECT @mensaje;
CALL NuevoProducto('Motorola G8 plus', -100, @mensaje); -- Error: precio menor que cero
SELECT @mensaje;

-- -------------------------------------------------
-- 4) Realizar un procedimiento almacenado llamado BuscarPedidos que reciba el
-- identificador de un pedido y muestre los datos del mismo. Por cada pedido mostrará el
-- identificador del producto, nombre, precio de lista, cantidad, precio de venta y total. Además
-- en la última fila mostrará los datos del pedido (fecha, cliente y total del pedido). La salida,
-- mostrada en la siguiente tabla, deberá estar ordenada alfabéticamente según el nombre del
-- producto. Incluir en el código la llamada al procedimiento.
-- -------------------------------------------------

DROP PROCEDURE IF EXISTS BuscarPedidos;
DELIMITER //
CREATE PROCEDURE BuscarPedidos(pIdPedido int)
SALIR:
BEGIN
    -- Variable auxiliar
    DECLARE vTotal float;

    -- Averiguo el total del pedido
    SET vTotal = (SELECT SUM(precio * cantidad) AS total
                  FROM ProductoDelPedido
                  WHERE idPedido = pIdPedido
                  LIMIT 1);

    -- Creo tabla temporal para order los datos
    CREATE TEMPORARY TABLE tmp (SELECT PR.idProducto,
                                       nombre,
                                       PR.precio             AS 'precio lista',
                                       cantidad,
                                       PDP.precio            AS 'precio venta',
                                       PDP.precio * cantidad AS total
                                FROM ProductoDelPedido PDP
                                         INNER JOIN Productos PR ON PDP.idProducto = PR.idProducto
                                WHERE PDP.idPedido = pIdPedido
                                ORDER BY nombre);

    -- Unión con la última fila
    (SELECT *
     FROM tmp)
    UNION
    (SELECT 'Fecha:', DATE(fecha), 'Cliente:', CONCAT(apellidos, ', ', nombres) AS Cliente, 'Total:', vTotal
     FROM Pedidos P
              INNER JOIN Clientes C ON P.idCliente = C.idCliente
     WHERE idPedido = pIdPedido);

    -- Borro tabla temporal
    DROP TEMPORARY TABLE tmp;
END
//
DELIMITER ;

-- Llamadas
CALL BuscarPedidos(1);
CALL BuscarPedidos(6);

-- -------------------------------------------------
-- 5) Utilizando triggers, implementar la lógica para que en caso que se quiera borrar un
-- producto incluido en un pedido se informe mediante un mensaje de error que no se puede.
-- Incluir el código con los borrados de un producto no incluido en ningún pedido, y otro de uno
-- que sí.
-- -------------------------------------------------

DROP TRIGGER IF EXISTS Productos_BEFORE_DELETE;

DELIMITER //
CREATE TRIGGER Productos_BEFORE_DELETE
    BEFORE DELETE
    ON Productos
    FOR EACH ROW
BEGIN
    IF EXISTS (SELECT idProducto FROM ProductoDelPedido WHERE idProducto = OLD.idProducto) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: no se puede borrar el producto por que está incluido en un pedido.';
    END IF;
END //
DELIMITER ;

DELETE FROM Productos WHERE idProducto = 1; -- Error: tiene pedidos asociados

DELETE FROM Productos WHERE idProducto = 21; -- OK: producto borrado