-- ==============================================================================
-- Enterprise Business Intelligence Suite (Multi-Region)
-- Script 03: Production Seed Data Generator
-- Generates realistic dates, geographics, products, customers, employees,
-- security bridge records, and synchronized multi-domain facts.
-- ==============================================================================

USE EnterpriseDW;
GO

SET NOCOUNT ON;

-- 1. Seed Dim_Date (2025-01-01 through 2026-12-31)
PRINT 'Populating Dim_Date...';
TRUNCATE TABLE dw.Dim_Date;

DECLARE @StartDate DATE = '2025-01-01';
DECLARE @EndDate DATE = '2026-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dw.Dim_Date (
        DateKey, FullDate, DayNumberOfWeek, DayNameOfWeek,
        DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear,
        MonthName, MonthNumberOfYear, CalendarQuarter,
        CalendarQuarterName, CalendarYear, CalendarYearMonth,
        CalendarYearQuarter, FiscalYear, FiscalQuarter, FiscalMonth,
        IsWeekend, IsHoliday, IsCurrentMonth, IsPriorMonth,
        IsCurrentYTD, IsPriorYTD
    )
    SELECT 
        YEAR(@StartDate) * 10000 + MONTH(@StartDate) * 100 + DAY(@StartDate) AS DateKey,
        @StartDate AS FullDate,
        DATEPART(WEEKDAY, @StartDate) AS DayNumberOfWeek,
        DATENAME(WEEKDAY, @StartDate) AS DayNameOfWeek,
        DAY(@StartDate) AS DayNumberOfMonth,
        DATEPART(DAYOFYEAR, @StartDate) AS DayNumberOfYear,
        DATEPART(ISO_WEEK, @StartDate) AS WeekNumberOfYear,
        DATENAME(MONTH, @StartDate) AS MonthName,
        MONTH(@StartDate) AS MonthNumberOfYear,
        DATEPART(QUARTER, @StartDate) AS CalendarQuarter,
        'Q' + CAST(DATEPART(QUARTER, @StartDate) AS NVARCHAR(2)) AS CalendarQuarterName,
        YEAR(@StartDate) AS CalendarYear,
        FORMAT(@StartDate, 'yyyy-MM') AS CalendarYearMonth,
        CAST(YEAR(@StartDate) AS NVARCHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, @StartDate) AS NVARCHAR(2)) AS CalendarYearQuarter,
        CASE WHEN MONTH(@StartDate) >= 4 THEN YEAR(@StartDate) ELSE YEAR(@StartDate) - 1 END AS FiscalYear,
        CASE 
            WHEN MONTH(@StartDate) BETWEEN 4 AND 6 THEN 1
            WHEN MONTH(@StartDate) BETWEEN 7 AND 9 THEN 2
            WHEN MONTH(@StartDate) BETWEEN 10 AND 12 THEN 3
            ELSE 4 
        END AS FiscalQuarter,
        CASE 
            WHEN MONTH(@StartDate) >= 4 THEN MONTH(@StartDate) - 3
            ELSE MONTH(@StartDate) + 9
        END AS FiscalMonth,
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
        0 AS IsHoliday,
        CASE WHEN YEAR(@StartDate) = 2026 AND MONTH(@StartDate) = 11 THEN 1 ELSE 0 END AS IsCurrentMonth,
        CASE WHEN YEAR(@StartDate) = 2026 AND MONTH(@StartDate) = 10 THEN 1 ELSE 0 END AS IsPriorMonth,
        CASE WHEN YEAR(@StartDate) = 2026 AND @StartDate <= '2026-11-07' THEN 1 ELSE 0 END AS IsCurrentYTD,
        CASE WHEN YEAR(@StartDate) = 2025 AND @StartDate <= '2025-11-07' THEN 1 ELSE 0 END AS IsPriorYTD;

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
GO

-- 2. Seed Dim_Geography
PRINT 'Populating Dim_Geography...';
SET IDENTITY_INSERT dw.Dim_Geography ON;
INSERT INTO dw.Dim_Geography (
    GeographyKey, GeographyID, GlobalRegion, OperatingRegion, SubRegion, 
    Country, CountryCode, StateProvince, City, PostalCode, RegionalDirectorEmail, CurrencyCode
) VALUES 
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
SET IDENTITY_INSERT dw.Dim_Geography OFF;
GO

