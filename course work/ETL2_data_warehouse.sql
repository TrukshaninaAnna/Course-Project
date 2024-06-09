
INSERT INTO datawarehouse.DimCategories (CategoryID, CategoryName)
SELECT DISTINCT CategoryID, CategoryName
FROM Categories
ON CONFLICT (CategoryID) DO NOTHING;

-- Наполнение DimCountries
INSERT INTO datawarehouse.DimCountries (CountryID, CountryName)
SELECT DISTINCT CountryID, CountryName
FROM CountriesOfOrigin
ON CONFLICT (CountryID) DO NOTHING;

-- Наполнение DimBrands
INSERT INTO datawarehouse.DimBrands (BrandID, BrandName)
SELECT DISTINCT BrandID, BrandName
FROM Brands
ON CONFLICT (BrandID) DO NOTHING;

-- Наполнение DimManufacturers
INSERT INTO datawarehouse.DimManufacturers (ManufacturerID, ManufacturerName, CountryID)
SELECT DISTINCT ManufacturerID, ManufacturerName, CountryID
FROM Manufacturers
ON CONFLICT (ManufacturerID) DO NOTHING;

-- Наполнение DimUsers
INSERT INTO datawarehouse.DimUsers (UserID, Username, Email, Address, Phone)
SELECT DISTINCT UserID, Username, Email, Address, Phone
FROM Users
ON CONFLICT (UserID) DO NOTHING;

-- Наполнение DimDate
INSERT INTO datawarehouse.DimDate (Date, Year, Month, Day, Quarter)
SELECT DISTINCT OrderDate, EXTRACT(YEAR FROM OrderDate), EXTRACT(MONTH FROM OrderDate), EXTRACT(DAY FROM OrderDate), EXTRACT(QUARTER FROM OrderDate)
FROM Orders
ON CONFLICT (Date) DO NOTHING;


-- Наполнение DimProducts с поддержкой SCD Type 2
INSERT INTO datawarehouse.DimProducts (ProductID, ProductName, CategoryID, BrandID, ManufacturerID, Price, AvailabilityStatus, StartDate, IsCurrent)
SELECT DISTINCT 
    p.ProductID, 
    p.ProductName, 
    p.CategoryID, 
    p.BrandID, 
    p.ManufacturerID, 
    p.Price, 
    p.AvailabilityStatus, 
    CURRENT_DATE, 
    TRUE
FROM Products p
ON CONFLICT (ProductID, BrandID, CategoryID, ManufacturerID) DO UPDATE 
SET 
    EndDate = EXCLUDED.StartDate - INTERVAL '1 day', 
    IsCurrent = FALSE
WHERE 
    datawarehouse.DimProducts.IsCurrent = TRUE;
	
	
-- Пример обновления продукта с ProductID = 1
SELECT update_dim_products(1, 120.00, TRUE);

-- Проверка содержимого таблицы DimProducts после обновления
SELECT * FROM datawarehouse.DimProducts WHERE ProductID = 1;



-- Наполнение Sales_Fact
INSERT INTO datawarehouse.Sales_Fact (OrderID, ProductID, UserID, DateID, Quantity, UnitPrice, TotalCost)
SELECT 
    od.OrderID,
    od.ProductID,
    o.UserID,
    dd.DateID,
    od.Quantity,
    od.UnitPrice,
    o.TotalCost
FROM OrderDetails od
JOIN Orders o ON od.OrderID = o.OrderID
JOIN datawarehouse.DimDate dd ON o.OrderDate = dd.Date;


-- Наполнение ProductRatings_Fact
INSERT INTO datawarehouse.ProductRatings_Fact (ProductID, UserID, BrandID, Rating)
SELECT 
    pr.ProductID,
    pr.UserID,
    p.BrandID,
    pr.Rating
FROM ProductRatings pr
JOIN Products p ON pr.ProductID = p.ProductID;


-- Наполнение ManufacturerCountry_Fact
INSERT INTO datawarehouse.ManufacturerCountry_Fact (ManufacturerID, CountryID)
SELECT DISTINCT 
    m.ManufacturerID,
    m.CountryID
FROM Manufacturers m
JOIN datawarehouse.DimCountries dc ON m.CountryID = dc.CountryID;



select * from datawarehouse.dimCategories;
select * from datawarehouse.DimBrands;
select * from datawarehouse.DimUsers;
select * from datawarehouse.DimDate;
select * from datawarehouse.DimCountries;
select * from datawarehouse.DimManufacturers;
select * from datawarehouse.DimProducts;
select * from datawarehouse.Sales_Fact;
select * from datawarehouse.ProductRatings_Fact;
select * from datawarehouse.ManufacturerCountry_Fact;


CREATE VIEW sales_trend_daily AS
SELECT 
    dd.Date,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimDate dd ON sf.DateID = dd.DateID
GROUP BY dd.Date
ORDER BY dd.Date;

CREATE VIEW sales_trend AS
SELECT 
    dd.Date,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimDate dd ON sf.DateID = dd.DateID
GROUP BY dd.Date
ORDER BY dd.Date;
	
	
CREATE VIEW sales_by_country AS
SELECT 
    dc.CountryName,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimProducts dp ON sf.ProductID = dp.ProductID
JOIN datawarehouse.ManufacturerCountry_Fact mcf ON dp.ManufacturerID = mcf.ManufacturerID
JOIN datawarehouse.DimCountries dc ON mcf.CountryID = dc.CountryID
GROUP BY dc.CountryName
ORDER BY TotalSales DESC;


CREATE VIEW sales_by_category AS
SELECT 
    dcat.CategoryName,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimProducts dp ON sf.ProductID = dp.ProductID
JOIN datawarehouse.DimCategories dcat ON dp.CategoryID = dcat.CategoryID
GROUP BY dcat.CategoryName
ORDER BY TotalSales DESC;


CREATE VIEW sales_by_brand AS
SELECT 
    db.BrandName,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimProducts dp ON sf.ProductID = dp.ProductID
JOIN datawarehouse.DimBrands db ON dp.BrandID = db.BrandID
GROUP BY db.BrandName
ORDER BY TotalSales DESC;


CREATE VIEW average_rating_by_product AS
SELECT 
    dp.ProductName,
    AVG(prf.Rating) AS AverageRating
FROM datawarehouse.ProductRatings_Fact prf
JOIN datawarehouse.DimProducts dp ON prf.ProductID = dp.ProductID
GROUP BY dp.ProductName
ORDER BY AverageRating DESC;


CREATE VIEW average_rating_by_brand AS
SELECT 
    db.BrandName,
    AVG(prf.Rating) AS AverageRating
FROM datawarehouse.ProductRatings_Fact prf
JOIN datawarehouse.DimProducts dp ON prf.ProductID = dp.ProductID
JOIN datawarehouse.DimBrands db ON dp.BrandID = db.BrandID
GROUP BY db.BrandName
ORDER BY AverageRating DESC;