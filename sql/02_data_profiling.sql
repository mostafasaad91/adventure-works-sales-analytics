/* ============================================================
   02 - Data Profiling
   Quality checks before any analysis: ranges, NULLs,
   duplicates, and revenue reconciliation
   ============================================================ */
USE AdventureWorks2022;
GO

-- 1. Order date range, channels, status values
SELECT
    MIN(OrderDate)                                          AS FirstOrder,
    MAX(OrderDate)                                          AS LastOrder,
    COUNT(*)                                                AS TotalOrders,
    SUM(CASE WHEN OnlineOrderFlag = 1 THEN 1 ELSE 0 END)    AS OnlineOrders,
    SUM(CASE WHEN OnlineOrderFlag = 0 THEN 1 ELSE 0 END)    AS StoreOrders,
    COUNT(DISTINCT [Status])                                AS DistinctStatuses,
    MIN([Status])                                           AS MinStatus,
    MAX([Status])                                           AS MaxStatus
FROM Sales.SalesOrderHeader;
GO

-- 2. NULL profile on key analytical columns
SELECT
    COUNT(*)                                               AS TotalRows,
    SUM(CASE WHEN SalesPersonID IS NULL THEN 1 ELSE 0 END) AS NullSalesPerson,   -- expected: online orders
    SUM(CASE WHEN CurrencyRateID IS NULL THEN 1 ELSE 0 END) AS NullCurrencyRate,
    SUM(CASE WHEN ShipDate IS NULL THEN 1 ELSE 0 END)      AS NullShipDate
FROM Sales.SalesOrderHeader;
GO

-- 3. Duplicate check: order numbers must be unique
SELECT SalesOrderNumber, COUNT(*) AS Cnt
FROM Sales.SalesOrderHeader
GROUP BY SalesOrderNumber
HAVING COUNT(*) > 1;
GO

-- 4. Revenue reconciliation: header SubTotal vs sum of line items
--    (validates we can trust either level for analysis)
SELECT
    COUNT(*) AS MismatchedOrders
FROM Sales.SalesOrderHeader h
JOIN (
    SELECT SalesOrderID, SUM(LineTotal) AS DetailTotal
    FROM Sales.SalesOrderDetail
    GROUP BY SalesOrderID
) d ON h.SalesOrderID = d.SalesOrderID
WHERE ABS(h.SubTotal - d.DetailTotal) > 0.01;
GO

-- 5. Logical date sanity: ship before order? due before ship?
SELECT
    SUM(CASE WHEN ShipDate < OrderDate THEN 1 ELSE 0 END) AS ShipBeforeOrder,
    SUM(CASE WHEN DueDate  < OrderDate THEN 1 ELSE 0 END) AS DueBeforeOrder,
    AVG(DATEDIFF(DAY, OrderDate, ShipDate) * 1.0)         AS AvgDaysToShip
FROM Sales.SalesOrderHeader
WHERE ShipDate IS NOT NULL;
GO

-- 6. Customer split: persons vs stores
SELECT
    SUM(CASE WHEN PersonID IS NOT NULL AND StoreID IS NULL THEN 1 ELSE 0 END) AS IndividualCustomers,
    SUM(CASE WHEN StoreID IS NOT NULL THEN 1 ELSE 0 END)                      AS StoreLinkedCustomers,
    COUNT(*)                                                                  AS TotalCustomers
FROM Sales.Customer;
GO

-- 7. Products: sellable vs never sold
SELECT
    COUNT(*)                                              AS TotalProducts,
    SUM(CASE WHEN sold.ProductID IS NULL THEN 1 ELSE 0 END) AS NeverSold,
    SUM(CASE WHEN p.FinishedGoodsFlag = 1 THEN 1 ELSE 0 END) AS FinishedGoods
FROM Production.Product p
LEFT JOIN (SELECT DISTINCT ProductID FROM Sales.SalesOrderDetail) sold
       ON p.ProductID = sold.ProductID;
GO

-- 8. Orders per year (data coverage — partial first/last years)
SELECT
    YEAR(OrderDate)      AS OrderYear,
    COUNT(*)             AS Orders,
    SUM(SubTotal)        AS Revenue,
    COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY OrderYear;
GO
