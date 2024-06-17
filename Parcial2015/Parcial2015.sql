-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2015
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 11
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2015

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
-- Date Created : Sunday, June 16, 2024 06:20:20
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2015;
CREATE DATABASE Parcial2015;
USE Parcial2015;

CREATE TABLE Edificios(
    IdEdificio    INT            NOT NULL,
    Nombre        VARCHAR(20)    NOT NULL,
    Domicilio     VARCHAR(50)    NOT NULL,
    Superficie    INT            NOT NULL,
    PRIMARY KEY (IdEdificio),
    UNIQUE INDEX UI_Nombre(Nombre)
)ENGINE=INNODB
;

CREATE TABLE Propietarios(
    IdPropietario    INT            NOT NULL,
    Apellidos        VARCHAR(30)    NOT NULL,
    Nombres          VARCHAR(20)    NOT NULL,
    Domicilio        VARCHAR(50)    NOT NULL,
    Telefono         VARCHAR(15),
    Correo           VARCHAR(50),
    PRIMARY KEY (IdPropietario),
    INDEX IX_Apellidos(Apellidos)
)ENGINE=INNODB
;

CREATE TABLE Unidades(
    IdEdificio       INT            NOT NULL,
    Piso             CHAR(2)        NOT NULL,
    Numero           CHAR(2)        NOT NULL,
    Tipo             VARCHAR(15)    NOT NULL DEFAULT 'Departamento' CHECK (Tipo IN ('Departamento', 'Cochera', 'Local')),
    Superficie       INT            NOT NULL,
    IdPropietario    INT            NOT NULL,
    PRIMARY KEY (IdEdificio, Piso, Numero),
    INDEX IX_Tipo(Tipo),
    INDEX IX_Edificio(IdEdificio),
    INDEX IX_Propietario(IdPropietario),
    FOREIGN KEY (IdEdificio)
    REFERENCES Edificios(IdEdificio),
    FOREIGN KEY (IdPropietario)
    REFERENCES Propietarios(IdPropietario)
)ENGINE=INNODB;

CREATE TABLE Expensas(
    IdEdificio     INT               NOT NULL,
    Piso           CHAR(2)           NOT NULL,
    Numero         CHAR(2)           NOT NULL,
    Periodo        DATE              NOT NULL,
    Importe        DECIMAL(10, 2)    NOT NULL,
    Vencimiento    DATE              NOT NULL,
    PRIMARY KEY (IdEdificio, Piso, Numero, Periodo),
    INDEX IX_EdificioNumeroPiso(IdEdificio, Numero, Piso),
    FOREIGN KEY (IdEdificio, Piso, Numero)
    REFERENCES Unidades(IdEdificio, Piso, Numero)
)ENGINE=INNODB
;

CREATE TABLE Rubros(
    IdRubro    INT            NOT NULL,
    Nombre     VARCHAR(20)    NOT NULL,
    PRIMARY KEY (IdRubro),
    UNIQUE INDEX UI_Nombre(Nombre)
)ENGINE=INNODB
;