-- 3. Seed Dim_Product
PRINT 'Populating Dim_Product...';
SET IDENTITY_INSERT dw.Dim_Product ON;
INSERT INTO dw.Dim_Product (
    ProductKey, ProductSKU, ProductName, ProductCategory, ProductSubcategory, Brand, Color, StandardUnitCost, ListUnitPrice, EffectiveStartDate
) VALUES 
(1, 'PRD-SRV-001', 'Enterprise Server Rack Titan 4U', 'Hardware', 'Servers', 'TitanCompute', 'Matte Black', 3200.00, 5800.00, '2025-01-01'),
(2, 'PRD-SRV-002', 'Edge Appliance Micro-Compute X', 'Hardware', 'Servers', 'TitanCompute', 'Silver', 850.00, 1550.00, '2025-01-01'),
(3, 'PRD-NET-001', '100Gbps Core Optical Switch 48P', 'Hardware', 'Networking', 'NexusFlow', 'Navy Blue', 4100.00, 7200.00, '2025-01-01'),
(4, 'PRD-NET-002', 'Secure SD-WAN Gateway Pro', 'Hardware', 'Networking', 'NexusFlow', 'Black', 620.00, 1200.00, '2025-01-01'),
(5, 'PRD-SFT-001', 'Cloud CyberSentinel Defense Suite', 'Software & Cloud', 'Cybersecurity', 'OmniShield', 'N/A', 150.00, 480.00, '2025-01-01'),
(6, 'PRD-SFT-002', 'AI Workflow Orchestrator Enterprise', 'Software & Cloud', 'AI & Analytics', 'OmniShield', 'N/A', 220.00, 650.00, '2025-01-01'),
(7, 'PRD-SFT-003', 'Unified Compliance & Audit Platform', 'Software & Cloud', 'Governance', 'OmniShield', 'N/A', 180.00, 520.00, '2025-01-01'),
(8, 'PRD-IOT-001', 'Industrial Telemetry Sensor Hub v2', 'IoT & Smart Edge', 'Industrial Sensors', 'PulseGrid', 'Yellow', 110.00, 290.00, '2025-01-01'),
(9, 'PRD-IOT-002', 'Environmental Monitor Beacon IP67', 'IoT & Smart Edge', 'Industrial Sensors', 'PulseGrid', 'Grey', 75.00, 195.00, '2025-01-01');
SET IDENTITY_INSERT dw.Dim_Product OFF;
GO

-- 4. Seed Dim_Customer
PRINT 'Populating Dim_Customer...';
SET IDENTITY_INSERT dw.Dim_Customer ON;
INSERT INTO dw.Dim_Customer (
    CustomerKey, CustomerID, CustomerName, CustomerType, IndustrySegment, CreditTier, GeographyKey, AccountManagerEmail
) VALUES 
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
SET IDENTITY_INSERT dw.Dim_Customer OFF;
GO

-- 5. Seed Dim_Department
PRINT 'Populating Dim_Department...';
SET IDENTITY_INSERT dw.Dim_Department ON;
INSERT INTO dw.Dim_Department (
    DepartmentKey, DepartmentCode, DepartmentName, BusinessUnit, CostCenterCode, DepartmentHead
) VALUES 
(1, 'DEPT-SLS', 'Commercial Sales & Business Dev', 'Go-To-Market', 'CC-1010', 'Evelyn Reed'),
(2, 'DEPT-ENG', 'Product Engineering & Cloud R&D', 'Technology', 'CC-2020', 'Marcus Chen'),
(3, 'DEPT-OPS', 'Global Supply Chain & Logistics', 'Operations', 'CC-3030', 'Elena Rostova'),
(4, 'DEPT-FIN', 'Corporate Finance & Treasury', 'G&A', 'CC-4040', 'Arthur Pendelton'),
(5, 'DEPT-HR', 'People, Culture & Talent Acquisition', 'G&A', 'CC-5050', 'Sophia Alvarez');
SET IDENTITY_INSERT dw.Dim_Department OFF;
GO

