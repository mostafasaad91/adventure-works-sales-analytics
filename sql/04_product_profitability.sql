/* ============================================================
   04 - Product Profitability
   Answers business questions block 2:
   profit (not just revenue) by category, loss-makers,
   discount impact, and dead stock
   Cost source: ProductCostHistory matched to order date,
   fallback to Product.StandardCost
   ============================================================ */
USE AdventureWorks2022;
GO

-- Reusable line-level profit view used by all queries below
CREATE OR ALTER VIEW Sales.vw_LineProfit AS
SELECT
    d.SalesOrderID,
    d.ProductID,
    h.OrderDate,
    d.OrderQty,
    d.UnitPriceDiscount,
    d.SpecialOfferID,
    d.LineTotal                                          AS Revenue,
    d.OrderQty * COALESCE(ch.StandardCost, p.StandardCost) AS Cost,
    d.LineTotal - d.OrderQty * COALESCE(ch.StandardCost, p.StandardCost) AS Profit
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p     ON d.ProductID = p.ProductID
LEFT JOIN Production.ProductCostHistory ch
       ON ch.ProductID = d.ProductID
      AND h.OrderDate >= ch.StartDate
      AND h.OrderDate <= COALESCE(ch.EndDate, '9999-12-31');
GO

-- ------------------------------------------------------------
-- Q1. Profit & margin by category / subcategory
-- Why: revenue ranking hides low-margin categories
-- ------------------------------------------------------------
SELECT
    c.Name  AS Category,
    sc.Name AS Subcategory,
    CAST(SUM(v.Revenue) AS DECIMAL(12,0)) AS Revenue,
    CAST(SUM(v.Profit)  AS DECIMAL(12,0)) AS Profit,
    CAST(100.0 * SUM(v.Profit) / NULLIF(SUM(v.Revenue), 0) AS DECIMAL(5,1)) AS MarginPct
FROM Sales.vw_LineProfit v
JOIN Production.Product p             ON v.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c     ON sc.ProductCategoryID = c.ProductCategoryID
GROUP BY c.Name, sc.Name
ORDER BY Profit DESC;
GO

-- ------------------------------------------------------------
-- Q2. Loss-making products (negative total profit)
-- Why: these leak money on every sale
-- ------------------------------------------------------------
SELECT TOP 15
    p.Name AS Product,
    CAST(SUM(v.Revenue) AS DECIMAL(12,0)) AS Revenue,
    CAST(SUM(v.Profit)  AS DECIMAL(12,0)) AS Profit,
    CAST(100.0 * SUM(v.Profit) / NULLIF(SUM(v.Revenue), 0) AS DECIMAL(6,1)) AS MarginPct,
    SUM(v.OrderQty) AS UnitsSold
FROM Sales.vw_LineProfit v
JOIN Production.Product p ON v.ProductID = p.ProductID
GROUP BY p.Name
HAVING SUM(v.Profit) < 0
ORDER BY Profit ASC;
GO

-- ------------------------------------------------------------
-- Q3. Discount impact: margin with vs without discount
-- Why: do promotions buy volume or just burn margin?
-- ------------------------------------------------------------
SELECT
    so.Description AS Offer,
    so.Type        AS OfferType,
    COUNT(*)       AS Lines,
    SUM(v.OrderQty) AS Units,
    CAST(SUM(v.Revenue) AS DECIMAL(12,0)) AS Revenue,
    CAST(100.0 * SUM(v.Profit) / NULLIF(SUM(v.Revenue), 0) AS DECIMAL(5,1)) AS MarginPct
FROM Sales.vw_LineProfit v
JOIN Sales.SpecialOffer so ON v.SpecialOfferID = so.SpecialOfferID
GROUP BY so.Description, so.Type
ORDER BY Revenue DESC;
GO

-- ------------------------------------------------------------
-- Q4. Dead stock: finished goods sitting in inventory
--     with zero (or near-zero) sales
-- Why: locked capital
-- ------------------------------------------------------------
SELECT TOP 15
    p.Name AS Product,
    p.ListPrice,
    inv.OnHand,
    CAST(inv.OnHand * p.StandardCost AS DECIMAL(12,0)) AS CapitalLocked,
    COALESCE(s.UnitsSold, 0) AS UnitsSold
FROM Production.Product p
JOIN (SELECT ProductID, SUM(Quantity) AS OnHand
      FROM Production.ProductInventory GROUP BY ProductID) inv
  ON p.ProductID = inv.ProductID
LEFT JOIN (SELECT ProductID, SUM(OrderQty) AS UnitsSold
           FROM Sales.SalesOrderDetail GROUP BY ProductID) s
  ON p.ProductID = s.ProductID
WHERE p.FinishedGoodsFlag = 1
  AND COALESCE(s.UnitsSold, 0) = 0
  AND inv.OnHand > 0
ORDER BY CapitalLocked DESC;
GO