CREATE TABLE Gastos(
    IdGasto       INT               NOT NULL,
    Fecha         DATE              NOT NULL,
    Importe       DECIMAL(10, 2)    NOT NULL,
    IdEdificio    INT               NOT NULL,
    IdRubro       INT               NOT NULL,
    PRIMARY KEY (IdGasto),
    INDEX IX_Fecha(Fecha),
    INDEX IX_Edificio(IdEdificio),
    INDEX IX_Rubro(IdRubro),
    FOREIGN KEY (IdEdificio)
    REFERENCES Edificios(IdEdificio),
    FOREIGN KEY (IdRubro)
    REFERENCES Rubros(IdRubro)
)ENGINE=INNODB
;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación del Stored Procedure
-- Crear un SP, llamado sp_movimientos, que dado un rango de meses (correspondientes a un mismo año)
-- muestre mes a mes el total de gastos y el total de expensas. El formato deberá ser: Mes, Total de Gastos,
-- Total de Expensas.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE sp_movimientos(IN year INT, IN start_month INT, IN end_month INT, OUT error_message VARCHAR(255))
BEGIN
    DECLARE has_error INT DEFAULT 0;
    DECLARE min_year INT;
    DECLARE max_year INT;

    SELECT YEAR(MIN(Fecha)) INTO min_year FROM (SELECT Fecha FROM Gastos UNION SELECT Periodo FROM Expensas) AS Dates;
    SELECT YEAR(MAX(Fecha)) INTO max_year FROM (SELECT Fecha FROM Gastos UNION SELECT Periodo FROM Expensas) AS Dates;

    IF min_year = max_year AND year <> min_year THEN
        SET error_message = CONCAT('Error: El año a ingresar debe ser ', min_year, '.');
        SET has_error = 1;
    ELSEIF year < min_year OR year > max_year THEN
        SET error_message = CONCAT('Error: El año debe estar entre ', min_year, ' y ', max_year, '.');
        SET has_error = 1;
    END IF;

    IF start_month < 1 OR start_month > 12 THEN
        SET error_message = 'Error: El mes de inicio debe estar entre 1 y 12.';
        SET has_error = 1;
    END IF;

    IF end_month < 1 OR end_month > 12 THEN
        SET error_message = 'Error: El mes de fin debe estar entre 1 y 12.';
        SET has_error = 1;
    END IF;

    IF start_month > end_month THEN
        SET error_message = 'Error: El mes de inicio no puede ser mayor que el mes de fin.';
        SET has_error = 1;
    END IF;

    IF has_error = 0 THEN
        SELECT
            Dates.Mes,
            COALESCE(Gastos, 0) AS 'Total de Gastos',
            COALESCE(Expensas, 0) AS 'Total de Expensas'
        FROM
            (SELECT MONTH(Fecha) AS Mes FROM Gastos WHERE YEAR(Fecha) = year AND MONTH(Fecha) BETWEEN start_month AND end_month
             UNION
             SELECT MONTH(Periodo) AS Mes FROM Expensas WHERE YEAR(Periodo) = year AND MONTH(Periodo) BETWEEN start_month AND end_month) AS Dates
        LEFT JOIN
            (SELECT MONTH(Fecha) AS Mes, SUM(Importe) AS Gastos FROM Gastos WHERE YEAR(Fecha) = year GROUP BY Mes) AS GastosTable
        ON Dates.Mes = GastosTable.Mes
        LEFT JOIN
            (SELECT MONTH(Periodo) AS Mes, SUM(Importe) AS Expensas FROM Expensas WHERE YEAR(Periodo) = year GROUP BY Mes) AS ExpensasTable
        ON Dates.Mes = ExpensasTable.Mes;
        SET error_message = 'La consulta se ejecutó con éxito.';
    END IF;
END;
//
DELIMITER ;

