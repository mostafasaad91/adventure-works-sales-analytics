/* ============================================================
   03 - Sales & Growth Analysis
   Answers business questions block 1:
   trend, seasonality, YoY, channel mix, new vs returning
   ============================================================ */
USE AdventureWorks2022;
GO

-- ------------------------------------------------------------
-- Q1. Monthly revenue trend
-- Why: yearly totals hide seasonality and the AOV break point
-- ------------------------------------------------------------
SELECT
    YEAR(OrderDate)                        AS OrderYear,
    MONTH(OrderDate)                       AS OrderMonth,
    COUNT(*)                               AS Orders,
    CAST(SUM(SubTotal) AS DECIMAL(12,0))   AS Revenue,
    CAST(AVG(SubTotal) AS DECIMAL(12,0))   AS AOV
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;
GO

-- ------------------------------------------------------------
-- Q2. Year-over-year growth per month (LAG window function)
-- Why: compare each month to same month last year,
--      so seasonality does not fool us
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        YEAR(OrderDate)  AS Yr,
        MONTH(OrderDate) AS Mo,
        SUM(SubTotal)    AS Revenue
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT
    Yr, Mo,
    CAST(Revenue AS DECIMAL(12,0)) AS Revenue,
    CAST(LAG(Revenue, 12) OVER (ORDER BY Yr, Mo) AS DECIMAL(12,0)) AS SameMonthLastYear,
    CAST(100.0 * (Revenue - LAG(Revenue, 12) OVER (ORDER BY Yr, Mo))
         / NULLIF(LAG(Revenue, 12) OVER (ORDER BY Yr, Mo), 0) AS DECIMAL(6,1)) AS YoYPct
FROM monthly
ORDER BY Yr, Mo;
GO

-- ------------------------------------------------------------
-- Q3. Channel breakdown per year: Online vs Store
-- Why: test the hypothesis — order count exploded but AOV
--      collapsed because the MIX shifted to small online orders
-- ------------------------------------------------------------
SELECT
    YEAR(OrderDate)                        AS OrderYear,
    CASE WHEN OnlineOrderFlag = 1 THEN 'Online' ELSE 'Store' END AS Channel,
    COUNT(*)                               AS Orders,
    CAST(SUM(SubTotal) AS DECIMAL(12,0))   AS Revenue,
    CAST(AVG(SubTotal) AS DECIMAL(12,0))   AS AOV
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate),
         CASE WHEN OnlineOrderFlag = 1 THEN 'Online' ELSE 'Store' END
ORDER BY OrderYear, Channel;
GO

-- ------------------------------------------------------------
-- Q4. Growth source: new vs returning customers per year
-- Why: growth from NEW customers is acquisition;
--      growth from RETURNING customers is retention.
--      Different problems -> different recommendations.
-- ------------------------------------------------------------
WITH first_order AS (
    SELECT CustomerID, MIN(OrderDate) AS FirstOrderDate
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)
SELECT
    YEAR(h.OrderDate) AS OrderYear,
    CASE WHEN YEAR(h.OrderDate) = YEAR(f.FirstOrderDate)
         THEN 'New' ELSE 'Returning' END  AS CustomerType,
    COUNT(DISTINCT h.CustomerID)          AS Customers,
    COUNT(*)                              AS Orders,
    CAST(SUM(h.SubTotal) AS DECIMAL(12,0)) AS Revenue
FROM Sales.SalesOrderHeader h
JOIN first_order f ON h.CustomerID = f.CustomerID
GROUP BY YEAR(h.OrderDate),
         CASE WHEN YEAR(h.OrderDate) = YEAR(f.FirstOrderDate)
              THEN 'New' ELSE 'Returning' END
ORDER BY OrderYear, CustomerType;
GO
