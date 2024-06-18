-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2021
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28
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
-- Date Created : Monday, June 17, 2024 17:50:11
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2021B;
CREATE DATABASE IF NOT EXISTS Parcial2021B;
USE Parcial2021B;

DROP TABLE IF EXISTS Actores;

CREATE TABLE IF NOT EXISTS Actores(
    idAutor      CHAR(10)       NOT NULL,
    nombres      VARCHAR(45)    NOT NULL,
    apellidos    VARCHAR(45),
    PRIMARY KEY (idAutor)
)ENGINE=INNODB
;


DROP TABLE IF EXISTS Peliculas;

CREATE TABLE IF NOT EXISTS Peliculas(
    idPelicula       INT             NOT NULL,
    titulo           VARCHAR(128)    NOT NULL,
    estreno          INT,
    duracion         INT,
    clasificacion    VARCHAR(10)     NOT NULL CHECK (clasificacion IN ('G', 'PG', 'PG-13', 'R', 'NC-17')) DEFAULT 'G',
    PRIMARY KEY (idPelicula),
    UNIQUE INDEX UI_titulosPeliculas(titulo)
)ENGINE=INNODB
;

SHOW INDEX FROM Peliculas;


DROP TABLE IF EXISTS ActoresDePeliculas;

-- En la tabla ActoresDePeliculas, se crean índices para las columnas idPelicula e idAutor.
-- Sin embargo, estas columnas también forman parte de la clave primaria compuesta (idPelicula, idAutor),
-- por lo que MySQL automáticamente crea índices para ellas.
-- Por lo tanto, la creación explícita de estos índices es innecesaria y puede ser omitida.
CREATE TABLE IF NOT EXISTS ActoresDePeliculas(
    idPelicula    INT         NOT NULL,
    idAutor       CHAR(10)    NOT NULL,
    PRIMARY KEY (idPelicula, idAutor),
    INDEX IX_idPelicula(idPelicula),
    INDEX IX_idAutor(idAutor),
    FOREIGN KEY (idPelicula)
    REFERENCES Peliculas(idPelicula),
    FOREIGN KEY (idAutor)
    REFERENCES Actores(idAutor)
)ENGINE=INNODB
;

SHOW INDEX FROM ActoresDePeliculas;


DROP TABLE IF EXISTS Direcciones;

CREATE TABLE IF NOT EXISTS Direcciones(
    idDireccion     INT            NOT NULL,
    calleYNumero    VARCHAR(50)    NOT NULL,
    municipio       VARCHAR(20),
    codigoPostal    VARCHAR(10),
    telefono        VARCHAR(20)    NOT NULL,
    PRIMARY KEY (idDireccion),
    UNIQUE INDEX UI_calleYNumeroDirecciones(calleYNumero)
)ENGINE=INNODB
;

SHOW INDEX FROM Direcciones;


DROP TABLE IF EXISTS Empleados;

    CREATE TABLE IF NOT EXISTS Empleados(
    idEmpleado     INT            NOT NULL,
    nombres        VARCHAR(45)    NOT NULL,
    apellidos      VARCHAR(45)    NOT NULL,
    idDireccion    INT            NOT NULL,
    correo         VARCHAR(50),
    estado         VARCHAR(1)     NOT NULL CHECK (estado IN ('E', 'D')) DEFAULT 'E',
    PRIMARY KEY (idEmpleado),
    UNIQUE INDEX UI_correoEmpleados(correo),
    INDEX IX_idDireccionEmpleados(idDireccion),
    FOREIGN KEY (idDireccion)
    REFERENCES Direcciones(idDireccion)
)ENGINE=INNODB;

SHOW INDEX FROM Empleados;

DROP TABLE IF EXISTS Sucursales;

CREATE TABLE IF NOT EXISTS Sucursales(
    idSucursal     CHAR(10)    NOT NULL,
    idGerente      INT         NOT NULL,
    idDireccion    INT         NOT NULL,
    PRIMARY KEY (idSucursal),
    INDEX IX_idGerenteSucursales(idGerente),
    INDEX IX_idDireccionSucursales(idDireccion),
    FOREIGN KEY (idGerente)
    REFERENCES Empleados(idEmpleado),
    FOREIGN KEY (idDireccion)
    REFERENCES Direcciones(idDireccion)
)ENGINE=INNODB
;

