-- ==============================================================================
-- Enterprise Business Intelligence Suite (Multi-Region)
-- Script 01: Core Schemas and Star Schema Table DDL
-- Supported Database: Microsoft SQL Server 2019/2022 / Azure SQL Database
-- ==============================================================================

-- 1. Drop fact tables (the ones holding the foreign keys) first
DROP TABLE IF EXISTS dw.Fact_Inventory;
DROP TABLE IF EXISTS dw.Fact_Sales;
-- add any other Fact_* tables here

-- 2. Then drop the dimensions
DROP TABLE IF EXISTS dw.Dim_Date;
DROP TABLE IF EXISTS dw.Dim_Geography;
DROP TABLE IF EXISTS dw.Dim_Product;
DROP TABLE IF EXISTS dw.Dim_Customer;
DROP TABLE IF EXISTS dw.Dim_Department;
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'EnterpriseDW')
BEGIN
    CREATE DATABASE EnterpriseDW;
END
GO

USE EnterpriseDW;
GO

-- 1. Create Logical Schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dw') EXEC('CREATE SCHEMA dw');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'sec') EXEC('CREATE SCHEMA sec');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'audit') EXEC('CREATE SCHEMA audit');
GO

-- 2. Audit Logging Table
DROP TABLE IF EXISTS audit.PipelineExecutionLog;
CREATE TABLE audit.PipelineExecutionLog (
    ExecutionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PipelineName NVARCHAR(100) NOT NULL,
    SourceSystem NVARCHAR(50) NOT NULL,
    TargetTable NVARCHAR(100) NOT NULL,
    RecordsRead INT NULL,
    RecordsInserted INT NULL,
    RecordsUpdated INT NULL,
    Status NVARCHAR(20) NOT NULL,
    StartTime DATETIME2(3) NOT NULL,
    EndTime DATETIME2(3) NULL,
    ErrorMessage NVARCHAR(MAX) NULL
);
GO

-- ==============================================================================
-- 3. Dimension Tables (Conformed Enterprise Dimensions)
-- ==============================================================================

-- Dim_Date
DROP TABLE IF EXISTS dw.Dim_Date;
CREATE TABLE dw.Dim_Date (
    DateKey INT PRIMARY KEY, -- Format: YYYYMMDD
    FullDate DATE NOT NULL,
    DayNumberOfWeek TINYINT NOT NULL,
    DayNameOfWeek NVARCHAR(15) NOT NULL,
    DayNumberOfMonth TINYINT NOT NULL,
    DayNumberOfYear SMALLINT NOT NULL,
    WeekNumberOfYear TINYINT NOT NULL,
    MonthName NVARCHAR(15) NOT NULL,
    MonthNumberOfYear TINYINT NOT NULL,
    CalendarQuarter TINYINT NOT NULL,
    CalendarQuarterName NVARCHAR(10) NOT NULL, -- e.g. 'Q1'
    CalendarYear SMALLINT NOT NULL,
    CalendarYearMonth NVARCHAR(10) NOT NULL, -- e.g. '2026-01'
    CalendarYearQuarter NVARCHAR(10) NOT NULL, -- e.g. '2026-Q1'
    FiscalYear SMALLINT NOT NULL,
    FiscalQuarter TINYINT NOT NULL,
    FiscalMonth TINYINT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL,
    IsCurrentMonth BIT NOT NULL,
    IsPriorMonth BIT NOT NULL,
    IsCurrentYTD BIT NOT NULL,
    IsPriorYTD BIT NOT NULL
);
CREATE NONCLUSTERED INDEX IX_Dim_Date_FullDate ON dw.Dim_Date(FullDate);
CREATE NONCLUSTERED INDEX IX_Dim_Date_YearMonth ON dw.Dim_Date(CalendarYearMonth);
GO

