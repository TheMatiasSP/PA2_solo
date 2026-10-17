USE NovaMarket_PA2_ISIL;
GO
-- B: preagregamos detalles POR PEDIDO y luego agrupamos POR CLIENTE.
-- Los filtros de estado y fecha están en el ON, no en WHERE.
;WITH MontoPorPedido AS (
 SELECT d.PedidoID,
  CAST(SUM(CAST(d.Cantidad AS DECIMAL(18,2))*d.PrecioUnitario) AS DECIMAL(18,2)) AS Monto
 FROM dbo.DetallePedido d GROUP BY d.PedidoID
)
SELECT c.ClienteID,c.Nombre,COUNT(p.PedidoID) AS TotalPedidos2026,
 CAST(COALESCE(SUM(COALESCE(m.Monto,0)),0) AS DECIMAL(18,2)) AS MontoVendido2026
FROM dbo.Cliente c
LEFT JOIN dbo.Pedido p ON p.ClienteID=c.ClienteID
 AND p.Estado='CONFIRMADO' AND p.FechaPedido>='20260101'
 AND p.FechaPedido<'20270101'
LEFT JOIN MontoPorPedido m ON m.PedidoID=p.PedidoID
WHERE c.Activo=1
GROUP BY c.ClienteID,c.Nombre
ORDER BY c.ClienteID;
GO
-- C: matriz ejecutable. Esperado vs obtenido para 4 casos controlados.
-- Cliente 4 = 1 pedido de 3 líneas (240+150+25=415).
-- Cliente 3 = solo pendiente, sin ventas válidas.
-- Cliente 5 = solo pendiente, sin ventas válidas.
-- Cliente 6 = pedidos anulados, sin ventas válidas.
;WITH MontoPorPedido AS (
 SELECT PedidoID,SUM(CAST(Cantidad AS DECIMAL(18,2))*PrecioUnitario) Monto
 FROM dbo.DetallePedido GROUP BY PedidoID
), Reporte AS (
 SELECT c.ClienteID,COUNT(p.PedidoID) AS Pedidos,
  CAST(COALESCE(SUM(COALESCE(m.Monto,0)),0) AS DECIMAL(18,2)) AS Monto
 FROM dbo.Cliente c LEFT JOIN dbo.Pedido p ON p.ClienteID=c.ClienteID
  AND p.Estado='CONFIRMADO' AND p.FechaPedido>='20260101'
  AND p.FechaPedido<'20270101'
 LEFT JOIN MontoPorPedido m ON m.PedidoID=p.PedidoID
 WHERE c.Activo=1 GROUP BY c.ClienteID
), Esperado AS (
 SELECT 4 AS ClienteID,1 AS Pedidos,CAST(415 AS DECIMAL(18,2)) AS Monto, 'Pedido 8 con tres lineas' AS Escenario
 UNION ALL SELECT 3,0,0,'Sin compras confirmadas'
 UNION ALL SELECT 5,0,0,'Pedido pendiente 9'
 UNION ALL SELECT 6,0,0,'Pedidos anulados 4 y 10'
)
SELECT e.ClienteID,e.Escenario,e.Pedidos AS PedidosEsperados,r.Pedidos AS PedidosObtenidos,
 e.Monto AS MontoEsperado,r.Monto AS MontoObtenido,
 CASE WHEN e.Pedidos=r.Pedidos AND e.Monto=r.Monto THEN 'CORRECTO' ELSE 'REVISAR' END Resultado
FROM Esperado e JOIN Reporte r ON r.ClienteID=e.ClienteID ORDER BY e.ClienteID;
GO
