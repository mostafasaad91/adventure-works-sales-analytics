/* ============================================================
   05 - Customer Analysis
   Answers business questions block 3:
   Pareto concentration, repeat-purchase behavior,
   time to second order, channel behavior differences
   ============================================================ */
USE AdventureWorks2022;
GO

-- ------------------------------------------------------------
-- Q1. Pareto: what share of revenue comes from top customers?
-- Method: rank customers by revenue, split into 10 deciles,
--         cumulative share per decile
-- ------------------------------------------------------------
WITH cust AS (
    SELECT CustomerID, SUM(SubTotal) AS Revenue
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
),
ranked AS (
    SELECT Revenue,
           NTILE(10) OVER (ORDER BY Revenue DESC) AS Decile
    FROM cust
)
SELECT
    Decile,
    COUNT(*)                                    AS Customers,
    CAST(SUM(Revenue) AS DECIMAL(12,0))         AS Revenue,
    CAST(100.0 * SUM(Revenue) / SUM(SUM(Revenue)) OVER () AS DECIMAL(5,1)) AS PctOfTotal,
    CAST(100.0 * SUM(SUM(Revenue)) OVER (ORDER BY Decile)
         / SUM(SUM(Revenue)) OVER () AS DECIMAL(5,1))                      AS CumulativePct
FROM ranked
GROUP BY Decile
ORDER BY Decile;
GO

-- ------------------------------------------------------------
-- Q2. Repeat purchase: how many customers ever come back?
-- ------------------------------------------------------------
WITH orders_per_cust AS (
    SELECT CustomerID, COUNT(*) AS Orders
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT
    CASE WHEN Orders = 1 THEN '1 order (one-and-done)'
         WHEN Orders BETWEEN 2 AND 3 THEN '2-3 orders'
         WHEN Orders BETWEEN 4 AND 9 THEN '4-9 orders'
         ELSE '10+ orders' END AS Segment,
    COUNT(*)                   AS Customers,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS PctOfCustomers
FROM orders_per_cust
GROUP BY CASE WHEN Orders = 1 THEN '1 order (one-and-done)'
              WHEN Orders BETWEEN 2 AND 3 THEN '2-3 orders'
              WHEN Orders BETWEEN 4 AND 9 THEN '4-9 orders'
              ELSE '10+ orders' END
ORDER BY MIN(Orders);
GO

-- ------------------------------------------------------------
-- Q3. Time to second order (for customers who did return)
-- Why: defines the realistic re-activation window
-- ------------------------------------------------------------
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
    COUNT(*)                              AS ReturningCustomers,
    AVG(DaysToSecond)                     AS AvgDays,
    MIN(DaysToSecond)                     AS MinDays,
    MAX(DaysToSecond)                     AS MaxDays,
    (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DaysToSecond) OVER ()
     FROM gaps)                           AS MedianDays
FROM gaps;
GO

-- ------------------------------------------------------------
-- Q4. Channel behavior: individual (online) vs store customers
-- ------------------------------------------------------------
SELECT
    CASE WHEN c.StoreID IS NULL THEN 'Individual' ELSE 'Store' END AS CustomerKind,
    COUNT(DISTINCT h.CustomerID)                    AS Customers,
    COUNT(*)                                        AS Orders,
    CAST(COUNT(*) * 1.0 / COUNT(DISTINCT h.CustomerID) AS DECIMAL(5,1)) AS OrdersPerCustomer,
    CAST(SUM(h.SubTotal) AS DECIMAL(12,0))          AS Revenue,
    CAST(SUM(h.SubTotal) / COUNT(DISTINCT h.CustomerID) AS DECIMAL(12,0)) AS RevenuePerCustomer
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
GROUP BY CASE WHEN c.StoreID IS NULL THEN 'Individual' ELSE 'Store' END;
GO
