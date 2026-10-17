/* NovaMarket PA2 — SQL Server 2017+.
   ATENCIÓN: reinicializa solamente las tablas del proyecto NovaMarket_PA2_ISIL.
   Ejecutar una sola vez al comenzar (si se repite, se reinician los datos). */
IF DB_ID(N'NovaMarket_PA2_ISIL') IS NULL
    EXEC(N'CREATE DATABASE NovaMarket_PA2_ISIL');
GO
USE NovaMarket_PA2_ISIL;
GO
DROP VIEW IF EXISTS dbo.vw_VentasCategoriaMes;
DROP VIEW IF EXISTS dbo.vw_ClientesSinCompra2026;
DROP TABLE IF EXISTS dbo.PedidoHistorico2025;
DROP TABLE IF EXISTS dbo.DetallePedido;
DROP TABLE IF EXISTS dbo.Pedido;
DROP TABLE IF EXISTS dbo.Producto;
DROP TABLE IF EXISTS dbo.Categoria;
DROP TABLE IF EXISTS dbo.Cliente;
GO
CREATE TABLE dbo.Cliente (
 ClienteID INT NOT NULL PRIMARY KEY,
 Documento VARCHAR(12) NOT NULL UNIQUE,
 Nombre NVARCHAR(100) NOT NULL,
 Ciudad NVARCHAR(60) NOT NULL,
 Activo BIT NOT NULL
);
CREATE TABLE dbo.Categoria (
 CategoriaID INT NOT NULL PRIMARY KEY,
 Nombre NVARCHAR(30) NOT NULL UNIQUE
);
CREATE TABLE dbo.Producto (
 ProductoID INT NOT NULL PRIMARY KEY,
 CategoriaID INT NOT NULL REFERENCES dbo.Categoria(CategoriaID),
 Nombre NVARCHAR(100) NOT NULL,
 PrecioLista DECIMAL(10,2) NOT NULL CHECK (PrecioLista > 0),
 PrecioOferta DECIMAL(10,2) NULL,
 Stock INT NOT NULL CHECK (Stock >= 0),
 Activo BIT NOT NULL,
 CONSTRAINT CK_PrecioOferta CHECK (PrecioOferta IS NULL OR PrecioOferta >= 0)
);
CREATE TABLE dbo.Pedido (
 PedidoID INT NOT NULL PRIMARY KEY,
 ClienteID INT NOT NULL REFERENCES dbo.Cliente(ClienteID),
 FechaPedido DATE NOT NULL,
 Estado VARCHAR(12) NOT NULL CHECK (Estado IN ('CONFIRMADO','PENDIENTE','ANULADO','BORRADOR')),
 Canal VARCHAR(20) NOT NULL
);
CREATE TABLE dbo.DetallePedido (
 DetalleID INT NOT NULL PRIMARY KEY,
 PedidoID INT NOT NULL REFERENCES dbo.Pedido(PedidoID),
 ProductoID INT NOT NULL REFERENCES dbo.Producto(ProductoID),
 Cantidad INT NOT NULL CHECK (Cantidad > 0),
 PrecioUnitario DECIMAL(10,2) NOT NULL CHECK (PrecioUnitario >= 0)
);
INSERT dbo.Categoria(CategoriaID,Nombre) VALUES
 (1,N'Redes'),(2,N'Seguridad'),(3,N'Accesorios');
INSERT dbo.Cliente(ClienteID,Documento,Nombre,Ciudad,Activo) VALUES
 (1,'90000001',N'Ana Redes',N'Lima',1),
 (2,'90000002',N'Bruno Mixto',N'Callao',1),
 (3,'90000003',N'Carla Sin Compras',N'Lima',1),
 (4,'90000004',N'Diego Varias Lineas',N'Arequipa',1),
 (5,'90000005',N'Elena Pendiente',N'Lima',1),
 (6,'90000006',N'Fabio Anulado',N'Cusco',1),
 (7,'90000007',N'Gina Borrador Detalle',N'Lima',1),
 (8,'90000008',N'Hugo Borrador Vacio',N'Piura',1),
 (9,'90000009',N'Ines Torres',N'Lima',1),
 (10,'90000010',N'Jorge Ramirez',N'Callao',1),
 (11,'90000011',N'Karla Paredes',N'Lima',1),
 (12,'90000012',N'Luis Valdez',N'Trujillo',1),
 (13,'90000013',N'Maria Soto',N'Chiclayo',1),
 (14,'90000014',N'Nora Sin Ventas',N'Lima',1),
 (15,'90000015',N'Oscar Inactivo',N'Lima',0);
