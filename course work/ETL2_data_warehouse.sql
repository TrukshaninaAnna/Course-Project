
INSERT INTO datawarehouse.DimCategories (CategoryID, CategoryName)
SELECT DISTINCT CategoryID, CategoryName
FROM Categories
ON CONFLICT (CategoryID) DO NOTHING;


INSERT INTO datawarehouse.DimCountries (CountryID, CountryName)
SELECT DISTINCT CountryID, CountryName
FROM CountriesOfOrigin
ON CONFLICT (CountryID) DO NOTHING;


INSERT INTO datawarehouse.DimBrands (BrandID, BrandName)
SELECT DISTINCT BrandID, BrandName
FROM Brands
ON CONFLICT (BrandID) DO NOTHING;


INSERT INTO datawarehouse.DimManufacturers (ManufacturerID, ManufacturerName, CountryID)
SELECT DISTINCT ManufacturerID, ManufacturerName, CountryID
FROM Manufacturers
ON CONFLICT (ManufacturerID) DO NOTHING;


INSERT INTO datawarehouse.DimDate (Date, Year, Month, Day, Quarter)
SELECT DISTINCT OrderDate, EXTRACT(YEAR FROM OrderDate), EXTRACT(MONTH FROM OrderDate), EXTRACT(DAY FROM OrderDate), EXTRACT(QUARTER FROM OrderDate)
FROM Orders
ON CONFLICT (Date) DO NOTHING;


INSERT INTO datawarehouse.DimProducts (ProductID, ProductName, CategoryID, BrandID, ManufacturerID, Price, AvailabilityStatus)
SELECT DISTINCT ProductID, ProductName, CategoryID, BrandID, ManufacturerID, Price, AvailabilityStatus
FROM Products
ON CONFLICT (ProductID) DO NOTHING;


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


INSERT INTO datawarehouse.ProductRatings_Fact (ProductID, UserID, BrandID, Rating)
SELECT 
    pr.ProductID,
    pr.UserID,
    p.BrandID,
    pr.Rating
FROM ProductRatings pr
JOIN Products p ON pr.ProductID = p.ProductID;



select * from datawarehouse.dimCategories;
select * from datawarehouse.DimBrands;
select * from datawarehouse.DimUsers;
select * from datawarehouse.DimDate;
select * from datawarehouse.DimCountries;
select * from datawarehouse.DimManufacturers;
select * from datawarehouse.DimProducts;
select * from datawarehouse.Sales_Fact;
select * from datawarehouse.ProductRatings_Fact;


select * from datawarehouse.sales_trend;
select * from datawarehouse.sales_by_user;
select * from datawarehouse.sales_by_country_of_origin;
select * from datawarehouse.sales_by_category;
select * from datawarehouse.sales_by_brand;
select * from datawarehouse.average_rating_by_product;
select * from datawarehouse.average_rating_by_brand;
