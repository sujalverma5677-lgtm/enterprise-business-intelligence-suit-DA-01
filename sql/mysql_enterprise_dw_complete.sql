-- ==============================================================================
-- Enterprise Business Intelligence Suite (Multi-Region)
-- Complete MySQL Database Script (DDL + Views + Multi-Region Seed Data)
-- Compatible with: MySQL 8.0+, MariaDB 10.5+, MySQL Workbench, phpMyAdmin
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS EnterpriseDW CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE EnterpriseDW;

-- Disable foreign key checks during batch table creation & seeding
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------------------------
-- 1. Dimensions
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS Dim_Date;
CREATE TABLE Dim_Date (
    DateKey INT PRIMARY KEY, -- Format: YYYYMMDD
    FullDate DATE NOT NULL,
    DayNumberOfWeek TINYINT NOT NULL,
    DayNameOfWeek VARCHAR(15) NOT NULL,
    DayNumberOfMonth TINYINT NOT NULL,
    DayNumberOfYear SMALLINT NOT NULL,
    WeekNumberOfYear TINYINT NOT NULL,
    MonthName VARCHAR(15) NOT NULL,
    MonthNumberOfYear TINYINT NOT NULL,
    CalendarQuarter TINYINT NOT NULL,
    CalendarQuarterName VARCHAR(10) NOT NULL,
    CalendarYear SMALLINT NOT NULL,
    CalendarYearMonth VARCHAR(10) NOT NULL,
    CalendarYearQuarter VARCHAR(10) NOT NULL,
    FiscalYear SMALLINT NOT NULL,
    FiscalQuarter TINYINT NOT NULL,
    FiscalMonth TINYINT NOT NULL,
    IsWeekend TINYINT(1) NOT NULL,
    IsHoliday TINYINT(1) NOT NULL,
    IsCurrentMonth TINYINT(1) NOT NULL,
    IsPriorMonth TINYINT(1) NOT NULL,
    IsCurrentYTD TINYINT(1) NOT NULL,
    IsPriorYTD TINYINT(1) NOT NULL,
    INDEX idx_date_fulldate (FullDate),
    INDEX idx_date_yearmonth (CalendarYearMonth)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Dim_Geography;
CREATE TABLE Dim_Geography (
    GeographyKey INT AUTO_INCREMENT PRIMARY KEY,
    GeographyID VARCHAR(30) NOT NULL UNIQUE,
    GlobalRegion VARCHAR(50) NOT NULL,
    OperatingRegion VARCHAR(50) NOT NULL,
    SubRegion VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    CountryCode CHAR(3) NOT NULL,
    StateProvince VARCHAR(50) NOT NULL,
    City VARCHAR(50) NOT NULL,
    PostalCode VARCHAR(20) NULL,
    RegionalDirectorEmail VARCHAR(100) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL,
    IsActive TINYINT(1) NOT NULL DEFAULT 1,
    INDEX idx_geo_region (OperatingRegion, GlobalRegion)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Dim_Product;
CREATE TABLE Dim_Product (
    ProductKey INT AUTO_INCREMENT PRIMARY KEY,
    ProductSKU VARCHAR(30) NOT NULL UNIQUE,
    ProductName VARCHAR(100) NOT NULL,
    ProductCategory VARCHAR(50) NOT NULL,
    ProductSubcategory VARCHAR(50) NOT NULL,
    Brand VARCHAR(50) NOT NULL,
    Color VARCHAR(20) NULL,
    StandardUnitCost DECIMAL(18,4) NOT NULL,
    ListUnitPrice DECIMAL(18,4) NOT NULL,
    TargetMarginPct DECIMAL(5,2) GENERATED ALWAYS AS (ROUND(((ListUnitPrice - StandardUnitCost) / NULLIF(ListUnitPrice, 0)) * 100, 2)) STORED,
    ProductStatus VARCHAR(20) NOT NULL DEFAULT 'Active',
    EffectiveStartDate DATE NOT NULL,
    EffectiveEndDate DATE NULL,
    IsCurrent TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Dim_Customer;
CREATE TABLE Dim_Customer (
    CustomerKey INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID VARCHAR(30) NOT NULL UNIQUE,
    CustomerName VARCHAR(100) NOT NULL,
    CustomerType VARCHAR(30) NOT NULL,
    IndustrySegment VARCHAR(50) NOT NULL,
    CreditTier VARCHAR(20) NOT NULL,
    GeographyKey INT NOT NULL,
    AccountManagerEmail VARCHAR(100) NOT NULL,
    FirstOrderDate DATE NULL,
    IsActive TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Dim_Department;
CREATE TABLE Dim_Department (
    DepartmentKey INT AUTO_INCREMENT PRIMARY KEY,
    DepartmentCode VARCHAR(20) NOT NULL UNIQUE,
    DepartmentName VARCHAR(50) NOT NULL,
    BusinessUnit VARCHAR(50) NOT NULL,
    CostCenterCode VARCHAR(20) NOT NULL,
    DepartmentHead VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Dim_Employee;
CREATE TABLE Dim_Employee (
    EmployeeKey INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeID VARCHAR(30) NOT NULL UNIQUE,
    FullName VARCHAR(100) NOT NULL,
    WorkEmail VARCHAR(100) NOT NULL,
    JobTitle VARCHAR(50) NOT NULL,
    JobRoleLevel VARCHAR(20) NOT NULL,
    DepartmentKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    HireDate DATE NOT NULL,
    TerminationDate DATE NULL,
    EmploymentStatus VARCHAR(20) NOT NULL,
    AnnualBaseSalaryUSD DECIMAL(18,2) NOT NULL,
    TargetBonusPct DECIMAL(5,2) NOT NULL,
    PerformanceRating TINYINT NOT NULL,
    FOREIGN KEY (DepartmentKey) REFERENCES Dim_Department(DepartmentKey),
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Dim_Warehouse;
CREATE TABLE Dim_Warehouse (
    WarehouseKey INT AUTO_INCREMENT PRIMARY KEY,
    WarehouseCode VARCHAR(20) NOT NULL UNIQUE,
    WarehouseName VARCHAR(80) NOT NULL,
    GeographyKey INT NOT NULL,
    StorageCapacitySqFt INT NOT NULL,
    WarehouseType VARCHAR(30) NOT NULL,
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 2. Row-Level Security Bridge Table
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS UserSecurityBridge;
CREATE TABLE UserSecurityBridge (
    SecurityMappingID INT AUTO_INCREMENT PRIMARY KEY,
    UserPrincipalName VARCHAR(100) NOT NULL,
    DisplayName VARCHAR(100) NOT NULL,
    RoleTitle VARCHAR(50) NOT NULL,
    GlobalRegion VARCHAR(50) NOT NULL,
    OperatingRegion VARCHAR(50) NOT NULL,
    AllowHRConfidential TINYINT(1) NOT NULL DEFAULT 0,
    AllowFinancialExecutive TINYINT(1) NOT NULL DEFAULT 0,
    INDEX idx_sec_upn (UserPrincipalName)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 3. Fact Tables
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS Fact_Sales;
CREATE TABLE Fact_Sales (
    SalesOrderKey BIGINT AUTO_INCREMENT PRIMARY KEY,
    OrderNumber VARCHAR(30) NOT NULL,
    OrderLineNumber INT NOT NULL,
    OrderDateKey INT NOT NULL,
    ShipDateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    SalesChannel VARCHAR(30) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL,
    ExchangeRateToUSD DECIMAL(12,6) NOT NULL,
    QuantitySold INT NOT NULL,
    UnitCostUSD DECIMAL(18,4) NOT NULL,
    UnitPriceUSD DECIMAL(18,4) NOT NULL,
    GrossRevenueUSD DECIMAL(18,4) NOT NULL,
    DiscountAmountUSD DECIMAL(18,4) NOT NULL,
    NetRevenueUSD DECIMAL(18,4) NOT NULL,
    TotalCostUSD DECIMAL(18,4) NOT NULL,
    GrossMarginUSD DECIMAL(18,4) GENERATED ALWAYS AS (ROUND(NetRevenueUSD - TotalCostUSD, 4)) STORED,
    TaxAmountUSD DECIMAL(18,4) NOT NULL,
    FreightAmountUSD DECIMAL(18,4) NOT NULL,
    INDEX idx_sales_date (OrderDateKey),
    INDEX idx_sales_cust (CustomerKey),
    INDEX idx_sales_prod (ProductKey),
    INDEX idx_sales_geo (GeographyKey),
    FOREIGN KEY (OrderDateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (CustomerKey) REFERENCES Dim_Customer(CustomerKey),
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey),
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Fact_FinancialLedger;
CREATE TABLE Fact_FinancialLedger (
    LedgerEntryKey BIGINT AUTO_INCREMENT PRIMARY KEY,
    DateKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    DepartmentKey INT NOT NULL,
    AccountCategory VARCHAR(40) NOT NULL,
    AccountSubCategory VARCHAR(60) NOT NULL,
    Scenario VARCHAR(20) NOT NULL,
    ActualAmountUSD DECIMAL(18,2) NOT NULL,
    BudgetAmountUSD DECIMAL(18,2) NOT NULL,
    VarianceUSD DECIMAL(18,2) GENERATED ALWAYS AS (ROUND(ActualAmountUSD - BudgetAmountUSD, 2)) STORED,
    JournalBatchID VARCHAR(40) NOT NULL,
    INDEX idx_fin_date (DateKey),
    INDEX idx_fin_geo (GeographyKey),
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey),
    FOREIGN KEY (DepartmentKey) REFERENCES Dim_Department(DepartmentKey)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Fact_SupplyChainInventory;
CREATE TABLE Fact_SupplyChainInventory (
    InventorySnapshotKey BIGINT AUTO_INCREMENT PRIMARY KEY,
    SnapshotDateKey INT NOT NULL,
    WarehouseKey INT NOT NULL,
    ProductKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    UnitsOnHand INT NOT NULL,
    UnitsInTransit INT NOT NULL,
    UnitsReserved INT NOT NULL,
    AvailableToPromise INT GENERATED ALWAYS AS (UnitsOnHand - UnitsReserved) STORED,
    SafetyStockThreshold INT NOT NULL,
    InventoryCarryingValueUSD DECIMAL(18,2) NOT NULL,
    StockoutRiskFlag TINYINT(1) GENERATED ALWAYS AS (CASE WHEN (UnitsOnHand - UnitsReserved) <= SafetyStockThreshold THEN 1 ELSE 0 END) STORED,
    DaysOfSupply DECIMAL(8,2) NOT NULL,
    LeadTimeDays INT NOT NULL,
    OTIFDeliveryRatePct DECIMAL(5,2) NOT NULL,
    INDEX idx_inv_date (SnapshotDateKey),
    FOREIGN KEY (SnapshotDateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (WarehouseKey) REFERENCES Dim_Warehouse(WarehouseKey),
    FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey),
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Fact_HRMonthlySnapshot;
CREATE TABLE Fact_HRMonthlySnapshot (
    SnapshotKey BIGINT AUTO_INCREMENT PRIMARY KEY,
    DateKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    GeographyKey INT NOT NULL,
    DepartmentKey INT NOT NULL,
    MonthlyBaseSalaryUSD DECIMAL(12,2) NOT NULL,
    OvertimeHours DECIMAL(6,2) NOT NULL,
    OvertimeCostUSD DECIMAL(12,2) NOT NULL,
    IsActiveHeadcount TINYINT(1) NOT NULL,
    IsNewHire TINYINT(1) NOT NULL,
    IsTerminated TINYINT(1) NOT NULL,
    TerminationType VARCHAR(30) NULL,
    TenureInMonths INT NOT NULL,
    FlightRiskScore DECIMAL(3,2) NOT NULL,
    INDEX idx_hr_date (DateKey),
    FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey),
    FOREIGN KEY (EmployeeKey) REFERENCES Dim_Employee(EmployeeKey),
    FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey),
    FOREIGN KEY (DepartmentKey) REFERENCES Dim_Department(DepartmentKey)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 4. Analytical Views
-- ------------------------------------------------------------------------------

CREATE OR ALTER VIEW vw_PowerBI_SalesAnalysis AS
SELECT 
    s.SalesOrderKey, s.OrderNumber, s.OrderLineNumber, s.OrderDateKey,
    d.FullDate AS OrderDate, d.CalendarYear AS OrderYear, d.CalendarYearMonth AS OrderYearMonth,
    s.CustomerKey, c.CustomerName, c.CustomerType, c.IndustrySegment,
    s.ProductKey, p.ProductName, p.ProductCategory, p.ProductSubcategory,
    s.GeographyKey, g.GlobalRegion, g.OperatingRegion, g.Country,
    s.SalesChannel, s.QuantitySold, s.UnitCostUSD, s.UnitPriceUSD,
    s.GrossRevenueUSD, s.DiscountAmountUSD, s.NetRevenueUSD, s.TotalCostUSD, s.GrossMarginUSD
FROM Fact_Sales s
JOIN Dim_Date d ON s.OrderDateKey = d.DateKey
JOIN Dim_Customer c ON s.CustomerKey = c.CustomerKey
JOIN Dim_Product p ON s.ProductKey = p.ProductKey
JOIN Dim_Geography g ON s.GeographyKey = g.GeographyKey;

-- ------------------------------------------------------------------------------
-- 5. Seeding Dimension Data
-- ------------------------------------------------------------------------------

-- Dim_Geography
INSERT INTO Dim_Geography (GeographyKey, GeographyID, GlobalRegion, OperatingRegion, SubRegion, Country, CountryCode, StateProvince, City, PostalCode, RegionalDirectorEmail, CurrencyCode) VALUES
(1, 'GEO-US-NY', 'Americas', 'North America', 'US East', 'United States', 'USA', 'New York', 'New York', '10001', 'director.na@enterprisegroup.com', 'USD'),
(2, 'GEO-US-CA', 'Americas', 'North America', 'US West', 'United States', 'USA', 'California', 'San Francisco', '94105', 'director.na@enterprisegroup.com', 'USD'),
(3, 'GEO-CA-ON', 'Americas', 'North America', 'Canada East', 'Canada', 'CAN', 'Ontario', 'Toronto', 'M5V 2T6', 'director.na@enterprisegroup.com', 'CAD'),
(4, 'GEO-UK-LON', 'EMEA', 'Western Europe', 'UK & Ireland', 'United Kingdom', 'GBR', 'Greater London', 'London', 'EC2R 8AH', 'director.emea@enterprisegroup.com', 'GBP'),
(5, 'GEO-DE-BER', 'EMEA', 'Western Europe', 'DACH', 'Germany', 'DEU', 'Berlin', 'Berlin', '10115', 'director.emea@enterprisegroup.com', 'EUR'),
(6, 'GEO-FR-PAR', 'EMEA', 'Western Europe', 'France', 'France', 'FRA', 'Ile-de-France', 'Paris', '75008', 'director.emea@enterprisegroup.com', 'EUR'),
(7, 'GEO-JP-TYO', 'APAC', 'APAC North', 'Japan', 'Japan', 'JPN', 'Tokyo', 'Tokyo', '100-0001', 'director.apac@enterprisegroup.com', 'JPY'),
(8, 'GEO-SG-SGP', 'APAC', 'APAC South', 'ASEAN', 'Singapore', 'SGP', 'Central', 'Singapore', '018981', 'director.apac@enterprisegroup.com', 'SGD'),
(9, 'GEO-AU-SYD', 'APAC', 'APAC South', 'ANZ', 'Australia', 'AUS', 'New South Wales', 'Sydney', '2000', 'director.apac@enterprisegroup.com', 'AUD'),
(10, 'GEO-BR-SP', 'Americas', 'LATAM', 'Brazil', 'Brazil', 'BRA', 'Sao Paulo', 'Sao Paulo', '01310-100', 'director.latam@enterprisegroup.com', 'BRL'),
(11, 'GEO-MX-CDMX', 'Americas', 'LATAM', 'Mexico', 'Mexico', 'MEX', 'Distrito Federal', 'Mexico City', '06000', 'director.latam@enterprisegroup.com', 'MXN');

-- Dim_Product
INSERT INTO Dim_Product (ProductKey, ProductSKU, ProductName, ProductCategory, ProductSubcategory, Brand, Color, StandardUnitCost, ListUnitPrice, EffectiveStartDate) VALUES
(1, 'PRD-SRV-001', 'Enterprise Server Rack Titan 4U', 'Hardware', 'Servers', 'TitanCompute', 'Matte Black', 3200.00, 5800.00, '2025-01-01'),
(2, 'PRD-SRV-002', 'Edge Appliance Micro-Compute X', 'Hardware', 'Servers', 'TitanCompute', 'Silver', 850.00, 1550.00, '2025-01-01'),
(3, 'PRD-NET-001', '100Gbps Core Optical Switch 48P', 'Hardware', 'Networking', 'NexusFlow', 'Navy Blue', 4100.00, 7200.00, '2025-01-01'),
(4, 'PRD-NET-002', 'Secure SD-WAN Gateway Pro', 'Hardware', 'Networking', 'NexusFlow', 'Black', 620.00, 1200.00, '2025-01-01'),
(5, 'PRD-SFT-001', 'Cloud CyberSentinel Defense Suite', 'Software & Cloud', 'Cybersecurity', 'OmniShield', 'N/A', 150.00, 480.00, '2025-01-01'),
(6, 'PRD-SFT-002', 'AI Workflow Orchestrator Enterprise', 'Software & Cloud', 'AI & Analytics', 'OmniShield', 'N/A', 220.00, 650.00, '2025-01-01'),
(7, 'PRD-SFT-003', 'Unified Compliance & Audit Platform', 'Software & Cloud', 'Governance', 'OmniShield', 'N/A', 180.00, 520.00, '2025-01-01'),
(8, 'PRD-IOT-001', 'Industrial Telemetry Sensor Hub v2', 'IoT & Smart Edge', 'Industrial Sensors', 'PulseGrid', 'Yellow', 110.00, 290.00, '2025-01-01'),
(9, 'PRD-IOT-002', 'Environmental Monitor Beacon IP67', 'IoT & Smart Edge', 'Industrial Sensors', 'PulseGrid', 'Grey', 75.00, 195.00, '2025-01-01');

-- Dim_Customer
INSERT INTO Dim_Customer (CustomerKey, CustomerID, CustomerName, CustomerType, IndustrySegment, CreditTier, GeographyKey, AccountManagerEmail) VALUES
(1, 'CUST-NA-001', 'GlobalFin Corp', 'Enterprise', 'Financial Services', 'Platinum', 1, 'am.east@enterprisegroup.com'),
(2, 'CUST-NA-002', 'Apex BioTech Dynamics', 'Enterprise', 'Healthcare & Life Sciences', 'Platinum', 2, 'am.west@enterprisegroup.com'),
(3, 'CUST-CA-001', 'Maple Energy Utilities', 'Mid-Market', 'Energy & Utilities', 'Gold', 3, 'am.ca@enterprisegroup.com'),
(4, 'CUST-UK-001', 'Royal Sovereign Asset Mgmt', 'Enterprise', 'Banking & Investments', 'Platinum', 4, 'am.uk@enterprisegroup.com'),
(5, 'CUST-DE-001', 'Bavaria Precision Automotive', 'Enterprise', 'Automotive & Manufacturing', 'Platinum', 5, 'am.de@enterprisegroup.com'),
(6, 'CUST-FR-001', 'Lumiere Retail Global', 'Enterprise', 'Consumer Goods', 'Gold', 6, 'am.fr@enterprisegroup.com'),
(7, 'CUST-JP-001', 'Nippon Robotics & Tech Ltd', 'Enterprise', 'Advanced Electronics', 'Platinum', 7, 'am.jp@enterprisegroup.com'),
(8, 'CUST-SG-001', 'Pacific Rim Trade Solutions', 'Mid-Market', 'Logistics & Trade', 'Gold', 8, 'am.sg@enterprisegroup.com'),
(9, 'CUST-AU-001', 'Southern Cross Logistics', 'Mid-Market', 'Transport & Warehousing', 'Gold', 9, 'am.au@enterprisegroup.com'),
(10, 'CUST-BR-001', 'Amazonia Agribusiness S.A.', 'Enterprise', 'Agriculture & Export', 'Gold', 10, 'am.latam@enterprisegroup.com'),
(11, 'CUST-MX-001', 'Azteca Telecommunications', 'Enterprise', 'Telecom', 'Gold', 11, 'am.latam@enterprisegroup.com');

-- Dim_Department
INSERT INTO Dim_Department (DepartmentKey, DepartmentCode, DepartmentName, BusinessUnit, CostCenterCode, DepartmentHead) VALUES
(1, 'DEPT-SLS', 'Commercial Sales & Business Dev', 'Go-To-Market', 'CC-1010', 'Evelyn Reed'),
(2, 'DEPT-ENG', 'Product Engineering & Cloud R&D', 'Technology', 'CC-2020', 'Marcus Chen'),
(3, 'DEPT-OPS', 'Global Supply Chain & Logistics', 'Operations', 'CC-3030', 'Elena Rostova'),
(4, 'DEPT-FIN', 'Corporate Finance & Treasury', 'G&A', 'CC-4040', 'Arthur Pendelton'),
(5, 'DEPT-HR', 'People, Culture & Talent Acquisition', 'G&A', 'CC-5050', 'Sophia Alvarez');

-- Dim_Warehouse
INSERT INTO Dim_Warehouse (WarehouseKey, WarehouseCode, WarehouseName, GeographyKey, StorageCapacitySqFt, WarehouseType) VALUES
(1, 'WH-US-01', 'North America Central Logistics Hub - Chicago', 1, 450000, 'Regional Hub'),
(2, 'WH-EU-01', 'EMEA Super-Hub - Rotterdam & Frankfurt', 5, 520000, 'Regional Hub'),
(3, 'WH-AP-01', 'APAC Gateway Hub - Singapore Changi', 8, 380000, 'Regional Hub'),
(4, 'WH-LA-01', 'LATAM Distribution Center - Sao Paulo', 10, 220000, 'Local Distribution');

-- Dim_Employee
INSERT INTO Dim_Employee (EmployeeKey, EmployeeID, FullName, WorkEmail, JobTitle, JobRoleLevel, DepartmentKey, GeographyKey, HireDate, TerminationDate, EmploymentStatus, AnnualBaseSalaryUSD, TargetBonusPct, PerformanceRating) VALUES
(1, 'EMP-1001', 'Sarah Jenkins', 'sjenkins@enterprisegroup.com', 'VP Global Sales', 'VP', 1, 1, '2020-03-15', NULL, 'Active', 240000.00, 35.00, 5),
(2, 'EMP-1002', 'David Miller', 'dmiller@enterprisegroup.com', 'Director Sales North America', 'Director', 1, 1, '2021-06-01', NULL, 'Active', 185000.00, 25.00, 4),
(3, 'EMP-1003', 'Julian Richter', 'jrichter@enterprisegroup.com', 'Director Sales EMEA', 'Director', 1, 5, '2021-09-15', NULL, 'Active', 180000.00, 25.00, 4),
(4, 'EMP-1004', 'Kenji Takahashi', 'ktakahashi@enterprisegroup.com', 'Director Sales APAC', 'Director', 1, 7, '2022-01-10', NULL, 'Active', 178000.00, 25.00, 5),
(5, 'EMP-1005', 'Mariana Silva', 'msilva@enterprisegroup.com', 'Director Sales LATAM', 'Director', 1, 10, '2022-04-01', NULL, 'Active', 155000.00, 25.00, 4),
(6, 'EMP-2001', 'Dr. Alex Vance', 'avance@enterprisegroup.com', 'Principal Cloud Architect', 'Lead', 2, 2, '2019-11-01', NULL, 'Active', 215000.00, 20.00, 5),
(7, 'EMP-2002', 'Hannah Weber', 'hweber@enterprisegroup.com', 'Senior AI Engineer', 'Specialist', 2, 5, '2022-08-15', NULL, 'Active', 145000.00, 15.00, 4),
(8, 'EMP-3001', 'Robert Zhang', 'rzhang@enterprisegroup.com', 'Global Supply Chain Director', 'Director', 3, 8, '2020-05-12', NULL, 'Active', 190000.00, 25.00, 4),
(9, 'EMP-4001', 'Claire Fontaine', 'cfontaine@enterprisegroup.com', 'Chief Financial Controller', 'Director', 4, 6, '2018-02-01', NULL, 'Active', 195000.00, 25.00, 5),
(10, 'EMP-5001', 'Patricia Gomez', 'pgomez@enterprisegroup.com', 'VP Human Resources', 'VP', 5, 1, '2019-07-01', NULL, 'Active', 210000.00, 30.00, 5),
(11, 'EMP-1006', 'Liam O''Connor', 'loconnor@enterprisegroup.com', 'Account Executive EMEA', 'Associate', 1, 4, '2023-02-15', '2026-06-30', 'Terminated', 95000.00, 15.00, 2),
(12, 'EMP-3002', 'Carlos Mendoza', 'cmendoza@enterprisegroup.com', 'Logistics Analyst LATAM', 'Associate', 3, 11, '2023-08-01', NULL, 'Active', 68000.00, 10.00, 3);

-- UserSecurityBridge
INSERT INTO UserSecurityBridge (UserPrincipalName, DisplayName, RoleTitle, GlobalRegion, OperatingRegion, AllowHRConfidential, AllowFinancialExecutive) VALUES
('exec.global@enterprisegroup.com', 'Victoria Sterling (CEO)', 'Global Executive', 'ALL', 'ALL', 1, 1),
('director.na@enterprisegroup.com', 'David Miller (NA VP)', 'Regional Director NA', 'Americas', 'North America', 0, 1),
('director.emea@enterprisegroup.com', 'Julian Richter (EMEA VP)', 'Regional Director EMEA', 'EMEA', 'Western Europe', 0, 1),
('director.apac@enterprisegroup.com', 'Kenji Takahashi (APAC VP)', 'Regional Director APAC', 'APAC', 'ALL', 0, 1),
('director.latam@enterprisegroup.com', 'Mariana Silva (LATAM VP)', 'Regional Director LATAM', 'Americas', 'LATAM', 0, 1),
('hr.lead@enterprisegroup.com', 'Patricia Gomez (CHRO)', 'HR Confidential Director', 'ALL', 'ALL', 1, 0);

-- ------------------------------------------------------------------------------
-- 6. Date Dimension Seeder Procedure (2025 to 2026)
-- ------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS PopulateCalendarDates;
DELIMITER $$
CREATE PROCEDURE PopulateCalendarDates()
BEGIN
    DECLARE curDate DATE DEFAULT '2025-01-01';
    DECLARE endDate DATE DEFAULT '2026-12-31';

    WHILE curDate <= endDate DO
        INSERT INTO Dim_Date (
            DateKey, FullDate, DayNumberOfWeek, DayNameOfWeek,
            DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear,
            MonthName, MonthNumberOfYear, CalendarQuarter,
            CalendarQuarterName, CalendarYear, CalendarYearMonth,
            CalendarYearQuarter, FiscalYear, FiscalQuarter, FiscalMonth,
            IsWeekend, IsHoliday, IsCurrentMonth, IsPriorMonth,
            IsCurrentYTD, IsPriorYTD
        ) VALUES (
            YEAR(curDate) * 10000 + MONTH(curDate) * 100 + DAY(curDate),
            curDate,
            DAYOFWEEK(curDate),
            DAYNAME(curDate),
            DAYOFMONTH(curDate),
            DAYOFYEAR(curDate),
            WEEK(curDate, 3),
            MONTHNAME(curDate),
            MONTH(curDate),
            QUARTER(curDate),
            CONCAT('Q', QUARTER(curDate)),
            YEAR(curDate),
            DATE_FORMAT(curDate, '%Y-%m'),
            CONCAT(YEAR(curDate), '-Q', QUARTER(curDate)),
            CASE WHEN MONTH(curDate) >= 4 THEN YEAR(curDate) ELSE YEAR(curDate) - 1 END,
            CASE 
                WHEN MONTH(curDate) BETWEEN 4 AND 6 THEN 1
                WHEN MONTH(curDate) BETWEEN 7 AND 9 THEN 2
                WHEN MONTH(curDate) BETWEEN 10 AND 12 THEN 3
                ELSE 4 
            END,
            CASE WHEN MONTH(curDate) >= 4 THEN MONTH(curDate) - 3 ELSE MONTH(curDate) + 9 END,
            CASE WHEN DAYOFWEEK(curDate) IN (1, 7) THEN 1 ELSE 0 END,
            0,
            CASE WHEN YEAR(curDate) = 2026 AND MONTH(curDate) = 11 THEN 1 ELSE 0 END,
            CASE WHEN YEAR(curDate) = 2026 AND MONTH(curDate) = 10 THEN 1 ELSE 0 END,
            CASE WHEN YEAR(curDate) = 2026 AND curDate <= '2026-11-07' THEN 1 ELSE 0 END,
            CASE WHEN YEAR(curDate) = 2025 AND curDate <= '2025-11-07' THEN 1 ELSE 0 END
        );
        SET curDate = DATE_ADD(curDate, INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

CALL PopulateCalendarDates();
DROP PROCEDURE IF EXISTS PopulateCalendarDates;

-- ------------------------------------------------------------------------------
-- 7. Seed Fact Records
-- ------------------------------------------------------------------------------

-- Seed Fact_Sales
INSERT INTO Fact_Sales (
    OrderNumber, OrderLineNumber, OrderDateKey, ShipDateKey, CustomerKey, ProductKey, GeographyKey,
    SalesChannel, CurrencyCode, ExchangeRateToUSD, QuantitySold, UnitCostUSD, UnitPriceUSD,
    GrossRevenueUSD, DiscountAmountUSD, NetRevenueUSD, TotalCostUSD, TaxAmountUSD, FreightAmountUSD
)
SELECT 
    CONCAT('SO-202', d.CalendarYear, '-', LPAD((c.CustomerKey * 100 + p.ProductKey * 10 + d.DayNumberOfMonth), 6, '0')),
    (p.ProductKey % 4) + 1,
    d.DateKey,
    d.DateKey + 3,
    c.CustomerKey,
    p.ProductKey,
    c.GeographyKey,
    CASE (p.ProductKey % 3) WHEN 0 THEN 'Direct B2B' WHEN 1 THEN 'Partner Reseller' ELSE 'Online Portal' END,
    'USD', 1.0,
    (p.ProductKey * 3) + ((d.DayNumberOfMonth % 5) + 1) * 2,
    p.StandardUnitCost,
    p.ListUnitPrice,
    p.ListUnitPrice * ((p.ProductKey * 3) + ((d.DayNumberOfMonth % 5) + 1) * 2),
    ROUND(p.ListUnitPrice * ((p.ProductKey * 3) + ((d.DayNumberOfMonth % 5) + 1) * 2) * (CASE WHEN c.CreditTier = 'Platinum' THEN 0.08 ELSE 0.03 END), 4),
    ROUND(p.ListUnitPrice * ((p.ProductKey * 3) + ((d.DayNumberOfMonth % 5) + 1) * 2) * (1.0 - (CASE WHEN c.CreditTier = 'Platinum' THEN 0.08 ELSE 0.03 END)), 4),
    p.StandardUnitCost * ((p.ProductKey * 3) + ((d.DayNumberOfMonth % 5) + 1) * 2),
    ROUND(p.ListUnitPrice * 0.075, 4),
    ROUND(120.00 * (p.ProductKey + 1), 4)
FROM Dim_Date d
CROSS JOIN Dim_Customer c
CROSS JOIN Dim_Product p
WHERE d.DayNumberOfMonth IN (5, 12, 18, 25, 28)
  AND (c.CustomerKey + p.ProductKey + d.DayNumberOfMonth) % 2 = 0;

-- Re-enable foreign key constraints
SET FOREIGN_KEY_CHECKS = 1;

-- Verification
SELECT 'Dim_Date' AS TableName, COUNT(*) AS RowCounts FROM Dim_Date
UNION ALL
SELECT 'Dim_Geography', COUNT(*) FROM Dim_Geography
UNION ALL
SELECT 'Dim_Product', COUNT(*) FROM Dim_Product
UNION ALL
SELECT 'Dim_Customer', COUNT(*) FROM Dim_Customer
UNION ALL
SELECT 'Fact_Sales', COUNT(*) FROM Fact_Sales;