-- 6. Seed Dim_Warehouse
PRINT 'Populating Dim_Warehouse...';
SET IDENTITY_INSERT dw.Dim_Warehouse ON;
INSERT INTO dw.Dim_Warehouse (
    WarehouseKey, WarehouseCode, WarehouseName, GeographyKey, StorageCapacitySqFt, WarehouseType
) VALUES 
(1, 'WH-US-01', 'North America Central Logistics Hub - Chicago', 1, 450000, 'Regional Hub'),
(2, 'WH-EU-01', 'EMEA Super-Hub - Rotterdam & Frankfurt', 5, 520000, 'Regional Hub'),
(3, 'WH-AP-01', 'APAC Gateway Hub - Singapore Changi', 8, 380000, 'Regional Hub'),
(4, 'WH-LA-01', 'LATAM Distribution Center - Sao Paulo', 10, 220000, 'Local Distribution');
SET IDENTITY_INSERT dw.Dim_Warehouse OFF;
GO

-- 7. Seed Dim_Employee
PRINT 'Populating Dim_Employee...';
SET IDENTITY_INSERT dw.Dim_Employee ON;
INSERT INTO dw.Dim_Employee (
    EmployeeKey, EmployeeID, FullName, WorkEmail, JobTitle, JobRoleLevel, DepartmentKey, GeographyKey, HireDate, TerminationDate, EmploymentStatus, AnnualBaseSalaryUSD, TargetBonusPct, PerformanceRating
) VALUES 
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
SET IDENTITY_INSERT dw.Dim_Employee OFF;
GO

-- 8. Seed sec.UserSecurityBridge (Dynamic RLS Mappings)
PRINT 'Populating sec.UserSecurityBridge...';
TRUNCATE TABLE sec.UserSecurityBridge;

INSERT INTO sec.UserSecurityBridge (
    UserPrincipalName, DisplayName, RoleTitle, GlobalRegion, OperatingRegion, AllowHRConfidential, AllowFinancialExecutive
) VALUES 
('exec.global@enterprisegroup.com', 'Victoria Sterling (CEO)', 'Global Executive', 'ALL', 'ALL', 1, 1),
('director.na@enterprisegroup.com', 'David Miller (NA VP)', 'Regional Director NA', 'Americas', 'North America', 0, 1),
('director.emea@enterprisegroup.com', 'Julian Richter (EMEA VP)', 'Regional Director EMEA', 'EMEA', 'Western Europe', 0, 1),
('director.apac@enterprisegroup.com', 'Kenji Takahashi (APAC VP)', 'Regional Director APAC', 'APAC', 'ALL', 0, 1),
('director.latam@enterprisegroup.com', 'Mariana Silva (LATAM VP)', 'Regional Director LATAM', 'Americas', 'LATAM', 0, 1),
('hr.lead@enterprisegroup.com', 'Patricia Gomez (CHRO)', 'HR Confidential Director', 'ALL', 'ALL', 1, 0);
GO

-- 9. Seed Fact_Sales (Multi-Region Transactions with Realistic Volume)
PRINT 'Generating Fact_Sales...';
TRUNCATE TABLE dw.Fact_Sales;

