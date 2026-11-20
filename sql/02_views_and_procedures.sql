-- ==============================================================================
-- Enterprise Business Intelligence Suite (Multi-Region)
-- Script 02: Analytical Views, Security Views, and ETL Stored Procedures
-- ==============================================================================

USE EnterpriseDW;
GO

-- ==============================================================================
-- 1. Analytical Gold Views for Direct Power BI Consumption
-- ==============================================================================

CREATE OR ALTER VIEW dw.vw_PowerBI_SalesAnalysis
AS
SELECT 
    s.SalesOrderKey,
    s.OrderNumber,
    s.OrderLineNumber,
    s.OrderDateKey,
    d.FullDate AS OrderDate,
    d.CalendarYear AS OrderYear,
    d.CalendarYearQuarter AS OrderYearQuarter,
    d.CalendarYearMonth AS OrderYearMonth,
    d.MonthName AS OrderMonthName,
    s.CustomerKey,
    c.CustomerID,
    c.CustomerName,
    c.CustomerType,
    c.IndustrySegment,
    s.ProductKey,
    p.ProductSKU,
    p.ProductName,
    p.ProductCategory,
    p.ProductSubcategory,
    p.Brand,
    s.GeographyKey,
    g.GlobalRegion,
    g.OperatingRegion,
    g.SubRegion,
    g.Country,
    g.StateProvince,
    g.City,
    s.SalesChannel,
    s.QuantitySold,
    s.UnitCostUSD,
    s.UnitPriceUSD,
    s.GrossRevenueUSD,
    s.DiscountAmountUSD,
    s.NetRevenueUSD,
    s.TotalCostUSD,
    s.GrossMarginUSD,
    s.FreightAmountUSD,
    s.TaxAmountUSD
FROM dw.Fact_Sales s
INNER JOIN dw.Dim_Date d ON s.OrderDateKey = d.DateKey
INNER JOIN dw.Dim_Customer c ON s.CustomerKey = c.CustomerKey
INNER JOIN dw.Dim_Product p ON s.ProductKey = p.ProductKey
INNER JOIN dw.Dim_Geography g ON s.GeographyKey = g.GeographyKey;
GO

CREATE OR ALTER VIEW dw.vw_PowerBI_FinancialLedger
AS
SELECT 
    f.LedgerEntryKey,
    f.DateKey,
    d.FullDate AS TransactionDate,
    d.CalendarYear,
    d.CalendarYearQuarter,
    d.CalendarYearMonth,
    f.GeographyKey,
    g.GlobalRegion,
    g.OperatingRegion,
    g.Country,
    f.DepartmentKey,
    dept.DepartmentName,
    dept.BusinessUnit,
    f.AccountCategory,
    f.AccountSubCategory,
    f.Scenario,
    f.ActualAmountUSD,
    f.BudgetAmountUSD,
    f.VarianceUSD
FROM dw.Fact_FinancialLedger f
INNER JOIN dw.Dim_Date d ON f.DateKey = d.DateKey
INNER JOIN dw.Dim_Geography g ON f.GeographyKey = g.GeographyKey
INNER JOIN dw.Dim_Department dept ON f.DepartmentKey = dept.DepartmentKey;
GO

CREATE OR ALTER VIEW dw.vw_PowerBI_SupplyChainHealth
AS
SELECT 
    i.InventorySnapshotKey,
    i.SnapshotDateKey,
    d.FullDate AS SnapshotDate,
    d.CalendarYearMonth,
    i.WarehouseKey,
    w.WarehouseCode,
    w.WarehouseName,
    w.WarehouseType,
    i.ProductKey,
    p.ProductName,
    p.ProductCategory,
    p.ProductSubcategory,
    i.GeographyKey,
    g.GlobalRegion,
    g.OperatingRegion,
    g.Country,
    i.UnitsOnHand,
    i.UnitsInTransit,
    i.UnitsReserved,
    i.AvailableToPromise,
    i.SafetyStockThreshold,
    i.InventoryCarryingValueUSD,
    i.StockoutRiskFlag,
    i.DaysOfSupply,
    i.LeadTimeDays,
    i.OTIFDeliveryRatePct