-- Dim_Geography (Central to Multi-Region RLS Architecture)
DROP TABLE IF EXISTS dw.Dim_Geography;
CREATE TABLE dw.Dim_Geography (
    GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
    GeographyID NVARCHAR(30) NOT NULL,
    GlobalRegion NVARCHAR(50) NOT NULL,      -- Americas, EMEA, APAC
    OperatingRegion NVARCHAR(50) NOT NULL,   -- North America, LATAM, Western Europe, Central/Eastern Europe, APAC North, APAC South
    SubRegion NVARCHAR(50) NOT NULL,
    Country NVARCHAR(50) NOT NULL,
    CountryCode CHAR(3) NOT NULL,
    StateProvince NVARCHAR(50) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    PostalCode NVARCHAR(20) NULL,
    RegionalDirectorEmail NVARCHAR(100) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1
);
CREATE UNIQUE NONCLUSTERED INDEX UQ_Dim_Geography_Code ON dw.Dim_Geography(GeographyID);
CREATE NONCLUSTERED INDEX IX_Dim_Geography_Region ON dw.Dim_Geography(OperatingRegion, GlobalRegion);
GO

-- Dim_Product
DROP TABLE IF EXISTS dw.Dim_Product;
CREATE TABLE dw.Dim_Product (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductSKU NVARCHAR(30) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    ProductCategory NVARCHAR(50) NOT NULL,
    ProductSubcategory NVARCHAR(50) NOT NULL,
    Brand NVARCHAR(50) NOT NULL,
    Color NVARCHAR(20) NULL,
    StandardUnitCost DECIMAL(18,4) NOT NULL,
    ListUnitPrice DECIMAL(18,4) NOT NULL,
    TargetMarginPct AS CAST(((ListUnitPrice - StandardUnitCost) / NULLIF(ListUnitPrice, 0)) * 100 AS DECIMAL(5,2)),
    ProductStatus NVARCHAR(20) NOT NULL DEFAULT 'Active',
    EffectiveStartDate DATE NOT NULL,
    EffectiveEndDate DATE NULL,
    IsCurrent BIT NOT NULL DEFAULT 1
);
CREATE UNIQUE NONCLUSTERED INDEX UQ_Dim_Product_SKU ON dw.Dim_Product(ProductSKU);
GO

-- Dim_Customer
DROP TABLE IF EXISTS dw.Dim_Customer;
CREATE TABLE dw.Dim_Customer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID NVARCHAR(30) NOT NULL,
    CustomerName NVARCHAR(100) NOT NULL,
    CustomerType NVARCHAR(30) NOT NULL, -- Enterprise, Mid-Market, SMB, Government
    IndustrySegment NVARCHAR(50) NOT NULL,
    CreditTier NVARCHAR(20) NOT NULL,
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    AccountManagerEmail NVARCHAR(100) NOT NULL,
    FirstOrderDate DATE NULL,
    IsActive BIT NOT NULL DEFAULT 1
);
CREATE NONCLUSTERED INDEX IX_Dim_Customer_Geo ON dw.Dim_Customer(GeographyKey);
GO

-- Dim_Department
DROP TABLE IF EXISTS dw.Dim_Department;
CREATE TABLE dw.Dim_Department (
    DepartmentKey INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentCode NVARCHAR(20) NOT NULL,
    DepartmentName NVARCHAR(50) NOT NULL,
    BusinessUnit NVARCHAR(50) NOT NULL,
    CostCenterCode NVARCHAR(20) NOT NULL,
    DepartmentHead NVARCHAR(100) NOT NULL
);
GO

-- Dim_Employee (HR Dimension)
DROP TABLE IF EXISTS dw.Dim_Employee;
CREATE TABLE dw.Dim_Employee (
    EmployeeKey INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID NVARCHAR(30) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    WorkEmail NVARCHAR(100) NOT NULL,
    JobTitle NVARCHAR(50) NOT NULL,
    JobRoleLevel NVARCHAR(20) NOT NULL, -- Associate, Specialist, Lead, Manager, Director, VP
    DepartmentKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Department(DepartmentKey),
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    HireDate DATE NOT NULL,
    TerminationDate DATE NULL,
    EmploymentStatus NVARCHAR(20) NOT NULL, -- Active, Terminated, On-Leave
    AnnualBaseSalaryUSD DECIMAL(18,2) NOT NULL,
    TargetBonusPct DECIMAL(5,2) NOT NULL,
    PerformanceRating TINYINT NOT NULL -- 1 to 5 scale
);
CREATE NONCLUSTERED INDEX IX_Dim_Employee_Geo ON dw.Dim_Employee(GeographyKey);
GO

