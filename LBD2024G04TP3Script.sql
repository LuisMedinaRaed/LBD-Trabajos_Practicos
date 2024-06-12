-- Año: 2024
-- Grupo Nro: 4
-- Integrantes: Lozano Iñaki Fernando, Medina Raed Luis Eugenio
-- Tema: Gestión de stock y distribución de bebidas gaseosas
-- Nombre del Esquema LBD2024G04
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL 8.0.30
-- GitHub Repositorio: LBD2024G04
-- GitHub Usuario: InakiLozano01, LuisMedinaRaed

-- -----------------------------------------------------
-- TRABAJO PRACTICO Nº3
-- -----------------------------------------------------

-- -----------------------------------------------------
-- TRIGGERS 
-- -----------------------------------------------------

-- Creación de la tabla de auditoría
CREATE TABLE AuditoriaClientes (
    idAuditoria INT AUTO_INCREMENT PRIMARY KEY,
    idCliente INT,
    columnaModificada VARCHAR(60),
    oldValue VARCHAR(255),
    newValue VARCHAR(255),
    tipoOperacion ENUM('CREACION', 'MODIFICACION', 'BORRADO'),
    usuario VARCHAR(100),
    fechaHora DATETIME,
    maquina VARCHAR(100)
) ENGINE=INNODB;

-- Cambiar delimitador para poder crear triggers con múltiples sentencias
DELIMITER $$

-- Trigger para la creación (INSERT)
CREATE TRIGGER trgClientesInsert
AFTER INSERT ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO AuditoriaClientes (
        idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina
    )
    VALUES
        (NEW.idCliente, 'idZona', NULL, NEW.idZona, 'CREACION', USER(), NOW(), @@hostname),
        (NEW.idCliente, 'cliente', NULL, NEW.cliente, 'CREACION', USER(), NOW(), @@hostname),
        (NEW.idCliente, 'cuil', NULL, NEW.cuil, 'CREACION', USER(), NOW(), @@hostname),
        (NEW.idCliente, 'email', NULL, NEW.email, 'CREACION', USER(), NOW(), @@hostname),
        (NEW.idCliente, 'direccion', NULL, NEW.direccion, 'CREACION', USER(), NOW(), @@hostname),
        (NEW.idCliente, 'telefono', NULL, NEW.telefono, 'CREACION', USER(), NOW(), @@hostname),
        (NEW.idCliente, 'estado', NULL, NEW.estado, 'CREACION', USER(), NOW(), @@hostname);
END$$

-- Trigger para la modificación (UPDATE)
CREATE TRIGGER trgClientesUpdate
AFTER UPDATE ON Clientes
FOR EACH ROW
BEGIN
    IF NOT (NEW.idZona <=> OLD.idZona) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'idZona', OLD.idZona, NEW.idZona, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;

    IF NOT (NEW.cliente <=> OLD.cliente) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'cliente', OLD.cliente, NEW.cliente, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;

    IF NOT (NEW.cuil <=> OLD.cuil) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'cuil', OLD.cuil, NEW.cuil, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;

    IF NOT (NEW.email <=> OLD.email) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'email', OLD.email, NEW.email, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;

    IF NOT (NEW.direccion <=> OLD.direccion) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'direccion', OLD.direccion, NEW.direccion, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;

    IF NOT (NEW.telefono <=> OLD.telefono) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'telefono', OLD.telefono, NEW.telefono, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;

    IF NOT (NEW.estado <=> OLD.estado) THEN
        INSERT INTO AuditoriaClientes (idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina)
        VALUES (NEW.idCliente, 'estado', OLD.estado, NEW.estado, 'MODIFICACION', USER(), NOW(), @@hostname);
    END IF;
END$$

-- Trigger para la eliminación (DELETE)
CREATE TRIGGER trgClientesDelete
AFTER DELETE ON Clientes
FOR EACH ROW
BEGIN
    INSERT INTO AuditoriaClientes (
        idCliente, columnaModificada, oldValue, newValue, tipoOperacion, usuario, fechaHora, maquina
    )
    VALUES
        (OLD.idCliente, 'idZona', OLD.idZona, NULL, 'BORRADO', USER(), NOW(), @@hostname),
        (OLD.idCliente, 'cliente', OLD.cliente, NULL, 'BORRADO', USER(), NOW(), @@hostname),
        (OLD.idCliente, 'cuil', OLD.cuil, NULL, 'BORRADO', USER(), NOW(), @@hostname),
        (OLD.idCliente, 'email', OLD.email, NULL, 'BORRADO', USER(), NOW(), @@hostname),
        (OLD.idCliente, 'direccion', OLD.direccion, NULL, 'BORRADO', USER(), NOW(), @@hostname),
        (OLD.idCliente, 'telefono', OLD.telefono, NULL, 'BORRADO', USER(), NOW(), @@hostname),
        (OLD.idCliente, 'estado', OLD.estado, NULL, 'BORRADO', USER(), NOW(), @@hostname);
