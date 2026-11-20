/*
 ==============================================================================
 Enterprise Business Intelligence Suite (Multi-Region)
 Power Query (M Code) Transformation Library: Conformed Facts
 ==============================================================================
*/

// Fact_Sales Query (M Code)
let
    Source = Sql.Database(#"ServerName", #"DatabaseName"),
    dw_Fact_Sales = Source{[Schema="dw",Item="Fact_Sales"]}[Data],
    #"Removed Negative Outliers" = Table.SelectRows(dw_Fact_Sales, each [QuantitySold] > 0 and [NetRevenueUSD] >= 0),
    #"Added Order Size Bucket" = Table.AddColumn(#"Removed Negative Outliers", "OrderValueTier", each 
        if [NetRevenueUSD] >= 50000 then "Tier 1: Enterprise (>= $50k)"
        else if [NetRevenueUSD] >= 10000 then "Tier 2: Mid-Tier ($10k-$50k)"
        else "Tier 3: Standard (< $10k)", type text),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Order Size Bucket",{
        {"SalesOrderKey", Int64.Type},
        {"OrderNumber", type text},
        {"OrderLineNumber", Int32.Type},
        {"OrderDateKey", Int32.Type},
        {"ShipDateKey", Int32.Type},
        {"CustomerKey", Int64.Type},
        {"ProductKey", Int64.Type},
        {"GeographyKey", Int64.Type},
        {"SalesChannel", type text},
        {"CurrencyCode", type text},
        {"ExchangeRateToUSD", type number},
        {"QuantitySold", Int32.Type},
        {"UnitCostUSD", Currency.Type},
        {"UnitPriceUSD", Currency.Type},
        {"GrossRevenueUSD", Currency.Type},
        {"DiscountAmountUSD", Currency.Type},
        {"NetRevenueUSD", Currency.Type},
        {"TotalCostUSD", Currency.Type},
        {"GrossMarginUSD", Currency.Type},
        {"TaxAmountUSD", Currency.Type},
        {"FreightAmountUSD", Currency.Type}
    })
in
    #"Changed Type"

// Fact_FinancialLedger Query (M Code)
let
    Source = Sql.Database(#"ServerName", #"DatabaseName"),
    dw_Fact_FinancialLedger = Source{[Schema="dw",Item="Fact_FinancialLedger"]}[Data],
    #"Added Variance % Column" = Table.AddColumn(dw_Fact_FinancialLedger, "BudgetVariancePct", each 
        if [BudgetAmountUSD] <> 0 then ([ActualAmountUSD] - [BudgetAmountUSD]) / [BudgetAmountUSD] else 0, Percentage.Type),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Variance % Column",{
        {"LedgerEntryKey", Int64.Type},
        {"DateKey", Int32.Type},
        {"GeographyKey", Int64.Type},
        {"DepartmentKey", Int64.Type},
        {"AccountCategory", type text},
        {"AccountSubCategory", type text},
        {"Scenario", type text},
        {"ActualAmountUSD", Currency.Type},
        {"BudgetAmountUSD", Currency.Type},
        {"VarianceUSD", Currency.Type},
        {"JournalBatchID", type text}
    })
in
    #"Changed Type"

// Fact_SupplyChainInventory Query (M Code)
let
    Source = Sql.Database(#"ServerName", #"DatabaseName"),
    dw_Fact_SupplyChainInventory = Source{[Schema="dw",Item="Fact_SupplyChainInventory"]}[Data],
    #"Added Health Status Flag" = Table.AddColumn(dw_Fact_SupplyChainInventory, "StockStatus", each 
        if [AvailableToPromise] <= 0 then "Stockout"
        else if [AvailableToPromise] <= [SafetyStockThreshold] then "Low Safety Stock"
        else "Healthy", type text),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Health Status Flag",{
        {"InventorySnapshotKey", Int64.Type},
        {"SnapshotDateKey", Int32.Type},
        {"WarehouseKey", Int64.Type},
        {"ProductKey", Int64.Type},
        {"GeographyKey", Int64.Type},
        {"UnitsOnHand", Int32.Type},
        {"UnitsInTransit", Int32.Type},
        {"UnitsReserved", Int32.Type},
        {"AvailableToPromise", Int32.Type},
        {"SafetyStockThreshold", Int32.Type},
        {"InventoryCarryingValueUSD", Currency.Type},
        {"StockoutRiskFlag", Int32.Type},
        {"DaysOfSupply", type number},
        {"LeadTimeDays", Int32.Type},
        {"OTIFDeliveryRatePct", Percentage.Type}
    })
in
    #"Changed Type"
