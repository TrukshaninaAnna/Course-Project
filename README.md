# Course-Project

Data Warehouse Project for Medical Equipment Store
1. Overview of the Main Operational Table
The primary operational table stores detailed information about orders placed in the online medical equipment store. This table is crucial for the day-to-day operations of the store and contains various data points necessary for processing orders, tracking products, and maintaining customer information.

Main Table: Orders
Columns:
OrderID: A unique identifier for each order.
UserID: The identifier for the user placing the order (links to the Users table).
OrderDate: The date and time the order was placed.
Status: The current status of the order (e.g., shipped, pending).
TotalCost: The total cost of the order.
This table tracks every order made by a user, including the status and total cost. It's crucial for operational reporting and serves as the primary source of data for the Sales_Fact table in the Data Warehouse.
2. Data Warehouse (DWH)
The Data Warehouse is designed to support analytical reporting and querying of historical data related to sales, users, and products. It stores both dimensional and fact data, enabling complex analyses and business intelligence (BI) reports.

Data Warehouse Schema:
The DWH schema consists of dimension and fact tables optimized for efficient data querying and analysis.

Dimension Tables:
DimCategories: Stores product categories (e.g., medical devices, pharmaceuticals).
DimCountries: Contains data on the country of origin for products.
DimBrands: Stores product brand information.
DimManufacturers: Contains details about manufacturers of the products.
DimUsers: Stores user details, such as names and contact information.
DimProducts: Contains product details, including brand, category, and manufacturer information.
DimDate: Stores date information (year, month, day, quarter) for time-based analysis.
Fact Tables:
Sales_Fact: Tracks sales transactions, including quantities sold, unit prices, and total sales per order.
ProductRatings_Fact: Stores product rating data provided by users, with fields for product IDs, user IDs, and rating scores.
SCD (Slowly Changing Dimensions) Implementation:
SCD Type 2 is implemented for the DimProducts table to maintain historical records of product data. This ensures changes in product information (e.g., brand, manufacturer) are tracked over time.
3. ETL Processes (Extract, Transform, Load)
Two key ETL processes were developed to move data from the operational system into the Data Warehouse:

First ETL Process:
Source: CSV files containing raw order, order detail, and product rating data.
Process:
Staging: Data is loaded into temporary staging tables from CSV files (e.g., TempOrders, TempOrderDetails).
Transformation:
Data is cleaned and transformed to match the structure of the dimension and fact tables.
For example, products are categorized, brands are matched, and manufacturers are linked to countries of origin.
Loading:
Dimension tables (DimCategories, DimBrands, DimManufacturers, etc.) are populated with unique values from the staging tables.
Fact tables (Sales_Fact, ProductRatings_Fact) are filled with data about sales and product ratings.
Second ETL Process:
Source: Data from the operational database.
Process:
Transformation:
Data from operational tables (like the Orders table) is transformed into a format suitable for the DWH schema.
Date transformations are applied to ensure correct entries into the DimDate table.
Loading:
Data is inserted into the dimension and fact tables, ensuring accurate linkages between users, products, and orders.
The process updates the Sales_Fact and ProductRatings_Fact tables with new sales and rating data.
Key Transformation Steps:
Inserting unique product categories, brands, and manufacturers into their respective dimension tables.
Calculating and updating the TotalCost for each order in the Sales_Fact table based on individual product prices and quantities.
Ensuring product ratings are within the valid range (1 to 5) before inserting them into the ProductRatings_Fact table.