SHOW INDEX FROM Sucursales;

DROP TABLE IF EXISTS Inventario;

CREATE TABLE IF NOT EXISTS Inventario(
    idInventario    INT         NOT NULL,
    idPelicula      INT         NOT NULL,
    idSucursal      CHAR(10)    NOT NULL,
    PRIMARY KEY (idInventario),
    INDEX IX_idPeliculaInventario(idPelicula),
    INDEX IX_idSucursalInventario(idSucursal),
    FOREIGN KEY (idPelicula)
    REFERENCES Peliculas(idPelicula),
    FOREIGN KEY (idSucursal)
    REFERENCES Sucursales(idSucursal)
)ENGINE=INNODB
;

SHOW INDEX FROM Inventario;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear una vista llamada VPeliculasEnSucursales que muestre el título de las películas,
-- el código de la sucursal donde se encuentra, la calle y número de la sucursal y los datos del
-- gerente de la sucursal (formato: “apellido, nombre”). La salida deberá estar ordenada
-- alfabéticamente según el título de las películas. En caso que una misma película aparezca
-- varias veces en una misma sucursal, en la salida deberá aparecer una única vez. Incluir el
-- código con la llamada a la vista
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS VPeliculasEnSucursales;

CREATE VIEW VPeliculasEnSucursales AS
SELECT
    P.titulo AS Titulo,
    I.idSucursal AS idSucursal,
    D.calleYNumero AS 'Calle y Numero',
    CONCAT(E.apellidos, ', ', E.nombres) AS Gerente
FROM
    Peliculas P
INNER JOIN
    Inventario I ON P.idPelicula = I.idPelicula
INNER JOIN
    Sucursales S ON I.idSucursal = S.idSucursal
INNER JOIN
    Direcciones D ON S.idDireccion = D.idDireccion
INNER JOIN
    Empleados E ON S.idGerente = E.idEmpleado
GROUP BY
    P.titulo, I.idSucursal
ORDER BY
    P.titulo;

