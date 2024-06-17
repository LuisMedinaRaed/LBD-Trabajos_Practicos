-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2017
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2017

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
-- Date Created : Monday, June 17, 2024 00:54:41
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2017;
CREATE DATABASE IF NOT EXISTS Parcial2017;
USE Parcial2017;

DROP TABLE IF EXISTS Categorias;

CREATE TABLE IF NOT EXISTS Categorias(
    IdCategoria    INT            NOT NULL,
    Nombre         VARCHAR(50)    NOT NULL,
    PRIMARY KEY (IdCategoria),
    UNIQUE INDEX UI_NombreCategorias(Nombre)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Clientes;

CREATE TABLE IF NOT EXISTS Clientes(
    IdCliente    INT            NOT NULL,
    Apellidos    VARCHAR(50)    NOT NULL,
    Nombres      VARCHAR(50)    NOT NULL,
    Telefono     VARCHAR(25)    NOT NULL,
    PRIMARY KEY (IdCliente),
    UNIQUE INDEX UI_Telefono(Telefono)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Productos;

CREATE TABLE IF NOT EXISTS Productos(
    IdProducto     INT               NOT NULL,
    Nombre         VARCHAR(50)       NOT NULL,
    Color          VARCHAR(15),
    Precio         DECIMAL(10, 4)    NOT NULL,
    IdCategoria    INT,
    PRIMARY KEY (IdProducto),
    UNIQUE INDEX UI_NombreProductos(Nombre),
    INDEX IX_IdCategoria(IdCategoria),
    FOREIGN KEY (IdCategoria)
    REFERENCES Categorias(IdCategoria)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Ofertas;

CREATE TABLE IF NOT EXISTS Ofertas(
    IdOferta          INT            NOT NULL,
    Descuento         FLOAT(8, 0)    NOT NULL DEFAULT 0.05,
    FechaInicio       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FechaFin          DATETIME       NOT NULL,
    CantidadMinima    INT            NOT NULL DEFAULT 1,
    CantidadMaxima    INT,
    PRIMARY KEY (IdOferta),
    INDEX IX_FechaInicio(FechaInicio),
    INDEX IX_FechaFin(FechaFin),
    CHECK (FechaFin > FechaInicio)
)ENGINE=INNODB;

DROP TABLE IF EXISTS OfertasDelProducto;

CREATE TABLE IF NOT EXISTS OfertasDelProducto(
    IdProducto    INT    NOT NULL,
    IdOferta      INT    NOT NULL,
    PRIMARY KEY (IdProducto, IdOferta),
    INDEX IX_IdProducto(IdProducto),
    INDEX IX_IdOferta(IdOferta),
    FOREIGN KEY (IdProducto)
    REFERENCES Productos(IdProducto),
    FOREIGN KEY (IdOferta)
    REFERENCES Ofertas(IdOferta)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Ventas;

CREATE TABLE IF NOT EXISTS Ventas(
    IdVenta      INT         NOT NULL,
    Fecha        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    IdCliente    INT         NOT NULL,
    PRIMARY KEY (IdVenta),
    INDEX IX_Fecha(Fecha),
    INDEX IX_IdCliente(IdCliente),
    FOREIGN KEY (IdCliente)
    REFERENCES Clientes(IdCliente)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Detalles;

CREATE TABLE IF NOT EXISTS Detalles(
    IdDetalle     INT               NOT NULL,
    IdVenta       INT               NOT NULL,
    IdProducto    INT               NOT NULL,
    Cantidad      INT               NOT NULL,
    Precio        DECIMAL(10, 4)    NOT NULL,
    Descuento     FLOAT(8, 0)       NOT NULL DEFAULT 0,
    IdOferta      INT               NOT NULL,
    PRIMARY KEY (IdDetalle, IdVenta),
    INDEX IX_IdOfertaProducto(IdOferta, IdProducto),
    INDEX IX_IdVenta(IdVenta),
    FOREIGN KEY (IdProducto, IdOferta)
    REFERENCES OfertasDelProducto(IdProducto, IdOferta),
    FOREIGN KEY (IdVenta)
    REFERENCES Ventas(IdVenta)
)ENGINE=INNODB
;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación del Stored Procedure
-- Crear un SP, llamado sp_CargarProducto, que permita dar de alta un producto, efectuar las
-- comprobaciones necesarias y devolver los mensajes de error correspondiente
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_CargarProducto;

DELIMITER //
CREATE PROCEDURE sp_CargarProducto(
    IN p_IdProducto INT,
    IN p_Nombre VARCHAR(50),
    IN p_Color VARCHAR(50),
    IN p_Precio DECIMAL(10, 4),
    IN p_IdCategoria INT,
    OUT p_ErrorMessage VARCHAR(255)
)
sp_CargarProducto:BEGIN
    DECLARE v_IdProductoExists INT;
    DECLARE v_NombreExists INT;
    DECLARE v_PrecioValid INT;
    DECLARE v_CategoriaExists INT;

    -- Comprobar si el ID del producto ya existe
    SELECT COUNT(*) INTO v_IdProductoExists FROM Productos WHERE IdProducto = p_IdProducto;
    IF v_IdProductoExists > 0 THEN
        SET p_ErrorMessage = 'Error: El ID del producto ya existe.';
        LEAVE sp_CargarProducto;
    END IF;

    -- Comprobar si el nombre del producto ya existe
    SELECT COUNT(*) INTO v_NombreExists FROM Productos WHERE Nombre = p_Nombre;
    IF v_NombreExists > 0 THEN
        SET p_ErrorMessage = 'Error: El nombre del producto ya existe.';
        LEAVE sp_CargarProducto;
    END IF;

    -- Comprobar si el precio del producto es válido
    IF p_Precio <= 0 THEN
        SET p_ErrorMessage = 'Error: El precio del producto debe ser mayor que 0.';
        LEAVE sp_CargarProducto;
    END IF;

    -- Comprobar si la categoría del producto existe
    SELECT COUNT(*) INTO v_CategoriaExists FROM Categorias WHERE IdCategoria = p_IdCategoria;
    IF v_CategoriaExists = 0 THEN
        SET p_ErrorMessage = 'Error: La categoría del producto no existe.';
        LEAVE sp_CargarProducto;
    END IF;

    -- Si todas las comprobaciones son correctas, insertar el nuevo producto
    INSERT INTO Productos(IdProducto, Nombre, Color, Precio, IdCategoria)
    VALUES (p_IdProducto, p_Nombre, p_Color, p_Precio, p_IdCategoria);

    -- Establecer el mensaje de éxito
    SET p_ErrorMessage = 'El producto se cargó correctamente.';
END //
DELIMITER ;

-- Llamada de prueba 1: Todos los parámetros son válidos
CALL sp_CargarProducto(1, 'Producto 1', 'Rojo', 100.0, 18, @ErrorMessage);
SELECT @ErrorMessage;

-- Llamada de prueba 2: El ID del producto ya existe
CALL sp_CargarProducto(707, 'Producto 2', 'Azul', 200.0, 1, @ErrorMessage);
SELECT @ErrorMessage;

-- Llamada de prueba 3: El nombre del producto ya existe
CALL sp_CargarProducto(2, 'Sport-100 Helmet, Red', 'Azul', 200.0, 1, @ErrorMessage);
SELECT @ErrorMessage;

-- Llamada de prueba 4: El precio del producto es inválido (menor o igual a 0)
CALL sp_CargarProducto(3, 'Producto 3', 'Verde', 0.0, 1, @ErrorMessage);
SELECT @ErrorMessage;

-- Llamada de prueba 5: La categoría del producto no existe
CALL sp_CargarProducto(4, 'Producto 4', 'Amarillo', 300.0, 999, @ErrorMessage);
SELECT @ErrorMessage;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación de la vista
-- Realizar una vista, llamada VTotalVentas, en donde se muestre el número de venta, la fecha de venta
-- en el formato “dd/mm/aaaa”, el apellido y nombre del cliente, el nombre del producto, la categoría (NULL
-- o vacío mostrar S/C), la cantidad de productos, el precio unitario y colocar en una nueva fila el “Total” de
-- ventas recaudado [20].
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS VTotalVentas;

CREATE VIEW VTotalVentas AS
SELECT
    V.IdVenta AS 'Número de venta',
    DATE_FORMAT(V.Fecha, '%d/%m/%Y') AS 'Fecha de venta',
    CONCAT(C.Apellidos, ' ', C.Nombres) AS 'Nombre del cliente',
    P.Nombre AS 'Nombre del producto',
    IFNULL(Cat.Nombre, 'S/C') AS 'Categoría',
    D.Cantidad AS 'Cantidad de productos',
    D.Precio AS 'Precio unitario',
    (D.Cantidad * D.Precio) AS 'Total de ventas recaudado'
FROM
    Ventas V
JOIN
    Clientes C ON V.IdCliente = C.IdCliente
JOIN
    Detalles D ON V.IdVenta = D.IdVenta
JOIN
    Productos P ON D.IdProducto = P.IdProducto
LEFT JOIN
    Categorias Cat ON P.IdCategoria = Cat.IdCategoria;

-- Cambiamos algunas categorías de productos por NULL para probar la funcionalidad de la vista
UPDATE Productos SET IdCategoria = NULL WHERE IdProducto = 710;
UPDATE Productos SET IdCategoria = NULL WHERE IdProducto = 709;
UPDATE Productos SET IdCategoria = NULL WHERE IdProducto = 707;
UPDATE Productos SET IdCategoria = NULL WHERE IdProducto = 708;

SELECT * FROM VTotalVentas;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un trigger llamado AuditarOfertas el cual se dispare luego de insertar una oferta cuyo
-- descuento tenga un valor mayor o igual al 10%, los datos se deben guardar en la tabla auditoria guardando
-- el nuevo valor de id oferta, descuento, fecha inicio, fecha fin, cantidad mínima y la cantidad máxima, el
-- usuario la fecha en que se realizó.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Creación de la tabla Auditoria
CREATE TABLE IF NOT EXISTS Auditoria(
    IdAuditoria    INT AUTO_INCREMENT PRIMARY KEY,
    IdOferta       INT,
    Descuento      FLOAT(8, 0),
    FechaInicio    DATETIME,
    FechaFin       DATETIME,
    CantidadMinima INT,
    CantidadMaxima INT,
    Usuario        VARCHAR(50),
    Fecha          DATETIME
);

-- Creación del trigger AuditarOfertas
DELIMITER //
CREATE TRIGGER AuditarOfertas
AFTER INSERT ON Ofertas
FOR EACH ROW
BEGIN
    IF NEW.Descuento >= 10 THEN
        INSERT INTO Auditoria(IdOferta, Descuento, FechaInicio, FechaFin, CantidadMinima, CantidadMaxima, Usuario, Fecha)
        VALUES (NEW.IdOferta, NEW.Descuento, NEW.FechaInicio, NEW.FechaFin, NEW.CantidadMinima, NEW.CantidadMaxima, CURRENT_USER(), NOW());
    END IF;
END; //
DELIMITER ;

-- Insertamos una oferta con un descuento del 10%
-- El trigger debería activarse y agregar una entrada en la tabla Auditoria
INSERT INTO Ofertas(IdOferta, Descuento, FechaInicio, FechaFin, CantidadMinima, CantidadMaxima)
VALUES (17, 10, '2024-06-20 00:00:00', '2024-06-30 23:59:59', 1, 100);

-- Insertamos una oferta con un descuento del 9%
-- El trigger no debería activarse ya que el descuento es menor al 10%
INSERT INTO Ofertas(IdOferta, Descuento, FechaInicio, FechaFin, CantidadMinima, CantidadMaxima)
VALUES (18, 9, '2024-06-20 00:00:00', '2024-06-30 23:59:59', 1, 100);

-- Insertamos una oferta con un descuento del 15%
-- El trigger debería activarse y agregar una entrada en la tabla Auditoria
INSERT INTO Ofertas(IdOferta, Descuento, FechaInicio, FechaFin, CantidadMinima, CantidadMaxima)
VALUES (19, 15, '2024-06-20 00:00:00', '2024-06-30 23:59:59', 1, 100);

-- Verificamos la tabla Auditoria
-- Deberíamos ver dos entradas correspondientes a las ofertas con descuentos del 10% y 15%
SELECT * FROM Auditoria;




