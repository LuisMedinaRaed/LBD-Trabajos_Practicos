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
-- Date Created : Monday, June 17, 2024 22:13:44
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2021e;
CREATE DATABASE IF NOT EXISTS Parcial2021e;
USE Parcial2021e;


DROP TABLE IF EXISTS Actores;

CREATE TABLE IF NOT EXISTS Actores(
    idActor      CHAR(10)       NOT NULL,
    apellidos    VARCHAR(50),
    nombres      VARCHAR(50)    NOT NULL,
    PRIMARY KEY (idActor)
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

DROP TABLE IF EXISTS ActoresDePeliculas;

CREATE TABLE IF NOT EXISTS ActoresDePeliculas(
    idActor       CHAR(10)    NOT NULL,
    idPelicula    INT         NOT NULL,
    PRIMARY KEY (idActor, idPelicula),
    INDEX IX_idActorActoresDePeliculas(idActor),
    INDEX IX_idPeliculaActoresDePeliculas(idPelicula),
    FOREIGN KEY (idActor)
    REFERENCES Actores(idActor),
    FOREIGN KEY (idPelicula)
    REFERENCES Peliculas(idPelicula)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Direcciones;

CREATE TABLE IF NOT EXISTS Direcciones(
    idDireccion     INT            NOT NULL,
    calleYNumero    VARCHAR(50)    NOT NULL,
    codigoPostal    VARCHAR(10),
    telefono        VARCHAR(25)    NOT NULL,
    municipio       VARCHAR(25),
    PRIMARY KEY (idDireccion),
    UNIQUE INDEX UI_calleYNumeroDirecciones(calleYNumero)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Empleados;

CREATE TABLE IF NOT EXISTS Empleados(
    idEmpleado     INT            NOT NULL,
    apellidos      VARCHAR(50)    NOT NULL,
    nombres        VARCHAR(50)    NOT NULL,
    correo         VARCHAR(50),
    estado         CHAR(1)        NOT NULL CHECK (estado IN ('E', 'D')) DEFAULT 'E',
    idDireccion    INT            NOT NULL,
    PRIMARY KEY (idEmpleado),
    UNIQUE INDEX UI_correoEmpleados(correo),
    INDEX IX_idDireccionEmpleados(idDireccion),
    FOREIGN KEY (idDireccion)
    REFERENCES Direcciones(idDireccion)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Sucursales;

CREATE TABLE IF NOT EXISTS Sucursales(
    idSucursal     CHAR(10)    NOT NULL,
    idDireccion    INT         NOT NULL,
    idGerente      INT         NOT NULL,
    PRIMARY KEY (idSucursal),
    INDEX IX_idDireccionSucursales(idDireccion),
    INDEX IX_idGerenteSucursales(idGerente),
    FOREIGN KEY (idDireccion)
    REFERENCES Direcciones(idDireccion),
    FOREIGN KEY (idGerente)
    REFERENCES Empleados(idEmpleado)
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
-- Crear una vista llamada VCantidadPeliculasEnSucursales que muestre el título de las
-- películas, el código de la sucursal donde se encuentra, la calle y número de la sucursal, la
-- cantidad de películas (por película) y los datos del gerente de la sucursal (formato: “apellido,
-- nombre”). La salida deberá estar ordenada alfabéticamente según el título de las películas.
-- Incluir el código con la llamada a la vista
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS VCantidadPeliculasEnSucursales;

CREATE VIEW VCantidadPeliculasEnSucursales AS
SELECT
    P.titulo AS 'Titulo',
    S.idSucursal AS 'idSucursal',
    D.calleYNumero AS 'Calle y numero',
    COUNT(I.idPelicula) AS 'Cantidad',
    CONCAT(E.apellidos, ', ', E.nombres) AS 'Gerente'
FROM
    Peliculas P
LEFT JOIN
    Inventario I ON P.idPelicula = I.idPelicula
LEFT JOIN
    Sucursales S ON I.idSucursal = S.idSucursal
LEFT JOIN
    Direcciones D ON S.idDireccion = D.idDireccion
LEFT JOIN
    Empleados E ON S.idGerente = E.idEmpleado
GROUP BY
    P.titulo, S.idSucursal, D.calleYNumero, E.apellidos, E.nombres
ORDER BY
    P.titulo;

SELECT * FROM VCantidadPeliculasEnSucursales;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado ModificarDireccion para modificar una
-- dirección, incluyendo el control de errores lógicos y mensajes de error necesarios
-- (implementar la lógica del manejo de errores empleando parámetros de salida). Incluir el
-- código con la llamada al procedimiento probando todos los casos con datos incorrectos y
-- uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Eliminar el procedimiento almacenado existente
DROP PROCEDURE IF EXISTS ModificarDireccion;

-- Crear el nuevo procedimiento almacenado
DELIMITER //
CREATE PROCEDURE ModificarDireccion(
    IN p_idDireccion INT,
    IN p_calleYNumero VARCHAR(50),
    IN p_codigoPostal VARCHAR(10),
    IN p_telefono VARCHAR(25),
    IN p_municipio VARCHAR(25),
    OUT mensaje VARCHAR(255)
)
proc_label: BEGIN
    -- Verificar si la dirección con el id proporcionado existe
    IF NOT EXISTS (SELECT * FROM Direcciones WHERE idDireccion = p_idDireccion) THEN
        -- Si no existe, establecer el mensaje de error y terminar el procedimiento
        SET mensaje = 'Error: La direccion con el id proporcionado no existe.';
        LEAVE proc_label;
    END IF;

    -- Verificar si la calle y número proporcionados ya existen en otra dirección
    IF EXISTS (SELECT * FROM Direcciones WHERE calleYNumero = p_calleYNumero AND idDireccion != p_idDireccion) THEN
        -- Si existen, establecer el mensaje de error y terminar el procedimiento
        SET mensaje = 'Error: La calle y numero proporcionados ya existen en otra direccion.';
        LEAVE proc_label;
    END IF;

    -- Si el teléfono o el municipio son NULL o una cadena vacía, no se modificarán los valores en la base de datos
    UPDATE Direcciones
    SET calleYNumero = IF(p_calleYNumero IS NULL, calleYNumero, p_calleYNumero),
        codigoPostal = IF(p_codigoPostal IS NULL, codigoPostal, p_codigoPostal),
        telefono = IF(p_telefono IS NULL OR p_telefono = '', telefono, p_telefono),
        municipio = IF(p_municipio IS NULL OR p_municipio = '', municipio, p_municipio)
    WHERE idDireccion = p_idDireccion;

    -- Establecer el mensaje de éxito
    SET mensaje = 'Direccion modificada exitosamente.';
END //
DELIMITER ;

-- Llamadas al procedimiento almacenado para cada uno de los mensajes de error

-- Error: La dirección con el id proporcionado no existe.
CALL ModificarDireccion(9999, 'Nueva Calle 123', '12345', '1234567890', 'Nueva Ciudad', @mensaje); -- idDireccion no existe
SELECT @mensaje;

-- Error: La calle y número proporcionados ya existen en otra dirección.
CALL ModificarDireccion(1, '900 Santiago de Compostela Parkway', '12345', '1234567890', 'Nueva Ciudad', @mensaje); -- calleYNumero ya existe
SELECT @mensaje;

-- El teléfono es NULL. En este caso, el valor del teléfono en la base de datos no se modificará.
CALL ModificarDireccion(1, 'Nueva Calle 123', '12345', NULL, 'Nueva Ciudad', @mensaje); -- telefono es NULL
SELECT @mensaje;

-- El teléfono es una cadena vacía. En este caso, el valor del teléfono en la base de datos no se modificará.
CALL ModificarDireccion(1, 'Nueva Calle 123', '12345', '', 'Nueva Ciudad', @mensaje); -- telefono es una cadena vacia
SELECT @mensaje;

-- El municipio es NULL. En este caso, el valor del municipio en la base de datos no se modificará.
CALL ModificarDireccion(1, 'Nueva Calle 123', '12345', '1234567890', NULL, @mensaje); -- municipio es NULL
SELECT @mensaje;

-- El municipio es una cadena vacía. En este caso, el valor del municipio en la base de datos no se modificará.
CALL ModificarDireccion(1, 'Nueva Calle 123', '12345', '1234567890', '', @mensaje); -- municipio es una cadena vacia
SELECT @mensaje;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado llamado TotalPeliculas que muestre por cada
-- actor su código, apellido y nombre (formato: apellido, nombre) y cantidad de películas en las
-- que participó. Al final del listado se deberá mostrar también la cantidad total de películas. La
-- salida deberá estar ordenada alfabéticamente según el apellido y nombre del actor. Incluir
-- en el código la llamada al procedimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS TotalPeliculas;

DELIMITER //
CREATE PROCEDURE TotalPeliculas()
BEGIN
    -- Crear una tabla temporal para almacenar los resultados
    CREATE TEMPORARY TABLE IF NOT EXISTS TempResultados (
        Codigo CHAR(10),
        Nombre VARCHAR(101),
        Cantidad INT
    );

    -- Insertar los resultados en la tabla temporal
    INSERT INTO TempResultados (Codigo, Nombre, Cantidad)
    SELECT
        A.idActor AS 'Codigo',
        CONCAT(A.apellidos, ', ', A.nombres) AS 'Nombre',
        COUNT(ADP.idPelicula) AS 'Cantidad de peliculas'
    FROM
        Actores A
    LEFT JOIN
        ActoresDePeliculas ADP ON A.idActor = ADP.idActor
    GROUP BY
        A.idActor, A.apellidos, A.nombres
    ORDER BY
        A.apellidos, A.nombres;

    -- Insertar la cantidad total de películas en la tabla temporal
    INSERT INTO TempResultados (Codigo, Nombre, Cantidad)
    SELECT
        NULL AS 'Codigo',
        'Total' AS 'Nombre',
        COUNT(idPelicula) AS 'Cantidad total de peliculas'
    FROM
        ActoresDePeliculas;

    -- Seleccionar todos los resultados de la tabla temporal
    SELECT * FROM TempResultados;

    -- Eliminar la tabla temporal
    DROP TEMPORARY TABLE IF EXISTS TempResultados;
END //
DELIMITER ;

CALL TotalPeliculas();

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Utilizando triggers, implementar la lógica para que en caso que se quiera modificar una
-- película especificando el título de otra película existente se informe mediante un mensaje
-- de error que no se puede. Incluir el código con la modificación del título de una película con
-- un valor distinto a cualquiera de las que ya hubiera definidas y otro con un valor igual a otra
-- que ya hubiera definida.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS verificar_titulo;

DELIMITER //
CREATE TRIGGER verificar_titulo
BEFORE UPDATE ON Peliculas
FOR EACH ROW
BEGIN
    IF NEW.titulo <> OLD.titulo AND EXISTS (SELECT 1 FROM Peliculas WHERE titulo = NEW.titulo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El titulo de la pelicula ya existe.';
    END IF;
END //
DELIMITER ;

-- Intentar actualizar el título de una película a un valor que ya existe
UPDATE Peliculas SET titulo = 'AFRICAN EGG' WHERE idPelicula = 1;

-- Intentar actualizar el título de una película a un valor que no existe
UPDATE Peliculas SET titulo = 'Nuevo titulo' WHERE idPelicula = 1;
