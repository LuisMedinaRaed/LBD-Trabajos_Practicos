-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2018
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 11 Home Single Language 23H2 - 22631.3737
-- Motor y Versión: MySQL Server 8.0.37
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2018

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
-- Date Created : Monday, June 17, 2024 02:14:29
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2018;
CREATE DATABASE IF NOT EXISTS Parcial2018;
USE Parcial2018;


DROP TABLE IF EXISTS Personas;

CREATE TABLE IF NOT EXISTS Personas(
    dni          INT            NOT NULL,
    apellidos    VARCHAR(40)    NOT NULL,
    nombres      VARCHAR(40)    NOT NULL,
    PRIMARY KEY (dni)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Alumnos;

CREATE TABLE IF NOT EXISTS Alumnos(
    dni    INT        NOT NULL,
    cx     CHAR(7)    NOT NULL,
    PRIMARY KEY (dni),
    UNIQUE INDEX UI_CX(cx),
    INDEX IX_dniAlumnos(dni),
    FOREIGN KEY (dni)
    REFERENCES Personas(dni)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Trabajos;

CREATE TABLE IF NOT EXISTS Trabajos(
    idTrabajo            INT             NOT NULL,
    titulo               VARCHAR(100)    NOT NULL,
    duracion             INT             NOT NULL DEFAULT 6,
    area                 VARCHAR(10)     NOT NULL,
    fechaPresentacion    DATE            NOT NULL,
    fechaAprobacion      DATE            NOT NULL,
    fechaFinalizacion    DATE,
    PRIMARY KEY (idTrabajo),
    UNIQUE INDEX UI_Titulo(titulo),
    CHECK (area IN ('Hardware', 'Redes', 'Software'))
)ENGINE=INNODB;

DROP TABLE IF EXISTS AlumnosEnTrabajos;

CREATE TABLE IF NOT EXISTS AlumnosEnTrabajos(
    idTrabajo    INT             NOT NULL,
    dni          INT             NOT NULL,
    desde        DATE            NOT NULL,
    hasta        DATE,
    razon        VARCHAR(100),
    PRIMARY KEY (idTrabajo, dni),
    INDEX IX_idTrabajoAlumnosEnTrabajos(idTrabajo),
    INDEX IX_dniAlumnosEnTrabajos(dni),
    FOREIGN KEY (idTrabajo)
    REFERENCES Trabajos(idTrabajo),
    FOREIGN KEY (dni)
    REFERENCES Alumnos(dni)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Cargos;

CREATE TABLE IF NOT EXISTS Cargos(
    idCargo    INT            NOT NULL,
    cargo      VARCHAR(20)    NOT NULL,
    PRIMARY KEY (idCargo),
    UNIQUE INDEX UI_Cargo(cargo)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Profesores;

CREATE TABLE IF NOT EXISTS Profesores(
    dni        INT    NOT NULL,
    idCargo    INT    NOT NULL,
    PRIMARY KEY (dni),
    INDEX IX_dniProfesores(dni),
    INDEX IX_idCargoProfesores(idCargo),
    FOREIGN KEY (dni)
    REFERENCES Personas(dni),
    FOREIGN KEY (idCargo)
    REFERENCES Cargos(idCargo)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS RolesEnTrabajos;

CREATE TABLE IF NOT EXISTS RolesEnTrabajos(
    idTrabajo    INT             NOT NULL,
    dni          INT             NOT NULL,
    rol          VARCHAR(7)      NOT NULL,
    desde        DATE            NOT NULL,
    hasta        DATE,
    razon        VARCHAR(100),
    PRIMARY KEY (idTrabajo, dni),
    INDEX IX_idTrabajoRolesEnTrabajos(idTrabajo),
    INDEX IX_dniRolesEnTrabajos(dni),
    FOREIGN KEY (idTrabajo)
    REFERENCES Trabajos(idTrabajo),
    FOREIGN KEY (dni)
    REFERENCES Profesores(dni),
    CHECK (rol IN ('Tutor', 'Cotutor', 'Jurado'))
)ENGINE=INNODB;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear un procedimiento llamado DetalleRoles, que reciba un rango de años y que muestre:
-- Año, DNI, Apellidos, Nombres, Tutor, Cotutor y Jurado, donde Tutor, Cotutor y Jurado muestran
-- la cantidad de trabajos en los que un profesor participó en un trabajo con ese rol entre el rango
-- de fechas especificado. El listado se mostrará ordenado por año, apellidos, nombres y DNI (se
-- pueden emplear vistas u otras estructuras para lograr la funcionalidad solicitada. Para obtener
-- el año de una fecha se puede emplear la función YEAR() [30].
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
DROP PROCEDURE IF EXISTS DetalleRoles;
CREATE PROCEDURE DetalleRoles(IN year_start INT, IN year_end INT)
BEGIN
    SELECT
        YEAR(rt.desde) AS Año,
        p.dni AS DNI,
        p.apellidos AS Apellidos,
        p.nombres AS Nombres,
        SUM(rt.rol = 'Tutor') AS Tutor,
        SUM(rt.rol = 'Cotutor') AS Cotutor,
        SUM(rt.rol = 'Jurado') AS Jurado
    FROM
        Personas p
    JOIN
        Profesores pr ON p.dni = pr.dni
    JOIN
        RolesEnTrabajos rt ON pr.dni = rt.dni
    WHERE
        YEAR(rt.desde) BETWEEN year_start AND year_end
    GROUP BY
        Año, DNI, Apellidos, Nombres
    ORDER BY
        Año, Apellidos, Nombres, DNI;
END //
DELIMITER ;

-- Llamada de ejemplo al procedimiento almacenado
CALL DetalleRoles(2017, 2018);

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Crear un procedimiento almacenado llamado NuevoTrabajo, para que agregue un trabajo
-- nuevo. El procedimiento deberá efectuar las comprobaciones necesarias (incluyendo que la
-- fecha de aprobación sea igual o mayor a la de presentación) y devolver los mensajes
-- correspondientes (uno por cada condición de error, y otro por el éxito)
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
DROP PROCEDURE IF EXISTS NuevoTrabajo;
CREATE PROCEDURE NuevoTrabajo(
    IN p_idTrabajo INT,
    IN p_titulo VARCHAR(100),
    IN p_duracion INT,
    IN p_area VARCHAR(10),
    IN p_fechaPresentacion DATE,
    IN p_fechaAprobacion DATE,
    IN p_fechaFinalizacion DATE,
    OUT p_message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_exists INT;

    -- Comprobar que el idTrabajo sea único
    SELECT COUNT(*) INTO v_exists FROM Trabajos WHERE idTrabajo = p_idTrabajo;
    IF v_exists > 0 THEN
        SET p_message = 'Error: El idTrabajo debe ser único.';
        LEAVE proc_label;
    END IF;

    -- Comprobar que la fecha de aprobación sea igual o mayor a la fecha de presentación
    IF p_fechaAprobacion < p_fechaPresentacion THEN
        SET p_message = 'Error: La fecha de aprobación debe ser igual o mayor a la fecha de presentación.';
        LEAVE proc_label;
    -- Comprobar que el área sea una de las permitidas
    ELSEIF p_area NOT IN ('Hardware', 'Redes', 'Software') THEN
        SET p_message = 'Error: El área debe ser Hardware, Redes o Software.';
        LEAVE proc_label;
    -- Comprobar que la duración sea mayor que 0
    ELSEIF p_duracion <= 0 THEN
        SET p_message = 'Error: La duración debe ser mayor que 0.';
        LEAVE proc_label;
    -- Comprobar que el título sea único
    ELSE
        SELECT COUNT(*) INTO v_exists FROM Trabajos WHERE titulo = p_titulo;
        IF v_exists > 0 THEN
            SET p_message = 'Error: El título del trabajo debe ser único.';
            LEAVE proc_label;
        END IF;
    END IF;

    -- Insertar el nuevo trabajo
    INSERT INTO Trabajos(idTrabajo, titulo, duracion, area, fechaPresentacion, fechaAprobacion, fechaFinalizacion)
    VALUES(p_idTrabajo, p_titulo, p_duracion, p_area, p_fechaPresentacion, p_fechaAprobacion, p_fechaFinalizacion);
    SET p_message = 'El trabajo se agregó con éxito.';
END proc_label //
DELIMITER ;

-- Prueba para el error: 'Error: El idTrabajo debe ser único.'
-- Proporciona un valor para p_idTrabajo que ya exista en la tabla Trabajos.
CALL NuevoTrabajo(1, 'Titulo Nuevo', 6, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;

-- Prueba para el error: 'Error: La fecha de aprobación debe ser igual o mayor a la fecha de presentación.'
-- Proporciona una fecha de aprobación que sea menor a la fecha de presentación.
CALL NuevoTrabajo(9, 'Titulo', 6, 'Software', '2024-06-01', '2024-05-01', NULL, @message);
SELECT @message AS Message;

-- Prueba para el error: 'Error: El área debe ser Hardware, Redes o Software.'
-- Proporciona un valor para p_area que no sea 'Hardware', 'Redes' o 'Software'.
CALL NuevoTrabajo(9, 'Titulo', 6, 'Invalido', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;

-- Prueba para el error: 'Error: La duración debe ser mayor que 0.'
-- Proporciona un valor para p_duracion que sea menor o igual a 0.
CALL NuevoTrabajo(9, 'Titulo', 0, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;

-- Prueba para el error: 'Error: El título del trabajo debe ser único.'
-- Proporciona un valor para p_titulo que ya exista en la tabla Trabajos.
CALL NuevoTrabajo(9, 'Sistema de Gestión y Seguimiento de Trabajos de Graduación de Ingeniería en Computación', 6, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;

-- Prueba para el éxito: 'El trabajo se agregó con éxito.'
-- Asegúrate de que todos los parámetros proporcionados sean válidos.
CALL NuevoTrabajo(9, 'Titulo Unico', 6, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Trigger
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Creación de la tabla de auditoría
CREATE TABLE AuditoriaTrabajos(
    idAuditoria INT AUTO_INCREMENT PRIMARY KEY,
    idTrabajo INT,
    titulo VARCHAR(100),
    duracion INT,
    area VARCHAR(10),
    fechaPresentacion DATE,
    fechaAprobacion DATE,
    fechaFinalizacion DATE,
    usuario VARCHAR(100),
    fechaAuditoria TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Creación del trigger AuditarTrabajos
DELIMITER //
CREATE TRIGGER AuditarTrabajos
AFTER INSERT ON Trabajos
FOR EACH ROW
BEGIN
    IF NEW.duracion > 12 OR NEW.duracion < 3 THEN
        INSERT INTO AuditoriaTrabajos(idTrabajo, titulo, duracion, area, fechaPresentacion, fechaAprobacion, fechaFinalizacion, usuario)
        VALUES(NEW.idTrabajo, NEW.titulo, NEW.duracion, NEW.area, NEW.fechaPresentacion, NEW.fechaAprobacion, NEW.fechaFinalizacion, CURRENT_USER());
    END IF;
END //
DELIMITER ;

-- Llamadas de prueba para el trigger AuditarTrabajos
-- Insertar un trabajo con una duración superior a 12 meses
CALL NuevoTrabajo(10, 'Titulo Largo', 13, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;
SELECT * FROM AuditoriaTrabajos;

-- Insertar un trabajo con una duración inferior a 3 meses
CALL NuevoTrabajo(11, 'Titulo Corto', 2, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;
SELECT * FROM AuditoriaTrabajos;

-- Prueba para agregar un trabajo con una duración entre 3 y 12 meses
-- Esta inserción no debería activar el trigger AuditarTrabajos
CALL NuevoTrabajo(12, 'Titulo Medio', 6, 'Software', '2024-06-01', '2024-06-01', NULL, @message);
SELECT @message AS Message;
SELECT * FROM AuditoriaTrabajos;