-- Dim_Warehouse
DROP TABLE IF EXISTS dw.Dim_Warehouse;
CREATE TABLE dw.Dim_Warehouse (
    WarehouseKey INT IDENTITY(1,1) PRIMARY KEY,
    WarehouseCode NVARCHAR(20) NOT NULL,
    WarehouseName NVARCHAR(80) NOT NULL,
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    StorageCapacitySqFt INT NOT NULL,
    WarehouseType NVARCHAR(30) NOT NULL -- Regional Hub, Local Distribution, Air Freight Gateway
);
GO

-- ==============================================================================
-- 4. Dynamic Row-Level Security Bridge Table
-- ==============================================================================
DROP TABLE IF EXISTS sec.UserSecurityBridge;
CREATE TABLE sec.UserSecurityBridge (
    SecurityMappingID INT IDENTITY(1,1) PRIMARY KEY,
    UserPrincipalName NVARCHAR(100) NOT NULL, -- Power BI Service UPN / Azure AD login
    DisplayName NVARCHAR(100) NOT NULL,
    RoleTitle NVARCHAR(50) NOT NULL,
    GlobalRegion NVARCHAR(50) NOT NULL,       -- 'ALL' or specific region: 'Americas', 'EMEA', 'APAC'
    OperatingRegion NVARCHAR(50) NOT NULL,    -- 'ALL' or specific region: 'North America', 'LATAM', 'Western Europe', etc.
    AllowHRConfidential BIT NOT NULL DEFAULT 0,
    AllowFinancialExecutive BIT NOT NULL DEFAULT 0
);
CREATE NONCLUSTERED INDEX IX_Sec_UPN ON sec.UserSecurityBridge(UserPrincipalName);
GO

-- ==============================================================================
-- 5. Fact Tables
-- ==============================================================================

-- Fact_Sales
DROP TABLE IF EXISTS dw.Fact_Sales;
CREATE TABLE dw.Fact_Sales (
    SalesOrderKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(30) NOT NULL,
    OrderLineNumber INT NOT NULL,
    OrderDateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    ShipDateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    CustomerKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Customer(CustomerKey),
    ProductKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Product(ProductKey),
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    SalesChannel NVARCHAR(30) NOT NULL, -- Direct B2B, Partner Reseller, Online Portal
    CurrencyCode CHAR(3) NOT NULL,
    ExchangeRateToUSD DECIMAL(12,6) NOT NULL,
    QuantitySold INT NOT NULL,
    UnitCostUSD DECIMAL(18,4) NOT NULL,
    UnitPriceUSD DECIMAL(18,4) NOT NULL,
    GrossRevenueUSD DECIMAL(18,4) NOT NULL,
    DiscountAmountUSD DECIMAL(18,4) NOT NULL,
    NetRevenueUSD DECIMAL(18,4) NOT NULL,
    TotalCostUSD DECIMAL(18,4) NOT NULL,
    GrossMarginUSD AS CAST(NetRevenueUSD - TotalCostUSD AS DECIMAL(18,4)) PERSISTED,
    TaxAmountUSD DECIMAL(18,4) NOT NULL,
    FreightAmountUSD DECIMAL(18,4) NOT NULL
);
CREATE NONCLUSTERED INDEX IX_Fact_Sales_OrderDate ON dw.Fact_Sales(OrderDateKey);
CREATE NONCLUSTERED INDEX IX_Fact_Sales_Geo ON dw.Fact_Sales(GeographyKey);
CREATE NONCLUSTERED INDEX IX_Fact_Sales_Cust ON dw.Fact_Sales(CustomerKey);
CREATE NONCLUSTERED INDEX IX_Fact_Sales_Prod ON dw.Fact_Sales(ProductKey);
GO