-- Prueba para el error: 'Error: El año a ingresar debe ser 2009'
CALL sp_movimientos(2030, 1, 12, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El mes de inicio debe estar entre 1 y 12.'
CALL sp_movimientos(2009, 0, 12, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El mes de fin debe estar entre 1 y 12.'
CALL sp_movimientos(2009, 1, 14, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El mes de inicio no puede ser mayor que el mes de fin.'
CALL sp_movimientos(2009, 12, 1, @error_message);
SELECT @error_message AS ErrorMessage;

-- Llamada exitosa
CALL sp_movimientos(2009, 5, 9, @error_message);
SELECT @error_message AS ErrorMessage;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación de la vista
-- Realizar una vista, llamada vista_unidades, que muestre un listado de los edificios junto con sus
-- unidades y propietarios (nombre del edificio, domicilio, superficie, piso de la unidad, número de la
-- unidad, tipo, superficie, apellido y nombre del propietario, y domicilio del propietario. La vista deberá
-- mostrar las unidades agrupadas por edificios, ordenadas por piso y número
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

CREATE VIEW vista_unidades AS
SELECT
    E.Nombre AS 'Nombre del Edificio',
    E.Domicilio AS 'Domicilio del Edificio',
    E.Superficie AS 'Superficie del Edificio',
    U.Piso AS 'Piso de la Unidad',
    U.Numero AS 'Número de la Unidad',
    U.Tipo AS 'Tipo de Unidad',
    U.Superficie AS 'Superficie de la Unidad',
    P.Apellidos AS 'Apellido del Propietario',
    P.Nombres AS 'Nombre del Propietario',
    P.Domicilio AS 'Domicilio del Propietario'
FROM
    Edificios E
JOIN
    Unidades U ON E.IdEdificio = U.IdEdificio
JOIN
    Propietarios P ON U.IdPropietario = P.IdPropietario
ORDER BY
    E.Nombre,
    U.Piso,
    U.Numero;

SELECT * FROM vista_unidades;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un SP, llamado sp_alta_unidad, para dar de alta una unidad. Dicho SP deberá efectuar las
-- comprobaciones necesarias y devolver los mensajes de error y resultado de la operación correspondientes
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER //
CREATE PROCEDURE sp_alta_unidad(
    IN p_IdEdificio INT,
    IN p_Piso CHAR(2),
    IN p_Numero CHAR(2),
    IN p_Tipo VARCHAR(15),
    IN p_Superficie INT,
    IN p_IdPropietario INT,
    OUT p_error_message VARCHAR(255)
)
BEGIN
    DECLARE has_error INT DEFAULT 0;

    IF p_IdEdificio IS NULL THEN
        SET p_error_message = 'Error: El IdEdificio es obligatorio.';
        SET has_error = 1;
    ELSEIF p_Piso IS NULL THEN
        SET p_error_message = 'Error: El Piso es obligatorio.';
        SET has_error = 1;
    ELSEIF p_Numero IS NULL THEN
        SET p_error_message = 'Error: El Numero es obligatorio.';
        SET has_error = 1;
    ELSEIF p_Superficie IS NULL THEN
        SET p_error_message = 'Error: La Superficie es obligatoria.';
        SET has_error = 1;
    ELSEIF p_IdPropietario IS NULL THEN
        SET p_error_message = 'Error: El IdPropietario es obligatorio.';
        SET has_error = 1;
    END IF;

    IF p_IdEdificio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Edificios WHERE IdEdificio = p_IdEdificio) THEN
        SET p_error_message = 'Error: El edificio especificado no existe.';
        SET has_error = 1;
    END IF;

    IF p_IdPropietario IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Propietarios WHERE IdPropietario = p_IdPropietario) THEN
        SET p_error_message = 'Error: El propietario especificado no existe.';
        SET has_error = 1;
    END IF;

    IF p_Tipo NOT IN ('Departamento', 'Cochera', 'Local') THEN
        SET p_error_message = 'Error: El tipo de unidad debe ser Departamento, Cochera o Local.';
        SET has_error = 1;
    END IF;

    IF has_error = 0 THEN
        INSERT INTO Unidades(IdEdificio, Piso, Numero, Tipo, Superficie, IdPropietario)
        VALUES (p_IdEdificio, p_Piso, p_Numero, p_Tipo, p_Superficie, p_IdPropietario);
        SET p_error_message = 'La unidad se agregó con éxito.';
    END IF;
END;
//
DELIMITER ;

-- Prueba para el error: 'Error: El IdEdificio es obligatorio.'
CALL sp_alta_unidad(NULL, '01', '01', 'Departamento', 100, 1, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El Piso es obligatorio.'
CALL sp_alta_unidad(1, NULL, '01', 'Departamento', 100, 1, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El Numero es obligatorio.'
CALL sp_alta_unidad(1, '01', NULL, 'Departamento', 100, 1, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: La Superficie es obligatoria.'
CALL sp_alta_unidad(1, '01', '01', 'Departamento', NULL, 1, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El IdPropietario es obligatorio.'
CALL sp_alta_unidad(1, '01', '01', 'Departamento', 100, NULL, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El propietario especificado no existe.'
CALL sp_alta_unidad(1, '01', '01', 'Departamento', 100, 9999, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el error: 'Error: El tipo de unidad debe ser Departamento, Cochera o Local.'
CALL sp_alta_unidad(1, '01', '01', 'Invalido', 100, 1, @error_message);
SELECT @error_message AS ErrorMessage;

-- Prueba para el éxito: 'La unidad se agregó con éxito.'
CALL sp_alta_unidad(1, '2', '2', 'Departamento', 1, 1, @error_message);
SELECT @error_message AS ErrorMessage;
