CREATE SCHEMA datawarehouse;


-- DimCategory table
CREATE TABLE IF NOT EXISTS datawarehouse.DimCategories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL
);

-- DimDate table
CREATE TABLE datawarehouse.DimDate (
    DateID SERIAL PRIMARY KEY,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Month INT NOT NULL,
    Day INT NOT NULL,
    Quarter INT NOT NULL,
	CONSTRAINT unique_date UNIQUE (Date)
);

-- Dimantion Country of Origin table
CREATE TABLE datawarehouse.DimCountries (
    CountryID INT PRIMARY KEY,
    CountryName VARCHAR(100) NOT NULL
);

-- DimManufacturers table
CREATE TABLE datawarehouse.DimManufacturers (
    ManufacturerID INT PRIMARY KEY,
    ManufacturerName VARCHAR(100) NOT NULL,
    CountryID INT,
    FOREIGN KEY (CountryID) REFERENCES datawarehouse.DimCountries(CountryID)
);

-- DimBrands table
CREATE TABLE datawarehouse.DimBrands (
    BrandID INT PRIMARY KEY,
    BrandName VARCHAR(100) NOT NULL
); 

-- DimProducts
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

-- Facts table for sales
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


-- Facts table for rating
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


ALTER TABLE datawarehouse.DimProducts
ADD COLUMN StartDate DATE DEFAULT CURRENT_DATE,
ADD COLUMN EndDate DATE DEFAULT '9999-12-31',
ADD COLUMN IsCurrent BOOLEAN DEFAULT TRUE;
ALTER TABLE datawarehouse.DimProducts
ADD CONSTRAINT unique_product UNIQUE (ProductID, BrandID, CategoryID, ManufacturerID);


--SCD2
CREATE OR REPLACE FUNCTION dim_products_update_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем, изменилось ли одно из значимых полей и установлен ли флаг текущей записи в TRUE
    IF (OLD.ProductName <> NEW.ProductName 
        OR OLD.CategoryID <> NEW.CategoryID 
        OR OLD.BrandID <> NEW.BrandID 
        OR OLD.ManufacturerID <> NEW.ManufacturerID 
        OR OLD.Price <> NEW.Price 
        OR OLD.AvailabilityStatus <> NEW.AvailabilityStatus)
        AND OLD.IsCurrent THEN
        
        -- Обновляем текущую запись, устанавливая дату окончания и флаг текущей записи в FALSE
        UPDATE datawarehouse.DimProducts
        SET EndDate = CURRENT_DATE,
            IsCurrent = FALSE
        WHERE ProductID = OLD.ProductID AND IsCurrent = TRUE;

        -- Вставляем новую запись с новыми значениями и текущей датой в качестве даты начала
        INSERT INTO datawarehouse.DimProducts (ProductID, ProductName, CategoryID, BrandID, ManufacturerID, Price, AvailabilityStatus, StartDate, EndDate, IsCurrent)
        VALUES (OLD.ProductID, NEW.ProductName, NEW.CategoryID, NEW.BrandID, NEW.ManufacturerID, NEW.Price, NEW.AvailabilityStatus, CURRENT_DATE, '9999-12-31', TRUE);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Создаем триггер для таблицы DimProducts, который будет срабатывать после обновления
CREATE TRIGGER dim_products_update
AFTER UPDATE ON datawarehouse.DimProducts
FOR EACH ROW
EXECUTE FUNCTION dim_products_update_trigger();



CREATE VIEW datawarehouse.sales_trend AS
SELECT 
    dd.Date,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimDate dd ON sf.DateID = dd.DateID
GROUP BY dd.Date
ORDER BY dd.Date;


	
	
CREATE VIEW datawarehouse.sales_by_country_of_origin AS
SELECT 
    dc.CountryName,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimProducts dp ON sf.ProductID = dp.ProductID
JOIN datawarehouse.DimManufacturers mcf ON dp.ManufacturerID = mcf.ManufacturerID
JOIN datawarehouse.DimCountries dc ON mcf.CountryID = dc.CountryID
GROUP BY dc.CountryName
ORDER BY TotalSales DESC;


CREATE VIEW datawarehouse.sales_by_category AS
SELECT 
    dcat.CategoryName,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimProducts dp ON sf.ProductID = dp.ProductID
JOIN datawarehouse.DimCategories dcat ON dp.CategoryID = dcat.CategoryID
GROUP BY dcat.CategoryName
ORDER BY TotalSales DESC;


CREATE VIEW datawarehouse.sales_by_brand AS
SELECT 
    db.BrandName,
    SUM(sf.TotalCost) AS TotalSales
FROM datawarehouse.Sales_Fact sf
JOIN datawarehouse.DimProducts dp ON sf.ProductID = dp.ProductID
JOIN datawarehouse.DimBrands db ON dp.BrandID = db.BrandID
GROUP BY db.BrandName
ORDER BY TotalSales DESC;


CREATE VIEW datawarehouse.average_rating_by_product AS
SELECT 
    dp.ProductName,
    AVG(prf.Rating) AS AverageRating
FROM datawarehouse.ProductRatings_Fact prf
JOIN datawarehouse.DimProducts dp ON prf.ProductID = dp.ProductID
GROUP BY dp.ProductName
ORDER BY AverageRating DESC;


CREATE VIEW datawarehouse.average_rating_by_brand AS
SELECT 
    db.BrandName,
    AVG(prf.Rating) AS AverageRating
FROM datawarehouse.ProductRatings_Fact prf
JOIN datawarehouse.DimProducts dp ON prf.ProductID = dp.ProductID
JOIN datawarehouse.DimBrands db ON dp.BrandID = db.BrandID
GROUP BY db.BrandName
ORDER BY AverageRating DESC;


