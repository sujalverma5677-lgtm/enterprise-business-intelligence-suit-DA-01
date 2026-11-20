# Enterprise Business Intelligence Suite: Data Dictionary

## 1. Conformed Dimensions

### `dw.Dim_Date`
| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `DateKey` | `INT` | Primary Key | Surrogate key in format `YYYYMMDD` (e.g. 20261107) |
| `FullDate` | `DATE` | Candidate Key | Standard calendar date (`YYYY-MM-DD`) |
| `CalendarYear` | `SMALLINT` | Attribute | Calendar Year (e.g. 2025, 2026) |
| `CalendarQuarter` | `TINYINT` | Attribute | Quarter number (1-4) |
| `CalendarQuarterName` | `NVARCHAR(10)` | Attribute | Format 'Q1', 'Q2', 'Q3', 'Q4' |
| `CalendarYearMonth` | `NVARCHAR(10)` | Attribute | Format 'YYYY-MM' (e.g. '2026-11') |
| `FiscalYear` | `SMALLINT` | Attribute | Fiscal year beginning April 1 |
| `IsCurrentYTD` | `BIT` | Flag | 1 if date falls within current Year-to-Date window |

### `dw.Dim_Geography`
| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `GeographyKey` | `INT` | Primary Key | Auto-incrementing surrogate key |
| `GeographyID` | `NVARCHAR(30)` | Business Key | Natural key (e.g. 'GEO-US-NY') |
| `GlobalRegion` | `NVARCHAR(50)` | Attribute | Macro region: 'Americas', 'EMEA', 'APAC' |
| `OperatingRegion` | `NVARCHAR(50)` | Security Attribute | 'North America', 'LATAM', 'Western Europe', 'APAC North', 'APAC South' |
| `Country` | `NVARCHAR(50)` | Attribute | Country name |
| `CountryCode` | `CHAR(3)` | Attribute | ISO 3-letter country code (USA, GBR, DEU, JPN) |
| `City` | `NVARCHAR(50)` | Attribute | Primary metropolitan hub |
| `RegionalDirectorEmail`| `NVARCHAR(100)`| Security Attribute | Email address of the regional director |

### `dw.Dim_Product`
| Column Name | Data Type | Key Type | Description |
| :--- | :--- | :--- | :--- |
| `ProductKey` | `INT` | Primary Key | Surrogate product key |
| `ProductSKU` | `NVARCHAR(30)` | Business Key | Unique SKU identifier (e.g. 'PRD-SRV-001') |
| `ProductName` | `NVARCHAR(100)`| Attribute | Commercial product name |
| `ProductCategory` | `NVARCHAR(50)` | Hierarchy L1 | 'Hardware', 'Software & Cloud', 'IoT & Smart Edge' |
| `ProductSubcategory`| `NVARCHAR(50)` | Hierarchy L2 | 'Servers', 'Networking', 'Cybersecurity', 'AI & Analytics' |
| `StandardUnitCost` | `DECIMAL(18,4)`| Numeric | Standard baseline cost in USD |
| `ListUnitPrice` | `DECIMAL(18,4)`| Numeric | Official global list price in USD |
| `TargetMarginPct` | `DECIMAL(5,2)` | Computed | `((ListUnitPrice - StandardUnitCost) / ListUnitPrice) * 100` |

---

## 2. Fact Tables

