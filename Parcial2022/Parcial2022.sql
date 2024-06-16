-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2022
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2022

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
-- Date Created : Sunday, June 16, 2024 03:05:56
-- Target DBMS : MySQL 8.x
--


DROP DATABASE IF EXISTS Parcial2022;
CREATE DATABASE Parcial2022;
USE Parcial2022;

CREATE TABLE Autores(
    idAutor         VARCHAR(11)    NOT NULL,
    apellido        VARCHAR(40)    NOT NULL,
    nombre          VARCHAR(20)    NOT NULL,
    telefono        CHAR(12)       DEFAULT 'UNKNOWN' NOT NULL,
    domicilio       VARCHAR(40),
    ciudad          VARCHAR(20),
    estado          CHAR(2),
    codigoPostal    CHAR(5),
    PRIMARY KEY (idAutor)
)ENGINE=INNODB
;

CREATE TABLE Editoriales(
    idEditorial    CHAR(4)        NOT NULL,
    nombre         VARCHAR(40)    NOT NULL,
    ciudad         VARCHAR(20),
    estado         CHAR(2),
    pais           VARCHAR(30)    DEFAULT 'USA' NOT NULL,
    PRIMARY KEY (idEditorial),
    UNIQUE INDEX UI_nombreEditorial(nombre)
)ENGINE=INNODB
;

CREATE TABLE Titulos(
    idTitulo            VARCHAR(6)       NOT NULL,
    titulo              VARCHAR(80)      NOT NULL,
    genero              CHAR(12)         DEFAULT 'UNDECIDED' NOT NULL,
    idEditorial         CHAR(4)          NOT NULL,
    precio              DECIMAL(8, 2)    CHECK (precio > 0),
    sinopsis            VARCHAR(200),
    fechaPublicacion    DATETIME         DEFAULT current_timestamp NOT NULL,
    PRIMARY KEY (idTitulo),
    INDEX ix_idEditorial(idEditorial),
    FOREIGN KEY (idEditorial)
    REFERENCES Editoriales(idEditorial)
)ENGINE=INNODB
;

CREATE TABLE Tiendas(
    idTienda        CHAR(4)        NOT NULL,
    nombre          VARCHAR(40)    NOT NULL,
    domicilio       VARCHAR(40)    NOT NULL,
    ciudad          VARCHAR(20),
    estado          CHAR(2),
    codigoPostal    CHAR(5),
    PRIMARY KEY (idTienda),
    UNIQUE INDEX UI_nombreTienda(nombre)
)ENGINE=INNODB
;

CREATE TABLE Ventas(
    codigoVenta    VARCHAR(20)    NOT NULL,
    idTienda       CHAR(4)        NOT NULL,
    fecha          DATETIME       NOT NULL,
    tipo           VARCHAR(12)    NOT NULL,
    PRIMARY KEY (codigoVenta),
    INDEX IX_idTienda(idTienda),
    FOREIGN KEY (idTienda)
    REFERENCES Tiendas(idTienda)
)ENGINE=INNODB
;

CREATE TABLE Detalles(
    idDetalle      INT            AUTO_INCREMENT,
    codigoVenta    VARCHAR(20)    NOT NULL,
    idTitulo       VARCHAR(6)     NOT NULL,
    cantidad       SMALLINT       NOT NULL CHECK (cantidad > 0),
    PRIMARY KEY (idDetalle),
    INDEX IX_idTitulo(idTitulo),
    INDEX IX_codigoVenta(codigoVenta),
    FOREIGN KEY (idTitulo)
    REFERENCES Titulos(idTitulo),
    FOREIGN KEY (codigoVenta)
    REFERENCES Ventas(codigoVenta)
)ENGINE=INNODB
;

CREATE TABLE TitulosDelAutor(
    idAutor     VARCHAR(11)    NOT NULL,
    idTitulo    VARCHAR(6)     NOT NULL,
    PRIMARY KEY (idAutor, idTitulo),
    INDEX IX_idAutor(idAutor),
    INDEX IX_idTitulo(idTitulo),
    FOREIGN KEY (idAutor)
    REFERENCES Autores(idAutor),
    FOREIGN KEY (idTitulo)
    REFERENCES Titulos(idTitulo)
)ENGINE=INNODB
;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista: Crear una vista llamada VCantidadVentas que muestre por cada tienda su código,
-- cantidad total de ventas y el importe total de todas esas ventas. La salida, mostrada en la
-- siguiente tabla, deberá estar ordenada descendentemente según la cantidad total de ventas
-- y el importe de las mismas. Incluir el código con la consulta a la vista
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