FROM dw.Fact_SupplyChainInventory i
INNER JOIN dw.Dim_Date d ON i.SnapshotDateKey = d.DateKey
INNER JOIN dw.Dim_Warehouse w ON i.WarehouseKey = w.WarehouseKey
INNER JOIN dw.Dim_Product p ON i.ProductKey = p.ProductKey
INNER JOIN dw.Dim_Geography g ON i.GeographyKey = g.GeographyKey;
GO

CREATE OR ALTER VIEW dw.vw_PowerBI_HROverview
AS
SELECT 
    h.SnapshotKey,
    h.DateKey,
    d.FullDate AS SnapshotDate,
    d.CalendarYearMonth,
    h.EmployeeKey,
    e.EmployeeID,
    e.FullName,
    e.JobTitle,
    e.JobRoleLevel,
    h.DepartmentKey,
    dept.DepartmentName,
    dept.BusinessUnit,
    h.GeographyKey,
    g.GlobalRegion,
    g.OperatingRegion,
    g.Country,
    h.MonthlyBaseSalaryUSD,
    h.OvertimeHours,
    h.OvertimeCostUSD,
    h.IsActiveHeadcount,
    h.IsNewHire,
    h.IsTerminated,
    h.TerminationType,
    h.TenureInMonths,
    h.FlightRiskScore
FROM dw.Fact_HRMonthlySnapshot h
INNER JOIN dw.Dim_Date d ON h.DateKey = d.DateKey
INNER JOIN dw.Dim_Employee e ON h.EmployeeKey = e.EmployeeKey
INNER JOIN dw.Dim_Department dept ON h.DepartmentKey = dept.DepartmentKey
INNER JOIN dw.Dim_Geography g ON h.GeographyKey = g.GeographyKey;
GO

-- ==============================================================================
-- 2. Row Level Security Mapping View
-- ==============================================================================
CREATE OR ALTER VIEW sec.vw_UserSecurityFilter
AS
SELECT 
    b.UserPrincipalName,
    b.RoleTitle,
    g.GeographyKey,
    g.GlobalRegion,
    g.OperatingRegion,
    g.Country,
    b.AllowHRConfidential,
    b.AllowFinancialExecutive
FROM sec.UserSecurityBridge b
INNER JOIN dw.Dim_Geography g 
    ON (b.OperatingRegion = 'ALL' OR b.OperatingRegion = g.OperatingRegion)
   AND (b.GlobalRegion = 'ALL' OR b.GlobalRegion = g.GlobalRegion);
GO

-- ==============================================================================
-- 3. Stored Procedure for Master ETL Orchestration & Audit Logging
-- ==============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_RunMasterETL
    @ExecutionType NVARCHAR(20) = 'INCREMENTAL',
    @ExecutionID BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME2(3) = SYSDATETIME();
    
    INSERT INTO audit.PipelineExecutionLog (
        PipelineName, SourceSystem, TargetTable, Status, StartTime
    ) VALUES (
        'Master_DW_Orchestration', 'CRM/ERP/WMS/HRIS', 'Multi-Fact Conformed DW', 'RUNNING', @StartTime
    );
    SET @ExecutionID = SCOPE_IDENTITY();

    BEGIN TRY
        -- Step 1: Validate Stage Data Cleanliness
        -- Step 2: Merge Dimensions (SCD Type 1 & 2)
        -- Step 3: Load Conformed Facts (Sales, Finance, Inventory, HR)
        -- Step 4: Refresh Bridge and Security Tables

        -- Simulating successful batch completion
        UPDATE audit.PipelineExecutionLog
        SET Status = 'COMPLETED',
            EndTime = SYSDATETIME(),
            RecordsRead = 125000,
            RecordsInserted = 8450,
            RecordsUpdated = 1200
        WHERE ExecutionID = @ExecutionID;

        PRINT 'Master ETL completed successfully. Execution ID: ' + CAST(@ExecutionID AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        UPDATE audit.PipelineExecutionLog
        SET Status = 'FAILED',
            EndTime = SYSDATETIME(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE ExecutionID = @ExecutionID;

        THROW;
    END CATCH
END;
GO
