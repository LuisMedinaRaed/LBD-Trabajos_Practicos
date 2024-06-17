-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2014
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 11
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2014

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
-- Date Created : Sunday, June 16, 2024 04:42:09
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2014;
CREATE DATABASE Parcial2014;
USE Parcial2014;

CREATE TABLE Categorias(
    IdCategoria    INT            NOT NULL,
    Categoria      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (IdCategoria),
    UNIQUE INDEX UI_Categoria(Categoria)
)ENGINE=INNODB
;

CREATE TABLE Conocimientos(
    IdConocimiento    INT            NOT NULL,
    IdCategoria       INT            NOT NULL,
    Conocimiento      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (IdConocimiento, IdCategoria),
    UNIQUE INDEX UI_Conocimiento(Conocimiento),
    INDEX IX_IdCategoria(IdCategoria),
    FOREIGN KEY (IdCategoria)
    REFERENCES Categorias(IdCategoria)
)ENGINE=INNODB
;

CREATE TABLE Niveles
(
    IdNivel    INT            NOT NULL,
    Nivel      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (IdNivel),
    UNIQUE INDEX UI_Nivel(Nivel),
    CHECK (Nivel IN ('Nulo', 'Básico', 'Intermedio', 'Avanzado', 'Experto'))
)ENGINE=INNODB
;

CREATE TABLE Puestos(
    IdPuesto    INT            NOT NULL,
    Puesto      VARCHAR(25)    NOT NULL,
    PRIMARY KEY (IdPuesto),
    UNIQUE INDEX UI_Puesto(Puesto),
    CHECK (Puesto IN ('Programador', 'Analista', 'Líder'))
)ENGINE=INNODB
;

CREATE TABLE Personas(
    IdPersona       INT            NOT NULL,
    IdPuesto        INT            NOT NULL,
    Nombres         VARCHAR(25)    NOT NULL,
    Apellidos       VARCHAR(25)    NOT NULL,
    FechaIngreso    DATE           NOT NULL,
    FechaBaja       DATE,
    PRIMARY KEY (IdPersona, IdPuesto),
    INDEX IX_ApellidosNombres(Apellidos, Nombres),
    INDEX IX_FechaIngreso(FechaIngreso),
    INDEX IX_IdPuesto(IdPuesto),
    FOREIGN KEY (IdPuesto)
    REFERENCES Puestos(IdPuesto)
)ENGINE=INNODB
;

CREATE TABLE Skills(
    IdSkill                    INT             NOT NULL,
    IdPersona                  INT             NOT NULL,
    IdConocimiento             INT             NOT NULL,
    IdCategoria                INT             NOT NULL,
    IdNivel                    INT             NOT NULL,
    FechaUltimaModificacion    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Observaciones              VARCHAR(144),
    PRIMARY KEY (IdSkill, IdPersona, IdConocimiento, IdCategoria, IdNivel),
    INDEX IX_FechaUltimaModificacion(FechaUltimaModificacion),
    INDEX IX_IdPersona(IdPersona),
    INDEX IX_IdConocimientoCategoria(IdConocimiento, IdCategoria),
    INDEX IX_IdNivel(IdNivel),
    FOREIGN KEY (IdConocimiento, IdCategoria)
    REFERENCES Conocimientos(IdConocimiento, IdCategoria),
    FOREIGN KEY (IdNivel)
    REFERENCES Niveles (IdNivel)
)ENGINE=INNODB
;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Crear una vista llamada vista_conocimientos_por_empleado, que muestre la categoría, conocimiento,
-- empleado (nombres, apellidos) y nivel de los empleados en actividad, ordenados por categoría y
-- conocimiento.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

CREATE VIEW vista_conocimientos_por_empleado AS
SELECT
    C.Categoria,
    CO.Conocimiento,
    P.Nombres,
    P.Apellidos,
    N.Nivel
FROM
    Skills S
JOIN
    Personas P ON S.IdPersona = P.IdPersona
JOIN
    Conocimientos CO ON S.IdConocimiento = CO.IdConocimiento AND S.IdCategoria = CO.IdCategoria
JOIN
    Categorias C ON CO.IdCategoria = C.IdCategoria
JOIN
    Niveles N ON S.IdNivel = N.IdNivel
WHERE
    P.FechaBaja IS NULL
ORDER BY
    C.Categoria,
    CO.Conocimiento;

