-- Año: 2024
-- Grupo Nro: 4
-- Integrantes: Lozano Iñaki Fernando, Medina Raed Luis Eugenio
-- Tema: Gestión de stock y distribución de bebidas gaseosas
-- Nombre del Esquema LBD2024G04
-- Plataforma (SO + Versión): Windows 10
-- Motor y Versión: MySQL 8.0.30
-- GitHub Repositorio: LBD2024G04
-- GitHub Usuario: InakiLozano01, LuisMedinaRaed

-- TRABAJO PRACTICO Nº1

DROP SCHEMA IF EXISTS LBD2024G04;

CREATE SCHEMA IF NOT EXISTS LBD2024G04;
USE LBD2024G04;

CREATE TABLE Zonas(
    idZona         INT            AUTO_INCREMENT,
    zona           VARCHAR(50)    NOT NULL,
    descripcion    TEXT           NOT NULL,
    estado         CHAR(1)        NOT NULL,
    PRIMARY KEY (idZona), 
    CHECK (estado IN ('A', 'B')),
    UNIQUE INDEX UI_zona(zona)
)ENGINE=INNODB
;

CREATE TABLE Clientes(
    idCliente    INT             AUTO_INCREMENT,
    idZona       INT             NOT NULL,
    cliente      VARCHAR(60)     NOT NULL,
    cuil         CHAR(11)        NOT NULL,
    email        VARCHAR(120)    NOT NULL,
    direccion    VARCHAR(120)    NOT NULL,
    telefono     VARCHAR(15),
    estado       CHAR(1)         NOT NULL,
	CHECK (estado IN ('A', 'B')),
	CHECK (telefono REGEXP '^[+]?[0-9]+$'),
    CHECK (cuil REGEXP '^[0-9]{11}$'),
    CHECK (email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$'),
    PRIMARY KEY (idCliente), 
    UNIQUE INDEX IX_cliente(cliente),
    UNIQUE INDEX IX_cuil(cuil),
    UNIQUE INDEX IX_email(email),
    INDEX IX_idZona(idZona), 
    CONSTRAINT FK_idZonaCliente FOREIGN KEY (idZona)
    REFERENCES Zonas(idZona) ON DELETE CASCADE
)ENGINE=INNODB
;

CREATE TABLE Proveedores(
    idProveedor    INT             AUTO_INCREMENT,
    proveedor      VARCHAR(60)     NOT NULL,
    email          VARCHAR(120)    NOT NULL,
    direccion      VARCHAR(120)    NOT NULL,
    telefono       VARCHAR(15),
    estado         CHAR(1)         NOT NULL,
    PRIMARY KEY (idProveedor), 
    CHECK (estado IN ('A', 'B')),
    CHECK (telefono REGEXP '^[+]?[0-9]+$'),
    CHECK (email REGEXP '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$'),
    UNIQUE INDEX UI_proveedor(proveedor),
    UNIQUE INDEX UI_email(email)
)ENGINE=INNODB
;

CREATE TABLE Entradas(
    idEntrada        INT         AUTO_INCREMENT,
    idProveedor      INT         NOT NULL,
    fecha            DATETIME    DEFAULT current_timestamp NOT NULL,
    observaciones    TEXT,
    estado           CHAR(1)     NOT NULL,
    PRIMARY KEY (idEntrada, idProveedor), 
    CHECK (estado IN ('A', 'B')),
    UNIQUE INDEX UI_idEntrada(idEntrada),
    INDEX IX_idProveedor(idProveedor),
    INDEX IX_idFechaEntrada(fecha), 
    CONSTRAINT FK_idProveedor FOREIGN KEY (idProveedor)
    REFERENCES Proveedores(idProveedor) ON DELETE CASCADE
)ENGINE=INNODB
;

CREATE TABLE Productos(
    idProducto     INT               AUTO_INCREMENT,
    producto       VARCHAR(100)      NOT NULL,
    descripcion    TEXT              NOT NULL,
    precio         DECIMAL(15, 2)    NOT NULL,
    estado         CHAR(1)           NOT NULL,
    PRIMARY KEY (idProducto), 
	CHECK (estado IN ('A', 'B')),
    CHECK (precio >= 0),
    UNIQUE INDEX UI_producto(producto),
    INDEX IX_precio(precio)
)ENGINE=INNODB
;

CREATE TABLE LineasEntrada(
    idEntrada      INT               NOT NULL,
    idProveedor    INT               NOT NULL,
    idProducto     INT               NOT NULL,
    cantidad       INT               NOT NULL,
    precio         DECIMAL(15, 2)    NOT NULL,
    PRIMARY KEY (idEntrada, idProveedor, idProducto), 
    CHECK (precio >= 0),
    CHECK (cantidad >= 0),
    INDEX IX_idEntradaProveedor(idEntrada, idProveedor),
    INDEX IX_idProducto(idProducto), 
    CONSTRAINT FK_idEntradaProveedor FOREIGN KEY (idEntrada, idProveedor)
    REFERENCES Entradas(idEntrada, idProveedor) ON DELETE CASCADE,
    CONSTRAINT FK_idProductoEntrada FOREIGN KEY (idProducto)
    REFERENCES Productos(idProducto) ON DELETE CASCADE
)ENGINE=INNODB
;

CREATE TABLE UnidadesTransporte(
    idUnidadTransporte    INT            AUTO_INCREMENT,
    idZona                INT            NOT NULL,
    patente               VARCHAR(11)    NOT NULL,
    estado                CHAR(1)        NOT NULL,
    PRIMARY KEY (idUnidadTransporte), 
    CHECK (estado IN ('A', 'B')),
    UNIQUE INDEX UI_patente(patente),
    INDEX IX_idZona(idZona), 
    CONSTRAINT FK_idZonaUnidadTransporte FOREIGN KEY (idZona)
    REFERENCES Zonas(idZona) ON DELETE CASCADE
)ENGINE=INNODB
;

CREATE TABLE Viajes(
    idViaje               INT         AUTO_INCREMENT,
    idZona                INT         NOT NULL,
    idUnidadTransporte    INT         NOT NULL,
    fecha                 DATETIME    DEFAULT current_timestamp NOT NULL,
    observaciones         TEXT,
    estado                CHAR(1)     NOT NULL,
	CHECK (estado IN ('A', 'D')),
    PRIMARY KEY (idViaje), 
    INDEX IX_fechaViaje(fecha),
    INDEX IX_idZona(idZona),
    INDEX IX_idUnidadTransporte(idUnidadTransporte), 
    CONSTRAINT FK_idUnidadTransporte FOREIGN KEY (idUnidadTransporte)
    REFERENCES UnidadesTransporte(idUnidadTransporte) ON DELETE CASCADE,
    CONSTRAINT FK_idZonaViaje FOREIGN KEY (idZona)
    REFERENCES Zonas(idZona) ON DELETE CASCADE
)ENGINE=INNODB
;

CREATE TABLE Pedidos(
    idPedido         INT         AUTO_INCREMENT,
    idCliente        INT         NOT NULL,
    idViaje          INT,
    fecha            DATETIME    DEFAULT current_timestamp NOT NULL,
    observaciones    TEXT,
    PRIMARY KEY (idPedido, idCliente), 
    UNIQUE INDEX UI_idPedido(idPedido),
    INDEX IX_fechaPedido(fecha),
    INDEX IX_idCliente(idCliente),
    INDEX IX_idViaje(idViaje), 
    CONSTRAINT FK_idCliente FOREIGN KEY (idCliente)
    REFERENCES Clientes(idCliente) ON DELETE CASCADE,
    CONSTRAINT FK_idViaje FOREIGN KEY (idViaje)
    REFERENCES Viajes(idViaje) ON DELETE CASCADE
)ENGINE=INNODB
;

CREATE TABLE LineasPedido(
    idPedido      INT               NOT NULL,
    idCliente     INT               NOT NULL,
    idProducto    INT               NOT NULL,
    cantidad      INT               NOT NULL,
    precio        DECIMAL(15, 2)    NOT NULL,
    PRIMARY KEY (idPedido, idCliente, idProducto), 
    CHECK (precio >= 0),
    CHECK (cantidad >= 0),
    INDEX IX_idPedidoCliente(idPedido, idCliente),
    INDEX IX_idProducto(idProducto), 
    CONSTRAINT FK_idPedidoCliente FOREIGN KEY (idPedido, idCliente)
    REFERENCES Pedidos(idPedido, idCliente) ON DELETE CASCADE,
    CONSTRAINT FK_idProductoPedido FOREIGN KEY (idProducto)
    REFERENCES Productos(idProducto) ON DELETE CASCADE
)ENGINE=INNODB
;

INSERT INTO Zonas (idZona, zona, descripcion, estado) VALUES 
(1, 'San Miguel de Tucumán', 'Capital de la provincia de Tucumán en el norte de Argentina.', 'A'),
(2, 'Yerba Buena', 'Importante ciudad ubicada cerca de San Miguel de Tucumán, en la provincia de Tucumán.', 'A'),
(3, 'Tafí Viejo', 'Ciudad ubicada en la provincia de Tucumán, cercana a San Miguel de Tucumán.', 'A'),
(4, 'Santiago del Estero', 'Capital de la provincia de Santiago del Estero en el norte de Argentina.', 'A'),
(5, 'La Banda', 'Importante ciudad cercana a Santiago del Estero, en la provincia de Santiago del Estero.', 'A'),
(6, 'Salta Capital', 'Capital de la provincia de Salta en el norte de Argentina.', 'A'),
(7, 'San Salvador de Jujuy', 'Capital de la provincia de Jujuy en el norte de Argentina.', 'A'),
(8, 'San Pedro de Jujuy', 'Importante ciudad ubicada en la provincia de Jujuy, cercana a San Salvador de Jujuy.', 'A'),
(9, 'Humahuaca', 'Ciudad turística ubicada en la provincia de Jujuy, conocida por su cerro de siete colores.', 'A'),
(10, 'Cafayate', 'Importante ciudad de la provincia de Salta, reconocida por su producción vitivinícola.', 'A'),
(11, 'Tilcara', 'Ciudad turística ubicada en la provincia de Jujuy, famosa por sus paisajes y ruinas indígenas.', 'A'),
(12, 'Tafí del Valle', 'Localidad turística ubicada en las sierras de Tucumán, conocida por su belleza natural.', 'A'),
(13, 'San Fernando del Valle de Catamarca', 'Capital de la provincia de Catamarca en el norte de Argentina.', 'A'),
(14, 'La Rioja Capital', 'Capital de la provincia de La Rioja en el norte de Argentina.', 'A'),
(15, 'Rosario de la Frontera', 'Ciudad ubicada en la provincia de Salta, conocida por sus tradiciones y festivales.', 'A'),
(16, 'Orán', 'Ciudad ubicada en la provincia de Salta, importante centro comercial y agrícola.', 'A'),
(17, 'San Ramón de la Nueva Orán', 'Importante ciudad ubicada en la provincia de Salta, cerca de la frontera con Bolivia.', 'A'),
(18, 'Joaquín V. González', 'Ciudad ubicada en la provincia de Salta, conocida por su producción de tabaco.', 'A'),
(19, 'San Pedro', 'Ciudad ubicada en la provincia de Jujuy, cerca de la frontera con Bolivia.', 'A'),
(21, 'Posadas', 'Capital de la provincia de Misiones, situada en el nordeste de Argentina.', 'B'),
(22, 'Corrientes Capital', 'Capital de la provincia de Corrientes, conocida por su carnaval.', 'B'),
(23, 'Resistencia', 'Capital de la provincia del Chaco, conocida por su cultura y eventos.', 'B'),
(24, 'Formosa Capital', 'Capital de la provincia de Formosa, ubicada en el noreste argentino.', 'B'),
(25, 'Paraná', 'Capital de la provincia de Entre Ríos, conocida por sus parques y museos.', 'B');

INSERT INTO Proveedores (idProveedor, proveedor, email, direccion, telefono, estado) VALUES 
(1, 'Bebidas del Norte S.A.', 'info@bebidasdelnorte.com', 'Av. Norte 123, Ciudad', '+5493811234567', 'A'),
(2, 'Fábrica de Refrescos Tuculán', 'contacto@tuculan.com', 'Calle Tucumán 456, San Miguel de Tucumán', '+5493819876543', 'A'),
(3, 'Bebidas Salteñas SRL', 'ventas@bebidasaltnas.com', 'Av. Salta 789, Salta', '+5493876543210', 'B'),
(4, 'Jujuy Bebidas SA', 'info@jujuybebidas.com', 'Calle Jujuy 101, San Salvador de Jujuy', '+5493881122334', 'A'),
(5, 'Santiagos Refrescos', 'ventas@santiagosrefrescos.com', 'Av. Santiago 567, Santiago del Estero', '+5493852233445', 'B'),
(6, 'Agua Clara SA', 'info@aguaclara.com', 'Av. Principal 789, San Miguel de Tucumán', '+5493818765432', 'A'),
(7, 'Bebidas del Sol', 'contacto@bebidasdelsol.com', 'Calle del Sol 345, Salta', '+5493875678901', 'A'),
(8, 'Tucu-Cola SA', 'ventas@tucucola.com', 'Av. Tucumán 678, San Miguel de Tucumán', '+5493812345678', 'A'),
(9, 'Jujuy Refrescos del Norte', 'info@jujuyrefrescos.com', 'Av. Norte 234, San Salvador de Jujuy', '+5493889988776', 'B'),
(10, 'Sabor Jujuyano SA', 'contacto@saborjujuyano.com', 'Calle Jujuy 567, San Salvador de Jujuy', '+5493884455667', 'A'),
(11, 'Bebidas Tucumanas SA', 'ventas@bebidasTucumanas.com', 'Av. Tucumán 890, San Miguel de Tucumán', '+5493816677889', 'A'),
(12, 'Refrescos Salteños', 'info@refrescossalteños.com', 'Calle Salta 678, Salta', '+5493871122334', 'A'),
(13, 'Sabor del Noroeste', 'contacto@sabordelnoroeste.com', 'Av. Noroeste 101, Santiago del Estero', '+5493856677889', 'B'),
(14, 'Agua Fresca SA', 'ventas@aguafresca.com', 'Av. Principal 123, Santiago del Estero', '+5493854455667', 'A'),
(15, 'Tucu-Soda', 'info@tucusoda.com', 'Calle Tucumán 678, San Miguel de Tucumán', '+5493813344556', 'A'),
(16, 'Jujuy Refrescos SRL', 'contacto@jujuyrefrescos.com', 'Av. Jujuy 345, San Salvador de Jujuy', '+5493885566778', 'A'),
(17, 'Bebidas del Norte SA', 'ventas@bebidasdelnorte.com', 'Av. Norte 456, Salta', '+5493877788990', 'B'),
(18, 'Refrescos del Este', 'info@refrescosdeleste.com', 'Av. Este 123, Santiago del Estero', '+5493852233445', 'A'),
(19, 'Sabor Tucumano', 'contacto@sabortucumano.com', 'Calle Tucumán 456, San Miguel de Tucumán', '+5493811122334', 'A'),
(20, 'Jujuy Refrescos del Sol', 'ventas@jujuyrefrescos.com', 'Av. del Sol 678, San Salvador de Jujuy', '+5493887788990', 'B'),
(21, 'Refrescos del Litoral S.A.', 'info@refrescosdellitoral.com', 'Calle Litoral 123, Posadas', '+5493761234567', 'B'),
(22, 'Bebidas Corrientes Ltd.', 'ventas@bebidasco.com', 'Av. Libertad 234, Corrientes Capital', '+5493796543210', 'B'),
(23, 'Agua del Chaco SRL', 'contacto@aguadelchaco.com', 'Av. San Martín 789, Resistencia', '+5493621122334', 'B'),
(24, 'Soda Formoseña SA', 'info@sodaformosena.com', 'Calle Pilcomayo 567, Formosa Capital', '+5493712345678', 'B'),
(25, 'Entre Ríos Beverages Corp.', 'ventas@erbbeverages.com', 'Av. del Río 345, Paraná', '+5493435678901', 'B');

INSERT INTO Productos (idProducto, producto, descripcion, precio, estado) VALUES 
(1, 'Secco Tradicional 500ml', 'Refresco tradicional de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(2, 'Secco Tradicional 1.5L', 'Refresco tradicional de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(3, 'Secco Tradicional 2.25L', 'Refresco tradicional de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(4, 'Secco Tradicional 3L', 'Refresco tradicional de la marca Secco en presentación de 3L.', 120.00, 'B'),
(5, 'Secco Pomelo 500ml', 'Refresco sabor pomelo de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(6, 'Secco Pomelo 1.5L', 'Refresco sabor pomelo de la marca Secco en presentación de 1.5L.', 70.00, 'B'),
(7, 'Secco Pomelo 2.25L', 'Refresco sabor pomelo de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(8, 'Secco Pomelo 3L', 'Refresco sabor pomelo de la marca Secco en presentación de 3L.', 120.00, 'A'),
(9, 'Secco Pomelo Intenso 500ml', 'Refresco sabor pomelo intenso de la marca Secco en presentación de 500ml.', 40.00, 'B'),
(10, 'Secco Pomelo Intenso 1.5L', 'Refresco sabor pomelo intenso de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(11, 'Secco Pomelo Intenso 2.25L', 'Refresco sabor pomelo intenso de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(12, 'Secco Pomelo Intenso 3L', 'Refresco sabor pomelo intenso de la marca Secco en presentación de 3L.', 120.00, 'A'),
(13, 'Secco Cola 500ml', 'Refresco de cola de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(14, 'Secco Cola 1.5L', 'Refresco de cola de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(15, 'Secco Cola 2.25L', 'Refresco de cola de la marca Secco en presentación de 2.25L.', 90.00, 'B'),
(16, 'Secco Cola 3L', 'Refresco de cola de la marca Secco en presentación de 3L.', 120.00, 'B'),
(17, 'Secco Naranja 500ml', 'Refresco sabor naranja de la marca Secco en presentación de 500ml.', 40.00, 'B'),
(18, 'Secco Naranja 1.5L', 'Refresco sabor naranja de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(19, 'Secco Naranja 2.25L', 'Refresco sabor naranja de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(20, 'Secco Naranja 3L', 'Refresco sabor naranja de la marca Secco en presentación de 3L.', 120.00, 'A'),
(21, 'Secco Lima Limón 500ml', 'Refresco sabor lima limón de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(22, 'Secco Lima Limón 1.5L', 'Refresco sabor lima limón de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(23, 'Secco Lima Limón 2.25L', 'Refresco sabor lima limón de la marca Secco en presentación de 2.25L.', 90.00, 'B'),
(24, 'Secco Lima Limón 3L', 'Refresco sabor lima limón de la marca Secco en presentación de 3L.', 120.00, 'B'),
(25, 'Secco Limón 500ml', 'Refresco sabor limón de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(26, 'Secco Limón 1.5L', 'Refresco sabor limón de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(27, 'Secco Limón 2.25L', 'Refresco sabor limón de la marca Secco en presentación de 2.25L.', 90.00, 'B'),
(28, 'Secco Limón 3L', 'Refresco sabor limón de la marca Secco en presentación de 3L.', 120.00, 'A'),
(29, 'Secco Limón Intenso 500ml', 'Refresco sabor limón intenso de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(30, 'Secco Limón Intenso 1.5L', 'Refresco sabor limón intenso de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(31, 'Secco Limón Intenso 2.25L', 'Refresco sabor limón intenso de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(32, 'Secco Limón Intenso 3L', 'Refresco sabor limón intenso de la marca Secco en presentación de 3L.', 120.00, 'B'),
(33, 'Secco Manzana 500ml', 'Refresco sabor manzana de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(34, 'Secco Manzana 1.5L', 'Refresco sabor manzana de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(35, 'Secco Manzana 2.25L', 'Refresco sabor manzana de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(36, 'Secco Manzana 3L', 'Refresco sabor manzana de la marca Secco en presentación de 3L.', 120.00, 'B'),
(37, 'Secco MultiFrutal 500ml', 'Refresco sabor multi-frutas de la marca Secco en presentación de 500ml.', 45.00, 'A'),
(38, 'Secco MultiFrutal 1.5L', 'Refresco sabor multi-frutas de la marca Secco en presentación de 1.5L.', 75.00, 'A'),
(39, 'Secco MultiFrutal 2.25L', 'Refresco sabor multi-frutas de la marca Secco en presentación de 2.25L.', 95.00, 'A'),
(40, 'Secco MultiFrutal 3L', 'Refresco sabor multi-frutas de la marca Secco en presentación de 3L.', 130.00, 'B'),
(41, 'Secco Tónica 500ml', 'Tónica de la marca Secco en presentación de 500ml.', 50.00, 'B'),
(42, 'Secco Tónica 1.5L', 'Tónica de la marca Secco en presentación de 1.5L.', 85.00, 'B'),
(43, 'Secco Tónica 2.25L', 'Tónica de la marca Secco en presentación de 2.25L.', 100.00, 'A'),
(44, 'Secco Tónica 3L', 'Tónica de la marca Secco en presentación de 3L.', 140.00, 'A'),
(45, 'Secco Soda 1.25L', 'Soda de la marca Secco en presentación de 1.25L.', 35.00, 'A'),
(46, 'Secco Soda 2.25L', 'Soda de la marca Secco en presentación de 2.25L.', 50.00, 'A'),
(47, 'Secco Sifón', 'Sifón de la marca Secco.', 25.00, 'A'),
(48, 'Secco Cola Sin Calorías 500ml', 'Refresco de cola sin calorías de la marca Secco en presentación de 500ml.', 40.00, 'B'),
(49, 'Secco Cola Sin Calorías 1.5L', 'Refresco de cola sin calorías de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(50, 'Secco Cola Sin Calorías 2.25L', 'Refresco de cola sin calorías de la marca Secco en presentación de 2.25L.', 90.00, 'B'),
(51, 'Secco Cola Sin Calorías 3L', 'Refresco de cola sin calorías de la marca Secco en presentación de 3L.', 120.00, 'A'),
(52, 'Secco Limón Sin Calorías 500ml', 'Refresco sabor limón sin calorías de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(53, 'Secco Limón Sin Calorías 1.5L', 'Refresco sabor limón sin calorías de la marca Secco en presentación de 1.5L.', 70.00, 'B'),
(54, 'Secco Limón Sin Calorías 2.25L', 'Refresco sabor limón sin calorías de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(55, 'Secco Limón Sin Calorías 3L', 'Refresco sabor limón sin calorías de la marca Secco en presentación de 3L.', 120.00, 'A'),
(56, 'Secco Naranja Sin Calorías 500ml', 'Refresco sabor naranja sin calorías de la marca Secco en presentación de 500ml.', 40.00, 'A'),
(57, 'Secco Naranja Sin Calorías 1.5L', 'Refresco sabor naranja sin calorías de la marca Secco en presentación de 1.5L.', 70.00, 'A'),
(58, 'Secco Naranja Sin Calorías 2.25L', 'Refresco sabor naranja sin calorías de la marca Secco en presentación de 2.25L.', 90.00, 'A'),
(59, 'Secco Naranja Sin Calorías 3L', 'Refresco sabor naranja sin calorías de la marca Secco en presentación de 3L.', 120.00, 'A'),
(60, 'BioFrut Naranja 1L', 'Jugo de naranja orgánico de la marca BioFrut en presentación de 1L.', 50.00, 'A'),
(61, 'BioFrut Naranja Durazno 1L', 'Jugo de naranja y durazno orgánico de la marca BioFrut en presentación de 1L.', 55.00, 'B'),
(62, 'BioFrut MultiFruta 1L', 'Jugo de multi-frutas orgánico de la marca BioFrut en presentación de 1L.', 60.00, 'A'),
(63, 'BioFrut Manzana 1L', 'Jugo de manzana orgánico de la marca BioFrut en presentación de 1L.', 50.00, 'B'),
(64, 'Bio Balance Naranja 500ml', 'Jugo de naranja de la marca Bio Balance en presentación de 500ml.', 30.00, 'A'),
(65, 'Bio Balance Naranja 1.5L', 'Jugo de naranja de la marca Bio Balance en presentación de 1.5L.', 50.00, 'A'),
(66, 'Bio Balance Pomelo 500ml', 'Jugo de pomelo de la marca Bio Balance en presentación de 500ml.', 35.00, 'A'),
(67, 'Bio Balance Pomelo 1.5L', 'Jugo de pomelo de la marca Bio Balance en presentación de 1.5L.', 55.00, 'A'),
(68, 'Bio Balance Pera 500ml', 'Jugo de pera de la marca Bio Balance en presentación de 500ml.', 30.00, 'A'),
(69, 'Bio Balance Pera 1.5L', 'Jugo de pera de la marca Bio Balance en presentación de 1.5L.', 50.00, 'A'),
(70, 'Bio Balance Manzana 500ml', 'Jugo de manzana de la marca Bio Balance en presentación de 500ml.', 30.00, 'A'),
(71, 'Bio Balance Manzana 1.5L', 'Jugo de manzana de la marca Bio Balance en presentación de 1.5L.', 50.00, 'A');

INSERT INTO Clientes (idCliente, idZona, cliente, cuil, email, direccion, telefono, estado) VALUES
(1, 1, 'Supermercado Don Chango', '20123456789', 'info@donchango.com', 'Calle Rivadavia 123, San Miguel de Tucumán', '+543811234567', 'A'),
(2, 1, 'Supermercado Santa Rita', '22567890124', 'santarita@supermercadosantarita.com', 'Av. España 567, San Miguel de Tucumán', '+543815678901', 'B'),
(3, 1, 'Hipermercado San Cayetano', '26901234568', 'contacto@hipersancayetano.com', 'Av. Mate de Luna 678, San Miguel de Tucumán', '+543819012345', 'A'),
(4, 1, 'Supermercado La Plaza', '21345678902', 'ventas@supermercadolaplaza.com', 'Calle 25 de Mayo 890, San Miguel de Tucumán', '+543813456789', 'A'),
(5, 1, 'Hipermercado Los Pinos', '25789012346', 'info@hiperlosPinos.com', 'Av. Roca 789, San Miguel de Tucumán', '+543817890123', 'A'),
(6, 2, 'Mayorista Los Andes', '30234567891', 'ventas@mayoristalosandes.com', 'Av. Belgrano 456, Santiago del Estero', '+543852345678', 'A'),
(7, 2, 'Mayorista La Estrella', '33678901235', 'info@mayoristalaestrella.com', 'Calle Mitre 890, Santiago del Estero', '+543856789012', 'A'),
(8, 2, 'Mayorista El Amanecer', '35012345679', 'ventas@mayoristaelamanecer.com', 'Av. Belgrano Sur 234, Santiago del Estero', '+543850123456', 'A'),
(9, 2, 'Mayorista El Sol', '34456789013', 'info@mayoristaelosol.com', 'Av. Belgrano Norte 456, Santiago del Estero', '+543854567890', 'A'),
(10, 2, 'Mayorista San Vicente', '37890123457', 'ventas@mayoristasanvicente.com', 'Av. Belgrano Oeste 678, Santiago del Estero', '+543858901234', 'B'),
(11, 3, 'Supermercado El Sol', '27345678902', 'contacto@supersolelsol.com', 'Av. Sarmiento 789, Salta', '+543873456789', 'A'),
(12, 3, 'Supermercado San Martín', '24789012346', 'info@supermercadosanmartin.com', 'Av. Belgrano 1234, Salta', '+543877890123', 'A'),
(13, 3, 'Supermercado San Lucas', '28123456780', 'info@supermercadosanlucas.com', 'Av. San Martín 789, Salta', '+543873123456', 'A'),
(14, 3, 'Supermercado La Perla', '30901234568', 'contacto@supermercadolaperla.com', 'Av. San Martín 1234, Salta', '+543879012345', 'A'),
(15, 4, 'Distribuidora El Alba', '23456789013', 'ventas@distribuidoraelalba.com', 'Calle San Martín 321, San Salvador de Jujuy', '+543884567890', 'B'),
(16, 4, 'Distribuidora La Cordillera', '31890123457', 'ventas@lacordillera.com', 'Av. Libertador 456, San Salvador de Jujuy', '+543888901234', 'A'),
(17, 4, 'Distribuidora San José', '32234567891', 'contacto@distribuidorasanjose.com', 'Av. Italia 123, San Salvador de Jujuy', '+543882345678', 'B'),
(18, 4, 'Distribuidora El Portal', '36678901235', 'ventas@distribuidoraelportal.com', 'Calle San Juan 567, San Salvador de Jujuy', '+543886789012', 'A'),
(19, 4, 'Distribuidora San Francisco', '38012345679', 'ventas@distribuidorasanfrancisco.com', 'Av. Independencia 456, San Salvador de Jujuy', '+543880123456', 'A'),
(20, 5, 'Supermercado Buena Onda', '40234567891', 'ventas@buenasonda.com', 'Av. Sarmiento 123, Salta', '+543872345678', 'B'),
(21, 6, 'Mayorista La Nueva Opción', '41345678902', 'info@nuevaopcion.com', 'Av. Belgrano 456, Santiago del Estero', '+543853456789', 'A'),
(22, 6, 'Mayorista El Gran Descuento', '42456789013', 'contacto@elgrandescuento.com', 'Calle Mitre 678, Santiago del Estero', '+543854567890', 'A'),
(23, 7, 'Supermercado La Esquina', '43567890124', 'ventas@esquinamercado.com', 'Av. San Martín 789, Salta', '+543875678901', 'A'),
(24, 8, 'Distribuidora El Nuevo Amanecer', '44678901235', 'info@nuevoamanecer.com', 'Av. Belgrano 1234, Salta', '+543876789012', 'A'),
(25, 9, 'Supermercado El Progreso', '45789012346', 'contacto@elprogreso.com', 'Av. España 234, San Miguel de Tucumán', '+543817890123', 'A'),
(26, 10, 'Mayorista La Estrella del Norte', '46890123457', 'ventas@estrellanorte.com', 'Av. Belgrano 567, San Miguel de Tucumán', '+543818901234', 'B'),
(27, 11, 'Distribuidora La Capital', '47901234568', 'info@lcapital.com', 'Calle San Martín 890, San Miguel de Tucumán', '+543819012345', 'A'),
(28, 12, 'Supermercado Los Primos', '48012345679', 'ventas@losprimos.com', 'Av. Mate de Luna 123, San Miguel de Tucumán', '+543810123456', 'A'),
(29, 13, 'Mayorista El Poderoso', '49123456780', 'contacto@elpoderoso.com', 'Av. España 456, San Miguel de Tucumán', '+543811234567', 'A'),
(30, 14, 'Supermercado El Dorado', '50234567891', 'ventas@eldorado.com', 'Calle Belgrano 789, San Miguel de Tucumán', '+543812345678', 'A'),
(31, 15, 'Distribuidora La Fortuna', '51345678902', 'info@lafortuna.com', 'Av. San Martín 234, San Miguel de Tucumán', '+543813456789', 'B'),
(32, 16, 'Supermercado El Paraíso', '52456789013', 'contacto@elparaiso.com', 'Av. Belgrano 678, San Miguel de Tucumán', '+543814567890', 'A'),
(33, 17, 'Mayorista El Gigante', '53567890124', 'ventas@elgigante.com', 'Calle Mitre 890, San Miguel de Tucumán', '+543815678901', 'A'),
(34, 18, 'Distribuidora La Victoria', '54678901235', 'info@lavictoria.com', 'Av. San Martín 1234, San Miguel de Tucumán', '+543816789012', 'A'),
(35, 19, 'Supermercado La Unión', '55789012346', 'contacto@launion.com', 'Av. España 567, San Miguel de Tucumán', '+543817890123', 'A');

INSERT INTO UnidadesTransporte (idUnidadTransporte, idZona, patente, estado) VALUES
(1, 1, 'ABC123', 'A'),
(2, 1, 'XYZ789', 'A'),
(3, 2, 'DEF456', 'A'),
(4, 2, 'UVW012', 'A'),
(5, 3, 'GHI789', 'A'),
(6, 3, 'LMN345', 'A'),
(7, 4, 'JKL101', 'A'),
(8, 4, 'OPQ567', 'A'),
(9, 5, 'MNO202', 'A'),
(10, 5, 'RST678', 'A'),
(11, 6, 'PQR303', 'A'),
(12, 6, 'FGH901', 'A'),
(13, 7, 'STU404', 'A'),
(14, 7, 'IJK234', 'A'),
(15, 8, 'VWX505', 'A'),
(16, 8, 'ABC456', 'A'),
(17, 9, 'YZA606', 'A'),
(18, 9, 'DEF789', 'A'),
(19, 10, 'AB111CD', 'A'),
(20, 10, 'AHI012', 'A'),
(21, 11, 'AE222EF', 'A'),
(22, 11, 'LMN346', 'A'),
(23, 12, 'AH333IJ', 'A'),
(24, 12, 'OPQ456', 'A'),
(25, 13, 'AK444LK', 'A'),
(26, 13, 'RST567', 'A'),
(27, 14, 'AN555OM', 'A'),
(28, 14, 'UVW678', 'A'),
(29, 15, 'AQ666RP', 'A'),
(30, 15, 'XYZ787', 'A'),
(31, 16, 'AT777US', 'A'),
(32, 16, 'IJK890', 'A'),
(33, 17, 'AW888XW', 'A'),
(34, 17, 'FGH951', 'A'),
(35, 18, 'AZ999AZ', 'A'),
(36, 18, 'ABC143', 'A'),
(37, 19, 'AA111PO', 'A'),
(38, 19, 'YZB606', 'A'),
(39, 19, 'DEA789', 'A'),
(40, 19, 'ABL456', 'A');

INSERT INTO Entradas (idEntrada, idProveedor, fecha, observaciones, estado) VALUES
(1, 1, '2023-12-01 08:00:00', NULL, 'A'),
(2, 2, '2023-12-02 09:30:00', NULL, 'A'),
(3, 3, '2023-12-03 10:45:00', NULL, 'A'),
(4, 4, '2023-12-04 11:20:00', NULL, 'A'),
(5, 5, '2023-12-05 12:00:00', NULL, 'A'),
(6, 6, '2023-12-06 13:15:00', NULL, 'A'),
(7, 7, '2023-12-07 14:30:00', NULL, 'A'),
(8, 8, '2023-12-08 15:45:00', NULL, 'A'),
(9, 9, '2023-12-09 16:10:00', NULL, 'A'),
(10, 10, '2023-12-10 17:30:00', NULL, 'A'),
(11, 11, '2024-01-01 18:40:00', NULL, 'A'),
(12, 12, '2024-01-02 19:55:00', NULL, 'A'),
(13, 13, '2024-01-03 20:20:00', NULL, 'A'),
(14, 14, '2024-01-04 21:00:00', NULL, 'A'),
(15, 15, '2024-01-05 22:15:00', NULL, 'A'),
(16, 16, '2024-01-06 23:30:00', NULL, 'A'),
(17, 17, '2024-01-07 00:45:00', NULL, 'A'),
(18, 18, '2024-01-08 01:10:00', NULL, 'A'),
(19, 19, '2024-01-09 02:30:00', NULL, 'A'),
(20, 20, '2024-01-10 03:40:00', NULL, 'A'),
(21, 1, '2023-12-05 12:00:00', NULL, 'A'),
(22, 2, '2023-12-02 09:30:00', NULL, 'A'),
(23, 3, '2023-12-07 14:30:00', NULL, 'A'),
(24, 4, '2023-12-01 08:00:00', NULL, 'A'),
(25, 5, '2023-12-09 16:10:00', NULL, 'A'),
(26, 6, '2023-12-06 13:15:00', NULL, 'A'),
(27, 7, '2023-12-04 11:20:00', NULL, 'A'),
(28, 8, '2023-12-10 17:30:00', NULL, 'A'),
(29, 9, '2023-12-08 15:45:00', NULL, 'A'),
(30, 10, '2023-12-03 10:45:00', NULL, 'A'),
(31, 7, '2023-12-04 10:45:00', NULL, 'A'),
(32, 14, '2023-12-05 10:45:00', NULL, 'A'),
(33, 10, '2023-12-07 10:45:00', NULL, 'A'),
(34, 8, '2023-12-11 10:45:00', NULL, 'A'),
(35, 9, '2023-12-13 10:45:00', NULL, 'A');

INSERT INTO LineasEntrada (idEntrada, idProveedor, idProducto, cantidad, precio) VALUES
(1, 1, 1, 100, 15.99),
(1, 1, 13, 50, 10.50),
(1, 1, 25, 200, 8.75),
(1, 1, 37, 150, 12.25),
(1, 1, 49, 100, 11.00),
(2, 2, 2, 80, 14.75),
(2, 2, 14, 120, 9.99),
(2, 2, 26, 100, 13.50),
(2, 2, 38, 50, 10.00),
(2, 2, 50, 200, 7.99),
(3, 3, 3, 120, 11.25),
(3, 3, 15, 90, 10.75),
(3, 3, 27, 150, 9.50),
(3, 3, 39, 80, 8.25),
(3, 3, 51, 100, 12.99),
(4, 4, 4, 50, 15.50),
(4, 4, 16, 200, 8.99),
(4, 4, 28, 100, 10.25),
(4, 4, 40, 120, 11.75),
(4, 4, 52, 80, 9.50),
(5, 5, 5, 100, 15.99),
(5, 5, 17, 50, 10.50),
(5, 5, 29, 200, 8.75),
(5, 5, 41, 150, 12.25),
(5, 5, 53, 100, 11.00),
(6, 6, 6, 80, 14.75),
(6, 6, 18, 120, 9.99),
(6, 6, 30, 100, 13.50),
(6, 6, 42, 50, 10.00),
(6, 6, 54, 200, 7.99),
(7, 7, 7, 120, 11.25),
(7, 7, 19, 90, 10.75),
(7, 7, 31, 150, 9.50),
(7, 7, 43, 80, 8.25),
(7, 7, 55, 100, 12.99),
(8, 8, 8, 50, 15.50),
(8, 8, 20, 200, 8.99),
(8, 8, 32, 100, 10.25),
(8, 8, 44, 120, 11.75),
(8, 8, 56, 80, 9.50),
(9, 9, 9, 100, 15.99),
(9, 9, 21, 50, 10.50),
(9, 9, 33, 200, 8.75),
(9, 9, 45, 150, 12.25),
(9, 9, 57, 100, 11.00),
(10, 10, 10, 80, 14.75),
(10, 10, 22, 120, 9.99),
(10, 10, 34, 100, 13.50),
(10, 10, 46, 50, 10.00),
(10, 10, 58, 200, 7.99),
(11, 11, 11, 120, 11.25),
(11, 11, 23, 90, 10.75),
(11, 11, 35, 150, 9.50),
(11, 11, 47, 80, 8.25),
(11, 11, 59, 100, 12.99),
(12, 12, 12, 50, 15.50),
(12, 12, 24, 200, 8.99),
(12, 12, 36, 100, 10.25),
(12, 12, 48, 120, 11.75),
(12, 12, 60, 80, 9.50),
(13, 13, 13, 100, 15.99),
(13, 13, 25, 50, 10.50),
(13, 13, 37, 200, 8.75),
(13, 13, 49, 150, 12.25),
(13, 13, 61, 100, 11.00),
(14, 14, 14, 80, 14.75),
(14, 14, 26, 120, 9.99),
(14, 14, 38, 100, 13.50),
(14, 14, 50, 50, 10.00),
(14, 14, 62, 200, 7.99),
(15, 15, 15, 120, 11.25),
(15, 15, 27, 90, 10.75),
(15, 15, 39, 150, 9.50),
(15, 15, 51, 80, 8.25),
(15, 15, 63, 100, 12.99),
(16, 16, 16, 50, 15.50),
(16, 16, 28, 200, 8.99),
(16, 16, 40, 100, 10.25),
(16, 16, 52, 120, 11.75),
(16, 16, 64, 80, 9.50),
(17, 17, 17, 100, 15.99),
(17, 17, 29, 50, 10.50),
(17, 17, 41, 200, 8.75),
(17, 17, 53, 150, 12.25),
(17, 17, 65, 100, 11.00),
(18, 18, 18, 80, 14.75),
(18, 18, 30, 120, 9.99),
(18, 18, 42, 100, 13.50),
(18, 18, 54, 50, 10.00),
(18, 18, 66, 200, 7.99),
(19, 19, 19, 120, 11.25),
(19, 19, 31, 90, 10.75),
(19, 19, 43, 150, 9.50),
(19, 19, 55, 80, 8.25),
(19, 19, 67, 100, 12.99),
(20, 20, 20, 50, 15.50),
(20, 20, 32, 200, 8.99),
(20, 20, 44, 100, 10.25),
(20, 20, 56, 120, 11.75),
(20, 20, 68, 80, 9.50),
(21, 1, 21, 100, 15.99),
(21, 1, 33, 50, 10.50),
(21, 1, 45, 200, 8.75),
(22, 2, 57, 150, 12.25),
(22, 2, 69, 100, 11.00),
(23, 3, 22, 80, 14.75),
(23, 3, 34, 120, 9.99),
(23, 3, 46, 100, 13.50),
(23, 3, 58, 50, 10.00),
(24, 4, 70, 200, 7.99),
(24, 4, 23, 120, 11.25),
(24, 4, 35, 90, 10.75),
(24, 4, 47, 150, 9.50),
(24, 4, 59, 80, 8.25),
(25, 5, 24, 100, 12.99),
(25, 5, 36, 50, 15.50),
(25, 5, 48, 200, 8.99),
(25, 5, 60, 100, 10.25),
(25, 5, 71, 120, 11.75),
(26, 6, 25, 80, 9.50),
(26, 6, 37, 100, 15.99),
(26, 6, 49, 50, 10.50),
(26, 6, 61, 200, 8.75),
(27, 7, 26, 150, 12.25),
(27, 7, 38, 100, 11.00),
(28, 8, 50, 80, 14.75),
(28, 8, 62, 120, 9.99),
(28, 8, 27, 100, 13.50),
(28, 8, 39, 50, 10.00),
(29, 9, 51, 200, 7.99),
(29, 9, 63, 120, 11.25),
(29, 9, 28, 90, 10.75),
(29, 9, 40, 150, 9.50),
(29, 9, 52, 80, 8.25),
(30, 10, 64, 100, 12.99),
(30, 10, 29, 50, 15.50),
(30, 10, 41, 200, 8.99),
(31, 7, 53, 100, 10.25),
(31, 7, 65, 120, 11.75),
(31, 7, 30, 100, 10.25),
(32, 14, 42, 100, 10.25),
(32, 14, 54, 100, 10.25),
(32, 14, 66, 100, 10.25),
(33, 10, 31, 100, 10.25),
(33, 10, 43, 100, 10.25),
(33, 10, 55, 100, 10.25),
(34, 8, 67, 100, 10.25),
(34, 8, 32, 100, 10.25),
(34, 8, 44, 100, 10.25),
(35, 9, 56, 100, 10.25),
(35, 9, 68, 100, 10.25),
(35, 9, 33, 100, 10.25);

INSERT INTO Viajes (idViaje, idZona, idUnidadTransporte, fecha, observaciones, estado) VALUES
(1, 1, 1, '2024-01-01 08:00:00', NULL, 'D'),
(2, 1, 1, '2024-01-02 10:30:00', NULL, 'D'),
(3, 2, 4, '2024-01-03 12:45:00', NULL, 'D'),
(4, 2, 4, '2024-01-04 09:15:00', NULL, 'D'),
(5, 3, 5, '2024-01-05 11:20:00', NULL, 'D'),
(6, 3, 6, '2024-01-06 14:00:00', NULL, 'D'),
(7, 4, 7, '2024-01-07 08:30:00', NULL, 'D'),
(8, 4, 8, '2024-01-08 10:45:00', NULL, 'D'),
(9, 5, 9, '2024-01-09 13:10:00', NULL, 'D'),
(10, 5, 10, '2024-01-10 15:20:00', NULL, 'D'),
(11, 6, 11, '2024-02-11 08:50:00', NULL, 'D'),
(12, 6, 12, '2024-02-12 11:00:00', NULL, 'D'),
(13, 7, 14, '2024-02-13 13:30:00', NULL, 'D'),
(14, 7, 14, '2024-02-14 16:40:00', NULL, 'D'),
(15, 8, 15, '2024-02-15 09:05:00', NULL, 'D'),
(16, 8, 16, '2024-03-16 10:15:00', NULL, 'D'),
(17, 9, 18, '2024-03-17 12:20:00', NULL, 'D'),
(18, 9, 18, '2024-03-18 14:35:00', NULL, 'D'),
(19, 10, 20, '2024-03-19 08:45:00', NULL, 'D'),
(20, 10, 20, '2024-03-20 11:10:00', NULL, 'D'),
(21, 11, 22, '2024-04-21 09:30:00', NULL, 'D'),
(22, 12, 22, '2024-04-22 11:45:00', NULL, 'D'),
(23, 13, 24, '2024-04-23 13:55:00', NULL, 'D'),
(24, 13, 24, '2024-04-24 16:00:00', NULL, 'A'),
(25, 14, 25, '2024-04-25 09:20:00', NULL, 'A');
    
INSERT INTO Pedidos (idPedido, idCliente, idViaje, fecha, observaciones) VALUES
(1, 1, 1, '2023-12-31 08:00:00', NULL),
(2, 4, 2, '2024-01-01 10:30:00', NULL),
(3, 6, 3, '2024-01-02 12:45:00', NULL),
(4, 7, 4, '2024-01-03 09:15:00', NULL),
(5, 11, 5, '2024-01-04 11:20:00', NULL),
(6, 12, 6, '2024-01-05 14:00:00', NULL),
(7, 16, 7, '2024-01-06 08:30:00', NULL),
(8, 15, 8, '2024-01-07 10:45:00', NULL),
(9, 20, 9, '2024-01-08 13:10:00', NULL),
(10, 20, 10, '2024-01-09 15:20:00', NULL),
(11, 21, 11, '2024-02-10 08:50:00', NULL),
(12, 22, 12, '2024-02-11 11:00:00', NULL),
(13, 23, 13, '2024-02-12 13:30:00', NULL),
(14, 23, 14, '2024-02-13 16:40:00', NULL),
(15, 24, 15, '2024-02-14 09:05:00', NULL),
(16, 24, 16, '2024-03-15 10:15:00', NULL),
(17, 25, 17, '2024-03-16 12:20:00', NULL),
(18, 25, 18, '2024-03-17 14:35:00', NULL),
(19, 26, 19, '2024-03-18 08:45:00', NULL),
(20, 26, 20, '2024-03-19 11:10:00', NULL),
(21, 27, 21, '2024-04-19 09:30:00', NULL),
(22, 28, 22, '2024-04-20 11:45:00', NULL),
(23, 29, 23, '2024-04-21 13:55:00', NULL),
(24, 29, 24, '2024-04-22 16:00:00', NULL),
(25, 30, 25, '2024-04-23 09:20:00', NULL),
(26, 1, 1, '2023-12-30 14:00:00', NULL),
(27, 1, 1, '2023-12-30 16:00:00', NULL),
(28, 4, 2, '2024-01-01 09:00:00', NULL),
(29, 4, 2, '2024-01-01 11:00:00', NULL),
(30, 10, 3, '2024-01-02 10:00:00', NULL),
(31, 10, 3, '2024-01-02 12:00:00', NULL),
(32, 10, 4, '2024-01-03 08:00:00', NULL),
(33, 10, 4, '2024-01-03 09:30:00', NULL),
(34, 11, 5, '2024-01-04 12:00:00', NULL),
(35, 11, 5, '2024-01-04 14:00:00', NULL),
(36, 14, 6, '2024-01-05 07:30:00', NULL),
(37, 14, 6, '2024-01-05 09:00:00', NULL),
(38, 15, 7, '2024-01-06 12:30:00', NULL),
(39, 15, 7, '2024-01-06 14:00:00', NULL),
(40, 15, 8, '2024-01-07 09:00:00', NULL),
(41, 15, 8, '2024-01-07 10:30:00', NULL),
(42, 20, 9, '2024-01-08 11:00:00', NULL),
(43, 20, 9, '2024-01-08 12:30:00', NULL),
(44, 20, 10, '2024-01-09 07:45:00', NULL),
(45, 20, 10, '2024-01-09 09:15:00', NULL),
(46, 21, 11, '2024-02-10 08:00:00', NULL),
(47, 21, 11, '2024-02-10 09:30:00', NULL),
(48, 21, 12, '2024-02-11 10:45:00', NULL),
(49, 21, 12, '2024-02-11 12:15:00', NULL),
(50, 23, 13, '2024-02-11 12:55:00', NULL),
(51, 23, 13, '2024-02-12 14:25:00', NULL),
(52, 23, 14, '2024-02-13 08:10:00', NULL),
(53, 23, 14, '2024-02-13 09:40:00', NULL),
(54, 24, 15, '2024-02-14 08:05:00', NULL),
(55, 24, 15, '2024-02-14 09:35:00', NULL),
(56, 24, 16, '2024-03-15 09:45:00', NULL),
(57, 24, 16, '2024-03-15 11:15:00', NULL),
(58, 25, 17, '2024-03-16 11:50:00', NULL),
(59, 25, 17, '2024-03-16 13:20:00', NULL),
(60, 25, 18, '2024-03-17 07:25:00', NULL),
(61, 25, 18, '2024-03-17 08:55:00', NULL),
(62, 26, 19, '2024-03-18 08:15:00', NULL),
(63, 26, 19, '2024-03-18 09:45:00', NULL),
(64, 26, 20, '2024-03-19 10:40:00', NULL),
(65, 26, 20, '2024-03-19 12:10:00', NULL),
(66, 27, 21, '2024-04-20 08:30:00', NULL),
(67, 27, 21, '2024-04-20 10:00:00', NULL),
(68, 28, 22, '2024-04-21 10:15:00', NULL),
(69, 28, 22, '2024-04-21 11:45:00', NULL),
(70, 29, 23, '2024-04-22 12:35:00', NULL),
(71, 29, 23, '2024-04-22 14:05:00', NULL),
(72, 29, 24, '2024-04-23 14:30:00', NULL),
(73, 29, 24, '2024-04-23 16:00:00', NULL),
(74, 30, 25, '2024-04-24 08:00:00', NULL),
(75, 30, 25, '2024-04-24 09:30:00', NULL);


INSERT INTO LineasPedido (idPedido, idCliente, idProducto, cantidad, precio) VALUES
(1, 1, 1, 10, 5.99),
(1, 1, 2, 20, 10.99),
(1, 1, 3, 15, 7.49),
(2, 4, 2, 5, 6.99),
(2, 4, 3, 10, 11.99),
(2, 4, 4, 15, 9.49),
(3, 6, 1, 12, 5.99),
(3, 6, 3, 10, 7.99),
(3, 6, 4, 8, 9.99),
(4, 7, 1, 20, 5.99),
(4, 7, 5, 25, 11.99),
(4, 7, 6, 15, 8.49),
(5, 11, 2, 30, 6.99),
(5, 11, 5, 15, 11.99),
(5, 11, 7, 10, 12.99),
(6, 12, 3, 12, 7.99),
(6, 12, 6, 20, 8.49),
(6, 12, 8, 10, 9.99),
(7, 16, 1, 5, 5.99),
(7, 16, 2, 10, 6.99),
(7, 16, 4, 15, 9.49),
(8, 15, 5, 8, 11.99),
(8, 15, 6, 12, 8.49),
(8, 15, 7, 10, 12.99),
(9, 20, 3, 20, 7.99),
(9, 20, 5, 15, 11.99),
(9, 20, 8, 12, 9.99),
(10, 20, 4, 10, 9.49),
(10, 20, 6, 8, 8.49),
(10, 20, 7, 6, 12.99),
(11, 21, 1, 12, 5.99),
(11, 21, 2, 10, 6.99),
(11, 21, 3, 15, 7.49),
(12, 22, 5, 10, 11.99),
(12, 22, 6, 15, 8.49),
(12, 22, 7, 5, 12.99),
(13, 23, 1, 5, 5.99),
(13, 23, 2, 10, 6.99),
(13, 23, 4, 8, 9.49),
(14, 23, 6, 12, 8.49),
(14, 23, 7, 10, 12.99),
(14, 23, 8, 15, 9.99),
(15, 24, 2, 20, 6.99),
(15, 24, 5, 25, 11.99),
(15, 24, 7, 10, 12.99),
(16, 24, 3, 15, 7.99),
(16, 24, 4, 20, 9.49),
(16, 24, 6, 12, 8.49),
(17, 25, 1, 10, 5.99),
(17, 25, 3, 15, 7.99),
(17, 25, 5, 20, 11.99),
(18, 25, 2, 12, 6.99),
(18, 25, 4, 10, 9.49),
(18, 25, 6, 8, 8.49),
(19, 26, 1, 20, 5.99),
(19, 26, 3, 15, 7.99),
(19, 26, 5, 10, 11.99),
(20, 26, 2, 15, 6.99),
(20, 26, 4, 20, 9.49),
(20, 26, 6, 12, 8.49),
(21, 27, 1, 5, 5.99),
(21, 27, 2, 10, 6.99),
(21, 27, 3, 15, 7.49),
(22, 28, 4, 8, 9.49),
(22, 28, 5, 10, 11.99),
(22, 28, 7, 12, 12.99),
(23, 29, 6, 15, 8.49),
(23, 29, 8, 20, 9.99),
(23, 29, 1, 10, 5.99),
(24, 29, 2, 12, 6.99),
(24, 29, 3, 15, 7.99),
(24, 29, 5, 8, 11.99),
(25, 30, 4, 10, 9.49),
(25, 30, 6, 15, 8.49),
(25, 30, 7, 12, 12.99),
(26, 1, 4, 12, 8.50),
(26, 1, 8, 15, 9.75),
(26, 1, 12, 10, 6.30),
(27, 1, 5, 20, 10.50),
(27, 1, 9, 18, 11.00),
(27, 1, 13, 22, 7.45),
(28, 4, 3, 14, 7.95),
(28, 4, 7, 11, 9.65),
(28, 4, 11, 8, 5.55),
(29, 4, 2, 10, 6.45),
(29, 4, 6, 5, 8.20),
(29, 4, 10, 15, 12.30),
(30, 10, 4, 25, 9.95),
(30, 10, 8, 12, 10.45),
(30, 10, 12, 8, 6.75),
(31, 10, 1, 30, 5.55),
(31, 10, 5, 15, 10.75),
(31, 10, 9, 20, 11.25),
(32, 10, 3, 18, 7.95),
(32, 10, 7, 22, 9.50),
(32, 10, 11, 11, 6.35),
(33, 10, 2, 10, 6.45),
(33, 10, 6, 7, 8.20),
(33, 10, 10, 9, 12.10),
(34, 11, 4, 5, 9.95),
(34, 11, 8, 10, 10.00),
(34, 11, 12, 20, 6.60),
(35, 11, 1, 15, 5.55),
(35, 11, 5, 12, 10.75),
(35, 11, 9, 8, 11.25),
(36, 14, 3, 20, 7.95),
(36, 14, 7, 10, 9.50),
(36, 14, 11, 15, 6.35),
(37, 14, 2, 10, 6.45),
(37, 14, 6, 25, 8.20),
(37, 14, 10, 12, 12.10),
(38, 15, 4, 18, 9.95),
(38, 15, 8, 11, 10.00),
(38, 15, 12, 6, 6.60),
(39, 15, 1, 30, 5.55),
(39, 15, 5, 15, 10.75),
(39, 15, 9, 20, 11.25),
(40, 15, 3, 12, 7.95),
(40, 15, 7, 22, 9.50),
(40, 15, 11, 11, 6.35),
(41, 15, 2, 10, 6.45),
(41, 15, 6, 7, 8.20),
(41, 15, 10, 9, 12.10),
(42, 20, 4, 5, 9.95),
(42, 20, 8, 10, 10.00),
(42, 20, 12, 20, 6.60),
(43, 20, 1, 15, 5.55),
(43, 20, 5, 12, 10.75),
(43, 20, 9, 8, 11.25),
(44, 20, 3, 20, 7.95),
(44, 20, 7, 10, 9.50),
(44, 20, 11, 15, 6.35),
(45, 20, 2, 10, 6.45),
(45, 20, 6, 25, 8.20),
(45, 20, 10, 12, 12.10),
(46, 21, 4, 7, 9.20),
(46, 21, 8, 13, 10.55),
(46, 21, 12, 5, 6.90),
(47, 21, 1, 12, 5.30),
(47, 21, 5, 10, 11.15),
(48, 21, 3, 8, 7.80),
(48, 21, 7, 6, 9.40),
(49, 21, 2, 9, 6.10),
(49, 21, 6, 5, 8.45),
(49, 21, 10, 7, 12.70),
(50, 23, 11, 5, 6.55),
(50, 23, 15, 8, 10.25),
(51, 23, 20, 10, 11.35),
(51, 23, 25, 4, 29.95),
(52, 23, 30, 12, 17.00),
(52, 23, 35, 7, 25.70),
(52, 23, 40, 9, 30.10),
(53, 23, 45, 3, 22.85),
(53, 23, 50, 11, 19.00),
(54, 24, 1, 10, 5.55),
(54, 24, 9, 15, 11.25),
(54, 24, 17, 6, 10.45),
(55, 24, 25, 12, 29.99),
(55, 24, 33, 9, 7.95),
(56, 24, 41, 8, 50.00),
(56, 24, 49, 11, 40.75),
(57, 24, 2, 7, 6.45),
(57, 24, 10, 14, 12.30),
(57, 24, 18, 5, 8.20),
(58, 25, 26, 15, 70.00),
(58, 25, 34, 12, 75.95),
(59, 25, 42, 10, 85.10),
(59, 25, 50, 8, 95.00),
(59, 25, 3, 5, 7.95),
(60, 25, 11, 6, 10.75),
(60, 25, 19, 3, 11.25),
(61, 25, 27, 4, 80.45),
(61, 25, 35, 7, 90.50),
(62, 26, 43, 9, 100.00),
(62, 26, 2, 10, 6.45),
(63, 26, 10, 8, 12.30),
(63, 26, 18, 11, 8.20),
(64, 26, 26, 13, 70.00),
(64, 26, 34, 6, 75.95),
(65, 26, 42, 5, 85.10),
(65, 26, 50, 12, 95.00),
(66, 27, 3, 7, 7.95),
(66, 27, 11, 10, 10.75),
(67, 27, 19, 8, 11.25),
(67, 27, 27, 15, 80.45),
(68, 28, 35, 6, 90.50),
(68, 28, 43, 9, 100.00),
(69, 28, 2, 11, 6.45),
(69, 28, 10, 14, 12.30),
(70, 29, 18, 7, 8.20),
(70, 29, 26, 5, 70.00),
(70, 29, 5, 12, 42.10),
(70, 29, 25, 15, 35.25),
(71, 29, 10, 9, 52.30),
(71, 29, 15, 8, 60.40),
(71, 29, 20, 14, 45.15),
(72, 29, 12, 11, 51.20),
(72, 29, 21, 6, 39.95),
(72, 29, 30, 10, 44.00),
(73, 29, 17, 5, 49.90),
(73, 29, 22, 8, 58.25),
(73, 29, 33, 12, 65.00),
(74, 30, 7, 15, 43.15),
(74, 30, 14, 9, 77.05),
(74, 30, 27, 6, 34.20),
(75, 30, 11, 12, 48.30),
(75, 30, 24, 7, 66.50),
(75, 30, 35, 5, 55.00);

-- CONSULTAS TRABAJO PRACTICO Nº2

-- 1. Dado un producto, listar todos sus pedidos (mostrar el nombre del producto, fecha del pedido, nombre, email y teléfono del cliente del pedido).

SET @producto_nombre = 'Secco Tradicional 500ml';

SELECT 
    p.producto AS `Nombre del Producto`, 
    pe.fecha AS `Fecha del Pedido`, 
    c.cliente AS `Nombre del Cliente`, 
    c.email AS `Email del Cliente`, 
    c.telefono AS `Teléfono del Cliente`
FROM 
    Productos p
    JOIN LineasPedido lp ON p.idProducto = lp.idProducto
    JOIN Pedidos pe ON lp.idPedido = pe.idPedido AND lp.idCliente = pe.idCliente
    JOIN Clientes c ON pe.idCliente = c.idCliente
WHERE 
    p.producto = @producto_nombre
ORDER BY 
    `Nombre del Producto`, `Fecha del Pedido`, `Nombre del Cliente`;
    
-- 2. Realizar un listado de pedidos agrupados por cliente (mostrar nombre del cliente, idpedido y fecha del pedido).

SELECT 
    c.cliente AS `Nombre del Cliente`, 
    pe.idPedido AS `ID del Pedido`, 
    pe.fecha AS `Fecha del Pedido`
FROM 
    Clientes c
    JOIN Pedidos pe ON c.idCliente = pe.idCliente
ORDER BY 
    `Nombre del Cliente`, `Fecha del Pedido`;

-- 3. Dado un producto, realizar un listado de sus entradas entre un rango de fechas, mostrando el nombre del producto, fecha de la entrada, nombre y correo del proveedor. 
-- Ordenar por la fecha de entrada en orden cronológico inverso.

SET @producto_nombre = 'Secco Limón 500ml';
SET @fecha_inicio = '2023-01-01';
SET @fecha_fin = '2024-12-31';

SELECT 
    p.producto AS `Nombre del Producto`, 
    e.fecha AS `Fecha de la Entrada`, 
    pr.proveedor AS `Nombre del Proveedor`, 
    pr.email AS `Email del Proveedor`
FROM 
    Productos p
    JOIN LineasEntrada le ON p.idProducto = le.idProducto
    JOIN Entradas e ON le.idEntrada = e.idEntrada AND le.idProveedor = e.idProveedor
    JOIN Proveedores pr ON e.idProveedor = pr.idProveedor
WHERE 
    p.producto = @producto_nombre 
    AND e.fecha BETWEEN @fecha_inicio AND @fecha_fin
ORDER BY 
    `Fecha de la Entrada` DESC, `Nombre del Producto`, `Nombre del Proveedor`;

-- 4. Hacer un ranking con las unidades de transporte que más viajes realizaron en un rango de fechas. Mostrar la patente y la cantidad de viajes.

SET @fecha_inicio = '2023-01-01';
SET @fecha_fin = '2024-12-31';

SELECT 
    ut.patente AS `Patente de la Unidad de Transporte`, 
    COUNT(v.idViaje) AS `Cantidad de Viajes`
FROM 
    UnidadesTransporte ut
    JOIN Viajes v ON ut.idUnidadTransporte = v.idUnidadTransporte
WHERE 
    v.fecha BETWEEN @fecha_inicio AND @fecha_fin
GROUP BY 
    `Patente de la Unidad de Transporte`
ORDER BY 
    `Cantidad de Viajes` DESC, `Patente de la Unidad de Transporte`;

-- 5. Hacer un ranking con los 10 clientes que más pedidos realizaron (por cantidad) entre un rago de fechas. Mostrar el nombre del cliente y el total de pedidos.

SET @fecha_inicio = '2024-01-01';
SET @fecha_fin = '2024-12-31';

SELECT 
    c.cliente AS `Nombre del Cliente`, 
    COUNT(pe.idPedido) AS `Total de Pedidos`
FROM 
    Clientes c
    JOIN Pedidos pe ON c.idCliente = pe.idCliente
WHERE 
    pe.fecha BETWEEN @fecha_inicio AND @fecha_fin
GROUP BY 
    `Nombre del Cliente`
ORDER BY 
    `Total de Pedidos` DESC, `Nombre del Cliente`
LIMIT 10;

-- 6. Hacer un ranking con los 10 clientes que más pedidos realizaron (por precio) entre un rago de fechas. Mostrar el nombre del cliente y el importe de los pedidos.

SET @fecha_inicio = '2024-01-01';
SET @fecha_fin = '2024-12-31';

SELECT 
    c.cliente AS `Nombre del Cliente`, 
    SUM(lp.precio * lp.cantidad) AS `Total del Importe`
FROM 
    Clientes c
    JOIN Pedidos pe ON c.idCliente = pe.idCliente
    JOIN LineasPedido lp ON pe.idPedido = lp.idPedido AND pe.idCliente = lp.idCliente
WHERE 
    pe.fecha BETWEEN @fecha_inicio AND @fecha_fin
GROUP BY 
    `Nombre del Cliente`
ORDER BY 
    `Total del Importe` DESC, `Nombre del Cliente`
LIMIT 10;

-- 7. Hacer un ranking con las 10 zonas a donde se realizaron más viajes entre un rago de fechas. Mostrar el nombre de la zona y la cantidad de viajes.

SET @fecha_inicio = '2024-01-01';
SET @fecha_fin = '2024-12-31';

SELECT 
    z.zona AS `Nombre de la Zona`, 
    COUNT(v.idViaje) AS `Cantidad de Viajes`
FROM 
    Zonas z
    JOIN Viajes v ON z.idZona = v.idZona
WHERE 
    v.fecha BETWEEN @fecha_inicio AND @fecha_fin
GROUP BY 
    `Nombre de la Zona`
ORDER BY 
    `Cantidad de Viajes` DESC, `Nombre de la Zona`
LIMIT 10;

-- 8. Crear una vista con la funcionalidad del apartado 4.

CREATE VIEW RankingUnidadesTransporte AS
SELECT 
    ut.patente AS `Patente de la Unidad de Transporte`, 
    COUNT(v.idViaje) AS `Cantidad de Viajes`
FROM 
    UnidadesTransporte ut
    JOIN Viajes v ON ut.idUnidadTransporte = v.idUnidadTransporte
GROUP BY 
    `Patente de la Unidad de Transporte`
ORDER BY 
    `Cantidad de Viajes` DESC, `Patente de la Unidad de Transporte`;

-- 9. Crear una copia de la tabla Productos, que además tenga una columna del tipo JSON para guardar el detalle de los pedidos (LineasPedido y Pedidos). Llenar esta tabla con los
-- mismos datos del TP1 y resolver la consulta: dado un producto listar todos sus pedidos (incluye cantidad, precio y fecha).

CREATE TABLE ProductosConDetalles (
    idProducto INT AUTO_INCREMENT,
    producto VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    precio DECIMAL(15, 2) NOT NULL,
    estado CHAR(1) NOT NULL,
    detalles_pedidos JSON,
    PRIMARY KEY (idProducto),
    UNIQUE INDEX UI_producto(producto)
);

INSERT INTO ProductosConDetalles (idProducto, producto, descripcion, precio, estado, detalles_pedidos)
SELECT 
    p.idProducto, 
    p.producto, 
    p.descripcion, 
    p.precio, 
    p.estado, 
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'idPedido', lp.idPedido,
            'idCliente', lp.idCliente,
            'cantidad', lp.cantidad,
            'precio', lp.precio,
            'fecha', pe.fecha
        )
    ) AS detalles_pedidos
FROM 
    Productos p
    LEFT JOIN LineasPedido lp ON p.idProducto = lp.idProducto
    LEFT JOIN Pedidos pe ON lp.idPedido = pe.idPedido AND lp.idCliente = pe.idCliente
GROUP BY 
    p.idProducto;

SET @producto_nombre = 'Secco Tradicional 500ml';

SELECT 
    p.producto AS `Nombre del Producto`,
    jt.fecha AS `Fecha del Pedido`,
    c.cliente AS `Nombre del Cliente`,
    c.email AS `Email del Cliente`,
    c.telefono AS `Teléfono del Cliente`
FROM 
    ProductosConDetalles p,
    JSON_TABLE(p.detalles_pedidos, '$[*]' 
        COLUMNS (
            idPedido INT PATH '$.idPedido',
            idCliente INT PATH '$.idCliente',
            cantidad INT PATH '$.cantidad',
            precio DECIMAL(15, 2) PATH '$.precio',
            fecha DATETIME PATH '$.fecha'
        )
    ) AS jt
JOIN Clientes c ON jt.idCliente = c.idCliente
WHERE 
    p.producto = @producto_nombre
ORDER BY 
    `Fecha del Pedido`, `Nombre del Cliente`, jt.idPedido;

-- 10: Realizar una vista que considere importante para su modelo. También dejar escrito el enunciado de la misma.

-- ENUNCIADO: Crear una vista que liste el stock actual disponible para cada producto, mostrando el nombre del producto, la cantidad en stock y su precio. 
-- Esta vista ayudará a mantener un control del inventario de manera eficiente.

CREATE VIEW StockActualPorProducto AS
SELECT 
    p.producto AS `Nombre del Producto`,
    IFNULL(SUM(le.cantidad), 0) - IFNULL(SUM(lp.cantidad), 0) AS `Stock Actual`,
    p.precio AS `Precio del Producto`
FROM 
    Productos p
    LEFT JOIN LineasEntrada le ON p.idProducto = le.idProducto
    LEFT JOIN LineasPedido lp ON p.idProducto = lp.idProducto
GROUP BY 
    p.idProducto,
    p.producto,
    p.precio
ORDER BY 
    `Stock Actual` DESC, `Nombre del Producto`;

-- ENUNCIADO: Crear una vista que liste todos los pedidos que están pendientes de envío, mostrando detalles del pedido, el cliente y el estado de envío. 
-- Esta vista es útil para el seguimiento y la gestión de pedidos en curso.

CREATE VIEW PedidosPendientesDeEnvio AS
SELECT 
    pe.fecha AS `Fecha del Pedido`,
    c.cliente AS `Nombre del Cliente`,
    c.email AS `Email del Cliente`,
    c.telefono AS `Teléfono del Cliente`,
    pe.observaciones AS `Observaciones del Pedido`,
    v.estado AS `Estado del Envío`
FROM 
    Pedidos pe
    JOIN Clientes c ON pe.idCliente = c.idCliente
    LEFT JOIN Viajes v ON pe.idViaje = v.idViaje
WHERE 
    v.estado = 'A' 
ORDER BY 
    `Fecha del Pedido`, `Nombre del Cliente`;
    
-- ENUNCIADO: Crear una vista que liste los productos más vendidos, mostrando el nombre del producto, la cantidad vendida y el total recaudado. 
-- Esta vista es útil para identificar los productos más populares y ajustar la estrategia de ventas.

CREATE VIEW ProductosMasVendidos AS
SELECT 
    p.producto AS `Nombre del Producto`,
    SUM(lp.cantidad) AS `Cantidad Vendida`,
    SUM(lp.cantidad * lp.precio) AS `Total Recaudado`
FROM 
    Productos p
    JOIN LineasPedido lp ON p.idProducto = lp.idProducto
    JOIN Pedidos pe ON lp.idPedido = pe.idPedido AND lp.idCliente = pe.idCliente
GROUP BY 
    `Nombre del Producto`
ORDER BY 
    `Cantidad Vendida` DESC, `Total Recaudado` DESC, `Nombre del Producto`;
    
-- ENUNCIADO: Crear una vista que liste todos los pedidos que han sido entregados, mostrando detalles del pedido, el cliente, la fecha de entrega y el estado. 
-- Esta vista es útil para llevar un registro de los pedidos completados y asegurar la satisfacción del cliente.

CREATE VIEW PedidosEntregados AS
SELECT 
    pe.fecha AS `Fecha del Pedido`,
    c.cliente AS `Nombre del Cliente`,
    c.email AS `Email del Cliente`,
    c.telefono AS `Teléfono del Cliente`,
    pe.observaciones AS `Observaciones del Pedido`,
    v.estado AS `Estado del Envío`
FROM 
    Pedidos pe
    JOIN Clientes c ON pe.idCliente = c.idCliente
    JOIN Viajes v ON pe.idViaje = v.idViaje
WHERE 
    v.estado = 'D'
ORDER BY 
    `Fecha del Pedido`, `Nombre del Cliente`;