-- Fact_FinancialLedger
DROP TABLE IF EXISTS dw.Fact_FinancialLedger;
CREATE TABLE dw.Fact_FinancialLedger (
    LedgerEntryKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    DepartmentKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Department(DepartmentKey),
    AccountCategory NVARCHAR(40) NOT NULL, -- Revenue, Cost of Goods Sold, OPEX, CAPEX, Tax
    AccountSubCategory NVARCHAR(60) NOT NULL, -- Payroll, Marketing, Logistics, Software Licenses, Depreciation
    Scenario NVARCHAR(20) NOT NULL, -- Actual, Budget, Forecast
    ActualAmountUSD DECIMAL(18,2) NOT NULL,
    BudgetAmountUSD DECIMAL(18,2) NOT NULL,
    VarianceUSD AS CAST(ActualAmountUSD - BudgetAmountUSD AS DECIMAL(18,2)) PERSISTED,
    JournalBatchID NVARCHAR(40) NOT NULL
);
CREATE NONCLUSTERED INDEX IX_Fact_Finance_Date ON dw.Fact_FinancialLedger(DateKey);
CREATE NONCLUSTERED INDEX IX_Fact_Finance_Geo ON dw.Fact_FinancialLedger(GeographyKey);
CREATE NONCLUSTERED INDEX IX_Fact_Finance_Dept ON dw.Fact_FinancialLedger(DepartmentKey);
GO

-- Fact_SupplyChainInventory
DROP TABLE IF EXISTS dw.Fact_SupplyChainInventory;
CREATE TABLE dw.Fact_SupplyChainInventory (
    InventorySnapshotKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    SnapshotDateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    WarehouseKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Warehouse(WarehouseKey),
    ProductKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Product(ProductKey),
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    UnitsOnHand INT NOT NULL,
    UnitsInTransit INT NOT NULL,
    UnitsReserved INT NOT NULL,
    AvailableToPromise  AS (UnitsOnHand - UnitsReserved) PERSISTED,
    SafetyStockThreshold INT NOT NULL,
    InventoryCarryingValueUSD DECIMAL(18,2) NOT NULL,
    StockoutRiskFlag AS (CASE WHEN (UnitsOnHand - UnitsReserved) <= SafetyStockThreshold THEN 1 ELSE 0 END) PERSISTED,
    DaysOfSupply DECIMAL(8,2) NOT NULL,
    LeadTimeDays INT NOT NULL,
    OTIFDeliveryRatePct DECIMAL(5,2) NOT NULL -- On-Time In-Full metric (0-100)
);
CREATE NONCLUSTERED INDEX IX_Fact_Inventory_Date ON dw.Fact_SupplyChainInventory(SnapshotDateKey);
CREATE NONCLUSTERED INDEX IX_Fact_Inventory_Warehouse ON dw.Fact_SupplyChainInventory(WarehouseKey);
CREATE NONCLUSTERED INDEX IX_Fact_Inventory_Geo ON dw.Fact_SupplyChainInventory(GeographyKey);
GO

-- Fact_HRMonthlySnapshot
DROP TABLE IF EXISTS dw.Fact_HRMonthlySnapshot;
CREATE TABLE dw.Fact_HRMonthlySnapshot (
    SnapshotKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Date(DateKey),
    EmployeeKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Employee(EmployeeKey),
    GeographyKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Geography(GeographyKey),
    DepartmentKey INT NOT NULL FOREIGN KEY REFERENCES dw.Dim_Department(DepartmentKey),
    MonthlyBaseSalaryUSD DECIMAL(12,2) NOT NULL,
    OvertimeHours DECIMAL(6,2) NOT NULL,
    OvertimeCostUSD DECIMAL(12,2) NOT NULL,
    IsActiveHeadcount BIT NOT NULL,
    IsNewHire BIT NOT NULL,
    IsTerminated BIT NOT NULL,
    TerminationType NVARCHAR(30) NULL, -- Voluntary, Involuntary, Retirement, None
    TenureInMonths INT NOT NULL,
    FlightRiskScore DECIMAL(3,2) NOT NULL -- Predictive attrition indicator 0.00 to 1.00
);
CREATE NONCLUSTERED INDEX IX_Fact_HR_Date ON dw.Fact_HRMonthlySnapshot(DateKey);
CREATE NONCLUSTERED INDEX IX_Fact_HR_Employee ON dw.Fact_HRMonthlySnapshot(EmployeeKey);
CREATE NONCLUSTERED INDEX IX_Fact_HR_Geo ON dw.Fact_HRMonthlySnapshot(GeographyKey);
GO
