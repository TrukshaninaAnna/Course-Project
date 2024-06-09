CREATE SCHEMA orders;

CREATE TABLE orders.TempOrders (
    OrderID serial primary key,
    OrderDate date,
    FullName text,
    Email text,
    Address text,
    Phone text,
    Status text
);

CREATE TABLE orders.TempOrderDetails (
    OrderDetailsID int,
    OrderID int,
    ProductName text,
    Сategory text,
    Brand text,
    Manufacturer text,
    CoutryOfOrigin text,
    Price numeric(10,2),
    Quantity int,
	UnitPrice numeric(10,2),
    AvailabilityStatus boolean
);

CREATE TABLE orders.TempProductRatings (
    ProductName text,
    UserFullName text,
    Rating int
);

COPY orders.TempOrders(OrderDate, FullName, Email, Address, Phone, Status)
FROM 'C:\course work\orders.csv'
DELIMITER ','
CSV HEADER
ENCODING 'WIN1251';

COPY orders.TempOrderDetails(OrderDetailsID, OrderID, ProductName, Сategory, Brand, Manufacturer, CoutryOfOrigin, Price, Quantity, UnitPrice, AvailabilityStatus)
FROM 'C:\course work\order_details.csv'
DELIMITER ','
CSV HEADER
ENCODING 'WIN1251';

COPY orders.TempProductRatings(ProductName, UserFullName, Rating)
FROM 'C:\course work\product_ratings.csv'
DELIMITER ','
CSV HEADER
ENCODING 'WIN1251';

select * from orders.TempOrders;
select * from orders.TempOrderDetails;
select * from orders.TempProductRatings;


INSERT INTO Categories (CategoryName)
SELECT DISTINCT Сategory
FROM orders.TempOrderDetails
ON CONFLICT (CategoryName) DO NOTHING;


INSERT INTO Brands (BrandName)
SELECT DISTINCT Brand
FROM orders.TempOrderDetails
ON CONFLICT (BrandName) DO NOTHING;


INSERT INTO Manufacturers (ManufacturerName, CountryID)
SELECT DISTINCT Manufacturer, c.CountryID
FROM orders.TempOrderDetails tod
JOIN CountriesOfOrigin c ON tod.CoutryOfOrigin = c.CountryName
ON CONFLICT (ManufacturerName) DO NOTHING;


INSERT INTO CountriesOfOrigin (CountryName)
SELECT DISTINCT CoutryOfOrigin
FROM orders.TempOrderDetails
ON CONFLICT (CountryName) DO NOTHING;


INSERT INTO Users (username, email, address, phone)
SELECT DISTINCT FullName, Email, Address, Phone
FROM orders.TempOrders
ON CONFLICT (email) DO NOTHING;


INSERT INTO Products (ProductName, CategoryID, BrandID, ManufacturerID, Price, AvailabilityStatus)
SELECT DISTINCT 
    tod.ProductName,
    cat.CategoryID,
    b.BrandID,
    m.ManufacturerID,
    tod.Price,
    tod.AvailabilityStatus
FROM orders.TempOrderDetails tod
JOIN Categories cat ON tod.Сategory = cat.CategoryName
JOIN Brands b ON tod.Brand = b.BrandName
JOIN Manufacturers m ON tod.Manufacturer = m.ManufacturerName
ON CONFLICT (ProductName, CategoryID, BrandID, ManufacturerID) DO NOTHING;


INSERT INTO Orders (UserID, OrderDate, Status, TotalCost)
SELECT 
    u.UserID,
    o.OrderDate,
    o.Status,
    COALESCE(SUM(tod.Price * tod.Quantity), 0) AS TotalCost
FROM orders.TempOrders o
JOIN Users u ON o.Email = u.email
LEFT JOIN orders.TempOrderDetails tod ON o.OrderID = tod.OrderID
GROUP BY u.UserID, o.OrderDate, o.Status;


INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
SELECT 
    o.OrderID,
    p.ProductID,
    tod.Quantity,
    tod.Price * tod.Quantity AS UnitPrice
FROM orders.TempOrderDetails tod
JOIN Orders o ON tod.OrderID = o.OrderID
JOIN Products p ON tod.ProductName = p.ProductName;


INSERT INTO ProductRatings (ProductID, UserID, Rating)
SELECT 
    p.ProductID,
    u.UserID,
    tpr.Rating
FROM orders.TempProductRatings tpr
JOIN Products p ON tpr.ProductName = p.ProductName
JOIN Users u ON tpr.UserFullName = u.username
WHERE tpr.Rating >= 1 AND tpr.Rating <= 5;


select * from Users;
select * from Categories;
select * from Brands;
select * from Manufacturers;
select * from CountriesOfOrigin;
select * from Products;
select * from Orders;
select * from OrderDetails;
select * from ProductRatings;