### `dw.Fact_Sales`
| Column Name | Data Type | Key Type | Description / Calculation |
| :--- | :--- | :--- | :--- |
| `SalesOrderKey` | `BIGINT` | Primary Key | Unique line-item surrogate key |
| `OrderNumber` | `NVARCHAR(30)` | Business Key | Sales order header identifier (e.g. 'SO-2026-000102') |
| `OrderDateKey` | `INT` | Foreign Key | References `dw.Dim_Date(DateKey)` |
| `CustomerKey` | `INT` | Foreign Key | References `dw.Dim_Customer(CustomerKey)` |
| `ProductKey` | `INT` | Foreign Key | References `dw.Dim_Product(ProductKey)` |
| `GeographyKey` | `INT` | Foreign Key | References `dw.Dim_Geography(GeographyKey)` |
| `QuantitySold` | `INT` | Additive Measure | Number of units purchased |
| `GrossRevenueUSD` | `DECIMAL(18,4)`| Additive Measure | `QuantitySold * UnitPriceUSD` |
| `DiscountAmountUSD`| `DECIMAL(18,4)`| Additive Measure | Promotional discount applied |
| `NetRevenueUSD` | `DECIMAL(18,4)`| Additive Measure | `GrossRevenueUSD - DiscountAmountUSD` |
| `TotalCostUSD` | `DECIMAL(18,4)`| Additive Measure | `QuantitySold * UnitCostUSD` |
| `GrossMarginUSD` | `DECIMAL(18,4)`| Additive Measure | `NetRevenueUSD - TotalCostUSD` |

### `dw.Fact_FinancialLedger`
| Column Name | Data Type | Key Type | Description / Calculation |
| :--- | :--- | :--- | :--- |
| `LedgerEntryKey` | `BIGINT` | Primary Key | Unique general ledger row key |
| `DateKey` | `INT` | Foreign Key | References `dw.Dim_Date(DateKey)` |
| `GeographyKey` | `INT` | Foreign Key | References `dw.Dim_Geography(GeographyKey)` |
| `DepartmentKey` | `INT` | Foreign Key | References `dw.Dim_Department(DepartmentKey)` |
| `AccountCategory` | `NVARCHAR(40)` | Attribute | 'Revenue', 'Cost of Goods Sold', 'OPEX', 'CAPEX' |
| `ActualAmountUSD` | `DECIMAL(18,2)`| Additive Measure | Realized transaction amount |
| `BudgetAmountUSD` | `DECIMAL(18,2)`| Additive Measure | Planned financial budget allocation |
| `VarianceUSD` | `DECIMAL(18,2)`| Additive Measure | `ActualAmountUSD - BudgetAmountUSD` |

### `dw.Fact_SupplyChainInventory`
| Column Name | Data Type | Key Type | Description / Calculation |
| :--- | :--- | :--- | :--- |
| `InventorySnapshotKey`| `BIGINT` | Primary Key | Monthly warehouse SKU snapshot key |
| `SnapshotDateKey` | `INT` | Foreign Key | References `dw.Dim_Date(DateKey)` |
| `WarehouseKey` | `INT` | Foreign Key | References `dw.Dim_Warehouse(WarehouseKey)` |
| `ProductKey` | `INT` | Foreign Key | References `dw.Dim_Product(ProductKey)` |
| `UnitsOnHand` | `INT` | Semi-Additive | Physical inventory on shelves |
| `UnitsReserved` | `INT` | Semi-Additive | Allocated for unfulfilled customer orders |
| `AvailableToPromise`| `INT` | Semi-Additive | `UnitsOnHand - UnitsReserved` |
| `SafetyStockThreshold`| `INT` | Attribute | Minimum buffer required to prevent stockouts |
| `OTIFDeliveryRatePct`| `DECIMAL(5,2)`| Numeric | On-Time In-Full supplier fulfillment percentage |

### `dw.Fact_HRMonthlySnapshot`
| Column Name | Data Type | Key Type | Description / Calculation |
| :--- | :--- | :--- | :--- |
| `SnapshotKey` | `BIGINT` | Primary Key | Monthly worker snapshot key |
| `DateKey` | `INT` | Foreign Key | References `dw.Dim_Date(DateKey)` |
| `EmployeeKey` | `INT` | Foreign Key | References `dw.Dim_Employee(EmployeeKey)` |
| `MonthlyBaseSalaryUSD`| `DECIMAL(12,2)`| Semi-Additive | Monthly base salary (confidential RLS protected) |
| `IsActiveHeadcount`| `BIT` | Semi-Additive | 1 if actively employed at snapshot date |
| `IsTerminated` | `BIT` | Additive Measure | 1 if employee departed during the calendar month |
| `FlightRiskScore` | `DECIMAL(3,2)` | Non-Additive | Predictive probability of resignation (0.00 - 1.00) |