INSERT dbo.Producto(ProductoID,CategoriaID,Nombre,PrecioLista,PrecioOferta,Stock,Activo) VALUES
 (1,1,N'Router AC1200',120,NULL,15,1),
 (2,1,N'Switch 8 puertos',190,NULL,8,1),
 (3,1,N'Access Point',250,NULL,20,1),
 (4,1,N'Cable de red',20,NULL,50,0),
 (5,2,N'Camara IP',150,NULL,25,1),
 (6,2,N'Kit de alarmas',300,NULL,12,1),
 (7,2,N'Sensor movimiento',75,NULL,40,1),
 (8,2,N'Grabador NVR',430,NULL,5,1),
 (9,3,N'Mouse',25,NULL,50,1),
 (10,3,N'Teclado',55,NULL,30,1),
 (11,3,N'Audifonos',80,NULL,20,1),
 (12,3,N'Hub USB',40,NULL,0,1);
-- Pedidos 1-10: pruebas explícitas y fáciles de explicar en el video.
INSERT dbo.Pedido(PedidoID,ClienteID,FechaPedido,Estado,Canal) VALUES
 (1,1,'2026-02-10','CONFIRMADO','WEB'),
 (2,2,'2026-03-11','CONFIRMADO','TIENDA'),
 (3,3,'2026-03-15','PENDIENTE','WEB'),
 (4,6,'2026-04-01','ANULADO','WEB'),
 (5,8,'2026-01-20','BORRADOR','WEB'),
 (6,7,'2026-01-22','BORRADOR','WEB'),
 (7,9,'2025-10-05','CONFIRMADO','TIENDA'),
 (8,4,'2026-06-09','CONFIRMADO','WEB'),
 (9,5,'2026-06-10','PENDIENTE','WEB'),
 (10,6,'2026-06-11','ANULADO','TIENDA');
INSERT dbo.DetallePedido(DetalleID,PedidoID,ProductoID,Cantidad,PrecioUnitario) VALUES
 (1,1,1,2,120),
 (2,2,1,1,120),(3,2,6,1,300),
 (4,3,5,1,150),(5,4,1,1,120),
 (6,6,9,1,25),(7,7,6,1,300),
 (8,8,1,2,120),(9,8,5,1,150),(10,8,9,1,25),
 (11,9,9,1,25),(12,10,5,1,150);
-- Pedidos 11-40: los clientes 1 a 8 quedan como casos controlados.
DECLARE @n INT = 11, @detalle INT = 13, @j INT;
WHILE @n <= 40
BEGIN
 INSERT dbo.Pedido(PedidoID,ClienteID,FechaPedido,Estado,Canal)
 VALUES (@n,9 + (@n % 5), DATEFROMPARTS(CASE WHEN @n % 3 = 0 THEN 2025 ELSE 2026 END,
  1 + (@n % 12),1 + (@n % 27)),
  CASE @n % 5 WHEN 0 THEN 'PENDIENTE' WHEN 1 THEN 'ANULADO'
       WHEN 2 THEN 'BORRADOR' ELSE 'CONFIRMADO' END,
  CASE WHEN @n % 2 = 0 THEN 'WEB' ELSE 'TIENDA' END);
 SET @j = 1;
 WHILE @j <= 3
 BEGIN
  INSERT dbo.DetallePedido(DetalleID,PedidoID,ProductoID,Cantidad,PrecioUnitario)
  SELECT @detalle,@n,ProductoID,1 + (@n % 3),PrecioLista
  FROM dbo.Producto WHERE ProductoID = 1 + ((@n + @j) % 12);
  SET @detalle += 1;
  SET @j += 1;
 END;
 SET @n += 1;
END;
SELECT 'Cliente' Tabla,COUNT(*) Cantidad FROM dbo.Cliente
UNION ALL SELECT 'Categoria',COUNT(*) FROM dbo.Categoria
UNION ALL SELECT 'Producto',COUNT(*) FROM dbo.Producto
UNION ALL SELECT 'Pedido',COUNT(*) FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido',COUNT(*) FROM dbo.DetallePedido;
-- Debe devolver 15 clientes, 3 categorías, 12 productos, 40 pedidos y 102 detalles.
GO
