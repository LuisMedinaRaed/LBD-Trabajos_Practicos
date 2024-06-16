-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2011
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2011

-- ------------------------------------------------------------------------------------------------------- --

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
--  Apartado 1: Creación de la Base de datos y sus Constraints
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP DATABASE IF EXISTS Parcial2011;
CREATE DATABASE Parcial2011;
USE Parcial2011;

--
-- ER/Studio Data Architect SQL Code Generation
-- Project :      DATA MODEL
--
-- Date Created : Sunday, June 16, 2024 02:34:51
-- Target DBMS : MySQL 8.x
--

CREATE TABLE Artistas(
    IdArtista       INT            NOT NULL,
    Apellidos       VARCHAR(30)    NOT NULL,
    Nombres         VARCHAR(30)    NOT NULL,
    Nacionalidad    VARCHAR(30)    NOT NULL,
    PRIMARY KEY (IdArtista),
    INDEX IX_ApellidosNombres(Apellidos, Nombres)
)ENGINE=INNODB
;

CREATE TABLE Estilos(
    IdEstilo    INT            NOT NULL,
    Estilo      VARCHAR(30)    NOT NULL,
    PRIMARY KEY (IdEstilo),
    UNIQUE INDEX UI_Estilo(Estilo)
)ENGINE=INNODB
;

CREATE TABLE Exposiciones(
    IdExposicion         INT             NOT NULL,
    Titulo               VARCHAR(50)     NOT NULL,
    Descripcion          VARCHAR(200),
    FechaInauguracion    DATE            NOT NULL,
    FechaClausura        DATE,
    PRIMARY KEY (IdExposicion),
    INDEX IX_TituloExposiciones(Titulo),
    CHECK (FechaInauguracion < FechaClausura)
)ENGINE=INNODB
;

CREATE TABLE Obras(
    IdObra          INT               NOT NULL,
    IdArtista       INT               NOT NULL,
    IdEstilo        INT               NOT NULL,
    Titulo          VARCHAR(60)       NOT NULL,
    Fecha           DATE              NOT NULL,
    PrecioSalida    DECIMAL(12, 2)    NOT NULL CHECK (PrecioSalida > 0),
    PRIMARY KEY (IdObra, IdArtista),
    INDEX IX_IdArtista(IdArtista),
    INDEX IX_IdEstilo(IdEstilo),
    UNIQUE INDEX UI_IdObra(IdObra),
    INDEX IX_TituloObras(Titulo),
    INDEX IX_FechaObras(Fecha),
    FOREIGN KEY (IdArtista)
    REFERENCES Artistas(IdArtista),
    FOREIGN KEY (IdEstilo)
    REFERENCES Estilos(IdEstilo)
)ENGINE=INNODB
;

CREATE TABLE Muestras(
    IdObra          INT    NOT NULL,
    IdArtista       INT    NOT NULL,
    IdExposicion    INT    NOT NULL,
    PRIMARY KEY (IdObra, IdArtista, IdExposicion),
    INDEX IX_IdExposicion(IdExposicion),
    INDEX IX_IdObraArtista(IdObra, IdArtista),
    FOREIGN KEY (IdExposicion)
    REFERENCES Exposiciones(IdExposicion),
    FOREIGN KEY (IdObra, IdArtista)
    REFERENCES Obras(IdObra, IdArtista)
)ENGINE=INNODB
;

