--Sales Amount by Region / Territory
--Top Sales Australia 9061000,5844
SELECT
    st.SalesTerritoryRegion,
    SUM(fis.SalesAmount) AS TotalSalesAmount
FROM FactInternetSales fis
JOIN DimSalesTerritory st
    ON fis.SalesTerritoryKey = st.SalesTerritoryKey
GROUP BY st.SalesTerritoryRegion
ORDER BY TotalSalesAmount DESC;

--Sales Amount by Product Category
--Top Product Bikes 28318144,6507 (96%) Revenue
SELECT
    pc.EnglishProductCategoryName,
    SUM(fis.SalesAmount) AS TotalSalesAmount
FROM FactInternetSales fis
JOIN DimProduct p
    ON fis.ProductKey = p.ProductKey
JOIN DimProductSubcategory psc
    ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
JOIN DimProductCategory pc
    ON psc.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY pc.EnglishProductCategoryName
ORDER BY TotalSalesAmount DESC;

--Sales Trend by Order Date (Month–Year)
SELECT
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName,
    SUM(fis.SalesAmount) AS TotalSalesAmount
FROM FactInternetSales fis
JOIN DimDate d
    ON fis.OrderDateKey = d.DateKey
GROUP BY
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName
ORDER BY
    d.CalendarYear,
    d.MonthNumberOfYear;


--Sales Processing Time (Delivery Performance)
SELECT
    MIN(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate)) AS FastestDeliveryDays,
    MAX(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate)) AS LongestDeliveryDays,
    AVG(CAST(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate) AS FLOAT)) AS AvgDeliveryDays
FROM FactInternetSales fis
WHERE fis.ShipDate IS NOT NULL;

--Overdue Orders (Late Delivery)
--Assumption: SLA = 5 hari ada 60398
SELECT
    COUNT(*) AS OverdueOrders
FROM FactInternetSales
WHERE DATEDIFF(DAY, OrderDate, ShipDate) > 5;

--SQL VALIDATION — Delivery Speed by Territory
SELECT
    st.SalesTerritoryRegion,
    MIN(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate)) AS FastestDeliveryDays,
    MAX(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate)) AS LongestDeliveryDays,
    AVG(CAST(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate) AS FLOAT)) AS AvgDeliveryDays
FROM FactInternetSales fis
JOIN DimSalesTerritory st
    ON fis.SalesTerritoryKey = st.SalesTerritoryKey
WHERE fis.ShipDate IS NOT NULL
GROUP BY st.SalesTerritoryRegion
ORDER BY AvgDeliveryDays;

--Delivery Performance by Customer Segment
--(Jika fokus customer experience)
SELECT
    c.EnglishEducation,
    AVG(CAST(DATEDIFF(DAY, fis.OrderDate, fis.ShipDate) AS FLOAT)) AS AvgDeliveryDays
FROM FactInternetSales fis
JOIN DimCustomer c
    ON fis.CustomerKey = c.CustomerKey
WHERE fis.ShipDate IS NOT NULL
GROUP BY c.EnglishEducation
ORDER BY AvgDeliveryDays;

--Delivery SLA Monitoring (GLOBAL KPI)

SELECT
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN DATEDIFF(DAY, OrderDate, ShipDate) <= 3 THEN 1 ELSE 0 END) AS FastOrders,
    SUM(CASE WHEN DATEDIFF(DAY, OrderDate, ShipDate) BETWEEN 4 AND 5 THEN 1 ELSE 0 END) AS OnTimeOrders,
    SUM(CASE WHEN DATEDIFF(DAY, OrderDate, ShipDate) > 7 THEN 1 ELSE 0 END) AS LateOrders
FROM FactInternetSales
WHERE ShipDate IS NOT NULL;

--Top 10 Customers by Sales Amount
SELECT TOP 10
    c.CustomerKey,
    c.[FirstName] || ' ' || c.[MiddleName] || ' '|| c.[LastName] as CustomerName,
    SUM(fis.SalesAmount) AS TotalSalesAmount
FROM FactInternetSales fis
JOIN DimCustomer c
    ON fis.CustomerKey = c.CustomerKey
GROUP BY c.CustomerKey, c.[FirstName], c.[MiddleName], c.[LastName]
ORDER BY TotalSalesAmount DESC;

--Bottom 10 Customers by Sales Amount
SELECT TOP 10
    c.CustomerKey,
     c.[FirstName] || ' ' || c.[MiddleName] || ' '|| c.[LastName] as CustomerName,
    SUM(fis.SalesAmount) AS TotalSalesAmount
FROM FactInternetSales fis
JOIN DimCustomer c
    ON fis.CustomerKey = c.CustomerKey
GROUP BY c.CustomerKey, c.[FirstName], c.[MiddleName], c.[LastName]
ORDER BY TotalSalesAmount ASC;

--FINANCE — SQL VALIDATION QUERIES
--Finance Overview (Summary by Account Type)
SELECT
    da.AccountType,
    SUM(ff.Amount) AS TotalAmount
FROM FactFinance ff
JOIN DimAccount da
    ON ff.AccountKey = da.AccountKey
GROUP BY da.AccountType
ORDER BY TotalAmount DESC;

--Finance Detail by Account
SELECT
    da.AccountType,
    SUM(ff.Amount) AS TotalAmount
FROM FactFinance ff
JOIN DimAccount da
    ON ff.AccountKey = da.AccountKey
GROUP BY
    da.AccountType
ORDER BY da.AccountType, TotalAmount DESC;

--Finance Trend by Period (Month–Year) --3102,39999999997 by end of the period
SELECT
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName,
    SUM(ff.Amount) AS TotalAmount
FROM FactFinance ff
JOIN DimDate d
    ON ff.DateKey = d.DateKey
GROUP BY
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName
ORDER BY
    d.CalendarYear,
    d.MonthNumberOfYear;

--Scenario Analysis (Actual vs Budget vs Forecast)
SELECT
    ds.ScenarioName,
    SUM(ff.Amount) AS TotalAmount
FROM FactFinance ff
JOIN DimScenario ds
    ON ff.ScenarioKey = ds.ScenarioKey
GROUP BY ds.ScenarioName
ORDER BY TotalAmount DESC;

--Actual vs Budget Variance
SELECT
    da.AccountType,
    SUM(CASE WHEN ds.ScenarioName = 'Actual' THEN ff.Amount ELSE 0 END) AS ActualAmount,
    SUM(CASE WHEN ds.ScenarioName = 'Budget' THEN ff.Amount ELSE 0 END) AS BudgetAmount,
    SUM(CASE WHEN ds.ScenarioName = 'Actual' THEN ff.Amount ELSE 0 END)
      - SUM(CASE WHEN ds.ScenarioName = 'Budget' THEN ff.Amount ELSE 0 END)
      AS VarianceAmount
FROM FactFinance ff
JOIN DimAccount da
    ON ff.AccountKey = da.AccountKey
JOIN DimScenario ds
    ON ff.ScenarioKey = ds.ScenarioKey
GROUP BY da.AccountType;

--YoY Financial Performance
SELECT
    d.CalendarYear,
    da.AccountType,
    SUM(ff.Amount) AS TotalAmount
FROM FactFinance ff
JOIN DimDate d
    ON ff.DateKey = d.DateKey
JOIN DimAccount da
    ON ff.AccountKey = da.AccountKey
GROUP BY
    d.CalendarYear,
    da.AccountType
ORDER BY
    d.CalendarYear,
    da.AccountType;