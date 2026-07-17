/* ============================================================
   06 - Geography, Sales Team & Operations
   Closes the remaining business questions:
   scrap/returns, territory strength & growth, shipping delay,
   quota attainment, commission vs performance
   ============================================================ */
USE AdventureWorks2022;
GO

-- ------------------------------------------------------------
-- Q1. Scrap: which products fail most in production?
-- Why: quality cost — complements the profitability analysis
-- ------------------------------------------------------------
SELECT TOP 10
    p.Name          AS Product,
    sr.Name         AS ScrapReason,
    SUM(w.ScrappedQty) AS ScrappedQty,
    CAST(SUM(w.ScrappedQty * p.StandardCost) AS DECIMAL(12,0)) AS ScrapCost
FROM Production.WorkOrder w
JOIN Production.Product p      ON w.ProductID = p.ProductID
JOIN Production.ScrapReason sr ON w.ScrapReasonID = sr.ScrapReasonID
GROUP BY p.Name, sr.Name
ORDER BY ScrapCost DESC;
GO

-- ------------------------------------------------------------
-- Q2. Territory strength: revenue, customers, AOV
-- Why: is a weak territory weak in customer COUNT or order VALUE?
-- ------------------------------------------------------------
SELECT
    t.Name AS Territory,
    t.CountryRegionCode AS Country,
    COUNT(DISTINCT h.CustomerID)           AS Customers,
    COUNT(*)                               AS Orders,
    CAST(SUM(h.SubTotal) AS DECIMAL(12,0)) AS Revenue,
    CAST(AVG(h.SubTotal) AS DECIMAL(12,0)) AS AOV,
    CAST(SUM(h.SubTotal) / COUNT(DISTINCT h.CustomerID) AS DECIMAL(12,0)) AS RevPerCustomer
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
GROUP BY t.Name, t.CountryRegionCode
ORDER BY Revenue DESC;
GO

-- ------------------------------------------------------------
-- Q3. Territory growth: 2013 vs 2012 full years
-- Why: small but fast-growing regions = investment candidates
-- (2014 is partial, so we compare the two complete years)
-- ------------------------------------------------------------
WITH yearly AS (
    SELECT t.Name AS Territory,
           YEAR(h.OrderDate) AS Yr,
           SUM(h.SubTotal)   AS Revenue
    FROM Sales.SalesOrderHeader h
    JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
    WHERE YEAR(h.OrderDate) IN (2012, 2013)
    GROUP BY t.Name, YEAR(h.OrderDate)
)
SELECT
    Territory,
    CAST(MAX(CASE WHEN Yr = 2012 THEN Revenue END) AS DECIMAL(12,0)) AS Rev2012,
    CAST(MAX(CASE WHEN Yr = 2013 THEN Revenue END) AS DECIMAL(12,0)) AS Rev2013,
    CAST(100.0 * (MAX(CASE WHEN Yr = 2013 THEN Revenue END)
                - MAX(CASE WHEN Yr = 2012 THEN Revenue END))
         / NULLIF(MAX(CASE WHEN Yr = 2012 THEN Revenue END), 0) AS DECIMAL(6,1)) AS GrowthPct
FROM yearly
GROUP BY Territory
ORDER BY GrowthPct DESC;
GO

-- ------------------------------------------------------------
-- Q4. Shipping delay by territory
-- Why: ops question — does any region ship slower?
-- ------------------------------------------------------------
SELECT
    t.Name AS Territory,
    COUNT(*) AS Orders,
    AVG(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS AvgDaysToShip,
    MAX(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS MaxDaysToShip
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
WHERE h.ShipDate IS NOT NULL
GROUP BY t.Name
ORDER BY AvgDaysToShip DESC;
GO

-- ------------------------------------------------------------
-- Q5. Quota attainment per salesperson (last 4 full quarters
--     of data: 2013Q3..2014Q2, quota vs actual per quarter)
-- Why: who delivers? is quota fair?
-- ------------------------------------------------------------
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
    t.Name                                 AS Territory,
    CAST(SUM(a.ActualSales) AS DECIMAL(12,0)) AS Actual,
    CAST(SUM(q.SalesQuota)  AS DECIMAL(12,0)) AS Quota,
    CAST(100.0 * SUM(a.ActualSales) / NULLIF(SUM(q.SalesQuota), 0) AS DECIMAL(6,1)) AS AttainPct
FROM actual a
JOIN quota q  ON a.SalesPersonID = q.SalesPersonID AND a.Yr = q.Yr AND a.Qtr = q.Qtr
JOIN Person.Person pp        ON a.SalesPersonID = pp.BusinessEntityID
JOIN Sales.SalesPerson sp    ON a.SalesPersonID = sp.BusinessEntityID
LEFT JOIN Sales.SalesTerritory t ON sp.TerritoryID = t.TerritoryID
GROUP BY pp.FirstName, pp.LastName, t.Name
ORDER BY AttainPct DESC;
GO

-- ------------------------------------------------------------
-- Q6. Commission vs performance
-- Why: does a higher commission rate correlate with more sales?
-- ------------------------------------------------------------
SELECT
    CONCAT(pp.FirstName, ' ', pp.LastName) AS SalesPerson,
    sp.CommissionPct,
    CAST(sp.SalesYTD AS DECIMAL(12,0))     AS SalesYTD,
    CAST(SUM(h.SubTotal) AS DECIMAL(12,0)) AS LifetimeSales
FROM Sales.SalesPerson sp
JOIN Person.Person pp ON sp.BusinessEntityID = pp.BusinessEntityID
LEFT JOIN Sales.SalesOrderHeader h ON h.SalesPersonID = sp.BusinessEntityID
GROUP BY pp.FirstName, pp.LastName, sp.CommissionPct, sp.SalesYTD
ORDER BY LifetimeSales DESC;
GO
