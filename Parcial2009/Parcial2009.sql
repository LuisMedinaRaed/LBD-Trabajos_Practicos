-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2009
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2009
-- ------------------------------------------------------------------------------------------------------- --

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
--  Apartado 1: Creación de la Base de datos y sus Constraints
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

--
-- ER/Studio Data Architect SQL Code Generation
-- Project :      Parcial2009.DM1
--
-- Date Created : Sunday, June 16, 2024 01:51:49
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2009;
CREATE DATABASE Parcial2009;
USE Parcial2009;

CREATE TABLE Cargos(
    IdCargo    INT            NOT NULL,
    Cargo      VARCHAR(50)    NOT NULL,
    PRIMARY KEY (IdCargo),
    UNIQUE INDEX UI_Cargo(Cargo)
)ENGINE=INNODB
;

CREATE TABLE Empleados(
    IdEmpleado    INT            NOT NULL,
    IdCargo       INT            NOT NULL,
    IdJefe        INT,
    Apellidos     VARCHAR(50)    NOT NULL,
    Nombres       VARCHAR(50),
    Direccion     VARCHAR(75)    NOT NULL,
    Telefono      CHAR(7)        NOT NULL CHECK (Telefono REGEXP '^4[0-9]{6}$'),
    PRIMARY KEY (IdEmpleado),
    INDEX IX_ApellidosNombres(Apellidos, Nombres),
    INDEX IX_IdCargo(IdCargo),
    INDEX IX_IdJefe(IdJefe),
    FOREIGN KEY (IdCargo)
    REFERENCES Cargos(IdCargo),
    FOREIGN KEY (IdJefe)
    REFERENCES Empleados(IdEmpleado)
)ENGINE=INNODB
;

CREATE TABLE Obras(
    IdObra           INT            NOT NULL,
    NombreObra       VARCHAR(75)    NOT NULL,
    DireccionObra    VARCHAR(75)    NOT NULL,
    TotalHoras       INT            NOT NULL,
    PRIMARY KEY (IdObra),
    UNIQUE INDEX UI_NombreObra(NombreObra)
)ENGINE=INNODB
;

CREATE TABLE Trabajos(
    IdObra         INT             NOT NULL,
    IdTrabajo      INT             NOT NULL,
    Descripcion    VARCHAR(100)    NOT NULL,
    Horas          INT,
    Estado         CHAR(1)         NOT NULL CHECK (Estado IN ('A', 'B')),
    PRIMARY KEY (IdObra, IdTrabajo),
    INDEX IX_IdObra(IdObra),
    FOREIGN KEY (IdObra)
    REFERENCES Obras(IdObra)
)ENGINE=INNODB
;

CREATE TABLE TrabajaEn(
    IdObra             INT    NOT NULL,
    IdTrabajo          INT    NOT NULL,
    IdEmpleado         INT    NOT NULL,
    HorasTrabajadas    INT    NOT NULL,
    PRIMARY KEY (IdObra, IdTrabajo, IdEmpleado),
    INDEX IX_IdEmpleado(IdEmpleado),
    INDEX IX_IdObraIdTrabajo(IdObra, IdTrabajo),
    FOREIGN KEY (IdObra, IdTrabajo)
    REFERENCES Trabajos(IdObra, IdTrabajo),
    FOREIGN KEY (IdEmpleado)
    REFERENCES Empleados(IdEmpleado)
)ENGINE=INNODB
;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación del Stored Procedure:
-- Crear un SP que dado IdEmpleado, liste los empleados a su cargo (solo 1 nivel) y la cantidad de horas
-- trabajadas por cada uno (IdEmpleado, Apellidos, Nombres, Cargo, TotalHoras) y una fila al final con el
-- total de horas de todos los empleados. Llamarlo rsp_empleados_a_cargo.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE rsp_empleados_a_cargo(IN _IdEmpleado INT, OUT _Mensaje VARCHAR(255))
BEGIN
    -- Comprobar si el empleado existe
    IF NOT EXISTS (SELECT 1 FROM Parcial2009.Empleados WHERE IdEmpleado = _IdEmpleado) THEN
        SET _Mensaje = 'Error: El empleado no existe.';
    ELSE
        -- Crear una tabla temporal para almacenar los resultados
        CREATE TEMPORARY TABLE IF NOT EXISTS Resultado AS
        SELECT E.IdEmpleado, E.Apellidos, E.Nombres, C.Cargo, ROUND(SUM(TE.HorasTrabajadas), 0) as TotalHoras
        FROM Parcial2009.Empleados E
        JOIN Parcial2009.Cargos C ON E.IdCargo = C.IdCargo
        JOIN Parcial2009.TrabajaEn TE ON E.IdEmpleado = TE.IdEmpleado
        WHERE E.IdJefe = _IdEmpleado
        GROUP BY E.IdEmpleado;

        -- Comprobar si el empleado tiene empleados a su cargo
        IF (SELECT COUNT(*) FROM Resultado) = 0 THEN
            SET _Mensaje = 'Error: El empleado no tiene empleados a su cargo.';
        ELSE
            -- Calcular el total de horas trabajadas por todos los empleados
            SELECT ROUND(SUM(TotalHoras), 0) INTO @totalHoras FROM Resultado;

            -- Seleccionar todos los empleados y sus horas trabajadas
            SELECT * FROM Resultado
            UNION ALL
            -- Seleccionar el total de horas trabajadas por todos los empleados
            SELECT NULL, NULL, NULL, 'Total', CAST(@totalHoras AS UNSIGNED);

            SET _Mensaje = 'Consulta ejecutada con éxito.';
        END IF;

        -- Eliminar la tabla temporal
        DROP TEMPORARY TABLE IF EXISTS Resultado;
    END IF;
