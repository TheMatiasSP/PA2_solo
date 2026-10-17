USE NovaMarket_PA2_ISIL;
GO
-- A: compra Redes confirmado 2026, pero ninguna compra Seguridad confirmada 2026.
SELECT c.ClienteID,c.Nombre,c.Ciudad
FROM dbo.Cliente AS c
WHERE EXISTS (
 SELECT 1 FROM dbo.Pedido AS p
 JOIN dbo.DetallePedido AS d ON d.PedidoID=p.PedidoID
 JOIN dbo.Producto AS pr ON pr.ProductoID=d.ProductoID
 JOIN dbo.Categoria AS ca ON ca.CategoriaID=pr.CategoriaID
 WHERE p.ClienteID=c.ClienteID AND p.Estado='CONFIRMADO'
 AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
 AND ca.Nombre=N'Redes'
)
AND NOT EXISTS (
 SELECT 1 FROM dbo.Pedido AS p
 JOIN dbo.DetallePedido AS d ON d.PedidoID=p.PedidoID
 JOIN dbo.Producto AS pr ON pr.ProductoID=d.ProductoID
 JOIN dbo.Categoria AS ca ON ca.CategoriaID=pr.CategoriaID
 WHERE p.ClienteID=c.ClienteID AND p.Estado='CONFIRMADO'
 AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
 AND ca.Nombre=N'Seguridad'
)
ORDER BY c.ClienteID;
-- B: promedio de PrecioLista de TODOS los productos en su categoría (activos o no).
SELECT p.ProductoID,p.Nombre,c.Nombre AS Categoria,p.PrecioLista,
 CAST((SELECT AVG(p2.PrecioLista) FROM dbo.Producto AS p2
       WHERE p2.CategoriaID=p.CategoriaID) AS DECIMAL(10,2)) AS PromedioCategoria
FROM dbo.Producto AS p
JOIN dbo.Categoria AS c ON c.CategoriaID=p.CategoriaID
WHERE p.PrecioLista > (SELECT AVG(p2.PrecioLista)
                       FROM dbo.Producto AS p2 WHERE p2.CategoriaID=p.CategoriaID)
ORDER BY c.Nombre,p.ProductoID;
-- C: dos pruebas conocidas: cliente 1 incluido; cliente 2 excluido (compró Seguridad).
SELECT c.ClienteID,c.Nombre,
 (SELECT COUNT(*) FROM dbo.Pedido p JOIN dbo.DetallePedido d ON d.PedidoID=p.PedidoID
  JOIN dbo.Producto pr ON pr.ProductoID=d.ProductoID
  WHERE p.ClienteID=c.ClienteID AND p.Estado='CONFIRMADO'
  AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
  AND pr.CategoriaID=1) AS LineasRedes,
 (SELECT COUNT(*) FROM dbo.Pedido p JOIN dbo.DetallePedido d ON d.PedidoID=p.PedidoID
  JOIN dbo.Producto pr ON pr.ProductoID=d.ProductoID
  WHERE p.ClienteID=c.ClienteID AND p.Estado='CONFIRMADO'
  AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
  AND pr.CategoriaID=2) AS LineasSeguridad
FROM dbo.Cliente c WHERE c.ClienteID IN (1,2);
