-- ==============================================================================
-- Enterprise Business Intelligence Suite (Multi-Region)
-- Script 04: Production Data Quality, Reconciliation & RLS Security Test Suite
-- ==============================================================================

USE EnterpriseDW;
GO

SET NOCOUNT ON;
PRINT '======================================================';
PRINT 'STARTING AUTOMATED TEST SUITE: ENTERPRISE DW VALIDATION';
PRINT '======================================================';

DECLARE @TotalTests INT = 0;
DECLARE @PassedTests INT = 0;
DECLARE @FailedTests INT = 0;

-- ------------------------------------------------------------------------------
-- TEST 1: Referential Integrity - Fact_Sales Foreign Keys
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
IF EXISTS (
    SELECT 1 FROM dw.Fact_Sales s
    LEFT JOIN dw.Dim_Date d ON s.OrderDateKey = d.DateKey
    LEFT JOIN dw.Dim_Customer c ON s.CustomerKey = c.CustomerKey
    LEFT JOIN dw.Dim_Product p ON s.ProductKey = p.ProductKey
    LEFT JOIN dw.Dim_Geography g ON s.GeographyKey = g.GeographyKey
    WHERE d.DateKey IS NULL OR c.CustomerKey IS NULL OR p.ProductKey IS NULL OR g.GeographyKey IS NULL
)
BEGIN
    PRINT '[FAIL] Test 1: Fact_Sales contains orphan foreign keys!';
    SET @FailedTests += 1;
END
ELSE
BEGIN
    PRINT '[PASS] Test 1: Fact_Sales referential integrity 100% verified.';
    SET @PassedTests += 1;
END

-- ------------------------------------------------------------------------------
-- TEST 2: Mathematical Revenue Integrity in Fact_Sales
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
IF EXISTS (
    SELECT 1 FROM dw.Fact_Sales 
    WHERE ABS(NetRevenueUSD - (GrossRevenueUSD - DiscountAmountUSD)) > 0.01
)
BEGIN
    PRINT '[FAIL] Test 2: NetRevenueUSD calculation mismatch detected!';
    SET @FailedTests += 1;
END
ELSE
BEGIN
    PRINT '[PASS] Test 2: Sales revenue arithmetic (Gross - Discount = Net) is 100% accurate.';
    SET @PassedTests += 1;
END

-- ------------------------------------------------------------------------------
-- TEST 3: Referential Integrity - Fact_FinancialLedger
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
IF EXISTS (
    SELECT 1 FROM dw.Fact_FinancialLedger f
    LEFT JOIN dw.Dim_Date d ON f.DateKey = d.DateKey
    LEFT JOIN dw.Dim_Geography g ON f.GeographyKey = g.GeographyKey
    LEFT JOIN dw.Dim_Department dept ON f.DepartmentKey = dept.DepartmentKey
    WHERE d.DateKey IS NULL OR g.GeographyKey IS NULL OR dept.DepartmentKey IS NULL
)
BEGIN
    PRINT '[FAIL] Test 3: Fact_FinancialLedger contains orphan keys!';
    SET @FailedTests += 1;
END
ELSE
BEGIN
    PRINT '[PASS] Test 3: Financial Ledger foreign keys verified.';
    SET @PassedTests += 1;
END

-- ------------------------------------------------------------------------------
-- TEST 4: Supply Chain Inventory Consistency
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
IF EXISTS (
    SELECT 1 FROM dw.Fact_SupplyChainInventory
    WHERE AvailableToPromise <> (UnitsOnHand - UnitsReserved)
       OR UnitsOnHand < 0
       OR OTIFDeliveryRatePct < 0 OR OTIFDeliveryRatePct > 100
)
BEGIN
    PRINT '[FAIL] Test 4: Inventory sanity check failed (negative units or invalid OTIF)!';
    SET @FailedTests += 1;
END
ELSE
BEGIN
    PRINT '[PASS] Test 4: Inventory available-to-promise and OTIF bounds verified.';
    SET @PassedTests += 1;
END

-- ------------------------------------------------------------------------------
-- TEST 5: HR Monthly Headcount & Flight Risk Sanity
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
IF EXISTS (
    SELECT 1 FROM dw.Fact_HRMonthlySnapshot
    WHERE FlightRiskScore < 0.0 OR FlightRiskScore > 1.0
       OR MonthlyBaseSalaryUSD <= 0
)
BEGIN
    PRINT '[FAIL] Test 5: HR metrics out of valid domain range!';
    SET @FailedTests += 1;
END
ELSE
BEGIN
    PRINT '[PASS] Test 5: HR salary positivity and flight risk probability bounds verified.';
    SET @PassedTests += 1;
END

-- ------------------------------------------------------------------------------
-- TEST 6: Row Level Security (RLS) Isolation Verification
-- Asserting that 'director.na@enterprisegroup.com' can ONLY see North American data
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
IF EXISTS (
    SELECT 1 FROM sec.vw_UserSecurityFilter
    WHERE UserPrincipalName = 'director.na@enterprisegroup.com'
      AND OperatingRegion <> 'North America'
)
BEGIN
    PRINT '[FAIL] Test 6: RLS breach! North America director has cross-region data leakage!';
    SET @FailedTests += 1;
END
ELSE
BEGIN
    PRINT '[PASS] Test 6: RLS isolation strictly enforced. NA Director isolated to North America.';
    SET @PassedTests += 1;
END

-- ------------------------------------------------------------------------------
-- TEST 7: Global Executive Full Visibility Test
-- ------------------------------------------------------------------------------
SET @TotalTests += 1;
DECLARE @TotalRegions INT = (SELECT COUNT(DISTINCT OperatingRegion) FROM dw.Dim_Geography);
DECLARE @ExecRegions INT = (
    SELECT COUNT(DISTINCT OperatingRegion) 
    FROM sec.vw_UserSecurityFilter 
    WHERE UserPrincipalName = 'exec.global@enterprisegroup.com'
);

IF @ExecRegions = @TotalRegions
BEGIN
    PRINT '[PASS] Test 7: Global Executive has complete 360-degree visibility across all regions.';
    SET @PassedTests += 1;
END
ELSE
BEGIN
    PRINT '[FAIL] Test 7: Global Executive view is missing one or more operating regions!';
    SET @FailedTests += 1;
END

-- ------------------------------------------------------------------------------
-- SUMMARY REPORT
-- ------------------------------------------------------------------------------
PRINT '------------------------------------------------------';
PRINT 'TEST EXECUTION SUMMARY:';
PRINT 'Total Tests Run : ' + CAST(@TotalTests AS NVARCHAR(10));
PRINT 'Passed Tests    : ' + CAST(@PassedTests AS NVARCHAR(10));
PRINT 'Failed Tests    : ' + CAST(@FailedTests AS NVARCHAR(10));
PRINT 'Accuracy Rate   : ' + CAST((@PassedTests * 100.0 / @TotalTests) AS NVARCHAR(10)) + '%';
PRINT '======================================================';
GO
