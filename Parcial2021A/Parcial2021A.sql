-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2021A
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 11 Home Single Language 23H2 - 22631.3737
-- Motor y Versión: MySQL Server 8.0.37
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2021A
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
-- Date Created : Monday, June 17, 2024 03:34:19
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2021A;
CREATE DATABASE IF NOT EXISTS Parcial2021A;
USE Parcial2021A;

DROP TABLE IF EXISTS Direcciones;

CREATE TABLE IF NOT EXISTS Direcciones(
    idDireccion     INT            NOT NULL,
    calleYNumero    VARCHAR(50)    NOT NULL,
    municipio         VARCHAR(20)    NOT NULL,
    codigoPostal    VARCHAR(10),
    telefono        VARCHAR(20)    NOT NULL,
    PRIMARY KEY (idDireccion),
    UNIQUE INDEX UI_calleYNumeroDireccion(calleYNumero)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Generos;

CREATE TABLE IF NOT EXISTS Generos(
    idGenero    CHAR(10)       NOT NULL,
    nombre      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (idGenero),
    UNIQUE INDEX UI_nombreGenero(nombre)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Peliculas;

CREATE TABLE IF NOT EXISTS Peliculas(
    idPelicula       INT             NOT NULL,
    titulo           VARCHAR(128)    NOT NULL,
    estreno          INT,
    duracion         INT,
    clasificacion    VARCHAR(10)     NOT NULL DEFAULT 'G' CHECK (clasificacion IN ('G', 'PG', 'PG-13', 'R', 'NC-17')),
    PRIMARY KEY (idPelicula),
    UNIQUE INDEX UI_tituloPelicula(titulo)
)ENGINE=INNODB;

DROP TABLE IF EXISTS GenerosDePeliculas;

CREATE TABLE IF NOT EXISTS GenerosDePeliculas(
    idPelicula    INT         NOT NULL,
    idGenero      CHAR(10)    NOT NULL,
    PRIMARY KEY (idPelicula, idGenero),
    INDEX IX_idPeliculaGenerosDePeliculas(idPelicula),
    INDEX IX_idGeneroGenerosDePeliculas(idGenero),
    FOREIGN KEY (idPelicula)
    REFERENCES Peliculas(idPelicula),
    FOREIGN KEY (idGenero)
    REFERENCES Generos(idGenero)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Personal;

CREATE TABLE IF NOT EXISTS Personal(
    idPersonal     INT            NOT NULL,
    nombres        VARCHAR(45)    NOT NULL,
    apellidos      VARCHAR(45)    NOT NULL,
    idDireccion    INT            NOT NULL,
    correo         VARCHAR(50),
    estado         CHAR(1)        NOT NULL DEFAULT 'E' CHECK (estado IN ('E', 'D')),
    PRIMARY KEY (idPersonal),
    UNIQUE INDEX UI_correoPersonal(correo),
    INDEX IX_idDireccionPersonal(idDireccion),
    FOREIGN KEY (idDireccion)
    REFERENCES Direcciones(idDireccion)
)ENGINE=INNODB;

DROP TABLE IF EXISTS Sucursales;

CREATE TABLE IF NOT EXISTS Sucursales(
    idSucursal     CHAR(10)    NOT NULL,
    idGerente      INT         NOT NULL,
    idDireccion    INT         NOT NULL,
    PRIMARY KEY (idSucursal),
    INDEX IX_idGerenteSucursales(idGerente),
    INDEX IX_idDireccionSucursales(idDireccion),
    FOREIGN KEY (idGerente)
    REFERENCES Personal(idPersonal),
    FOREIGN KEY (idDireccion)
    REFERENCES Direcciones(idDireccion)
)ENGINE=INNODB
;

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

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear una vista llamada VCantidadPeliculas que muestre por cada película su código,
-- título y la cantidad total entre las distintas sucursales. La salida deberá estar ordenada
-- alfabéticamente según el título de las películas. Incluir el código con la consulta a la vista.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS VCantidadPeliculas;

CREATE VIEW VCantidadPeliculas AS
SELECT
    p.idPelicula AS Codigo,
    p.titulo AS Titulo,
    COUNT(i.idPelicula) AS CantidadTotal
FROM
    Peliculas p
JOIN
    Inventario i ON p.idPelicula = i.idPelicula
GROUP BY
    p.idPelicula, p.titulo
ORDER BY
    p.titulo;

SELECT * FROM VCantidadPeliculas;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado NuevaDireccion para dar de alta una
-- dirección, incluyendo el control de errores lógicos y mensajes de error necesarios
-- (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
-- código con la llamada al procedimiento probando todos los casos con datos incorrectos y
-- uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS NuevaDireccion;

DELIMITER //
CREATE PROCEDURE NuevaDireccion(
    IN p_idDireccion INT,
    IN p_calleYNumero VARCHAR(50),
    IN p_municipio VARCHAR(20),
    IN p_codigoPostal VARCHAR(10),
    IN p_telefono VARCHAR(20),
    OUT p_error_message VARCHAR(255)
)
proc_label: BEGIN
    -- Verificar si los datos son válidos
    IF p_idDireccion <= 0 THEN
        SET p_error_message = 'Error: idDireccion debe ser un número positivo.';
        LEAVE proc_label;
    END IF;

    IF p_calleYNumero IS NULL OR p_calleYNumero = '' THEN
        SET p_error_message = 'Error: calleYNumero no puede estar vacío o nulo.';
        LEAVE proc_label;
    END IF;

    IF p_municipio IS NULL OR p_municipio = '' THEN
        SET p_error_message = 'Error: municipio no puede estar vacío o nulo.';
        LEAVE proc_label;
    END IF;

    IF p_telefono IS NULL OR p_telefono = '' THEN
        SET p_error_message = 'Error: telefono no puede estar vacío o nulo.';
        LEAVE proc_label;
    END IF;

    -- Verificar si idDireccion ya existe
    IF EXISTS (SELECT 1 FROM Direcciones WHERE idDireccion = p_idDireccion) THEN
        SET p_error_message = 'Error: idDireccion ya existe.';
        LEAVE proc_label;
    END IF;

    -- Verificar si calleYNumero ya existe
    IF EXISTS (SELECT 1 FROM Direcciones WHERE calleYNumero = p_calleYNumero) THEN
        SET p_error_message = 'Error: calleYNumero ya existe.';
        LEAVE proc_label;
    END IF;

    -- Insertar nueva dirección
    INSERT INTO Direcciones(idDireccion, calleYNumero, municipio, codigoPostal, telefono)
    VALUES (p_idDireccion, p_calleYNumero, p_municipio, p_codigoPostal, p_telefono);
    SET p_error_message = 'Éxito: Nueva dirección añadida.';
END //
DELIMITER ;

-- Prueba con idDireccion negativo
-- Esto debería dar un error ya que idDireccion debe ser un número positivo
CALL NuevaDireccion(-1, '123 Main St', 'City', '12345', '123-456-7890', @error_message);
SELECT @error_message;

-- Prueba con calleYNumero vacío
-- Esto debería dar un error ya que calleYNumero no puede estar vacío o nulo
CALL NuevaDireccion(1, '', 'City', '12345', '123-456-7890', @error_message);
SELECT @error_message;

-- Prueba con municipio nulo
-- Esto debería dar un error ya que municipio no puede estar vacío o nulo
CALL NuevaDireccion(1, '123 Main St', NULL, '12345', '123-456-7890', @error_message);
SELECT @error_message;

-- Prueba con telefono vacío
-- Esto debería dar un error ya que telefono no puede estar vacío o nulo
CALL NuevaDireccion(1, '123 Main St', 'City', '12345', '', @error_message);
SELECT @error_message;

-- Prueba con idDireccion duplicado
-- Primero insertamos una dirección válida
CALL NuevaDireccion(606, '123 Main St', 'City', '12345', '123-456-7890', @error_message);
SELECT @error_message;

-- Luego intentamos insertar otra dirección con el mismo idDireccion
-- Esto debería dar un error ya que idDireccion ya existe
CALL NuevaDireccion(606, '456 Oak St', 'Town', '67890', '123-456-7890', @error_message);
SELECT @error_message;

-- Intentamos insertar otra dirección con el mismo calleYNumero
-- Esto debería dar un error ya que calleYNumero ya existe
CALL NuevaDireccion(607, '123 Main St', 'Metropolis', '33445', '555-666-7777', @error_message);
SELECT @error_message;

-- Prueba con datos correctos
-- Esto debería tener éxito ya que todos los datos son válidos y únicos
CALL NuevaDireccion(607, '789 Pine St', 'Metropolis', '33445', '555-666-7777', @error_message);
SELECT @error_message;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado BuscarPeliculasPorGenero que reciba
-- el código de un género y muestre sucursal por sucursal, película por película, la cantidad
-- con el mismo. Por cada película del género especificado se deberá mostrar su código y
-- título, el código de la sucursal, la cantidad y la calle y número de la sucursal. La salida
-- deberá estar ordenada alfabéticamente según el título de las películas. Incluir en el código
-- la llamada al procedimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS BuscarPeliculasPorGenero;

DELIMITER //
CREATE PROCEDURE BuscarPeliculasPorGenero(IN p_idGenero CHAR(10))
BEGIN
    SELECT
        p.idPelicula AS CodigoPelicula,
        p.titulo AS TituloPelicula,
        s.idSucursal AS CodigoSucursal,
        COUNT(i.idPelicula) AS Cantidad,
        d.calleYNumero AS DireccionSucursal
    FROM
        Peliculas p
    JOIN
        GenerosDePeliculas g ON p.idPelicula = g.idPelicula
    JOIN
        Inventario i ON p.idPelicula = i.idPelicula
    JOIN
        Sucursales s ON i.idSucursal = s.idSucursal
    JOIN
        Direcciones d ON s.idDireccion = d.idDireccion
    WHERE
        g.idGenero = p_idGenero
    GROUP BY
        p.idPelicula, p.titulo, s.idSucursal, d.calleYNumero
    ORDER BY
        p.titulo;
END //
DELIMITER ;

CALL BuscarPeliculasPorGenero('6');

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Utilizando triggers, implementar la lógica para que en caso que se quiera borrar una
-- dirección referenciada por una sucursal o un personal se informe mediante un mensaje de
-- error que no se puede. Incluir el código con los borrados de una dirección para la cual no
-- hay sucursales ni personal, y otro para la que sí.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS PreventDeleteOnReferencedAddress;

DELIMITER //
CREATE TRIGGER PreventDeleteOnReferencedAddress
BEFORE DELETE ON Direcciones
FOR EACH ROW
BEGIN
    DECLARE sucursal_count INT;
    DECLARE personal_count INT;

    SELECT COUNT(*) INTO sucursal_count
    FROM Sucursales
    WHERE idDireccion = OLD.idDireccion;

    SELECT COUNT(*) INTO personal_count
    FROM Personal
    WHERE idDireccion = OLD.idDireccion;

    IF sucursal_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar una dirección que está siendo referenciada por una sucursal.';
    ELSEIF personal_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede eliminar una dirección que está siendo referenciada por un personal.';
    END IF;
END //
DELIMITER ;

-- Obtener una dirección que no está siendo referenciada
SELECT idDireccion
FROM Direcciones d
WHERE NOT EXISTS (SELECT 1 FROM Sucursales s WHERE s.idDireccion = d.idDireccion)
AND NOT EXISTS (SELECT 1 FROM Personal p WHERE p.idDireccion = d.idDireccion)
LIMIT 1;

-- Obtener una dirección que está siendo referenciada solo por una sucursal
SELECT idDireccion
FROM Direcciones d
WHERE EXISTS (SELECT 1 FROM Sucursales s WHERE s.idDireccion = d.idDireccion)
AND NOT EXISTS (SELECT 1 FROM Personal p WHERE p.idDireccion = d.idDireccion)
LIMIT 1;

-- Obtener una dirección que está siendo referenciada solo por un personal
SELECT idDireccion
FROM Direcciones d
WHERE NOT EXISTS (SELECT 1 FROM Sucursales s WHERE s.idDireccion = d.idDireccion)
AND EXISTS (SELECT 1 FROM Personal p WHERE p.idDireccion = d.idDireccion)
LIMIT 1;

-- Intenta eliminar una dirección que no está siendo referenciada
DELETE FROM Direcciones WHERE idDireccion = 504;

-- Intenta eliminar una dirección que está siendo referenciada solo por una sucursal
DELETE FROM Direcciones WHERE idDireccion = 1;

-- Intenta eliminar una dirección que está siendo referenciada solo por un personal
DELETE FROM Direcciones WHERE idDireccion = 3;