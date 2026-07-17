/* ============================================================
   07 - Power BI star schema (schema: pbi)
   One fact view at sales-line grain + conformed dimensions.
   Power BI imports these 5 views only — no raw tables.
   ============================================================ */
USE AdventureWorks2022;
GO
IF SCHEMA_ID('pbi') IS NULL EXEC('CREATE SCHEMA pbi');
GO

-- ------------------------------------------------------------
-- FactSales: line grain, profit precomputed (vw_LineProfit)
-- ------------------------------------------------------------
CREATE OR ALTER VIEW pbi.FactSales AS
SELECT
    v.SalesOrderID,
    v.ProductID,
    h.CustomerID,
    h.TerritoryID,
    h.SalesPersonID,
    CAST(v.OrderDate AS DATE) AS OrderDate,
    h.OnlineOrderFlag,
    v.SpecialOfferID,
    v.OrderQty,
    v.Revenue,
    v.Cost,
    v.Profit
FROM Sales.vw_LineProfit v
JOIN Sales.SalesOrderHeader h ON v.SalesOrderID = h.SalesOrderID;
GO

-- ------------------------------------------------------------
-- DimDate: one row per calendar day covering the data range
-- ------------------------------------------------------------
CREATE OR ALTER VIEW pbi.DimDate AS
SELECT
    d.[Date],
    YEAR(d.[Date])                       AS [Year],
    MONTH(d.[Date])                      AS MonthNo,
    FORMAT(d.[Date], 'MMM yyyy')         AS MonthName,
    YEAR(d.[Date]) * 100 + MONTH(d.[Date]) AS YearMonthKey,
    DATEPART(QUARTER, d.[Date])          AS QuarterNo,
    CONCAT(YEAR(d.[Date]), ' Q', DATEPART(QUARTER, d.[Date])) AS YearQuarter
FROM (
    SELECT DATEADD(DAY, n.n, '2011-01-01') AS [Date]
    FROM (SELECT TOP (1400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
          FROM sys.all_objects a CROSS JOIN sys.all_objects b) n
) d
WHERE d.[Date] <= '2014-12-31';
GO

-- ------------------------------------------------------------
-- DimProduct: product -> subcategory -> category
-- ------------------------------------------------------------
CREATE OR ALTER VIEW pbi.DimProduct AS
SELECT
    p.ProductID,
    p.Name                       AS Product,
    COALESCE(sc.Name, 'Other')   AS Subcategory,
    COALESCE(c.Name,  'Other')   AS Category,
    p.ListPrice,
    p.StandardCost
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory c     ON sc.ProductCategoryID = c.ProductCategoryID;
GO

-- ------------------------------------------------------------
-- DimCustomer: kind + Python RFM segment
-- ------------------------------------------------------------
CREATE OR ALTER VIEW pbi.DimCustomer AS
SELECT
    c.CustomerID,
    CASE WHEN c.StoreID IS NULL THEN 'Individual' ELSE 'Store' END AS CustomerKind,
    COALESCE(s.Name, CONCAT(pp.FirstName, ' ', pp.LastName), 'Unknown') AS CustomerName,
    COALESCE(seg.Segment, 'Unsegmented') AS Segment
FROM Sales.Customer c
LEFT JOIN Sales.Store s        ON c.StoreID = s.BusinessEntityID
LEFT JOIN Person.Person pp     ON c.PersonID = pp.BusinessEntityID
LEFT JOIN dbo.CustomerSegments seg ON c.CustomerID = seg.CustomerID;
GO

-- ------------------------------------------------------------
-- DimTerritory
-- ------------------------------------------------------------
CREATE OR ALTER VIEW pbi.DimTerritory AS
SELECT
    t.TerritoryID,
    t.Name              AS Territory,
    t.CountryRegionCode AS CountryCode,
    t.[Group]           AS Region
FROM Sales.SalesTerritory t;
GO

-- ------------------------------------------------------------
-- DimSalesPerson
-- ------------------------------------------------------------
CREATE OR ALTER VIEW pbi.DimSalesPerson AS
SELECT
    sp.BusinessEntityID AS SalesPersonID,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS SalesPerson,
    sp.CommissionPct
FROM Sales.SalesPerson sp
JOIN Person.Person pp ON sp.BusinessEntityID = pp.BusinessEntityID;
GO

-- Sanity check: row counts per view
SELECT 'FactSales' v, COUNT(*) n FROM pbi.FactSales
UNION ALL SELECT 'DimDate',        COUNT(*) FROM pbi.DimDate
UNION ALL SELECT 'DimProduct',     COUNT(*) FROM pbi.DimProduct
UNION ALL SELECT 'DimCustomer',    COUNT(*) FROM pbi.DimCustomer
UNION ALL SELECT 'DimTerritory',   COUNT(*) FROM pbi.DimTerritory
UNION ALL SELECT 'DimSalesPerson', COUNT(*) FROM pbi.DimSalesPerson;
GO
