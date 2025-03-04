--1)
CREATE TABLE FactSupplierPurchases (
    PurchaseID SERIAL PRIMARY KEY,
    SupplierID INT,
    TotalPurchaseAmount DECIMAL,
    PurchaseDate DATE,
    NumberOfProducts INT,
    FOREIGN KEY (SupplierID) REFERENCES DimSupplier(SupplierID)
);

INSERT INTO FactSupplierPurchases (SupplierID, TotalPurchaseAmount, PurchaseDate, NumberOfProducts)
SELECT 
    p.SupplierID, 
    SUM(od.UnitPrice * od.qty) AS TotalPurchaseAmount, 
    CURRENT_DATE AS PurchaseDate, 
    COUNT(DISTINCT od.ProductID) AS NumberOfProducts
FROM staging_order_details od
JOIN staging_products p ON od.ProductID = p.ProductID
GROUP BY p.SupplierID;

--1.5 Querying the Data Mart
SELECT
    s.CompanyName,
    SUM(fsp.TotalPurchaseAmount) AS TotalSpend,
    EXTRACT(YEAR FROM fsp.PurchaseDate) AS Year,
    EXTRACT(MONTH FROM fsp.PurchaseDate) AS Month
FROM FactSupplierPurchases fsp
JOIN DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY s.CompanyName, Year, Month
ORDER BY TotalSpend DESC;

SELECT
    s.CompanyName,
    p.ProductName,
    AVG(od.UnitPrice) AS AverageUnitPrice,
    SUM(od.qty) AS TotalQuantityPurchased,
    SUM(od.UnitPrice * od.qty) AS TotalSpend
FROM staging_order_details od
JOIN staging_products p ON od.ProductID = p.ProductID
JOIN DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, p.ProductName
ORDER BY s.CompanyName, TotalSpend DESC;

SELECT
    s.CompanyName,
    p.ProductName,
    SUM(od.UnitPrice * od.qty) AS TotalSpend
FROM staging_order_details od
JOIN staging_products p ON od.ProductID = p.ProductID
JOIN DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, p.ProductName
ORDER BY s.CompanyName, TotalSpend DESC
LIMIT 5;


--2)

CREATE TABLE FactProductSales (
    FactSalesID SERIAL PRIMARY KEY,
    DateID INT,
    ProductID INT,
    QuantitySold INT,
    TotalSales DECIMAL(10,2),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID)
);

INSERT INTO FactProductSales (DateID, ProductID, QuantitySold, TotalSales)
SELECT 
    (SELECT DateID FROM DimDate WHERE Date = s.OrderDate) AS DateID,
    p.ProductID, 
    sod.qty, 
    (sod.qty * sod.UnitPrice) AS TotalSales
FROM staging_order_details sod
JOIN staging_orders s ON sod.OrderID = s.OrderID
JOIN staging_products p ON sod.ProductID = p.ProductID;
--2.5 Querying the Data Mart
SELECT 
    p.ProductName,
    SUM(fps.QuantitySold) AS TotalQuantitySold,
    SUM(fps.TotalSales) AS TotalRevenue
FROM 
    FactProductSales fps
JOIN DimProduct p ON fps.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalRevenue DESC
LIMIT 5;


SELECT 
    c.CategoryName, 
    EXTRACT(YEAR FROM d.Date) AS Year,
    EXTRACT(MONTH FROM d.Date) AS Month,
    SUM(fps.QuantitySold) AS TotalQuantitySold,
    SUM(fps.TotalSales) AS TotalRevenue
FROM 
    FactProductSales fps
JOIN DimProduct p ON fps.ProductID = p.ProductID
JOIN DimCategory c ON p.CategoryID = c.CategoryID
JOIN DimDate d ON fps.DateID = d.DateID
GROUP BY c.CategoryName, Year, Month, d.Date
ORDER BY Year, Month, TotalRevenue DESC;

SELECT 
    p.ProductName,
    p.UnitsInStock,
    p.UnitPrice,
    (p.UnitsInStock * p.UnitPrice) AS InventoryValue
FROM 
    DimProduct p
ORDER BY InventoryValue DESC;	
	

SELECT 
    s.CompanyName,
    COUNT(DISTINCT fps.FactSalesID) AS NumberOfSalesTransactions,
    SUM(fps.QuantitySold) AS TotalProductsSold,
    SUM(fps.TotalSales) AS TotalRevenueGenerated
FROM 
    FactProductSales fps
JOIN DimProduct p ON fps.ProductID = p.ProductID
JOIN DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName
ORDER BY TotalRevenueGenerated DESC

	
		
--3) the scripts do not work 
	

--4)
--4.5 Querying the Data Mart
SELECT d.Month, d.Year, c.CategoryName, SUM(fs.TotalAmount) AS TotalSales
FROM FactSales fs
JOIN DimDate d ON fs.DateID = d.DateID
JOIN DimCategory c ON fs.CategoryID = c.CategoryID
GROUP BY d.Month, d.Year, c.CategoryName
ORDER BY d.Year, d.Month, TotalSales DESC;	
	
SELECT d.Quarter, d.Year, p.ProductName, SUM(fs.QuantitySold) AS TotalQuantitySold
FROM FactSales fs
JOIN DimDate d ON fs.DateID = d.DateID
JOIN DimProduct p ON fs.ProductID = p.ProductID
GROUP BY d.Quarter, d.Year, p.ProductName
ORDER BY d.Year, d.Quarter, TotalQuantitySold DESC
LIMIT 5;
				
SELECT cu.CompanyName, SUM(fs.TotalAmount) AS TotalSpent, COUNT(DISTINCT fs.salesid) AS TransactionsCount
FROM FactSales fs
JOIN DimCustomer cu ON fs.CustomerID = cu.CustomerID
GROUP BY cu.CompanyName
ORDER BY TotalSpent DESC;
	
SELECT e.FirstName, e.LastName, COUNT(fs.salesid) AS NumberOfSales, SUM(fs.TotalAmount) AS TotalSales
FROM FactSales fs
JOIN DimEmployee e ON fs.EmployeeID = e.EmployeeID
GROUP BY e.FirstName, e.LastName
ORDER BY TotalSales DESC;	
					
WITH MonthlySales AS (
SELECT
        d.Year,
        d.Month,
        SUM(fs.TotalAmount) AS TotalSales
    FROM FactSales fs
    JOIN DimDate d ON fs.DateID = d.DateID
    GROUP BY d.Year, d.Month
),
MonthlyGrowth AS (
    SELECT
        Year,
        Month,
        TotalSales,
        LAG(TotalSales) OVER (ORDER BY Year, Month) AS PreviousMonthSales,
        (TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Month)) / LAG(TotalSales) OVER (ORDER BY Year, Month) AS GrowthRate
    FROM MonthlySales
)
SELECT * FROM MonthlyGrowth;
	
	
	
	
	
	
	