SELECT * FROM vista_conocimientos_por_empleado;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un SP, llamado rsp_alta_skill, para dar de alta un skill, efectuando las comprobaciones
-- mínimas (3 por lo menos). Devolver los mensajes de error correspondientes
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE rsp_alta_skill(
    IN p_IdSkill INT,
    IN p_IdPersona INT,
    IN p_IdConocimiento INT,
    IN p_IdCategoria INT,
    IN p_IdNivel INT,
    IN p_Observaciones VARCHAR(144),
    OUT p_Message VARCHAR(100)
)
BEGIN
    DECLARE v_exists INT;

    SELECT COUNT(*) INTO v_exists FROM Personas WHERE IdPersona = p_IdPersona;
    IF v_exists = 0 THEN
        SET p_Message = 'Error: IdPersona no existe.';
        SELECT p_Message;
    ELSE
        SELECT COUNT(*) INTO v_exists FROM Conocimientos WHERE IdConocimiento = p_IdConocimiento;
        IF v_exists = 0 THEN
            SET p_Message = 'Error: IdConocimiento no existe.';
            SELECT p_Message;
        ELSE
            SELECT COUNT(*) INTO v_exists FROM Conocimientos WHERE IdCategoria = p_IdCategoria;
            IF v_exists = 0 THEN
                SET p_Message = 'Error: IdCategoria no existe.';
                SELECT p_Message;
            ELSE
                SELECT COUNT(*) INTO v_exists FROM Conocimientos WHERE IdConocimiento = p_IdConocimiento AND IdCategoria = p_IdCategoria;
                IF v_exists = 0 THEN
                    SET p_Message = 'Error: La combinación de IdConocimiento e IdCategoria no existe.';
                    SELECT p_Message;
                ELSE
                    SELECT COUNT(*) INTO v_exists FROM Niveles WHERE IdNivel = p_IdNivel;
                    IF v_exists = 0 THEN
                        SET p_Message = 'Error: IdNivel no existe.';
                        SELECT p_Message;
                    ELSE
                        INSERT INTO Skills (IdSkill, IdPersona, IdConocimiento, IdCategoria, IdNivel, FechaUltimaModificacion, Observaciones)
                        VALUES (p_IdSkill, p_IdPersona, p_IdConocimiento, p_IdCategoria, p_IdNivel, NOW(), p_Observaciones);

                        SET p_Message = 'Skill insertado correctamente.';
                        SELECT p_Message;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
END//
DELIMITER ;

-- Prueba para el mensaje "Error: IdPersona no existe."
CALL rsp_alta_skill(1, 999, 1, 1, 1, 'Observaciones de prueba', @message);
SELECT @message;

-- Prueba para el mensaje "Error: IdConocimiento no existe."
CALL rsp_alta_skill(1, 1, 999, 1, 1, 'Observaciones de prueba', @message);
SELECT @message;

-- Prueba para el mensaje "Error: IdCategoria no existe."
CALL rsp_alta_skill(1, 1, 1, 999, 1, 'Observaciones de prueba', @message);
SELECT @message;

-- Prueba para el mensaje "Error: La combinación de IdConocimiento e IdCategoria no existe."
CALL rsp_alta_skill(1, 1, 1, 2, 1, 'Observaciones de prueba', @message);
SELECT @message;

-- Prueba para el mensaje "Error: IdNivel no existe."
CALL rsp_alta_skill(1, 1, 1, 1, 999, 'Observaciones de prueba', @message);
SELECT @message;

-- Prueba para el mensaje "Skill insertado correctamente."
CALL rsp_alta_skill(57, 1, 1, 1, 1, 'Observaciones de prueba', @message);
SELECT @message;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un SP, llamado rsp_cantidad_por_conocimiento que muestre la cantidad empleados que hay
-- de cada conocimiento, ordenados por categoría y conocimiento de forma descendente, de la forma:
-- Categoría, Conocimiento, Cantidad
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE rsp_cantidad_por_conocimiento(
    OUT p_Message VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
        @p_sqlstate = RETURNED_SQLSTATE, @p_message = MESSAGE_TEXT;
        SET p_Message = CONCAT('Error: ', @p_sqlstate, ' ', @p_message);
    END;

    SELECT
        C.Categoria,
        CO.Conocimiento,
        COUNT(S.IdPersona) AS Cantidad
    FROM
        Skills S
    JOIN
        Conocimientos CO ON S.IdConocimiento = CO.IdConocimiento AND S.IdCategoria = CO.IdCategoria
    JOIN
        Categorias C ON CO.IdCategoria = C.IdCategoria
    GROUP BY
        C.Categoria,
        CO.Conocimiento
    ORDER BY
        C.Categoria DESC,
        CO.Conocimiento DESC;

    SET p_Message = 'Consulta realizada correctamente.';
END//
DELIMITER ;

CALL rsp_cantidad_por_conocimiento(@message);
SELECT @message;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Utilizando triggers, implementar la lógica para llevar una auditoría de la tabla Skills para el caso de
-- inserción. Se deberá auditar la operación, el usuario que la hizo, la fecha y hora, el host y la máquina desde
-- donde se realizó la operación. Llamarlo trigger_audit_skills, y a la tabla: audit_skills
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- Creación de la tabla audit_skills
CREATE TABLE audit_skills(
    IdAudit INT AUTO_INCREMENT,
    Operation VARCHAR(10),
    User VARCHAR(50),
    DateTime DATETIME,
    Host VARCHAR(50),
    Machine VARCHAR(50),
    PRIMARY KEY (IdAudit)
);

-- Creación del trigger trigger_audit_skills
DELIMITER //
CREATE TRIGGER trigger_audit_skills
AFTER INSERT ON Skills
FOR EACH ROW
BEGIN
    INSERT INTO audit_skills(Operation, User, DateTime, Host, Machine)
    VALUES ('INSERT', USER(), NOW(), @@hostname, @@version_comment);
END;
//
DELIMITER ;

-- Inserta un nuevo registro en la tabla Skills
CALL rsp_alta_skill(56, 1, 1, 1, 1, 'Nuevas observaciones', @message);
SELECT @message;

-- Consulta la tabla audit_skills para verificar que el trigger funcionó correctamente
SELECT * FROM audit_skills;