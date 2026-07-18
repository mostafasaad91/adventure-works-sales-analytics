/* ============================================================
   08 - Additional Power BI views closing dashboard coverage gaps:
   new-vs-returning, discount/offer impact, dead stock,
   quota attainment, repeat-purchase segments.
   (Cohort retention & basket affinity are added separately by
   the Python notebook, which is the source of truth for those.)
   ============================================================ */
USE AdventureWorks2022;
GO

-- Add OrderCount (order frequency) to the existing customer dimension.
-- Additive only - existing columns/relationships are untouched.
CREATE OR ALTER VIEW pbi.DimCustomer AS
SELECT
    c.CustomerID,
    CASE WHEN c.StoreID IS NULL THEN 'Individual' ELSE 'Store' END AS CustomerKind,
    COALESCE(s.Name, CONCAT(pp.FirstName, ' ', pp.LastName), 'Unknown') AS CustomerName,
    COALESCE(seg.Segment, 'Unsegmented') AS Segment,
    seg.Frequency AS OrderCount
FROM Sales.Customer c
LEFT JOIN Sales.Store s        ON c.StoreID = s.BusinessEntityID
LEFT JOIN Person.Person pp     ON c.PersonID = pp.BusinessEntityID
LEFT JOIN dbo.CustomerSegments seg ON c.CustomerID = seg.CustomerID;
GO

