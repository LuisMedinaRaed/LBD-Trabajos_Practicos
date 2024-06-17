-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2016
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2016

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
-- Date Created : Sunday, June 16, 2024 23:44:53
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2016;
CREATE DATABASE IF NOT EXISTS Parcial2016;
USE Parcial2016;

DROP TABLE IF EXISTS planesestudio;

CREATE TABLE IF NOT EXISTS planesestudio(
    IdPlan    INT            NOT NULL,
    Nombre    VARCHAR(70),
    Desde     DATE           NOT NULL,
    Hasta     DATE,
    PRIMARY KEY (IdPlan),
    UNIQUE INDEX UI_NombrePlanesEstudio(Nombre),
    CHECK (Desde < Hasta)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS materias;

CREATE TABLE IF NOT EXISTS materias(
    Codigo    INT            NOT NULL,
    Nombre    VARCHAR(30)    NOT NULL,
    Tipo      VARCHAR(20)    NOT NULL CHECK (Tipo IN ('Opcional', 'Obligatoria')),
    PRIMARY KEY (Codigo),
    UNIQUE INDEX UI_NombreMaterias(Nombre)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS detalleplan;

CREATE TABLE IF NOT EXISTS detalleplan(
    IdPlan          INT    NOT NULL,
    Codigo          INT    NOT NULL,
    CargaHoraria    INT    NOT NULL,
    PRIMARY KEY (IdPlan, Codigo),
    INDEX IX_IdPlan(IdPlan),
    INDEX IX_Codigo(Codigo),
    FOREIGN KEY (IdPlan)
    REFERENCES planesestudio(IdPlan),
    FOREIGN KEY (Codigo)
    REFERENCES materias(Codigo)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS establecimientos;

CREATE TABLE IF NOT EXISTS establecimientos(
    IdEstablecimiento    INT             NOT NULL,
    Codigo               VARCHAR(10)     NOT NULL,
    Nombre               VARCHAR(100)    NOT NULL,
    Domicilio            VARCHAR(70)     NOT NULL,
    Tipo                 VARCHAR(10)     NOT NULL CHECK (Tipo IN ('Público', 'Privado')),
    PRIMARY KEY (IdEstablecimiento),
    UNIQUE INDEX UI_NombreEstablecimientos(Nombre),
    UNIQUE INDEX UI_Codigo(Codigo)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS niveles;

CREATE TABLE IF NOT EXISTS niveles(
    IdNivel    INT            NOT NULL,
    Nombre     VARCHAR(15)    NOT NULL,
    PRIMARY KEY (IdNivel),
    UNIQUE INDEX UI_NombreNiveles(Nombre)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS ofertaacademica;

CREATE TABLE IF NOT EXISTS ofertaacademica(
    IdPlan               INT    NOT NULL,
    IdNivel              INT    NOT NULL,
    IdEstablecimiento    INT    NOT NULL,
    PRIMARY KEY (IdPlan, IdNivel, IdEstablecimiento),
    INDEX IX_IdPlan(IdPlan),
    INDEX IX_IdNivel(IdNivel),
    INDEX IX_IdEstablecimiento(IdEstablecimiento),
    FOREIGN KEY (IdPlan)
    REFERENCES planesestudio(IdPlan),
    FOREIGN KEY (IdNivel)
    REFERENCES niveles(IdNivel),
    FOREIGN KEY (IdEstablecimiento)
    REFERENCES establecimientos(IdEstablecimiento)
)ENGINE=INNODB
;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación de la vista
-- Realizar una vista, llamada OfertaAcademicaEstablecimientos donde se muestre el Nombre del
-- Establecimiento, el nivel, el Nombre de PlanEstudio, la Materia y la CargaHoraria. Contemplar aquellos
-- planes que no tengan una oferta académica.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS OfertaAcademicaEstablecimientos;

CREATE VIEW OfertaAcademicaEstablecimientos AS
SELECT
    E.Nombre AS NombreEstablecimiento,
    N.Nombre AS Nivel,
    P.Nombre AS NombrePlanEstudio,
    M.Nombre AS Materia,
    D.CargaHoraria
FROM planesestudio P
LEFT JOIN detalleplan D ON P.IdPlan = D.IdPlan
LEFT JOIN materias M ON D.Codigo = M.Codigo
LEFT JOIN ofertaacademica O ON P.IdPlan = O.IdPlan
LEFT JOIN establecimientos E ON O.IdEstablecimiento = E.IdEstablecimiento
LEFT JOIN niveles N ON O.IdNivel = N.IdNivel;

SELECT * FROM OfertaAcademicaEstablecimientos;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un SP, llamado CargarMateriaEnPlan el cual cargue una determinada materia en el plan de
-- estudios, efectuar las comprobaciones necesarias y devolver los mensajes de error correspondiente
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS CargarMateriaEnPlan;

DELIMITER //
DROP PROCEDURE IF EXISTS CargarMateriaEnPlan;
CREATE PROCEDURE CargarMateriaEnPlan(IN p_IdPlan INT, IN p_Codigo INT)
proc_label: BEGIN
    DECLARE v_exists INT;

    -- Verificar si el plan de estudios existe
    SELECT COUNT(*) INTO v_exists FROM planesestudio WHERE IdPlan = p_IdPlan;
    IF v_exists = 0 THEN
        SELECT 'Error: El plan de estudios no existe.' AS Message;
        LEAVE proc_label;
    END IF;

    -- Verificar si la materia existe
    SELECT COUNT(*) INTO v_exists FROM materias WHERE Codigo = p_Codigo;
    IF v_exists = 0 THEN
        SELECT 'Error: La materia no existe.' AS Message;
        LEAVE proc_label;
    END IF;

    -- Verificar si la materia ya está en el plan de estudios
    SELECT COUNT(*) INTO v_exists FROM detalleplan WHERE IdPlan = p_IdPlan AND Codigo = p_Codigo;
    IF v_exists > 0 THEN
        SELECT 'Error: La materia ya está en el plan de estudios.' AS Message;
        LEAVE proc_label;
    END IF;

    -- Insertar la materia en el plan de estudios
    INSERT INTO detalleplan(IdPlan, Codigo, CargaHoraria) VALUES (p_IdPlan, p_Codigo, 0);
    SELECT 'La materia ha sido agregada al plan de estudios exitosamente.' AS Message;
END proc_label //
DELIMITER ;

-- Prueba para el mensaje de error 'El plan de estudios no existe.'
CALL CargarMateriaEnPlan(9999, 1); -- 9999 es un IdPlan que no existe en la tabla planesestudio

-- Prueba para el mensaje de error 'La materia no existe.'
CALL CargarMateriaEnPlan(967, 9999); -- 967 es un IdPlan existente y 9999 es un Codigo que no existe en la tabla materias

-- Prueba para el mensaje de error 'La materia ya está en el plan de estudios.'
-- Primero, inserta una materia en un plan de estudios
CALL CargarMateriaEnPlan(967, 10); -- 967 es un IdPlan existente y 10 es un Codigo existente
-- Luego, intenta insertar la misma materia en el mismo plan de estudios
CALL CargarMateriaEnPlan(967, 10); -- Esto debería devolver el mensaje de error


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Trigger
-- Realizar un trigger llamado AuditarCargaHoraria el cual se dispare luego de modificar la carga horaria
-- por un valor menor o igual a cero, los datos se deben guardar en la tabla auditoria guardando el valor
-- original de la carga horaria, la materia y el plan de estudio, el usuario la fecha en que se realizó.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS auditoria;

CREATE TABLE IF NOT EXISTS auditoria(
    IdAuditoria    INT AUTO_INCREMENT PRIMARY KEY,
    CargaHorariaOriginal INT,
    CodigoMateria  INT,
    IdPlan         INT,
    Usuario        VARCHAR(50),
    Fecha          DATETIME
);

DROP TRIGGER IF EXISTS AuditarCargaHoraria;

DELIMITER //
CREATE TRIGGER AuditarCargaHoraria
AFTER UPDATE ON detalleplan
FOR EACH ROW
BEGIN
    IF NEW.CargaHoraria <= 0 THEN
        INSERT INTO auditoria(CargaHorariaOriginal, CodigoMateria, IdPlan, Usuario, Fecha)
        VALUES (OLD.CargaHoraria, OLD.Codigo, OLD.IdPlan, CURRENT_USER(), NOW());
    END IF;
END //
DELIMITER ;

-- Actualizamos la CargaHoraria a un valor menor que cero
UPDATE detalleplan SET CargaHoraria = -1 WHERE IdPlan = 876 AND Codigo = 5457;

-- Verificamos que el trigger funcionó correctamente revisando la tabla auditoria
SELECT * FROM auditoria;

-- Ahora, actualizamos la CargaHoraria a cero
UPDATE detalleplan SET CargaHoraria = 0 WHERE IdPlan = 876 AND Codigo = 5457;

-- Verifica nuevamente que el trigger funcionó correctamente
SELECT * FROM auditoria;

-- Actualizamos la CargaHoraria a un valor mayor que cero
UPDATE detalleplan SET CargaHoraria = 5 WHERE IdPlan = 876 AND Codigo = 5457;

-- Verifica que el trigger no se activó revisando la tabla auditoria
SELECT * FROM auditoria;