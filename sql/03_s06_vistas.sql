USE NovaMarket_PA2_ISIL;
GO
CREATE OR ALTER VIEW dbo.vw_VentasCategoriaMes AS
 SELECT YEAR(p.FechaPedido) AS Anio,MONTH(p.FechaPedido) AS Mes,
  c.CategoriaID,c.Nombre AS NombreCategoria,
  SUM(d.Cantidad) AS TotalUnidades,
  CAST(SUM(CAST(d.Cantidad AS DECIMAL(18,2))*d.PrecioUnitario) AS DECIMAL(18,2)) AS MontoTotal
 FROM dbo.Pedido p JOIN dbo.DetallePedido d ON d.PedidoID=p.PedidoID
 JOIN dbo.Producto pr ON pr.ProductoID=d.ProductoID
 JOIN dbo.Categoria c ON c.CategoriaID=pr.CategoriaID
 WHERE p.Estado='CONFIRMADO'
 GROUP BY YEAR(p.FechaPedido),MONTH(p.FechaPedido),c.CategoriaID,c.Nombre;
GO
CREATE OR ALTER VIEW dbo.vw_ClientesSinCompra2026 AS
 SELECT c.ClienteID,c.Nombre,c.Ciudad
 FROM dbo.Cliente c
 WHERE NOT EXISTS (
  SELECT 1 FROM dbo.Pedido p WHERE p.ClienteID=c.ClienteID
  AND p.Estado='CONFIRMADO' AND p.FechaPedido>='20260101'
  AND p.FechaPedido<'20270101');
GO
-- Consumo de ambas vistas.
SELECT * FROM dbo.vw_VentasCategoriaMes WHERE Anio=2026 ORDER BY Mes,MontoTotal DESC;
SELECT * FROM dbo.vw_ClientesSinCompra2026 ORDER BY ClienteID;
-- Contraste independiente de vista sin compras (debe ser 0 diferencias).
SELECT ClienteID,Nombre,Ciudad FROM dbo.vw_ClientesSinCompra2026
EXCEPT
SELECT c.ClienteID,c.Nombre,c.Ciudad FROM dbo.Cliente c
LEFT JOIN dbo.Pedido p ON p.ClienteID=c.ClienteID AND p.Estado='CONFIRMADO'
 AND p.FechaPedido>='20260101' AND p.FechaPedido<'20270101'
WHERE p.PedidoID IS NULL;
-- Tomamos DOS agrupaciones 2026 de la vista y comparamos contra las líneas originales.
;WITH DosGrupos AS (
 SELECT TOP (2) Anio,Mes,CategoriaID,TotalUnidades,MontoTotal
 FROM dbo.vw_VentasCategoriaMes WHERE Anio=2026
 ORDER BY Mes,CategoriaID
)
SELECT v.Anio,v.Mes,v.CategoriaID,v.TotalUnidades AS UnidadesVista,
 v.MontoTotal AS MontoVista,
 SUM(d.Cantidad) AS UnidadesOrigen,
 CAST(SUM(CAST(d.Cantidad AS DECIMAL(18,2))*d.PrecioUnitario) AS DECIMAL(18,2)) AS MontoOrigen
FROM DosGrupos v JOIN dbo.Pedido p ON p.Estado='CONFIRMADO'
 AND YEAR(p.FechaPedido)=v.Anio AND MONTH(p.FechaPedido)=v.Mes
JOIN dbo.DetallePedido d ON d.PedidoID=p.PedidoID
JOIN dbo.Producto pr ON pr.ProductoID=d.ProductoID AND pr.CategoriaID=v.CategoriaID
GROUP BY v.Anio,v.Mes,v.CategoriaID,v.TotalUnidades,v.MontoTotal
ORDER BY v.Mes,v.CategoriaID;

-- Comprobación inversa: ambas consultas de clientes sin compra deben coincidir.
SELECT c.ClienteID,c.Nombre,c.Ciudad FROM dbo.Cliente c
LEFT JOIN dbo.Pedido p ON p.ClienteID=c.ClienteID AND p.Estado='CONFIRMADO'
 AND p.FechaPedido>='20260101' AND p.FechaPedido<'20270101'
WHERE p.PedidoID IS NULL
EXCEPT
SELECT ClienteID,Nombre,Ciudad FROM dbo.vw_ClientesSinCompra2026;
GO