SELECT * FROM VPeliculasEnSucursales;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado ModificarPelicula para modificar una
-- incluyendo el control de errores lógicos y mensajes de error necesarios
-- (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
-- código con la llamada al procedimiento probando todos los casos con datos incorrectos y
-- uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS ModificarPelicula;

DELIMITER //
CREATE PROCEDURE ModificarPelicula(IN v_idPelicula INT, IN v_nuevoTitulo VARCHAR(128), IN v_nuevoEstreno INT, IN v_nuevaDuracion INT, IN v_nuevaClasificacion VARCHAR(10), OUT v_mensajeError VARCHAR(255))
proc_label: BEGIN
    DECLARE v_peliculaExistente INT;
    DECLARE v_tituloExistente INT;
    DECLARE v_clasificacionValida INT;

    SELECT COUNT(*) INTO v_peliculaExistente FROM Peliculas WHERE idPelicula = v_idPelicula;
    SELECT COUNT(*) INTO v_tituloExistente FROM Peliculas WHERE titulo = v_nuevoTitulo AND idPelicula != v_idPelicula;
    SET v_clasificacionValida = CASE WHEN v_nuevaClasificacion IN ('G', 'PG', 'PG-13', 'R', 'NC-17') THEN 1 ELSE 0 END;

    IF v_peliculaExistente = 0 THEN
        SET v_mensajeError = 'Error: La pelicula no existe.';
        LEAVE proc_label;
    END IF;

    IF v_tituloExistente > 0 THEN
        SET v_mensajeError = 'Error: El titulo de la pelicula ya existe.';
        LEAVE proc_label;
    END IF;

    IF v_clasificacionValida = 0 AND v_nuevaClasificacion IS NOT NULL THEN
        SET v_mensajeError = 'Error: Clasificacion de pelicula invalida.';
        LEAVE proc_label;
    END IF;

    UPDATE Peliculas
    SET titulo = IF(v_nuevoTitulo IS NULL, titulo, v_nuevoTitulo),
        estreno = IF(v_nuevoEstreno IS NULL, estreno, v_nuevoEstreno),
        duracion = IF(v_nuevaDuracion IS NULL, duracion, v_nuevaDuracion),
        clasificacion = IF(v_nuevaClasificacion IS NULL, clasificacion, v_nuevaClasificacion)
    WHERE idPelicula = v_idPelicula;

    SET v_mensajeError = 'Pelicula actualizada exitosamente.';
END //
DELIMITER ;

-- Caso 1: La película no existe
-- Intentamos actualizar una película con un id que no existe en la base de datos.
-- Solo se intenta cambiar el título, pero la película no existe, por lo que se espera el mensaje de error 'Error: La pelicula no existe.'
CALL ModificarPelicula(1001, 'Nuevo Titulo', NULL, NULL, NULL, @mensajeError);
SELECT @mensajeError;

-- Caso 2: El título de la película ya existe
-- Intentamos actualizar el título de una película a un título que ya existe en la base de datos.
-- Solo se intenta cambiar el título, pero el título ya existe, por lo que se espera el mensaje de error 'Error: El titulo de la pelicula ya existe.'
CALL ModificarPelicula(1, 'ZORRO ARK', NULL, NULL, NULL, @mensajeError);
SELECT @mensajeError;

-- Caso 3: Clasificación de película inválida
-- Intentamos actualizar la clasificación de una película a una clasificación que no es válida.
-- Solo se intenta cambiar la clasificación, pero la clasificación no es válida, por lo que se espera el mensaje de error 'Error: Clasificacion de pelicula invalida.'
CALL ModificarPelicula(1, NULL, NULL, NULL, 'O', @mensajeError);
SELECT @mensajeError;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado BuscarPeliculasPorAutor que reciba el
-- código de un actor y muestre sucursal por sucursal, película por película, la cantidad con el
-- mismo. Por cada película del autor especificado se deberá mostrar su código y título, el
-- código de la sucursal, la cantidad y la calle y número de la sucursal. La salida deberá estar
-- ordenada alfabéticamente según el título de las películas. Incluir en el código la llamada al
-- procedimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS BuscarPeliculasPorAutor;

DELIMITER //
CREATE PROCEDURE BuscarPeliculasPorAutor(IN v_idAutor CHAR(10))
BEGIN
    SELECT
        P.idPelicula AS 'Codigo Pelicula',
        P.titulo AS 'Titulo Pelicula',
        I.idSucursal AS 'Codigo Sucursal',
        COUNT(*) AS 'Cantidad',
        D.calleYNumero AS 'Calle y Numero'
    FROM
        ActoresDePeliculas ADP
    JOIN
        Peliculas P ON ADP.idPelicula = P.idPelicula
    JOIN
        Inventario I ON P.idPelicula = I.idPelicula
    JOIN
        Sucursales S ON I.idSucursal = S.idSucursal
    JOIN
        Direcciones D ON S.idDireccion = D.idDireccion
    WHERE
        ADP.idAutor = v_idAutor
    GROUP BY
        P.idPelicula, I.idSucursal
    ORDER BY
        P.titulo;
END //
DELIMITER ;

CALL BuscarPeliculasPorAutor('100');

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Realizar un trigger llamado AuditarCargaHoraria el cual se dispare luego de modificar la carga horaria
-- por un valor menor o igual a cero, los datos se deben guardar en la tabla auditoria guardando el valor
-- original de la carga horaria, la materia y el plan de estudio, el usuario la fecha en que se realizó
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE TRIGGER VerificarDireccionUnica BEFORE UPDATE ON Direcciones
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Direcciones WHERE calleYNumero = NEW.calleYNumero AND idDireccion != NEW.idDireccion) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La direccion ya existe.';
    END IF;
END //
DELIMITER ;

-- Caso 1: Intentamos actualizar la calle y número a un valor que ya existe en la tabla.
-- Se espera que se lance un error.
UPDATE Direcciones SET calleYNumero = '1121 Loja Avenue' WHERE idDireccion = 1;

-- Caso 2: Intentamos actualizar la calle y número a un valor que no existe en la tabla.
-- Se espera que la actualización sea exitosa.
UPDATE Direcciones SET calleYNumero = 'Calle Nueva 456' WHERE idDireccion = 1;
