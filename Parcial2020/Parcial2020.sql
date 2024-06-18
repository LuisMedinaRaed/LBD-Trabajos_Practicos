-- ------------------------------------------------------------------------------------------------------- --
-- Año: 2020
-- Alumno: Medina Raed, Luis Eugenio
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL Server 8.0.28 (Community Edition)
-- GitHub Usuarios: LuisMedinaRaed
-- Examen Final Laboratorio de Bases de Datos 2020

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
-- Date Created : Tuesday, June 18, 2024 00:45:42
-- Target DBMS : MySQL 8.x
--

DROP DATABASE IF EXISTS Parcial2020;
CREATE DATABASE IF NOT EXISTS Parcial2020;
USE Parcial2020;

DROP TABLE IF EXISTS Agencias;

CREATE TABLE IF NOT EXISTS Agencias(
    IDAgencia    INT            NOT NULL,
    Direccion    VARCHAR(45)    NOT NULL,
    Localidad    VARCHAR(45)    NOT NULL,
    PRIMARY KEY (IDAgencia)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Usuarios;

CREATE TABLE IF NOT EXISTS Usuarios(
    IDUsuario    INT            NOT NULL,
    Apellidos    VARCHAR(45)    NOT NULL,
    Nombres      VARCHAR(45)    NOT NULL,
    Domicilio    VARCHAR(45)    NOT NULL,
    Localidad    VARCHAR(45)    NOT NULL,
    CP           VARCHAR(8)     NOT NULL,
    PRIMARY KEY (IDUsuario)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Trabajadores;

CREATE TABLE IF NOT EXISTS Trabajadores(
    Legajo       INT            NOT NULL,
    Documento    INT            NOT NULL,
    Nombres      VARCHAR(45)    NOT NULL,
    Apellidos    VARCHAR(45)    NOT NULL,
    Ingreso      DATE           NOT NULL,
    Clase        VARCHAR(14)    NOT NULL,
    IDAgencia    INT            NOT NULL,
    PRIMARY KEY (Legajo),
    UNIQUE INDEX UI_DocumentoTrabajadores(Documento),
    INDEX IX_IDAgenciaTrabajadores(IDAgencia),
    FOREIGN KEY (IDAgencia)
    REFERENCES Agencias(IDAgencia),
    CHECK (Clase IN ('Oficinista', 'Cartero'))
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Pedidos;

CREATE TABLE IF NOT EXISTS Pedidos(
    IDPedido        VARCHAR(20)      NOT NULL,
    Remitente       INT              NOT NULL,
    Destinatario    INT              NOT NULL,
    Legajo          INT              NOT NULL,
    Costo           DECIMAL(5, 2)    NOT NULL,
    PRIMARY KEY (IDPedido),
    INDEX IX_RemitentePedidos(Remitente),
    INDEX IX_DestinatarioPedidos(Destinatario),
    INDEX IX_LegajoPedidos(Legajo),
    FOREIGN KEY (Remitente)
    REFERENCES Usuarios(IDUsuario),
    FOREIGN KEY (Destinatario)
    REFERENCES Usuarios(IDUsuario),
    FOREIGN KEY (Legajo)
    REFERENCES Trabajadores(Legajo)
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Correspondencias;

CREATE TABLE IF NOT EXISTS Correspondencias(
    IDPedido    VARCHAR(20)    NOT NULL,
    Clase       VARCHAR(12)    NOT NULL,
    Sello       VARCHAR(5)     NOT NULL,
    PRIMARY KEY (IDPedido),
    INDEX IX_IDPedidoCorrespondencias(IDPedido),
    FOREIGN KEY (IDPedido)
    REFERENCES Pedidos(IDPedido),
    CHECK (Clase IN ('Simple', 'Certificada', 'Express')),
    CHECK (Sello IN ('Negro', 'Rojo'))
)ENGINE=INNODB
;

DROP TABLE IF EXISTS Paquetes;

CREATE TABLE IF NOT EXISTS Paquetes(
    IDPedido    VARCHAR(20)    NOT NULL,
    Tipo        VARCHAR(40)    NOT NULL,
    PRIMARY KEY (IDPedido),
    INDEX IX_IDPedidoPaquetes(IDPedido),
    FOREIGN KEY (IDPedido)
    REFERENCES Pedidos(IDPedido),
    CHECK (Tipo IN ('El usuario lo prepara', 'La agencia lo prepara'))
)ENGINE=INNODB
;

DROP TABLE IF EXISTS PedidosPorAgencias;

CREATE TABLE IF NOT EXISTS PedidosPorAgencias(
    IDAgencia     INT            NOT NULL,
    IDPedido      VARCHAR(20)    NOT NULL,
    FechaYHora    DATETIME       NOT NULL,
    PRIMARY KEY (IDAgencia, IDPedido),
    INDEX IX_IDAgenciaPedidosPorAgencias(IDAgencia),
    INDEX IX_IDPedidoPedidosPorAgencias(IDPedido),
    FOREIGN KEY (IDAgencia)
    REFERENCES Agencias(IDAgencia),
    FOREIGN KEY (IDPedido)
    REFERENCES Pedidos(IDPedido)
)ENGINE=INNODB
;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 2: Creación del Stored Procedure
-- Realizar un procedimiento almacenado, llamado BorrarTrabajador, para borrar un
-- trabajador. El mismo deberá incluir el control de errores lógicos y mensajes de error
-- necesarios. Incluir el código con la llamada al procedimiento probando todos los
-- casos con datos incorrectos y uno con datos correctos.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS BorrarTrabajador;

DELIMITER //
CREATE PROCEDURE BorrarTrabajador(IN p_legajo INT)
borrar_trabajador: BEGIN
    -- Verificar si el trabajador existe
    IF NOT EXISTS (SELECT 1 FROM Trabajadores WHERE Legajo = p_legajo) THEN
        SELECT 'Error: No existe un trabajador con ese legajo.';
        LEAVE borrar_trabajador;
    END IF;

    -- Verificar si el trabajador está referenciado en la tabla Pedidos
    IF EXISTS (SELECT 1 FROM Pedidos WHERE Legajo = p_legajo) THEN
        SELECT 'Error: No se puede borrar el trabajador porque está referenciado en la tabla Pedidos.';
        LEAVE borrar_trabajador;
    END IF;

    -- Si no hay errores, borrar el trabajador
    DELETE FROM Trabajadores WHERE Legajo = p_legajo;
    SELECT CONCAT('El trabajador con legajo ', p_legajo, ' ha sido borrado con éxito.');
END //
DELIMITER ;

CALL BorrarTrabajador(9999); -- Legajo que no existe
CALL BorrarTrabajador(320001); -- Legajo que está referenciado en la tabla Pedidos

SELECT t.Legajo
FROM Trabajadores t
LEFT JOIN Pedidos p ON t.Legajo = p.Legajo
WHERE p.Legajo IS NULL;

CALL BorrarTrabajador(10003); -- Legajo que puede ser borrado

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 3: Creación del Stored Procedure
-- Realizar un procedimiento almacenado, llamado RankingUsuariosPorPedidos,
-- para que muestre un ranking con los usuarios que más pedidos realizan (por costo)
-- entre un rango de fechas.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS RankingUsuariosPorPedidos;

DELIMITER //
CREATE PROCEDURE RankingUsuariosPorPedidos(IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT u.IDUsuario, u.Apellidos, u.Nombres, SUM(p.Costo) AS TotalCosto
    FROM Usuarios u
    JOIN Pedidos p ON u.IDUsuario = p.Remitente
    JOIN PedidosPorAgencias pa ON p.IDPedido = pa.IDPedido
    WHERE pa.FechaYHora BETWEEN p_fecha_inicio AND p_fecha_fin
    GROUP BY u.IDUsuario
    ORDER BY TotalCosto DESC
    LIMIT 10;
END //
DELIMITER ;

CALL RankingUsuariosPorPedidos('2014-01-01', '2015-12-31');


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 4: Creación de la vista
-- Crear una vista, llamada RutaPaquete, para que muestre toda la ruta de un paquete
-- determinado. Se deberá mostrar el número de pedido, dirección y localidad de la
-- agencia, fecha y hora por la que pasa por la agencia, apellido y nombre del
-- remitente, apellido y nombre del destinatario. El listado deberá estar ordenado
-- descendentemente por fecha y hora.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP VIEW IF EXISTS RutaPaquete;

CREATE VIEW RutaPaquete AS
SELECT
    p.IDPedido,
    CONCAT(UPPER(SUBSTRING(a.Direccion, 1, 1)), LOWER(SUBSTRING(a.Direccion, 2))) AS Direccion,
    a.Localidad,
    pa.FechaYHora,
    CONCAT_WS(', ', r.Apellidos, r.Nombres) AS Remitente,
    CONCAT_WS(', ', d.Apellidos, d.Nombres) AS Destinatario
FROM
    Pedidos p
JOIN
    PedidosPorAgencias pa ON p.IDPedido = pa.IDPedido
JOIN
    Agencias a ON pa.IDAgencia = a.IDAgencia
JOIN
    Usuarios r ON p.Remitente = r.IDUsuario
JOIN
    Usuarios d ON p.Destinatario = d.IDUsuario
ORDER BY
    pa.FechaYHora DESC;

SELECT * FROM RutaPaquete WHERE IDPedido = 'b9';

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- Apartado 5: Creación del Trigger
-- Implementar la lógica para llevar una auditoría para la operación del apartado 2. Se
-- deberá auditar el usuario que la hizo, la fecha y hora de la operación, la máquina
-- desde donde se la hizo y toda la información necesaria para la auditoría.
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS AuditoriaBorrarTrabajador;

-- Creación de la tabla de auditoría
CREATE TABLE IF NOT EXISTS AuditoriaBorrarTrabajador (
    IDAuditoria INT AUTO_INCREMENT PRIMARY KEY,
    Usuario VARCHAR(45) NOT NULL,
    FechaHora DATETIME NOT NULL,
    Maquina VARCHAR(45) NOT NULL,
    Legajo INT NOT NULL,
    Documento INT NOT NULL,
    Nombres VARCHAR(45) NOT NULL,
    Apellidos VARCHAR(45) NOT NULL,
    Ingreso DATE NOT NULL,
    Clase VARCHAR(14) NOT NULL,
    IDAgencia INT NOT NULL
);

DROP TRIGGER IF EXISTS Trabajadores_BEFORE_DELETE;

-- Creación del trigger
CREATE TRIGGER IF NOT EXISTS Trabajadores_BEFORE_DELETE
BEFORE DELETE ON Trabajadores
FOR EACH ROW
BEGIN
    INSERT INTO AuditoriaBorrarTrabajador (Usuario, FechaHora, Maquina, Legajo, Documento, Nombres, Apellidos, Ingreso, Clase, IDAgencia)
    VALUES (USER(), NOW(), @@hostname, OLD.Legajo, OLD.Documento, OLD.Nombres, OLD.Apellidos, OLD.Ingreso, OLD.Clase, OLD.IDAgencia);
END;

-- Prueba del trigger
-- Verificar los trabajadores existentes
SELECT * FROM Trabajadores;

-- Intentar borrar un trabajador con Legajo 10003
CALL BorrarTrabajador(10004);

-- Verificar si se ha insertado un registro en la tabla de auditoría
SELECT * FROM AuditoriaBorrarTrabajador;

-- Intentar borrar un trabajador que no existe
CALL BorrarTrabajador(999);

-- Verificar que no se ha insertado un registro en la tabla de auditoría
SELECT * FROM AuditoriaBorrarTrabajador;



