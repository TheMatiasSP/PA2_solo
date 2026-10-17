USE NovaMarket_PA2_ISIL;
GO
-- A: snapshot de origen, inserción histórica sin duplicados, contraste de cantidades.
IF OBJECT_ID(N'dbo.PedidoHistorico2025',N'U') IS NULL
 CREATE TABLE dbo.PedidoHistorico2025 (
 PedidoID INT NOT NULL PRIMARY KEY, ClienteID INT NOT NULL,
 FechaPedido DATE NOT NULL, Estado VARCHAR(12) NOT NULL, Canal VARCHAR(20) NOT NULL
 );
SELECT COUNT(*) AS ConfirmadosAntesDe2026
FROM dbo.Pedido WHERE Estado='CONFIRMADO' AND FechaPedido<'20260101';
INSERT dbo.PedidoHistorico2025(PedidoID,ClienteID,FechaPedido,Estado,Canal)
SELECT p.PedidoID,p.ClienteID,p.FechaPedido,p.Estado,p.Canal
FROM dbo.Pedido AS p
WHERE p.Estado='CONFIRMADO' AND p.FechaPedido<'20260101'
AND NOT EXISTS (SELECT 1 FROM dbo.PedidoHistorico2025 AS h WHERE h.PedidoID=p.PedidoID);
SELECT @@ROWCOUNT AS FilasInsertadasHistorico;
SELECT (SELECT COUNT(*) FROM dbo.Pedido WHERE Estado='CONFIRMADO' AND FechaPedido<'20260101') AS CantidadOrigen,
       (SELECT COUNT(*) FROM dbo.PedidoHistorico2025) AS CantidadDestino;
SELECT h.* FROM dbo.PedidoHistorico2025 h ORDER BY h.PedidoID;
-- Comprobación completa del histórico (incluye valores y no solo cantidad).
SELECT p.PedidoID FROM dbo.Pedido p WHERE p.Estado='CONFIRMADO'
AND p.FechaPedido<'20260101'
EXCEPT
SELECT h.PedidoID FROM dbo.PedidoHistorico2025 h;
SELECT h.PedidoID FROM dbo.PedidoHistorico2025 h
EXCEPT
SELECT p.PedidoID FROM dbo.Pedido p WHERE p.Estado='CONFIRMADO'
AND p.FechaPedido<'20260101';
-- Diferencias esperadas: 0 filas (origen sin copia o copia sin origen).
SELECT p.PedidoID FROM dbo.Pedido p WHERE p.Estado='CONFIRMADO'
AND p.FechaPedido<'20260101' AND NOT EXISTS
 (SELECT 1 FROM dbo.PedidoHistorico2025 h WHERE h.PedidoID=p.PedidoID);
GO
-- B: guardar FOTO anterior de todos los precios (en cada ejecución).
SELECT p.ProductoID,p.CategoriaID,p.Activo,p.Stock,p.PrecioLista,p.PrecioOferta
INTO #AntesOferta FROM dbo.Producto p;
UPDATE p SET PrecioOferta=CAST(ROUND(p.PrecioLista*0.90,2) AS DECIMAL(10,2))
FROM dbo.Producto p INNER JOIN dbo.Categoria c ON c.CategoriaID=p.CategoriaID
WHERE c.Nombre=N'Redes' AND p.Activo=1 AND p.Stock>=10;
SELECT a.ProductoID,a.PrecioLista,a.PrecioOferta AS OfertaAntes,
 p.PrecioOferta AS OfertaDespues,
 CASE WHEN a.PrecioOferta=p.PrecioOferta OR (a.PrecioOferta IS NULL AND p.PrecioOferta IS NULL)
 THEN 'IGUAL' ELSE 'CAMBIO' END AS Resultado
FROM #AntesOferta a JOIN dbo.Producto p ON p.ProductoID=a.ProductoID
ORDER BY a.ProductoID;
-- Debe devolver cero violaciones fuera del filtro o por variación de PrecioLista.
-- Descuento comprobado frente al precio de lista original (debe devolver cero filas).
SELECT p.ProductoID,p.PrecioOferta
FROM dbo.Producto p JOIN dbo.Categoria c ON c.CategoriaID=p.CategoriaID
WHERE c.Nombre=N'Redes' AND p.Activo=1 AND p.Stock>=10
AND (p.PrecioOferta IS NULL OR p.PrecioOferta<>CAST(ROUND(p.PrecioLista*0.90,2) AS DECIMAL(10,2)));
-- Filas modificadas fuera del alcance (debe devolver cero filas).
SELECT p.ProductoID FROM dbo.Producto p JOIN #AntesOferta a ON a.ProductoID=p.ProductoID
WHERE p.PrecioLista<>a.PrecioLista OR
 ((a.CategoriaID<>1 OR a.Activo<>1 OR a.Stock<10)
 AND (p.PrecioOferta<>a.PrecioOferta OR (p.PrecioOferta IS NULL AND a.PrecioOferta IS NOT NULL)
 OR (p.PrecioOferta IS NOT NULL AND a.PrecioOferta IS NULL)));
DROP TABLE #AntesOferta;
GO
-- C: foto anterior de pedidos, borrado protegido y resultado auditable.
SELECT p.PedidoID,p.Estado,
 CASE WHEN EXISTS (SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID=p.PedidoID)
      THEN 1 ELSE 0 END AS TeniaDetalle
INTO #PedidosAntes FROM dbo.Pedido p;
SELECT p.PedidoID,p.Estado,COUNT(d.DetalleID) AS NumeroDetalles
FROM dbo.Pedido p LEFT JOIN dbo.DetallePedido d ON d.PedidoID=p.PedidoID
WHERE p.Estado='BORRADOR' GROUP BY p.PedidoID,p.Estado;
DELETE p FROM dbo.Pedido p
WHERE p.Estado='BORRADOR' AND NOT EXISTS
 (SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID=p.PedidoID);
SELECT @@ROWCOUNT AS BorradoresSinDetalleEliminados;
SELECT a.PedidoID,a.Estado FROM #PedidosAntes a
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pedido p WHERE p.PedidoID=a.PedidoID);
-- Cero filas indebidas eliminadas: estado diferente o borrador con detalle.
SELECT a.PedidoID FROM #PedidosAntes a
WHERE NOT EXISTS (SELECT 1 FROM dbo.Pedido p WHERE p.PedidoID=a.PedidoID)
AND (a.Estado<>'BORRADOR' OR a.TeniaDetalle=1);
-- La eliminación fue completa: no debe quedar borrador sin detalles.
SELECT p.PedidoID FROM dbo.Pedido p WHERE p.Estado='BORRADOR'
AND NOT EXISTS (SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID=p.PedidoID);
SELECT PedidoID,Estado FROM dbo.Pedido WHERE PedidoID IN (1,2,5,6,7,8);
DROP TABLE #PedidosAntes;
GO