WITH MonthDates AS (
    SELECT DateKey, FullDate 
    FROM dw.Dim_Date 
    WHERE DayNumberOfMonth IN (5, 12, 18, 25, 28)
),
SalesOrders AS (
    SELECT 
        d.DateKey AS OrderDateKey,
        d.DateKey + 3 AS ShipDateKey,
        c.CustomerKey,
        p.ProductKey,
        c.GeographyKey,
        CASE (p.ProductKey % 3)
            WHEN 0 THEN 'Direct B2B'
            WHEN 1 THEN 'Partner Reseller'
            ELSE 'Online Portal'
        END AS SalesChannel,
        'USD' AS CurrencyCode,
        1.000000 AS ExchangeRateToUSD,
        (p.ProductKey * 3) + ((DAY(d.FullDate) % 5) + 1) * 2 AS QuantitySold,
        p.StandardUnitCost,
        p.ListUnitPrice,
        CAST(p.ListUnitPrice * ((p.ProductKey * 3) + ((DAY(d.FullDate) % 5) + 1) * 2) AS DECIMAL(18,4)) AS GrossRevenueUSD,
        CAST(p.ListUnitPrice * ((p.ProductKey * 3) + ((DAY(d.FullDate) % 5) + 1) * 2) * 
            CASE WHEN c.CreditTier = 'Platinum' THEN 0.08 ELSE 0.03 END AS DECIMAL(18,4)) AS DiscountAmountUSD,
        CAST(p.StandardUnitCost * ((p.ProductKey * 3) + ((DAY(d.FullDate) % 5) + 1) * 2) AS DECIMAL(18,4)) AS TotalCostUSD,
        CAST(120.00 * (p.ProductKey + 1) AS DECIMAL(18,4)) AS FreightAmountUSD,
        CAST(p.ListUnitPrice * 0.075 AS DECIMAL(18,4)) AS TaxAmountUSD
    FROM MonthDates d
    CROSS JOIN dw.Dim_Customer c
    CROSS JOIN dw.Dim_Product p
    WHERE (c.CustomerKey + p.ProductKey + DAY(d.FullDate)) % 2 = 0
)
INSERT INTO dw.Fact_Sales (
    OrderNumber, OrderLineNumber, OrderDateKey, ShipDateKey, CustomerKey, ProductKey, GeographyKey,
    SalesChannel, CurrencyCode, ExchangeRateToUSD, QuantitySold, UnitCostUSD, UnitPriceUSD,
    GrossRevenueUSD, DiscountAmountUSD, NetRevenueUSD, TotalCostUSD, TaxAmountUSD, FreightAmountUSD
)
SELECT 
    'SO-202' + CAST(YEAR(d.FullDate) AS NVARCHAR(4)) + '-' + RIGHT('00000' + CAST(ROW_NUMBER() OVER(ORDER BY OrderDateKey, CustomerKey, ProductKey) AS NVARCHAR(6)), 6),
    (ProductKey % 4) + 1 AS OrderLineNumber,
    OrderDateKey,
    ShipDateKey,
    CustomerKey,
    ProductKey,
    GeographyKey,
    SalesChannel,
    CurrencyCode,
    ExchangeRateToUSD,
    QuantitySold,
    StandardUnitCost,
    ListUnitPrice,
    GrossRevenueUSD,
    DiscountAmountUSD,
    GrossRevenueUSD - DiscountAmountUSD AS NetRevenueUSD,
    TotalCostUSD,
    TaxAmountUSD,
    FreightAmountUSD
FROM SalesOrders
INNER JOIN dw.Dim_Date d ON SalesOrders.OrderDateKey = d.DateKey;
GO

-- 10. Seed Fact_FinancialLedger
PRINT 'Generating Fact_FinancialLedger...';
TRUNCATE TABLE dw.Fact_FinancialLedger;

DECLARE @YearMonthList TABLE (DateKey INT, YM NVARCHAR(10));
INSERT INTO @YearMonthList
SELECT MIN(DateKey), CalendarYearMonth
FROM dw.Dim_Date
GROUP BY CalendarYearMonth;

INSERT INTO dw.Fact_FinancialLedger (
    DateKey, GeographyKey, DepartmentKey, AccountCategory, AccountSubCategory, Scenario, ActualAmountUSD, BudgetAmountUSD, JournalBatchID
)
SELECT 
    ym.DateKey,
    g.GeographyKey,
    dept.DepartmentKey,
    cats.AccountCategory,
    cats.AccountSubCategory,
    'Actual' AS Scenario,
    cats.BaseAmount * (1.0 + (g.GeographyKey * 0.05) + (CASE WHEN RIGHT(ym.YM, 2) IN ('03','06','09','12') THEN 0.15 ELSE 0.0 END)) AS ActualAmountUSD,
    cats.BaseAmount * 1.02 AS BudgetAmountUSD,
    'GL-BATCH-' + REPLACE(ym.YM, '-', '') + '-' + CAST(g.GeographyKey AS NVARCHAR(3))
FROM @YearMonthList ym
CROSS JOIN dw.Dim_Geography g
CROSS JOIN dw.Dim_Department dept
CROSS JOIN (
    VALUES 
    ('Revenue', 'Product Sales & Subscriptions', 125000.00),
    ('Cost of Goods Sold', 'Direct Production & Cloud Hosting', 45000.00),
    ('OPEX', 'Payroll & Compensations', 38000.00),
    ('OPEX', 'Marketing & Demand Gen', 14000.00),
    ('OPEX', 'Logistics & Warehousing Freight', 11000.00),
    ('CAPEX', 'Data Center Hardware & R&D', 18000.00)
) cats (AccountCategory, AccountSubCategory, BaseAmount)
WHERE (g.GeographyKey + dept.DepartmentKey) % 2 = 0;
GO

-- 11. Seed Fact_SupplyChainInventory
PRINT 'Generating Fact_SupplyChainInventory...';
TRUNCATE TABLE dw.Fact_SupplyChainInventory;

