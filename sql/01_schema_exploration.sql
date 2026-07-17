/* ============================================================
   01 - Schema Exploration
   AdventureWorks2022 — understand core tables and relationships
   ============================================================ */
USE AdventureWorks2022;
GO

-- 1. Row counts for all tables (fast, via partition stats)
SELECT
    s.name  AS SchemaName,
    t.name  AS TableName,
    SUM(p.rows) AS [RowCount]
FROM sys.tables t
JOIN sys.schemas s   ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY SUM(p.rows) DESC;
GO

-- 2. Foreign keys around the sales core (how tables connect)
SELECT
    fk.name                                   AS FKName,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id)     AS ChildTable,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS ParentTable
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) IN
      ('SalesOrderHeader', 'SalesOrderDetail', 'Customer', 'Product')
ORDER BY ChildTable;
GO

-- 3. Columns of the two fact tables
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Sales'
  AND TABLE_NAME IN ('SalesOrderHeader', 'SalesOrderDetail')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
GO