END$$

DELIMITER ;

-- Llamada de prueba de éxito
CALL rsp_empleados_a_cargo(1, @Mensaje); -- El IdEmpleado 1 existe y tiene empleados a su cargo
SELECT @Mensaje;

-- Llamada de prueba de error: empleado no existe
CALL rsp_empleados_a_cargo(9999, @Mensaje); -- El IdEmpleado 9999 no existe
SELECT @Mensaje;

-- Llamada de prueba de error: empleado no tiene empleados a su cargo
CALL rsp_empleados_a_cargo(4, @Mensaje); -- El IdEmpleado 4 existe pero no tiene empleados a su cargo
SELECT @Mensaje;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación de la Vista:
-- Realizar una vista que muestre un listado de trabajos con el total de horas estimado y el real trabajado
-- (NombreObra, Descripción, Horas, Total HorasTrabajadas). Llamarla vista_trabajos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

CREATE VIEW vista_trabajos AS
SELECT O.NombreObra, T.Descripcion, T.Horas, SUM(TE.HorasTrabajadas) as 'Total HorasTrabajadas'
FROM Parcial2009.Obras O
JOIN Parcial2009.Trabajos T ON O.IdObra = T.IdObra
JOIN Parcial2009.TrabajaEn TE ON T.IdObra = TE.IdObra AND T.IdTrabajo = TE.IdTrabajo
GROUP BY O.NombreObra, T.Descripcion, T.Horas;

SELECT * FROM vista_trabajos;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación del Stored Procedure
-- Realizar un SP para dar de alta un empleado. Efectuar las comprobaciones y devolver mensajes de error.
-- Llamarlo rsp_alta_empleado.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE rsp_alta_empleado(
    IN _IdEmpleado INT,
    IN _IdCargo INT,
    IN _IdJefe INT,
    IN _Apellidos VARCHAR(50),
    IN _Nombres VARCHAR(50),
    IN _Direccion VARCHAR(75),
    IN _Telefono CHAR(7),
    OUT _Mensaje VARCHAR(255)
)
BEGIN
    -- Comprobar si el empleado ya existe
    IF EXISTS (SELECT 1 FROM Empleados WHERE IdEmpleado = _IdEmpleado) THEN
        SET _Mensaje = 'Error: El empleado ya existe.';
    -- Comprobar si el cargo existe
    ELSEIF NOT EXISTS (SELECT 1 FROM Cargos WHERE IdCargo = _IdCargo) THEN
        SET _Mensaje = 'Error: El cargo no existe.';
    -- Comprobar si el jefe existe
    ELSEIF NOT EXISTS (SELECT 1 FROM Empleados WHERE IdEmpleado = _IdJefe) THEN
        SET _Mensaje = 'Error: El jefe no existe.';
    -- Comprobar si el número de teléfono es válido
    ELSEIF NOT _Telefono REGEXP '^4[0-9]{6}$' THEN
        SET _Mensaje = 'Error: El número de teléfono no es válido.';
    ELSE
        -- Insertar los detalles del empleado
        INSERT INTO Parcial2009.Empleados (IdEmpleado, IdCargo, IdJefe, Apellidos, Nombres, Direccion, Telefono)
        VALUES (_IdEmpleado, _IdCargo, _IdJefe, _Apellidos, _Nombres, _Direccion, _Telefono);

        SET _Mensaje = 'Empleado dado de alta con éxito.';
    END IF;
END$$

DELIMITER ;

-- Llamada de prueba de éxito
CALL rsp_alta_empleado(100, 1, 1, 'Apellido', 'Nombre', 'Direccion', '4000000', @Mensaje); -- El IdEmpleado 100 no existe y el IdCargo 1 y IdJefe 1 existen
SELECT @Mensaje;

-- Llamada de prueba de error: empleado ya existe
CALL rsp_alta_empleado(1, 1, 1, 'Apellido', 'Nombre', 'Direccion', '4000000', @Mensaje); -- El IdEmpleado 1 ya existe
SELECT @Mensaje;

-- Llamada de prueba de error: cargo no existe
CALL rsp_alta_empleado(101, 9999, 1, 'Apellido', 'Nombre', 'Direccion', '4000000', @Mensaje); -- El IdCargo 9999 no existe
SELECT @Mensaje;

-- Llamada de prueba de error: jefe no existe
CALL rsp_alta_empleado(101, 1, 9999, 'Apellido', 'Nombre', 'Direccion', '4000000', @Mensaje); -- El IdJefe 9999 no existe
SELECT @Mensaje;

-- Llamada de prueba de error: número de teléfono no válido
CALL rsp_alta_empleado(101, 1, 1, 'Apellido', 'Nombre', 'Direccion', '5000000', @Mensaje); -- El número de teléfono no comienza con 4
SELECT @Mensaje;