WITH MonthSnapshots AS (
    SELECT MAX(DateKey) AS SnapshotDateKey, CalendarYearMonth
    FROM dw.Dim_Date
    GROUP BY CalendarYearMonth
)
INSERT INTO dw.Fact_SupplyChainInventory (
    SnapshotDateKey, WarehouseKey, ProductKey, GeographyKey,
    UnitsOnHand, UnitsInTransit, UnitsReserved, SafetyStockThreshold,
    InventoryCarryingValueUSD, DaysOfSupply, LeadTimeDays, OTIFDeliveryRatePct
)
SELECT 
    m.SnapshotDateKey,
    w.WarehouseKey,
    p.ProductKey,
    w.GeographyKey,
    (150 + (p.ProductKey * 40) - (w.WarehouseKey * 15)) AS UnitsOnHand,
    (30 + (p.ProductKey * 8)) AS UnitsInTransit,
    (25 + (p.ProductKey * 5)) AS UnitsReserved,
    50 AS SafetyStockThreshold,
    CAST((150 + (p.ProductKey * 40) - (w.WarehouseKey * 15)) * p.StandardUnitCost AS DECIMAL(18,2)) AS InventoryCarryingValueUSD,
    CAST(32.5 + (p.ProductKey % 5) * 4 AS DECIMAL(8,2)) AS DaysOfSupply,
    14 + (w.WarehouseKey * 2) AS LeadTimeDays,
    CAST(92.50 + ((p.ProductKey + w.WarehouseKey) % 7) AS DECIMAL(5,2)) AS OTIFDeliveryRatePct
FROM MonthSnapshots m
CROSS JOIN dw.Dim_Warehouse w
CROSS JOIN dw.Dim_Product p;
GO

-- 12. Seed Fact_HRMonthlySnapshot
PRINT 'Generating Fact_HRMonthlySnapshot...';
TRUNCATE TABLE dw.Fact_HRMonthlySnapshot;

WITH MonthEndDates AS (
    SELECT MAX(DateKey) AS DateKey, CalendarYearMonth
    FROM dw.Dim_Date
    GROUP BY CalendarYearMonth
)
INSERT INTO dw.Fact_HRMonthlySnapshot (
    DateKey, EmployeeKey, GeographyKey, DepartmentKey,
    MonthlyBaseSalaryUSD, OvertimeHours, OvertimeCostUSD,
    IsActiveHeadcount, IsNewHire, IsTerminated, TerminationType,
    TenureInMonths, FlightRiskScore
)
SELECT 
    m.DateKey,
    e.EmployeeKey,
    e.GeographyKey,
    e.DepartmentKey,
    CAST(e.AnnualBaseSalaryUSD / 12.0 AS DECIMAL(12,2)) AS MonthlyBaseSalaryUSD,
    CAST(CASE WHEN e.JobRoleLevel = 'Associate' THEN 8.5 ELSE 0.0 END AS DECIMAL(6,2)) AS OvertimeHours,
    CAST(CASE WHEN e.JobRoleLevel = 'Associate' THEN (e.AnnualBaseSalaryUSD / (12.0 * 160)) * 1.5 * 8.5 ELSE 0.0 END AS DECIMAL(12,2)) AS OvertimeCostUSD,
    CASE WHEN e.EmploymentStatus = 'Active' OR (e.EmploymentStatus = 'Terminated' AND m.DateKey < 20260701) THEN 1 ELSE 0 END AS IsActiveHeadcount,
    CASE WHEN YEAR(e.HireDate) = 2023 AND m.DateKey = 20250131 THEN 1 ELSE 0 END AS IsNewHire,
    CASE WHEN e.EmploymentStatus = 'Terminated' AND m.DateKey = 20260630 THEN 1 ELSE 0 END AS IsTerminated,
    CASE WHEN e.EmploymentStatus = 'Terminated' THEN 'Voluntary' ELSE 'None' END AS TerminationType,
    DATEDIFF(MONTH, e.HireDate, d.FullDate) AS TenureInMonths,
    CAST(CASE WHEN e.PerformanceRating <= 2 THEN 0.78 WHEN e.PerformanceRating = 3 THEN 0.35 ELSE 0.12 END AS DECIMAL(3,2)) AS FlightRiskScore
FROM MonthEndDates m
INNER JOIN dw.Dim_Date d ON m.DateKey = d.DateKey
CROSS JOIN dw.Dim_Employee e;
GO

PRINT 'Enterprise Data Seeding Completed Successfully.';
GO