-- One row per order: is this the customer's first order (New) or a repeat (Returning)?
-- Joins to FactSales on SalesOrderID.
CREATE OR ALTER VIEW pbi.DimOrderType AS
WITH first_order AS (
    SELECT CustomerID, MIN(OrderDate) AS FirstOrderDate
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT
    h.SalesOrderID,
    CASE WHEN h.OrderDate = f.FirstOrderDate THEN 'New' ELSE 'Returning' END AS CustomerType
FROM Sales.SalesOrderHeader h
JOIN first_order f ON h.CustomerID = f.CustomerID;
GO

-- Discount/promotion metadata. Joins to FactSales on SpecialOfferID.
CREATE OR ALTER VIEW pbi.DimOffer AS
SELECT
    SpecialOfferID,
    Description AS OfferDescription,
    Type AS OfferType
FROM Sales.SpecialOffer;
GO

-- Standalone table: finished goods with zero sales but stock on hand.
CREATE OR ALTER VIEW pbi.DeadStock AS
SELECT
    p.Name AS Product,
    p.ListPrice,
    inv.OnHand,
    CAST(inv.OnHand * p.StandardCost AS DECIMAL(12,0)) AS CapitalLocked
FROM Production.Product p
JOIN (SELECT ProductID, SUM(Quantity) AS OnHand
      FROM Production.ProductInventory GROUP BY ProductID) inv
  ON p.ProductID = inv.ProductID
LEFT JOIN (SELECT ProductID, SUM(OrderQty) AS UnitsSold
           FROM Sales.SalesOrderDetail GROUP BY ProductID) s
  ON p.ProductID = s.ProductID
WHERE p.FinishedGoodsFlag = 1
  AND COALESCE(s.UnitsSold, 0) = 0
  AND inv.OnHand > 0;
GO

-- Standalone table: quota attainment per sales rep, last 4 complete quarters.
CREATE OR ALTER VIEW pbi.QuotaAttainment AS
WITH actual AS (
    SELECT h.SalesPersonID,
           DATEPART(QUARTER, h.OrderDate) AS Qtr,
           YEAR(h.OrderDate)              AS Yr,
           SUM(h.SubTotal)                AS ActualSales
    FROM Sales.SalesOrderHeader h
    WHERE h.SalesPersonID IS NOT NULL
      AND h.OrderDate >= '2013-07-01'
    GROUP BY h.SalesPersonID, YEAR(h.OrderDate), DATEPART(QUARTER, h.OrderDate)
),
quota AS (
    SELECT BusinessEntityID AS SalesPersonID,
           YEAR(QuotaDate)  AS Yr,
           DATEPART(QUARTER, QuotaDate) AS Qtr,
           SalesQuota
    FROM Sales.SalesPersonQuotaHistory
    WHERE QuotaDate >= '2013-07-01'
)
SELECT
    CONCAT(pp.FirstName, ' ', pp.LastName) AS SalesPerson,
    t.Name AS Territory,
    CAST(SUM(a.ActualSales) AS DECIMAL(12,0)) AS ActualSales,
    CAST(SUM(q.SalesQuota)  AS DECIMAL(12,0)) AS Quota,
    CAST(100.0 * SUM(a.ActualSales) / NULLIF(SUM(q.SalesQuota), 0) AS DECIMAL(6,1)) AS AttainPct
FROM actual a
JOIN quota q  ON a.SalesPersonID = q.SalesPersonID AND a.Yr = q.Yr AND a.Qtr = q.Qtr
JOIN Person.Person pp        ON a.SalesPersonID = pp.BusinessEntityID
JOIN Sales.SalesPerson sp    ON a.SalesPersonID = sp.BusinessEntityID
LEFT JOIN Sales.SalesTerritory t ON sp.TerritoryID = t.TerritoryID
GROUP BY pp.FirstName, pp.LastName, t.Name;
GO

-- Standalone table: how many orders customers place, bucketed.
CREATE OR ALTER VIEW pbi.RepeatPurchaseSegments AS
WITH opc AS (
    SELECT CustomerID, COUNT(*) AS Orders
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT
    CASE WHEN Orders = 1 THEN '1 order (one-and-done)'
         WHEN Orders BETWEEN 2 AND 3 THEN '2-3 orders'
         WHEN Orders BETWEEN 4 AND 9 THEN '4-9 orders'
         ELSE '10+ orders' END AS Segment,
    COUNT(*) AS Customers,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS PctOfCustomers
FROM opc
GROUP BY CASE WHEN Orders = 1 THEN '1 order (one-and-done)'
              WHEN Orders BETWEEN 2 AND 3 THEN '2-3 orders'
              WHEN Orders BETWEEN 4 AND 9 THEN '4-9 orders'
              ELSE '10+ orders' END;
GO

-- Standalone single-row table: repeat-purchase timing summary.
CREATE OR ALTER VIEW pbi.RepeatPurchaseStats AS
WITH numbered AS (
    SELECT CustomerID, OrderDate,
           ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS rn
    FROM Sales.SalesOrderHeader
),
gaps AS (
    SELECT o1.CustomerID,
           DATEDIFF(DAY, o1.OrderDate, o2.OrderDate) AS DaysToSecond
    FROM numbered o1
    JOIN numbered o2 ON o1.CustomerID = o2.CustomerID AND o2.rn = 2
    WHERE o1.rn = 1
)
SELECT
    COUNT(*) AS ReturningCustomers,
    CAST(AVG(DaysToSecond * 1.0) AS DECIMAL(6,1)) AS AvgDaysToSecond,
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DaysToSecond) OVER ()
     FROM gaps) AS MedianDaysToSecond
FROM gaps;
GO

-- Sanity check
SELECT 'DimOrderType' v, COUNT(*) n FROM pbi.DimOrderType
UNION ALL SELECT 'DimOffer',              COUNT(*) FROM pbi.DimOffer
UNION ALL SELECT 'DeadStock',             COUNT(*) FROM pbi.DeadStock
UNION ALL SELECT 'QuotaAttainment',       COUNT(*) FROM pbi.QuotaAttainment
UNION ALL SELECT 'RepeatPurchaseSegments',COUNT(*) FROM pbi.RepeatPurchaseSegments
UNION ALL SELECT 'RepeatPurchaseStats',   COUNT(*) FROM pbi.RepeatPurchaseStats
UNION ALL SELECT 'DimCustomer(OrderCount check)', COUNT(*) FROM pbi.DimCustomer WHERE OrderCount IS NOT NULL;
GO
