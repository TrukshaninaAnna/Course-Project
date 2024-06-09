-- Создание схемы для хранилища данных
CREATE SCHEMA datawarehouse;


-- Таблица измерений категорий
CREATE TABLE IF NOT EXISTS datawarehouse.DimCategories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL
);

-- Таблица измерений для дат
CREATE TABLE datawarehouse.DimDate (
    DateID SERIAL PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Month INT NOT NULL,
    Day INT NOT NULL,
    Quarter INT NOT NULL,
	CONSTRAINT unique_date UNIQUE (Date)
);

-- Таблица измерений для продуктов
CREATE TABLE datawarehouse.DimProducts (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    CategoryID INT,
    BrandID INT,
    ManufacturerID INT,
    Price NUMERIC(10, 2),
    AvailabilityStatus BOOLEAN,
    FOREIGN KEY (BrandID) REFERENCES datawarehouse.DimBrands(BrandID),
    FOREIGN KEY (CategoryID) REFERENCES datawarehouse.DimCategories(CategoryID),
    FOREIGN KEY (ManufacturerID) REFERENCES datawarehouse.DimManufacturers(ManufacturerID)
);

-- Таблица измерений для пользователей
CREATE TABLE datawarehouse.DimUsers (
    UserID INT PRIMARY KEY,
    Username VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Address VARCHAR(255),
    Phone VARCHAR(20)
);

-- Таблица измерений для производителей
CREATE TABLE datawarehouse.DimManufacturers (
    ManufacturerID INT PRIMARY KEY,
    ManufacturerName VARCHAR(100) NOT NULL,
    CountryID INT
);

-- Таблица измерений для стран
CREATE TABLE datawarehouse.DimCountries (
    CountryID INT PRIMARY KEY,
    CountryName VARCHAR(100) NOT NULL
);

-- Таблица измерений для брендов
CREATE TABLE datawarehouse.DimBrands (
    BrandID INT PRIMARY KEY,
    BrandName VARCHAR(100) NOT NULL
);

-- Таблица фактов для продаж
CREATE TABLE datawarehouse.Sales_Fact (
    SalesID SERIAL PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    UserID INT,
    DateID INT,
    Quantity INT,
    UnitPrice NUMERIC(10, 2),
    TotalCost NUMERIC(10, 2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES datawarehouse.DimProducts(ProductID),
    FOREIGN KEY (UserID) REFERENCES datawarehouse.DimUsers(UserID),
    FOREIGN KEY (DateID) REFERENCES datawarehouse.DimDate(DateID)
);

-- Таблица фактов для связи производителей и стран
CREATE TABLE datawarehouse.ManufacturerCountry_Fact (
    ManufacturerCountryID SERIAL PRIMARY KEY,
    ManufacturerID INT,
    CountryID INT,
    FOREIGN KEY (ManufacturerID) REFERENCES datawarehouse.DimManufacturers(ManufacturerID),
    FOREIGN KEY (CountryID) REFERENCES datawarehouse.DimCountries(CountryID)
);


-- Таблица фактов для рейтингов продуктов
CREATE TABLE datawarehouse.ProductRatings_Fact (
    RatingID SERIAL PRIMARY KEY,
    ProductID INT,
    UserID INT,
    BrandID INT,
    Rating INT,
    FOREIGN KEY (ProductID) REFERENCES datawarehouse.DimProducts(ProductID),
    FOREIGN KEY (UserID) REFERENCES datawarehouse.DimUsers(UserID),
    FOREIGN KEY (BrandID) REFERENCES datawarehouse.DimBrands(BrandID),
    CONSTRAINT chk_rating CHECK (Rating >= 1 AND Rating <= 5)
);


-- Добавление новых столбцов для поддержки SCD Type 2
ALTER TABLE datawarehouse.DimProducts
ADD COLUMN StartDate DATE DEFAULT CURRENT_DATE,
ADD COLUMN EndDate DATE DEFAULT '9999-12-31',
ADD COLUMN IsCurrent BOOLEAN DEFAULT TRUE;

ALTER TABLE datawarehouse.DimProducts
ADD CONSTRAINT unique_product UNIQUE (ProductID, BrandID, CategoryID, ManufacturerID);

-- Обновление существующих записей, устанавливая текущую дату в качестве StartDate
UPDATE datawarehouse.DimProducts
SET StartDate = CURRENT_DATE;

-- Обновление существующих записей, устанавливая EndDate по умолчанию
UPDATE datawarehouse.DimProducts
SET EndDate = '9999-12-31';

-- Процедура обновления DimProducts для поддержки SCD Type 2
CREATE OR REPLACE FUNCTION update_dim_products(
    p_product_id INT,
    p_price NUMERIC(10, 2),
    p_availability_status BOOLEAN
) RETURNS VOID AS $$
BEGIN
    -- Обновление текущих записей, устанавливая EndDate и IsCurrent = FALSE
    UPDATE datawarehouse.DimProducts
    SET EndDate = CURRENT_DATE - INTERVAL '1 day', IsCurrent = FALSE
    WHERE ProductID = p_product_id AND IsCurrent = TRUE;
    
    -- Вставка новой записи
    INSERT INTO datawarehouse.DimProducts (ProductID, ProductName, BrandID, CategoryID, ManufacturerID, Price, AvailabilityStatus, StartDate, EndDate, IsCurrent)
    SELECT ProductID, ProductName, BrandID, CategoryID, ManufacturerID, p_price, p_availability_status, CURRENT_DATE, '9999-12-31', TRUE
    FROM datawarehouse.DimProducts
    WHERE ProductID = p_product_id
    ORDER BY StartDate DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;