CREATE TABLE Ofertas(
    IdOferta        CHAR(10)          NOT NULL,
    IdObra          INT               NOT NULL,
    IdArtista       INT               NOT NULL,
    IdExposicion    INT               NOT NULL,
    Fecha           DATE,
    Importe         DECIMAL(12, 2)    NOT NULL CHECK (Importe > 0),
    Ofertante       VARCHAR(100)      NOT NULL,
    Vendida         CHAR(1)           NOT NULL CHECK (Vendida IN ('S', 'N')),
    PRIMARY KEY (IdOferta, IdObra, IdArtista, IdExposicion),
    UNIQUE INDEX UI_IdOferta(IdOferta),
    INDEX IX_IdObraArtistaExposicion(IdObra, IdArtista, IdExposicion),
    INDEX IX_FechaOfertas(Fecha),
    INDEX IX_Ofertante(Ofertante),
    FOREIGN KEY (IdObra, IdArtista, IdExposicion)
    REFERENCES Muestras(IdObra, IdArtista, IdExposicion)
)ENGINE=INNODB
;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación del Stored Procedure
-- Crear un SP que dado IdArtista, liste sus obras con su precio de salida, la mejor oferta recibida, si fue
-- vendida o no y la ganancia (Importe – PrecioSalida). Ganancia 0 si no fue vendida. Todos los cuadros,
-- incluso aquellos que no tienen ofertas en cuyo caso la mejor oferta es 0. El formato es (IdObra, Titulo,
-- PrecioSalida, MejorOferta, FueVendido[S|N], Ganancia). Llamarlo gsp_estado_obras
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE gsp_estado_obras(IN IdArtista INT, OUT Message VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        SET Message = CONCAT('Error: ', @errno, ' (', @sqlstate, '): ', @text);
    END;

    IF EXISTS (SELECT 1 FROM Parcial2011.Artistas as A WHERE a.IdArtista = IdArtista) THEN
        SELECT
            Obras.IdObra,
            Obras.Titulo,
            Obras.PrecioSalida,
            COALESCE(MAX(Ofertas.Importe), 0) AS MejorOferta,
            IF(MAX(Ofertas.Vendida) = 'S', 'S', 'N') AS FueVendido,
            IF(MAX(Ofertas.Vendida) = 'S', COALESCE(MAX(Ofertas.Importe), 0) - Obras.PrecioSalida, 0) AS Ganancia
        FROM
            Parcial2011.Obras LEFT JOIN Parcial2011.Ofertas
            ON Obras.IdObra = Ofertas.IdObra AND Obras.IdArtista = Ofertas.IdArtista
        WHERE
            Obras.IdArtista = IdArtista
        GROUP BY
            Obras.IdObra;
        SET Message = 'Consulta ejecutada con éxito.';
    ELSE
        SET Message = 'Error: IdArtista no existe en la tabla Artistas.';
    END IF;
END //
DELIMITER ;

-- Intentar llamar SP con idArtista inexistente
CALL gsp_estado_obras(7, @Message);
SELECT @Message;

-- Intentar llamar SP con idArtista valido
CALL gsp_estado_obras(1, @Message);
SELECT @Message;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación de la vista
-- Realizar una vista que muestre un listado de las ventas realizadas IdObra, Titulo, Estilo, IdArtista,
-- ApellidosArtista, NombresArtista, IdExposicion, TituloExposicion, FechaVenta, Ofertante, Importe. La
-- fecha de venta es Fecha de la tabla Ofertas. Llamarla vista_ventas [20].
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

CREATE VIEW vista_ventas AS
SELECT
    Obras.IdObra,
    Obras.Titulo,
    Estilos.Estilo,
    Artistas.IdArtista,
    Artistas.Apellidos AS ApellidosArtista,
    Artistas.Nombres AS NombresArtista,
    Exposiciones.IdExposicion,
    Exposiciones.Titulo AS TituloExposicion,
    Ofertas.Fecha AS FechaVenta,
    Ofertas.Ofertante,
    Ofertas.Importe
FROM
    Parcial2011.Ofertas
JOIN
    Parcial2011.Obras ON Ofertas.IdObra = Obras.IdObra AND Ofertas.IdArtista = Obras.IdArtista
JOIN
    Parcial2011.Artistas ON Obras.IdArtista = Artistas.IdArtista
JOIN
    Parcial2011.Estilos ON Obras.IdEstilo = Estilos.IdEstilo
JOIN
    Parcial2011.Exposiciones ON Ofertas.IdExposicion = Exposiciones.IdExposicion
WHERE
    Ofertas.Vendida = 'S';

SELECT * FROM vista_ventas;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un SP para dar de alta una obra. Efectuar las comprobaciones y devolver mensajes de error.
-- Llamarlo gsp_alta_obra
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE gsp_alta_obra(IN IdObra INT, IN IdArtista INT, IN IdEstilo INT, IN Titulo VARCHAR(60), IN Fecha DATE, IN PrecioSalida DECIMAL(12,2), OUT Message VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        SET Message = CONCAT('Error: ', @errno, ' (', @sqlstate, '): ', @text);
    END;

    IF IdObra IS NULL THEN
        SET Message = 'Error: IdObra no puede ser NULL.';
    ELSEIF IdArtista IS NULL THEN
        SET Message = 'Error: IdArtista no puede ser NULL.';
    ELSEIF IdEstilo IS NULL THEN
        SET Message = 'Error: IdEstilo no puede ser NULL.';
    ELSEIF Titulo IS NULL THEN
        SET Message = 'Error: Titulo no puede ser NULL.';
    ELSEIF Fecha IS NULL THEN
        SET Message = 'Error: Fecha no puede ser NULL.';
    ELSEIF PrecioSalida IS NULL THEN
        SET Message = 'Error: PrecioSalida no puede ser NULL.';
    ELSEIF PrecioSalida <= 0 THEN
        SET Message = 'Error: PrecioSalida debe ser mayor que 0.';
    ELSEIF EXISTS (SELECT 1 FROM Parcial2011.Obras as o WHERE o.IdObra = IdObra) THEN
        SET Message = 'Error: IdObra ya existe en la tabla Obras.';
    ELSEIF NOT EXISTS (SELECT 1 FROM Parcial2011.Artistas as a WHERE a.IdArtista = IdArtista) THEN
        SET Message = 'Error: IdArtista no existe en la tabla Artistas.';
    ELSEIF NOT EXISTS (SELECT 1 FROM Parcial2011.Estilos as e WHERE e.IdEstilo = IdEstilo) THEN
        SET Message = 'Error: IdEstilo no existe en la tabla Estilos.';
    ELSE
        INSERT INTO Parcial2011.Obras (IdObra, IdArtista, IdEstilo, Titulo, Fecha, PrecioSalida)
        VALUES (IdObra, IdArtista, IdEstilo, Titulo, Fecha, PrecioSalida);
        SET Message = 'Obra insertada con éxito.';
    END IF;
END //
DELIMITER ;

-- Intentar insertar una obra con IdObra NULL
CALL gsp_alta_obra(NULL, 1, 1, 'Obra de prueba', '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con IdArtista NULL
CALL gsp_alta_obra(1, NULL, 1, 'Obra de prueba', '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con IdEstilo NULL
CALL gsp_alta_obra(1, 1, NULL, 'Obra de prueba', '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con Titulo NULL
CALL gsp_alta_obra(1, 1, 1, NULL, '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con Fecha NULL
CALL gsp_alta_obra(1, 1, 1, 'Obra de prueba', NULL, 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con PrecioSalida NULL
CALL gsp_alta_obra(1, 1, 1, 'Obra de prueba', '2022-01-01', NULL, @Message);
SELECT @Message;

-- Intentar insertar una obra con PrecioSalida menor o igual a 0
CALL gsp_alta_obra(1, 1, 1, 'Obra de prueba', '2022-01-01', 0, @Message);
SELECT @Message;

-- Intentar insertar una obra con IdObra duplicado
CALL gsp_alta_obra(1, 1, 1, 'Obra de prueba', '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con IdArtista que no existe
CALL gsp_alta_obra(31, 9999, 1, 'Obra de prueba', '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con IdEstilo que no existe
CALL gsp_alta_obra(31, 1, 9999, 'Obra de prueba', '2022-01-01', 1000.00, @Message);
SELECT @Message;

-- Intentar insertar una obra con todos los parámetros correctos
CALL gsp_alta_obra(31, 6, 3, 'Obra exitosa', '2022-01-01', 1000.00, @Message);
SELECT @Message;
