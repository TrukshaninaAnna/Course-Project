DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Manufacturers;
DROP TABLE IF EXISTS Brands;
DROP TABLE IF EXISTS Categories;
DROP TABLE IF EXISTS CountriesOfOrigin;
DROP TABLE IF EXISTS ProductRatings;

-- #1 Table for countries
CREATE TABLE CountriesOfOrigin (
    CountryID SERIAL PRIMARY KEY,
    CountryName VARCHAR(100) UNIQUE NOT NULL
);

-- #2 Table for product categories
CREATE TABLE Categories (
    CategoryID SERIAL PRIMARY KEY,
    CategoryName VARCHAR(100) UNIQUE NOT NULL
);

-- #3 Table for brands
CREATE TABLE Brands (
    BrandID SERIAL PRIMARY KEY,
    BrandName VARCHAR(100) UNIQUE NOT NULL
);

-- #4 Table for manufacturers
CREATE TABLE Manufacturers (
    ManufacturerID SERIAL PRIMARY KEY,
    ManufacturerName VARCHAR(100) UNIQUE NOT NULL,
    CountryID INT REFERENCES CountriesOfOrigin(CountryID)
);

-- #5 Table for products
CREATE TABLE Products (
    ProductID SERIAL PRIMARY KEY,
    ProductName VARCHAR(255) UNIQUE NOT NULL,
	CategoryID INT REFERENCES Categories(CategoryID),
    BrandID INT REFERENCES Brands(BrandID),
    ManufacturerID INT REFERENCES Manufacturers(ManufacturerID),
    Price NUMERIC(10, 2) NOT NULL,
    AvailabilityStatus BOOLEAN NOT NULL,
	CONSTRAINT unique_product UNIQUE (ProductName, CategoryID, BrandID, ManufacturerID)
);

-- #6 Table for users
CREATE TABLE Users (
    UserID SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(20)
);

-- #7 Table for orders
CREATE TABLE Orders (
    OrderID SERIAL PRIMARY KEY,
    UserID INT REFERENCES Users(UserID),
    OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(100) NOT NULL,
    TotalCost NUMERIC(10, 2) NOT NULL
);

-- #8 Table for order details
CREATE TABLE OrderDetails (
    OrderDetailID SERIAL PRIMARY KEY,
    OrderID INT REFERENCES Orders(OrderID),
    ProductID INT REFERENCES Products(ProductID),
    Quantity INT NOT NULL,
    UnitPrice NUMERIC(10, 2) NOT NULL
);


-- #9 Table for ratings
CREATE TABLE ProductRatings (
    RatingID SERIAL PRIMARY KEY,
    ProductID INT REFERENCES Products(ProductID),
    UserID INT REFERENCES Users(UserID),
    Rating INT NOT NULL,
    CONSTRAINT chk_rating CHECK (Rating >= 1 AND Rating <= 5)
);