END$$

-- Restaurar el delimitador predeterminado
DELIMITER ;

-- Insertar registros de prueba en la tabla Clientes
INSERT INTO Clientes (idZona, cliente, cuil, email, direccion, telefono, estado) VALUES (25, 'Distribuidora Santiago', '20345678901', 'clienteC@example.com', 'Calle Verde 123', '+543852363678', 'A');

-- Actualizar un registro en la tabla Clientes
UPDATE Clientes SET direccion = 'Calle Verde 456', telefono = '+543852362678' WHERE idCliente = 1;

-- Eliminar un registro de la tabla Clientes
DELETE FROM Clientes WHERE idCliente = 2;

-- -----------------------------------------------------
-- PROCEDIMIENTOS ALMACENADOS
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Creación de un cliente.
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE CrearCliente(
    IN p_idZona INT,
    IN p_cliente VARCHAR(60),
    IN p_cuil CHAR(11),
    IN p_email VARCHAR(120),
    IN p_direccion VARCHAR(120),
    IN p_telefono VARCHAR(60),
    IN p_estado CHAR(1),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        ROLLBACK;
        SET p_mensaje = 'Error en la inserción del cliente.';
    END;

    START TRANSACTION;

    -- Validaciones
    IF p_estado NOT IN ('A', 'B') THEN
        SET p_mensaje = 'Estado no válido.';
        ROLLBACK;
    ELSEIF CHAR_LENGTH(p_telefono) > 15 THEN
        SET p_mensaje = 'Teléfono demasiado largo.';
        ROLLBACK;
    ELSEIF NOT (p_telefono REGEXP '^[+]?[0-9]+$') THEN
        SET p_mensaje = 'Teléfono no válido.';
        ROLLBACK;
    ELSEIF NOT (p_cuil REGEXP '^[0-9]{11}$') THEN
        SET p_mensaje = 'CUIL no válido.';
        ROLLBACK;
    ELSEIF NOT (p_email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$') THEN
        SET p_mensaje = 'Email no válido.';
        ROLLBACK;
    ELSEIF NOT EXISTS (SELECT 1 FROM Zonas WHERE idZona = p_idZona AND estado = 'A') THEN
        SET p_mensaje = 'Zona no encontrada o inactiva.';
        ROLLBACK;
    ELSE
        -- Inserción del cliente
        INSERT INTO Clientes (idZona, cliente, cuil, email, direccion, telefono, estado)
        VALUES (p_idZona, p_cliente, p_cuil, p_email, p_direccion, p_telefono, p_estado);

        COMMIT;
        SET p_mensaje = 'Cliente creado exitosamente.';
    END IF;
END //

DELIMITER ;

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
-- Llamada correcta
CALL CrearCliente(3, 'Cliente Ejemplo', '20304050607', 'cliente@ejemplo.com', 'Direccion Ejemplo 123', '+541122334455', 'A', @mensaje);
SELECT @mensaje;

-- Llamada con error: estado no válido
CALL CrearCliente(2, 'Cliente Ejemplo', '20304050607', 'cliente@ejemplo.com', 'Direccion Ejemplo 123', '+541122334455', 'C', @mensaje);
-- Intención: Probar el control de error para un estado no válido.
SELECT @mensaje;

-- Llamada con error: teléfono demasiado largo
CALL CrearCliente(1, 'Cliente Ejemplo', '20304050607', 'cliente@ejemplo.com', 'Direccion Ejemplo 123', '+5411223344556677889900', 'A', @mensaje);
-- Intención: Probar el control de error para un teléfono demasiado largo.
SELECT @mensaje;

-- Llamada con error: teléfono no válido
CALL CrearCliente(1, 'Cliente Ejemplo', '20304050607', 'cliente@ejemplo.com', 'Direccion Ejemplo 123', '+5411ASF4455', 'A', @mensaje);
-- Intención: Probar el control de error para un formato de teléfono no válido.
SELECT @mensaje;

-- Llamada con error: CUIL no válido
CALL CrearCliente(1, 'Cliente Ejemplo', 'CUIL_INVAL', 'cliente@ejemplo.com', 'Direccion Ejemplo 123', '+541122334455', 'A', @mensaje);
-- Intención: Probar el control de error para un formato de CUIL no válido.
SELECT @mensaje;

-- Llamada con error: email no válido
CALL CrearCliente(1, 'Cliente Ejemplo', '20304050607', 'email_invalido', 'Direccion Ejemplo 123', '+541122334455', 'A', @mensaje);
-- Intención: Probar el control de error para un formato de email no válido.
SELECT @mensaje;


-- -----------------------------------------------------
-- Modificación de un cliente.
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE ModificarCliente(
    IN p_idCliente INT,
    IN p_idZona INT,
    IN p_cliente VARCHAR(60),
    IN p_cuil CHAR(11),
    IN p_email VARCHAR(120),
    IN p_direccion VARCHAR(120),
    IN p_telefono VARCHAR(15),
    IN p_estado CHAR(1),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        ROLLBACK;
        SET p_mensaje = 'Error en la modificación del cliente.';
    END;

    START TRANSACTION;

    -- Validaciones
    IF p_estado NOT IN ('A', 'B') THEN
        SET p_mensaje = 'Estado no válido.';
        ROLLBACK;
    ELSEIF NOT (p_telefono REGEXP '^[+]?[0-9]+$') THEN
        SET p_mensaje = 'Teléfono no válido.';
        ROLLBACK;
    ELSEIF NOT (p_cuil REGEXP '^[0-9]{11}$') THEN
        SET p_mensaje = 'CUIL no válido.';
        ROLLBACK;
    ELSEIF NOT (p_email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$') THEN
        SET p_mensaje = 'Email no válido.';
        ROLLBACK;
    ELSEIF NOT EXISTS (SELECT 1 FROM Zonas WHERE idZona = p_idZona AND estado = 'A') THEN
        SET p_mensaje = 'Zona no encontrada o inactiva.';
        ROLLBACK;
    ELSEIF NOT EXISTS (SELECT 1 FROM Clientes WHERE idCliente = p_idCliente) THEN
        SET p_mensaje = 'Cliente no encontrado.';
        ROLLBACK;
    ELSE
        -- Actualización del cliente
        UPDATE Clientes
        SET idZona = p_idZona,
            cliente = p_cliente,
            cuil = p_cuil,
            email = p_email,
            direccion = p_direccion,
            telefono = p_telefono,
            estado = p_estado
        WHERE idCliente = p_idCliente;

        COMMIT;
        SET p_mensaje = 'Cliente modificado exitosamente.';
    END IF;
END //

DELIMITER ;

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
-- Llamada correcta
CALL ModificarCliente(7, 7, 'Distribuidora Pepito', '16123456789', 'info@distrilafuente.com', 'Calle Alem 123', '+543856789012', 'A', @mensaje);
SELECT @mensaje;

-- Llamada con error: estado no válido
CALL ModificarCliente(1, 2, 'Cliente Modificado', '20304050607', 'cliente_modificado@ejemplo.com', 'Direccion Modificada 123', '+541122334455', 'C', @mensaje);
-- Intención: Probar el control de error para un estado no válido.
SELECT @mensaje;

-- Llamada con error: teléfono no válido
CALL ModificarCliente(1, 2, 'Cliente Modificado', '20304050607', 'cliente_modificado@ejemplo.com', 'Direccion Modificada 123', '+54381ASF4567', 'A', @mensaje);
-- Intención: Probar el control de error para un formato de teléfono no válido.
SELECT @mensaje;

-- Llamada con error: cliente no encontrado
CALL ModificarCliente(999, 7, 'Cliente Modificado', '20304050607', 'cliente_modificado@ejemplo.com', 'Direccion Modificada 123', '+541122334455', 'A', @mensaje);
-- Intención: Probar el control de error para un cliente inexistente.
SELECT @mensaje;

-- -----------------------------------------------------
-- Borrado de un cliente.
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE BorrarCliente(
    IN p_idCliente INT,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        ROLLBACK;
        SET p_mensaje = 'Error en la eliminación del cliente.';
    END;

    START TRANSACTION;

    -- Validación: Verificar si el cliente existe
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE idCliente = p_idCliente) THEN
        SET p_mensaje = 'Cliente no encontrado.';
        ROLLBACK;
    ELSE
        -- Validación: Verificar si el cliente está inactivo
        IF EXISTS (SELECT 1 FROM Clientes WHERE idCliente = p_idCliente AND estado = 'A') THEN
            SET p_mensaje = 'No se puede eliminar el cliente. El cliente está activo. Se debe dar de baja primero.';
            ROLLBACK;
        -- Validación: Verificar si el cliente tiene pedidos asociados
        ELSEIF EXISTS (SELECT 1 FROM Pedidos WHERE idCliente = p_idCliente) THEN
            SET p_mensaje = 'No se puede eliminar el cliente. Tiene pedidos asociados.';
            ROLLBACK;
        ELSE
            -- Eliminación del cliente
            DELETE FROM Clientes WHERE idCliente = p_idCliente;

            COMMIT;
            SET p_mensaje = 'Cliente eliminado exitosamente.';
        END IF;
    END IF;
END //

DELIMITER ;

-- -----------------------------------------------------
-- Cambiamos el estado de un cliente a Baja para luego eliminarlo
UPDATE Clientes
SET estado = 'B'
WHERE idCliente = 76; 
-- -----------------------------------------------------

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
-- Caso de éxito: Cliente sin pedidos
CALL BorrarCliente(76, @mensaje);
SELECT @mensaje AS mensaje; -- Debería devolver "Cliente eliminado exitosamente."

-- Llamada con error: cliente no encontrado
CALL BorrarCliente(999, @mensaje);
-- Intención: Probar el control de error para un cliente inexistente.
SELECT @mensaje;

-- Llamada con error: cliente con pedidos existentes
CALL BorrarCliente(4, @mensaje);
-- Intención: Probar el control de error para un cliente con pedidos existentes.
SELECT @mensaje;

-- Error: Cliente activo
CALL BorrarCliente(3, @mensaje);
SELECT @mensaje AS mensaje; -- Debería devolver "No se puede eliminar el cliente. El cliente está activo. Se debe dar de baja primero."

-- -----------------------------------------------------
-- Buscar Clientes
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE BuscarCliente(
    IN p_cliente VARCHAR(60),
    OUT p_idCliente INT,
    OUT p_cuil CHAR(11),
    OUT p_email VARCHAR(120),
    OUT p_direccion VARCHAR(120),
    OUT p_telefono VARCHAR(15),
    OUT p_estado CHAR(1),
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        SET p_mensaje = 'Error en la búsqueda del cliente.';
    END;

    -- Inicializar los parámetros de salida
    SET p_idCliente = NULL;
    SET p_cuil = NULL;
    SET p_email = NULL;
    SET p_direccion = NULL;
    SET p_telefono = NULL;
    SET p_estado = NULL;

    -- Validación: Verificar si el nombre de cliente es válido
    IF p_cliente IS NULL OR p_cliente = '' THEN
        SET p_mensaje = 'Nombre de cliente no válido.';
    ELSE
        -- Validación: Verificar si el cliente existe
        IF NOT EXISTS (SELECT 1 FROM Clientes WHERE cliente = p_cliente) THEN
            SET p_mensaje = 'Cliente no encontrado.';
        ELSE
            -- Recuperar la información del cliente
            SELECT idCliente, cuil, email, direccion, telefono, estado
            INTO p_idCliente, p_cuil, p_email, p_direccion, p_telefono, p_estado
            FROM Clientes
            WHERE cliente = p_cliente;

            -- Verificar si el cliente está inactivo
            IF p_estado = 'B' THEN
                SET p_mensaje = 'Cliente encontrado pero está inactivo.';
            ELSE
                SET p_mensaje = 'Cliente encontrado exitosamente.';
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
-- Caso de éxito: Cliente existe
CALL BuscarCliente('Distribuidora La Colina', @idCliente, @cuil, @email, @direccion, @telefono, @estado, @mensaje);
SELECT @idCliente AS idCliente, @cuil AS cuil, @email AS email, @direccion AS direccion, @telefono AS telefono, @estado AS estado, @mensaje AS mensaje;
-- Debería devolver los datos del cliente y el mensaje "Cliente encontrado exitosamente."

-- Error: Cliente no existe
CALL BuscarCliente('Nombre Inexistente', @idCliente, @cuil, @email, @direccion, @telefono, @estado, @mensaje);
SELECT @idCliente AS idCliente, @cuil AS cuil, @email AS email, @direccion AS direccion, @telefono AS telefono, @estado AS estado, @mensaje AS mensaje;
-- Debería devolver "Cliente no encontrado."

-- Error: Nombre de cliente no válido (cadena vacía)
CALL BuscarCliente('', @idCliente, @cuil, @email, @direccion, @telefono, @estado, @mensaje);
SELECT @idCliente AS idCliente, @cuil AS cuil, @email AS email, @direccion AS direccion, @telefono AS telefono, @estado AS estado, @mensaje AS mensaje;
-- Debería devolver "Nombre de cliente no válido."

-- Error: Cliente inactivo 
CALL BuscarCliente('Mayorista La Perla', @idCliente, @cuil, @email, @direccion, @telefono, @estado, @mensaje);
SELECT @idCliente AS idCliente, @cuil AS cuil, @email AS email, @direccion AS direccion, @telefono AS telefono, @estado AS estado, @mensaje AS mensaje;
-- Debería devolver los datos del cliente y el mensaje "Cliente encontrado pero está inactivo.", pero mostrando el estado 'B'


-- -----------------------------------------------------
-- Dado un producto, realizar un listado de sus entradas entre un rango de fechas,
-- mostrando el nombre del producto, fecha de la entrada, nombre y correo del
-- proveedor.
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE ListarEntradasProducto(
    IN p_idProducto INT,
    IN p_fechaInicio DATETIME,
    IN p_fechaFin DATETIME,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        SET p_mensaje = 'Error en la búsqueda de entradas.';
    END;

    -- Validaciones iniciales
    IF p_fechaInicio > p_fechaFin THEN
        SET p_mensaje = 'La fecha de inicio no puede ser mayor que la fecha de fin.';
    ELSEIF p_idProducto <= 0 THEN
        SET p_mensaje = 'ID de producto no válido.';
    ELSEIF NOT EXISTS (SELECT 1 FROM Productos WHERE idProducto = p_idProducto) THEN
        SET p_mensaje = 'Producto no encontrado.';
    ELSE
        -- Realizar la consulta
        SELECT p.producto, e.fecha, pr.proveedor, pr.email
        FROM LineasEntrada le
        JOIN Entradas e ON le.idEntrada = e.idEntrada AND le.idProveedor = e.idProveedor
        JOIN Proveedores pr ON e.idProveedor = pr.idProveedor
        JOIN Productos p ON le.idProducto = p.idProducto
        WHERE le.idProducto = p_idProducto
          AND e.fecha BETWEEN p_fechaInicio AND p_fechaFin
        ORDER BY e.fecha;

        SET p_mensaje = 'Listado generado exitosamente.';
    END IF;
END //

DELIMITER ;

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
-- Caso de éxito: Producto existe y hay entradas en el rango de fechas
CALL ListarEntradasProducto(10, '2023-01-01 00:00:00', '2024-12-31 23:59:59', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver las entradas del producto y el mensaje "Listado generado exitosamente."

-- Error: Producto no existe
CALL ListarEntradasProducto(999, '2023-01-01 00:00:00', '2023-12-31 23:59:59', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver "Producto no encontrado."

-- Error: ID de producto no válido (negativo o cero)
CALL ListarEntradasProducto(-1, '2023-01-01 00:00:00', '2023-12-31 23:59:59', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver "ID de producto no válido."

-- Error: Fecha de inicio es mayor que la fecha de fin
CALL ListarEntradasProducto(1, '2023-12-31 23:59:59', '2023-01-01 00:00:00', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver "La fecha de inicio no puede ser mayor que la fecha de fin."

-- -----------------------------------------------------
-- Dado un producto, listar todos sus pedidos (mostrar el nombre del producto, fecha
-- del pedido, nombre, email y teléfono del cliente del pedido).
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE ListarPedidosProducto(
    IN p_idProducto INT,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        SET p_mensaje = 'Error en la búsqueda de pedidos.';
    END;

    -- Validación: Verificar si el ID de producto es válido
    IF p_idProducto <= 0 THEN
        SET p_mensaje = 'ID de producto no válido.';
    ELSE
        -- Verificar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM Productos WHERE idProducto = p_idProducto) THEN
            SET p_mensaje = 'Producto no encontrado.';
        ELSE
            -- Realizar la consulta
            SELECT pr.producto, p.fecha, c.cliente, c.email, c.telefono
            FROM LineasPedido lp
            JOIN Pedidos p ON lp.idPedido = p.idPedido AND lp.idCliente = p.idCliente
            JOIN Clientes c ON p.idCliente = c.idCliente
            JOIN Productos pr ON lp.idProducto = pr.idProducto
            WHERE lp.idProducto = p_idProducto
            ORDER BY p.fecha;

            IF NOT FOUND_ROWS() THEN
                SET p_mensaje = 'No hay pedidos asociados a este producto.';
            ELSE
                SET p_mensaje = 'Listado de pedidos generado exitosamente.';
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
-- Caso de éxito: Producto existe y tiene pedidos asociados
CALL ListarPedidosProducto(1, @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver los pedidos del producto y el mensaje "Listado de pedidos generado exitosamente."

-- Error: Producto no existe
CALL ListarPedidosProducto(999, @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver "Producto no encontrado."

-- Error: ID de producto no válido (negativo o cero)
CALL ListarPedidosProducto(-1, @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver "ID de producto no válido."

-- Insertamos un nuevo producto que no tenga pedidos asociados
INSERT INTO Productos (producto, descripcion, precio, estado) VALUES ('Bio Balance Manzana 3L', 'Jugo de manzana de la marca Bio Balance en presentación de 3L.', 130.00, 'A');

-- Error: Producto existe pero no tiene pedidos asociados
CALL ListarPedidosProducto(72, @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver "No hay pedidos asociados a este producto."


-- -----------------------------------------------------
-- Realizar un procedimiento almacenado con alguna funcionalidad que considere
-- de interés.

-- Listar todos los viajes realizados a una zona específica.
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE ListarViajesPorZona(
    IN p_idZona INT,
    IN p_fechaInicio DATE,
    IN p_fechaFin DATE,
    OUT p_mensaje VARCHAR(255)
)
BEGIN
    DECLARE exit_flag INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Manejo de errores SQL
        SET p_mensaje = 'Error interno al listar los viajes por zona.';
        SET exit_flag = 1;
    END;

    -- Validación: Verificar si la zona existe
    IF NOT EXISTS (SELECT 1 FROM Zonas WHERE idZona = p_idZona) THEN
        SET p_mensaje = 'La zona especificada no existe en la base de datos.';
        SET exit_flag = 1;
    END IF;

    -- Validación: Verificar si la fecha de inicio es posterior a la fecha de fin
    IF p_fechaInicio > p_fechaFin THEN
        SET p_mensaje = 'La fecha de inicio no puede ser posterior a la fecha de fin.';
        SET exit_flag = 1;
    END IF;

    -- Listar los viajes por zona y rango de fechas
    IF exit_flag = 0 THEN
        SELECT idViaje, fecha, observaciones
        FROM Viajes
        WHERE idZona = p_idZona
        AND fecha BETWEEN p_fechaInicio AND p_fechaFin;

        IF NOT FOUND_ROWS() THEN
            SET p_mensaje = 'No hay viajes registrados en la zona especificada dentro del rango de fechas proporcionado.';
        ELSE
            SET p_mensaje = 'Listado de viajes por zona generado exitosamente.';
        END IF;
    END IF;
END //

DELIMITER ;

-- Sentencias de llamada al procedimiento creado.
-- -----------------------------------------------------
CALL ListarViajesPorZona(1, '2024-01-01', '2024-12-31', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería devolver el mensaje "Listado de viajes por zona generado exitosamente." junto con los viajes realizados en la zona 1 durante el año 2024.

CALL ListarViajesPorZona(999, '2024-01-01', '2024-12-31', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería generar un mensaje de error indicando que la zona especificada no existe en la base de datos.

CALL ListarViajesPorZona(1, '2025-01-01', '2024-12-31', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería generar un mensaje de error indicando que la fecha de inicio no puede ser posterior a la fecha de fin.

CALL ListarViajesPorZona(5, '2022-10-01', '2022-12-31', @mensaje);
SELECT @mensaje AS mensaje;
-- Debería generar un mensaje indicando que no hay viajes registrados en la zona especificada dentro del rango de fechas proporcionado.