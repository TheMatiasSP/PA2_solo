USE NovaMarket_PA2_ISIL;
GO
-- A: aumentar de 40 a 210 pedidos; al menos 400 detalles en total.
-- Repetible: si ya existe el PedidoID, no vuelve a añadirlo.
DECLARE @n INT=41,@d INT,@j INT;
SELECT @d=ISNULL(MAX(DetalleID),0)+1 FROM dbo.DetallePedido;
WHILE @n <= 210
BEGIN
 IF NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID=@n)
 BEGIN
  INSERT dbo.Pedido(PedidoID,ClienteID,FechaPedido,Estado,Canal)
  VALUES (@n,9+(@n%5),DATEFROMPARTS(CASE WHEN @n%4=0 THEN 2025 ELSE 2026 END,
   1+(@n%12),1+(@n%27)),
   CASE @n%6 WHEN 0 THEN 'ANULADO' WHEN 1 THEN 'PENDIENTE'
    WHEN 2 THEN 'BORRADOR' ELSE 'CONFIRMADO' END,'WEB');
  SET @j=1;
  WHILE @j<=2
  BEGIN
   INSERT dbo.DetallePedido(DetalleID,PedidoID,ProductoID,Cantidad,PrecioUnitario)
   SELECT @d,@n,ProductoID,1+(@n%3),PrecioLista
   FROM dbo.Producto WHERE ProductoID=1+((@n+@j)%12);
   SET @d+=1; SET @j+=1;
  END;
 END;
 SET @n+=1;
END;
-- Conteo general.
SELECT 'Cliente' Tabla,COUNT(*) Total FROM dbo.Cliente
UNION ALL SELECT 'Categoria',COUNT(*) FROM dbo.Categoria
UNION ALL SELECT 'Producto',COUNT(*) FROM dbo.Producto
UNION ALL SELECT 'Pedido',COUNT(*) FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido',COUNT(*) FROM dbo.DetallePedido;
SELECT YEAR(FechaPedido) Anio,Estado,COUNT(*) Cantidad
FROM dbo.Pedido GROUP BY YEAR(FechaPedido),Estado ORDER BY Anio,Estado;
-- Pruebas con ID explícito: 8 varias líneas, 3 pendiente, 10 anulado, 6 borrador con detalle.
SELECT p.PedidoID,p.ClienteID,p.Estado,p.FechaPedido,COUNT(d.DetalleID) Lineas,
 COALESCE(SUM(d.Cantidad*d.PrecioUnitario),0) ImporteBruto
FROM dbo.Pedido p LEFT JOIN dbo.DetallePedido d ON d.PedidoID=p.PedidoID
WHERE p.PedidoID IN (3,6,8,10)
GROUP BY p.PedidoID,p.ClienteID,p.Estado,p.FechaPedido ORDER BY p.PedidoID;
-- Integridad: las dos consultas deben devolver 0 filas.
SELECT d.DetalleID FROM dbo.DetallePedido d LEFT JOIN dbo.Pedido p ON p.PedidoID=d.PedidoID
WHERE p.PedidoID IS NULL;
SELECT d.DetalleID FROM dbo.DetallePedido d LEFT JOIN dbo.Producto p ON p.ProductoID=d.ProductoID
WHERE p.ProductoID IS NULL;
GO