CREATE VIEW VCantidadVentas AS
SELECT
    v.idTienda AS `Codigo de Tienda`,
    COUNT(*) AS `Cantidad Total de Ventas`,
    SUM(d.cantidad * t.precio) AS `Importe Total de Ventas`
FROM
    Parcial2022.Ventas v
JOIN
    Parcial2022.Detalles d ON v.codigoVenta = d.codigoVenta
JOIN
    Parcial2022.Titulos t ON d.idTitulo = t.idTitulo
GROUP BY
    v.idTienda
ORDER BY
    COUNT(*) DESC,
    SUM(d.cantidad * t.precio) DESC;

SELECT * FROM VCantidadVentas;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure: Realizar un procedimiento almacenado llamado NuevaEditorial para dar de alta una
-- editorial, incluyendo el control de errores lógicos y mensajes de error necesarios
-- (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
-- código con la llamada al procedimiento probando todos los casos con datos incorrectos y
-- uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE NuevaEditorial(
    IN idEditorial CHAR(4),
    IN nombre VARCHAR(40),
    IN ciudad VARCHAR(20),
    IN estado CHAR(2),
    IN pais VARCHAR(30),
    OUT mensaje VARCHAR(255)
)
BEGIN
    DECLARE existe INT;
    DECLARE sinEstadoCiudad BOOLEAN DEFAULT FALSE;

    IF idEditorial = '' THEN
        SET mensaje = 'Error: El idEditorial no puede estar vacío.';
    ELSEIF nombre = '' THEN
        SET mensaje = 'Error: El nombre no puede estar vacío.';
    ELSE
        SELECT COUNT(*) INTO existe FROM Parcial2022.Editoriales AS e WHERE e.idEditorial = idEditorial;

        IF existe > 0 THEN
            SET mensaje = 'Error: La editorial con este idEditorial ya existe.';
        ELSE
            SELECT COUNT(*) INTO existe FROM Parcial2022.Editoriales AS e WHERE e.nombre = nombre;

            IF existe > 0 THEN
                SET mensaje = 'Error: Ya existe una editorial con este nombre.';
            ELSE
                IF pais = '' THEN
                    SET pais = 'USA';
                    SET mensaje = 'No se especificó país, se colocó USA por defecto.';
                END IF;

                IF ciudad = '' AND estado = '' THEN
                    SET sinEstadoCiudad = TRUE;
                END IF;

                INSERT INTO Parcial2022.Editoriales(idEditorial, nombre, ciudad, estado, pais)
                VALUES (idEditorial, nombre, ciudad, estado, pais);

                IF sinEstadoCiudad THEN
                    SET mensaje = CONCAT(IFNULL(mensaje, ''), ' Se creó una editorial sin especificar ciudad y estado.');
                ELSE
                    IF ciudad = '' THEN
                        SET mensaje = CONCAT(IFNULL(mensaje, ''), ' Se creó una editorial sin especificar ciudad.');
                    END IF;

                    IF estado = '' THEN
                        SET mensaje = CONCAT(IFNULL(mensaje, ''), ' Se creó una editorial sin especificar estado.');
                    END IF;
                END IF;

                IF mensaje IS NULL THEN
                    SET mensaje = 'La editorial ha sido creada exitosamente.';
                END IF;
            END IF;
        END IF;
    END IF;
END//
DELIMITER ;

-- Caso con datos incorrectos (idEditorial vacío)
CALL NuevaEditorial('', 'Editorial Existente', 'Ciudad', 'ST', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos incorrectos (nombre vacío)
CALL NuevaEditorial('E001', '', 'Ciudad', 'ST', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos incorrectos (la editorial ya existe)
CALL NuevaEditorial('E001', 'Editorial Existente', 'Ciudad', 'ST', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos incorrectos (nombre de editorial ya existe)
CALL NuevaEditorial('E003', 'New Moon Books', 'Otra Ciudad', 'OC', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos correctos (sin especificar estado)
CALL NuevaEditorial('E006', 'Editorial sin Estado', 'Nueva Ciudad', '', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos correctos (sin especificar ciudad)
CALL NuevaEditorial('E007', 'Editorial sin Ciudad', '', 'NC', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos correctos (sin especificar ciudad y estado)
CALL NuevaEditorial('E008', 'Editorial sin Ciudad y Estado', '', '', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso con datos correctos
CALL NuevaEditorial('E005', 'Otra Nueva Editorial', 'Otra Nueva Ciudad', 'A', 'USA', @mensaje);
SELECT @mensaje AS Mensaje;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado BuscarTitulosPorAutor que reciba el
-- código de un autor y muestre los títulos del mismo. Por cada título del autor especificado se
-- deberá mostrar su código y título, género, nombre de la editorial, precio, sinopsis y fecha de
-- publicación. La salida, mostrada en la siguiente tabla, deberá estar ordenada
-- alfabéticamente según el título. Incluir en el código la llamada al procedimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE BuscarTitulosPorAutor(IN idAutor VARCHAR(11), OUT mensaje VARCHAR(255))
BEGIN
    DECLARE existe INT;

    SELECT COUNT(*) INTO existe FROM Parcial2022.Autores AS a WHERE a.idAutor = idAutor;
    IF existe = 0 THEN
        SET mensaje = 'Error: No existe un autor con el id especificado.';
    ELSE
        SELECT COUNT(*) INTO existe FROM Parcial2022.TitulosDelAutor AS a WHERE a.idAutor = idAutor;
        IF existe = 0 THEN
            SET mensaje = 'Error: El autor especificado no tiene títulos.';
        ELSE
            SELECT
                t.idTitulo AS 'Código de Título',
                t.titulo AS 'Título',
                t.genero AS 'Género',
                e.nombre AS 'Nombre de la Editorial',
                t.precio AS 'Precio',
                t.sinopsis AS 'Sinopsis',
                t.fechaPublicacion AS 'Fecha de Publicación'
            FROM
                Parcial2022.TitulosDelAutor ta
            JOIN
                Parcial2022.Titulos t ON ta.idTitulo = t.idTitulo
            JOIN
                Parcial2022.Editoriales e ON t.idEditorial = e.idEditorial
            WHERE
                ta.idAutor = idAutor AND existe != 0
            ORDER BY
                t.titulo;

            SET mensaje = 'La consulta se realizó con éxito.';
        END IF;
    END IF;
END//
DELIMITER ;

-- Caso de éxito (el autor existe y tiene títulos)
CALL BuscarTitulosPorAutor('213-46-8915', @mensaje);
SELECT @mensaje AS Mensaje;

-- Caso de falla (el autor no existe)
CALL BuscarTitulosPorAutor('A999', @mensaje); 
SELECT @mensaje AS Mensaje;

-- Caso de falla (el autor existe pero no tiene títulos)
CALL BuscarTitulosPorAutor('341-22-1782', @mensaje); 
SELECT @mensaje AS Mensaje;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del trigger
-- Utilizando triggers, implementar la lógica para que en caso que se quiera borrar una
-- editorial referenciada por un título se informe mediante un mensaje de error que no se
-- puede. Incluir el código con los borrados de una editorial que no tiene títulos, y otro de una
-- que sí.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TRIGGER prevent_editorial_delete BEFORE DELETE ON Parcial2022.Editoriales
FOR EACH ROW
BEGIN
    DECLARE titulo_count INT;
    SELECT COUNT(*) INTO titulo_count FROM Parcial2022.Titulos WHERE idEditorial = OLD.idEditorial;
    IF titulo_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: No se puede borrar una editorial que tiene títulos asociados.';
    END IF;
END//
DELIMITER ;
	
-- Intenta borrar una editorial que tiene títulos
DELETE FROM Parcial2022.Editoriales WHERE idEditorial = '1389';

-- Intenta borrar una editorial que no tiene títulos
DELETE FROM Parcial2022.Editoriales WHERE idEditorial = '1622';