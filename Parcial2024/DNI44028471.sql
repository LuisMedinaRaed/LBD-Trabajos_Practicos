-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2024
-- Alumno: Medina Raed, Luis Eugenio
-- DNI: 44.028.471
-- Plataforma (SO + Versión): Windows 11 Home Single Language 23H2 - 22631.3737
-- Motor y Versión: MySQL Server 8.0.37
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2024
-- ------------------------------------------------------------------------------------------------------- --

-- ----------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------
--  Apartado 1: Creación de la Base de datos y sus Constraints
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP DATABASE IF EXISTS DNI44028471;
CREATE DATABASE IF NOT EXISTS DNI44028471;
USE DNI44028471;

--
-- ER/Studio Data Architect SQL Code Generation
-- Project :      DATA MODEL
--
-- Date Created : Tuesday, June 18, 2024 16:48:04
-- Target DBMS : MySQL 8.x
--

DROP TABLE IF EXISTS Categorias;

CREATE TABLE IF NOT EXISTS Categorias(
    idCategoria    INT            NOT NULL,
    Categoria      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (idCategoria),
    UNIQUE INDEX UI_Categoria(Categoria)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Conocimientos;

CREATE TABLE IF NOT EXISTS Conocimientos(
    idConocimiento    INT            NOT NULL,
    idCategoria       INT            NOT NULL,
    Conocimiento      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (idConocimiento, idCategoria),
    UNIQUE INDEX UI_Conocimiento(Conocimiento),
    INDEX IX_idCategoriaConocimientos(idCategoria),
    INDEX IX_idConocimientoConocimientos(idConocimiento),
    FOREIGN KEY (idCategoria)
    REFERENCES Categorias(idCategoria)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Puestos;

CREATE TABLE IF NOT EXISTS Puestos(
    idPuesto    INT            NOT NULL,
    Puesto      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (idPuesto),
    UNIQUE INDEX UI_Puesto(Puesto)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Personas;

CREATE TABLE IF NOT EXISTS Personas(
    idPersona       INT            NOT NULL,
    idPuesto        INT            NOT NULL,
    Nombres         VARCHAR(25)    NOT NULL,
    Apellidos       VARCHAR(25)    NOT NULL,
    FechaIngreso    DATE           NOT NULL,
    FechaBaja       DATE,
    PRIMARY KEY (idPersona),
    INDEX IX_idPuestoPersonas(idPuesto),
    FOREIGN KEY (idPuesto)
    REFERENCES Puestos(idPuesto),
    CHECK (FechaBaja > FechaIngreso OR FechaBaja IS NULL)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Niveles;

CREATE TABLE IF NOT EXISTS Niveles(
    idNivel    INT            NOT NULL,
    Nivel      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (idNivel),
    UNIQUE INDEX UI_Nivel(Nivel)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Habilidades;

CREATE TABLE IF NOT EXISTS Habilidades(
    idHabilidad                INT             NOT NULL,
    idPersona                  INT             NOT NULL,
    idConocimiento             INT             NOT NULL,
    idCategoria                INT             NOT NULL,
    idNivel                    INT             NOT NULL DEFAULT 1,
    FechaUltimaModificacion    DATE            NOT NULL DEFAULT (CURRENT_TIMESTAMP),
    Observaciones              VARCHAR(144),
    PRIMARY KEY (idHabilidad),
    INDEX IX_idPersonaHabilidades(idPersona),
    INDEX IX_idConocimientoCategoriaHabilidades(idConocimiento, idCategoria),
    INDEX IX_idNivelHabilidades(idNivel),
    INDEX IX_idConocimientoHabilidades(idConocimiento),
    INDEX IX_idCategoriaHabilidades(idCategoria),
    FOREIGN KEY (idPersona)
    REFERENCES Personas(idPersona),
    FOREIGN KEY (idConocimiento, idCategoria)
    REFERENCES Conocimientos(idConocimiento, idCategoria),
    FOREIGN KEY (idNivel)
    REFERENCES Niveles(idNivel)
) ENGINE=INNODB;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear una vista llamada vista_conocimientos_por_empleado, que muestre la
-- categoría, conocimiento, empleado (apellidos y nombres) y nivel de los empleados,
-- ordenados por categoría y conocimiento. En caso que el empleado no estuviera en
-- actividad, en el nivel se mostrará “Dado de baja”.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS vista_conocimientos_por_empleado;

CREATE VIEW vista_conocimientos_por_empleado AS
SELECT
    c.Categoria,
    con.Conocimiento,
    CONCAT(p.Apellidos, ', ', p.Nombres) AS Empleado,
    IF(p.FechaBaja IS NOT NULL, 'Dado de baja', n.Nivel) AS Nivel
FROM
    Habilidades h
INNER JOIN
    Personas p ON h.idPersona = p.idPersona
INNER JOIN
    Conocimientos con ON h.idConocimiento = con.idConocimiento AND h.idCategoria = con.idCategoria
INNER JOIN
    Categorias c ON con.idCategoria = c.idCategoria
INNER JOIN
    Niveles n ON h.idNivel = n.idNivel
ORDER BY
    c.Categoria, con.Conocimiento;

SELECT * FROM vista_conocimientos_por_empleado;

-- Este código SQL crea una vista llamada "vista_conocimientos_por_empleado".
-- La vista muestra la categoría, el conocimiento, el nombre del empleado y el nivel de habilidad de cada empleado.
-- Los empleados se listan en orden de categoría y conocimiento.
-- Si un empleado no está activo (es decir, si la fecha de baja no es NULL), en lugar del nivel de habilidad, se muestra "Dado de baja".
-- Se utilizan INNER JOIN para unir las tablas "Habilidades", "Personas", "Conocimientos", "Categorias" y "Niveles" en base a las columnas correspondientes.
-- Como resultado, solo se mostrarán los empleados que tienen al menos una habilidad registrada. Los empleados sin habilidades no se mostrarán en esta vista.

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado, llamado rsp_borrar_habilidad, para borrar una
-- habilidad, efectuando las comprobaciones necesarias (devolver los mensajes de error
-- correspondientes empleando parámetros de salida). Incluir el código con la llamada al
-- procedimiento probando todos los casos con datos incorrectos y uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS rsp_borrar_habilidad;

DELIMITER //
CREATE PROCEDURE rsp_borrar_habilidad(IN habilidad_id INT, OUT mensaje VARCHAR(255))
proc_label: BEGIN
    DECLARE existe INT;

    -- Verificar si habilidad_id es NULL
    IF habilidad_id IS NULL THEN
        SET mensaje = 'Error: El ID de la habilidad no puede ser NULL.';
        LEAVE proc_label;
    END IF;

    -- Verificar si habilidad_id es válido
    IF habilidad_id <= 0 THEN
        SET mensaje = 'Error: El ID de la habilidad debe ser mayor que cero.';
        LEAVE proc_label;
    END IF;

    -- Verificar si existe la habilidad
    SELECT COUNT(*) INTO existe FROM Habilidades WHERE idHabilidad = habilidad_id;

    IF existe = 0 THEN
        SET mensaje = 'Error: La habilidad no existe.';
        LEAVE proc_label;
    END IF;

    -- Borrar la habilidad
    DELETE FROM Habilidades WHERE idHabilidad = habilidad_id;

    -- Personalizar el mensaje de éxito
    SET mensaje = CONCAT('Éxito: La habilidad con el ID ', habilidad_id, ' fue borrada con éxito.');
END //
DELIMITER ;

-- Prueba con un `habilidad_id` null
-- Este caso debería devolver un mensaje de error indicando que el ID de la habilidad proporcionado no es válido.
CALL rsp_borrar_habilidad(NULL, @mensaje);
SELECT @mensaje;

-- Prueba con un `habilidad_id` inválido (menor o igual a 0):
-- Este caso debería devolver un mensaje de error indicando que el ID de la habilidad proporcionado no es válido.
CALL rsp_borrar_habilidad(0, @mensaje);
SELECT @mensaje;

-- Prueba con un `habilidad_id` que no existe en la tabla `Habilidades`:
-- Este caso debería devolver un mensaje de error indicando que la habilidad no existe.
CALL rsp_borrar_habilidad(9999, @mensaje);
SELECT @mensaje;

-- Prueba de éxito con un `habilidad_id` válido:
-- Este caso debería devolver un mensaje de éxito indicando que la habilidad con el ID proporcionado fue borrada con éxito.
CALL rsp_borrar_habilidad(1, @mensaje);
SELECT @mensaje;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un procedimiento almacenado, llamado rsp_cantidades que muestre la
-- cantidad de empleados que hay de cada conocimiento, ordenados por categoría y
-- conocimiento de forma descendente, de la forma: Categoría, Conocimiento, Cantidad.
-- También se deberá mostrar, al final, una fila que muestre la cantidad total de categorías
-- (distintas), la cantidad total de conocimientos y la cantidad total de empleados (tomar sólo
-- las categorías y conocimientos que formen parte de las habilidades de los empleados)
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS rsp_cantidades;

DELIMITER //
CREATE PROCEDURE rsp_cantidades()
BEGIN
    -- Seleccionar la cantidad de empleados que hay de cada conocimiento, ordenados por categoría y conocimiento de forma descendente
    SELECT
        c.Categoria,
        con.Conocimiento,
        COUNT(p.idPersona) AS Cantidad
    FROM
        Habilidades h
    INNER JOIN
        Personas p ON h.idPersona = p.idPersona
    INNER JOIN
        Conocimientos con ON h.idConocimiento = con.idConocimiento AND h.idCategoria = con.idCategoria
    INNER JOIN
        Categorias c ON con.idCategoria = c.idCategoria
    GROUP BY
        c.Categoria, con.Conocimiento
    UNION ALL
    -- Seleccionar la cantidad total de categorías (distintas), la cantidad total de conocimientos y la cantidad total de empleados
    SELECT
        CAST(COUNT(DISTINCT c.idCategoria) AS CHAR) AS TotalCategorias,
        CAST(COUNT(DISTINCT con.idConocimiento) AS CHAR) AS TotalConocimientos,
        CAST(COUNT(p.idPersona) AS CHAR) AS TotalEmpleados
    FROM
        Habilidades h
    INNER JOIN
        Personas p ON h.idPersona = p.idPersona
    INNER JOIN
        Conocimientos con ON h.idConocimiento = con.idConocimiento AND h.idCategoria = con.idCategoria
    INNER JOIN
        Categorias c ON con.idCategoria = c.idCategoria
    ORDER BY
        Categoria DESC, Conocimiento DESC;
END //
DELIMITER ;

CALL rsp_cantidades();

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Utilizando triggers, implementar la lógica para que en caso que se quiera borrar un
-- puesto que sea de alguna persona se informe mediante un mensaje de error que no se
-- puede. Incluir el código con los borrados de un puesto que no tenga ninguna persona, y otro
-- de uno que sí.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_before_delete_puesto;

DELIMITER //
CREATE TRIGGER trg_before_delete_puesto
BEFORE DELETE ON Puestos
FOR EACH ROW
BEGIN
    DECLARE personas INT;

    SELECT COUNT(*) INTO personas
    FROM Personas
    WHERE idPuesto = OLD.idPuesto;

    IF personas > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: No se puede borrar un puesto que está asignado a una persona.';
    END IF;
END //
DELIMITER ;

-- Insertar un puesto con un ID específico
INSERT INTO Puestos (idPuesto, Puesto) VALUES (100, 'NombrePuesto');

-- Intentar borrar el puesto insertado que no esta vinculado a ninguna persona
DELETE FROM Puestos WHERE idPuesto = 100;

-- Intentar borrar un puesto que está asignado a una persona
DELETE FROM Puestos WHERE idPuesto = 1;