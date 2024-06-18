-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2021
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2021

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
-- Date Created : Monday, June 17, 2024 21:07:21
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2021d;
CREATE DATABASE IF NOT EXISTS Parcial2021d;
USE Parcial2021d;

DROP TABLE IF EXISTS Domicilios;

CREATE TABLE IF NOT EXISTS Domicilios(
    idDomicilio     INT            NOT NULL,
    calleYNumero    VARCHAR(60)    NOT NULL,
    codigoPostal    VARCHAR(10),
    telefono        VARCHAR(25)    NOT NULL,
    municipio       VARCHAR(25)    NOT NULL,
    PRIMARY KEY (idDomicilio),
    UNIQUE INDEX UI_calleYNumeroDomicilios(calleYNumero)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Clientes;

CREATE TABLE IF NOT EXISTS Clientes(
    idCliente      INT            NOT NULL,
    apellidos      VARCHAR(50)    NOT NULL,
    nombres        VARCHAR(50)    NOT NULL,
    correo         VARCHAR(50),
    estado         CHAR(1)        NOT NULL CHECK (estado IN ('E', 'D')) DEFAULT 'E',
    idDomicilio    INT            NOT NULL,
    PRIMARY KEY (idCliente),
    UNIQUE INDEX UI_correoClientes(correo),
    INDEX IX_idDomicilioClientes(idDomicilio),
    FOREIGN KEY (idDomicilio)
    REFERENCES Domicilios(idDomicilio)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Tiendas;

CREATE TABLE IF NOT EXISTS Tiendas(
    idTienda       INT    NOT NULL,
    idDomicilio    INT    NOT NULL,
    PRIMARY KEY (idTienda),
    INDEX IX_idDomicilioTiendas(idDomicilio),
    FOREIGN KEY (idDomicilio)
    REFERENCES Domicilios(idDomicilio)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Peliculas;

CREATE TABLE IF NOT EXISTS Peliculas(
    idPelicula       INT             NOT NULL,
    titulo           VARCHAR(128)    NOT NULL,
    clasificacion    VARCHAR(5)      NOT NULL CHECK (clasificacion IN ('G', 'PG', 'PG-13', 'R', 'NC-17')) DEFAULT 'G',
    estreno          INT,
    duracion         INT,
    PRIMARY KEY (idPelicula),
    UNIQUE INDEX UI_tituloPeliculas(titulo)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Registros;

CREATE TABLE IF NOT EXISTS Registros(
    idRegistro    INT    NOT NULL,
    idTienda      INT    NOT NULL,
    idPelicula    INT    NOT NULL,
    PRIMARY KEY (idRegistro),
    INDEX IX_idTiendaRegistros(idTienda),
    INDEX IX_idPeliculaRegistros(idPelicula),
    FOREIGN KEY (idTienda)
    REFERENCES Tiendas(idTienda),
    FOREIGN KEY (idPelicula)
    REFERENCES Peliculas(idPelicula)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Alquileres;

CREATE TABLE IF NOT EXISTS Alquileres(
    idAlquiler         INT         NOT NULL,
    fechaAlquiler      DATETIME    NOT NULL,
    fechaDevolucion    DATETIME,
    idCliente          INT         NOT NULL,
    idRegistro         INT         NOT NULL,
    PRIMARY KEY (idAlquiler),
    INDEX IX_idClienteAlquileres(idCliente),
    INDEX IX_idRegistroAlquileres(idRegistro),
    FOREIGN KEY (idCliente)
    REFERENCES Clientes(idCliente),
    FOREIGN KEY (idRegistro)
    REFERENCES Registros(idRegistro)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Pagos;

CREATE TABLE IF NOT EXISTS Pagos(
    idPago        INT              NOT NULL,
    idCliente     INT              NOT NULL,
    idAlquiler    INT              NOT NULL,
    importe       DECIMAL(5, 2)    NOT NULL,
    fecha         DATETIME         NOT NULL,
    PRIMARY KEY (idPago),
    INDEX IX_idClientePagos(idCliente),
    INDEX IX_idAlquilerPagos(idAlquiler),
    FOREIGN KEY (idCliente)
    REFERENCES Clientes(idCliente),
    FOREIGN KEY (idAlquiler)
    REFERENCES Alquileres(idAlquiler)
)ENGINE=INNODB
;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear una vista llamada VRankingAlquileres que muestre un ranking con los 10 clientes
-- que más cantidad de películas hayan alquilado. Por cada cliente se deberá mostrar su
-- código, apellido y nombre (formato: apellido, nombre) y la cantidad total de alquileres. La
-- salida deberá estar ordenada descendentemente según la cantidad de alquileres, y para el
-- caso de 2 clientes con la misma cantidad de alquileres, alfabéticamente según apellido y
-- nombre. Incluir el código con la consulta a la vista.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS VRankingAlquileres;

DROP VIEW IF EXISTS VRankingAlquileres;

CREATE VIEW VRankingAlquileres AS
SELECT
    C.idCliente AS 'idCliente',
    CONCAT(
        UPPER(SUBSTRING(C.apellidos, 1, 1)),
        LOWER(SUBSTRING(C.apellidos, 2)),
        ', ',
        UPPER(SUBSTRING(C.nombres, 1, 1)),
        LOWER(SUBSTRING(C.nombres, 2))
    ) AS 'Cliente',
    COUNT(A.idAlquiler) AS 'Cantidad'
FROM
    Alquileres A
INNER JOIN
    Clientes C ON A.idCliente = C.idCliente
GROUP BY
    C.idCliente,
    C.apellidos,
    C.nombres
ORDER BY
    COUNT(A.idAlquiler) DESC,
    C.apellidos ASC,
    C.nombres ASC
LIMIT 10;

SELECT * FROM VRankingAlquileres;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado BorrarPelicula para borrar una película,
-- incluyendo el control de errores lógicos y mensajes de error necesarios (implementar la
-- lógica del manejo de errores empleando parámetros de salida). Incluir el código con la
-- llamada al procedimiento probando todos los casos con datos incorrectos y uno con datos
-- correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminar el procedimiento almacenado si ya existe
DROP PROCEDURE IF EXISTS BorrarPelicula;

-- Crear el procedimiento almacenado
DELIMITER //
CREATE PROCEDURE BorrarPelicula(IN p_idPelicula INT, OUT p_mensaje VARCHAR(255))
proc: BEGIN
    DECLARE v_referenced INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;

    -- Verificar si la película existe
    SELECT COUNT(*) INTO v_exists FROM Peliculas WHERE idPelicula = p_idPelicula;
    IF v_exists = 0 THEN
        SET p_mensaje = 'Error: La película con el ID proporcionado no existe.';
        LEAVE proc;
    END IF;

    -- Verificar si la película está siendo referenciada en la tabla Registros
    SELECT COUNT(*) INTO v_referenced FROM Registros WHERE idPelicula = p_idPelicula;
    IF v_referenced > 0 THEN
        SET p_mensaje = 'Error: La película está siendo referenciada en la tabla Registros.';
        LEAVE proc;
    END IF;

    -- Borrar la película
    DELETE FROM Peliculas WHERE idPelicula = p_idPelicula;
    SET p_mensaje = 'La película ha sido borrada exitosamente.';
END //
DELIMITER ;

-- Prueba para el mensaje de error "Error: La película con el ID proporcionado no existe."
CALL BorrarPelicula(1005, @mensaje);
SELECT @mensaje;

-- Prueba para el mensaje de error "Error: La película está siendo referenciada en la tabla Registros."
CALL BorrarPelicula(1, @mensaje);
SELECT @mensaje;

INSERT INTO Peliculas (idPelicula, titulo, clasificacion, estreno, duracion)
VALUES (1001, 'THE MATRIX', 'R', 1999, 136);

-- Prueba para el mensaje "La película ha sido borrada exitosamente."
CALL BorrarPelicula(1001, @mensaje);
SELECT @mensaje;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado TotalAlquileres que reciba el código de
-- un cliente y muestre por cada película la cantidad de veces que la alquiló. Se deberá
-- mostrar el código de la película, su título y la cantidad de veces que fue alquilada. Al final
-- del listado deberá mostrar también la cantidad total de alquileres efectuados. La salida
-- deberá estar ordenada alfabéticamente según el título de la película. Incluir en el código la
-- llamada al procedimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminar el procedimiento almacenado si ya existe
DROP PROCEDURE IF EXISTS TotalAlquileres;

-- Crear el procedimiento almacenado
DELIMITER //
CREATE PROCEDURE TotalAlquileres(IN p_idCliente INT, OUT p_mensaje VARCHAR(255))
proc: BEGIN
    -- Declarar la variable para almacenar el total de alquileres
    DECLARE totalAlquileres INT;
    DECLARE v_exists INT DEFAULT 0;

    -- Verificar si el cliente existe
    SELECT COUNT(*) INTO v_exists FROM Clientes WHERE idCliente = p_idCliente;
    IF v_exists = 0 THEN
        SET p_mensaje = 'Error: El cliente con el ID proporcionado no existe.';
        LEAVE proc;
    END IF;

    -- Crear una tabla temporal para almacenar los resultados
    CREATE TEMPORARY TABLE IF NOT EXISTS Resultados (
        idPelicula INT,
        Titulo VARCHAR(128),
        Cantidad INT
    );

    -- Obtener la cantidad de veces que cada película fue alquilada por el cliente
    INSERT INTO Resultados
    SELECT
        P.idPelicula,
        P.titulo,
        COUNT(A.idAlquiler)
    FROM
        Alquileres A
    INNER JOIN
        Registros R ON A.idRegistro = R.idRegistro
    INNER JOIN
        Peliculas P ON R.idPelicula = P.idPelicula
    WHERE
        A.idCliente = p_idCliente
    GROUP BY
        P.idPelicula, P.titulo
    ORDER BY
        P.titulo;

    -- Obtener el total de alquileres del cliente
    SELECT
        COUNT(A.idAlquiler) INTO totalAlquileres
    FROM
        Alquileres A
    WHERE
        A.idCliente = p_idCliente;

    -- Insertar el total de alquileres en la tabla temporal
    INSERT INTO Resultados VALUES (NULL, NULL, totalAlquileres);

    -- Mostrar los resultados
    SELECT * FROM Resultados;

    -- Eliminar la tabla temporal
    DROP TABLE Resultados;

    SET p_mensaje = 'El procedimiento se ejecutó correctamente.';
END proc //
DELIMITER ;

-- Prueba para el mensaje de error "Error: El cliente con el ID proporcionado no existe."
CALL TotalAlquileres(999, @mensaje);
SELECT @mensaje;

-- Prueba para el mensaje "El procedimiento se ejecutó correctamente."
CALL TotalAlquileres(1, @mensaje);
SELECT @mensaje;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Utilizando triggers, implementar la lógica para que en caso que se quiera crear una
-- película ya existente según código y/o título se informe mediante un mensaje de error que
-- no se puede. Incluir el código con las creaciones de películas existentes según código y/o
-- título y otro inexistente.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminar el trigger si ya existe
DROP TRIGGER IF EXISTS VerificarPeliculaExistente;

-- Crear el trigger
DELIMITER //
CREATE TRIGGER VerificarPeliculaExistente
BEFORE INSERT ON Peliculas
FOR EACH ROW
BEGIN
    DECLARE existe INT;

    -- Verificar si existe una película con el mismo código
    SELECT COUNT(*) INTO existe FROM Peliculas WHERE idPelicula = NEW.idPelicula;
    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Ya existe una película con el mismo código.';
    END IF;

    -- Verificar si existe una película con el mismo título
    SELECT COUNT(*) INTO existe FROM Peliculas WHERE titulo = NEW.titulo;
    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Ya existe una película con el mismo título.';
    END IF;
END //
DELIMITER ;

-- Intentar insertar una película existente según código
INSERT INTO Peliculas (idPelicula, titulo, clasificacion, estreno, duracion)
VALUES (1, 'TITULO DE LA PELICULA', 'PG', 2022, 120);

-- Intentar insertar una película existente según título
INSERT INTO Peliculas (idPelicula, titulo, clasificacion, estreno, duracion)
VALUES (1002, 'ZORRO ARK', 'PG', 2022, 120);

-- Intentar insertar una película inexistente
INSERT INTO Peliculas (idPelicula, titulo, clasificacion, estreno, duracion)
VALUES (1003, 'TITULO DE LA PELICULA NUEVA', 'PG', 2022, 120);
