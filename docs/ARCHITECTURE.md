# Enterprise Business Intelligence Suite: Architecture & Design

## 1. Executive Summary
The **Enterprise Business Intelligence Suite** is a unified analytics platform engineered for a multi-national enterprise operating across **Americas (North America & LATAM)**, **EMEA (Western Europe)**, and **APAC (North & South)**. It breaks down enterprise data silos by integrating **Commercial Sales**, **Financial General Ledger**, **Supply Chain Logistics**, and **Human Resources** into a single Kimball-compliant Dimensional Data Warehouse with Row-Level Security (RLS).

---

## 2. High-Level System Architecture

```mermaid
flowchart TD
    subgraph Source_Systems ["Operational Source Systems (OLTP & APIs)"]
        S1["ERP / SAP (Financials & GL)"]
        S2["Salesforce / CRM (Orders & Deals)"]
        S3["WMS / Manhattan (Inventory & Warehouses)"]
        S4["Workday / HRIS (Headcount & Payroll)"]
    end

    subgraph Ingestion_Layer ["Azure Data Factory (ADF) / Scheduled Jobs"]
        ADF1["ADF Pipeline: Incremental CDC Ingestion"]
        ADF2["Metadata Logging & Audit (audit.PipelineExecutionLog)"]
    end

    subgraph Data_Warehouse ["Enterprise Star Schema DW (Azure SQL / SQL Server)"]
        subgraph Staging_Zone ["Schema: stg"]
            STG["Raw Landing & Deduplication"]
        end
        subgraph Core_DW ["Schema: dw (Kimball Star Schema)"]
            D_DATE["Dim_Date"]
            D_GEO["Dim_Geography"]
            D_PROD["Dim_Product"]
            D_CUST["Dim_Customer"]
            D_DEPT["Dim_Department"]
            D_EMP["Dim_Employee"]
            D_WH["Dim_Warehouse"]

            F_SALES["Fact_Sales"]
            F_FIN["Fact_FinancialLedger"]
            F_INV["Fact_SupplyChainInventory"]
            F_HR["Fact_HRMonthlySnapshot"]
        end
        subgraph Security_Zone ["Schema: sec"]
            SEC_BRIDGE["UserSecurityBridge\n(UPN <-> Region Mapping)"]
        end
    end

    subgraph Semantic_Layer ["Power BI Service / Analysis Services"]
        SEM["DirectQuery / Import Composite Semantic Model"]
        RLS_ENGINE["DAX Dynamic Row-Level Security Engine"]
        DAX_LIB["Enterprise DAX Measure Library (YTD, YoY, Margins, OTIF)"]
    end

    subgraph Presentation_Layer ["Executive & Operational Dashboards"]
        P1["Page 1: Executive KPI Command Center"]
        P2["Page 2: Commercial Sales & Margin Analytics"]
        P3["Page 3: Financial & Operational P&L"]
        P4["Page 4: Supply Chain & Warehouse Health"]
        P5["Page 5: People Analytics (HR Confidential)"]
        P6["Page 6: Transaction Drill-Through Detail"]
    end

    Source_Systems --> ADF1
    ADF1 --> ADF2
    ADF1 --> STG
    STG --> Core_DW
    SEC_BRIDGE -.-> RLS_ENGINE
    Core_DW --> SEM
    SEM --> RLS_ENGINE
    RLS_ENGINE --> DAX_LIB
    DAX_LIB --> Presentation_Layer
```

---

## 3. Conformed Star Schema (Entity-Relationship Diagram)

```mermaid
erDiagram
    Dim_Date ||--o{ Fact_Sales : "OrderDateKey"
    Dim_Date ||--o{ Fact_FinancialLedger : "DateKey"
    Dim_Date ||--o{ Fact_SupplyChainInventory : "SnapshotDateKey"
    Dim_Date ||--o{ Fact_HRMonthlySnapshot : "DateKey"

    Dim_Geography ||--o{ Fact_Sales : "GeographyKey"
    Dim_Geography ||--o{ Fact_FinancialLedger : "GeographyKey"
    Dim_Geography ||--o{ Fact_SupplyChainInventory : "GeographyKey"
    Dim_Geography ||--o{ Fact_HRMonthlySnapshot : "GeographyKey"
    Dim_Geography ||--o{ Dim_Customer : "GeographyKey"
    Dim_Geography ||--o{ Dim_Warehouse : "GeographyKey"
    Dim_Geography ||--o{ Dim_Employee : "GeographyKey"
    Dim_Geography }|--|| UserSecurityBridge : "OperatingRegion / GlobalRegion"

    Dim_Product ||--o{ Fact_Sales : "ProductKey"
    Dim_Product ||--o{ Fact_SupplyChainInventory : "ProductKey"

    Dim_Customer ||--o{ Fact_Sales : "CustomerKey"
    Dim_Department ||--o{ Fact_FinancialLedger : "DepartmentKey"
    Dim_Department ||--o{ Fact_HRMonthlySnapshot : "DepartmentKey"

    Dim_Warehouse ||--o{ Fact_SupplyChainInventory : "WarehouseKey"
    Dim_Employee ||--o{ Fact_HRMonthlySnapshot : "EmployeeKey"

    Fact_Sales {
        bigint SalesOrderKey PK
        nvarchar OrderNumber
        int OrderDateKey FK
        int CustomerKey FK
        int ProductKey FK
        int GeographyKey FK
        int QuantitySold
        decimal GrossRevenueUSD
        decimal DiscountAmountUSD
        decimal NetRevenueUSD
        decimal TotalCostUSD
        decimal GrossMarginUSD
    }

    Fact_FinancialLedger {
        bigint LedgerEntryKey PK
        int DateKey FK
        int GeographyKey FK
        int DepartmentKey FK
        nvarchar AccountCategory
        decimal ActualAmountUSD
        decimal BudgetAmountUSD
        decimal VarianceUSD
    }

    Fact_SupplyChainInventory {
        bigint InventorySnapshotKey PK
        int SnapshotDateKey FK
        int WarehouseKey FK
        int ProductKey FK
        int UnitsOnHand
        int AvailableToPromise
        decimal OTIFDeliveryRatePct
    }

    Fact_HRMonthlySnapshot {
        bigint SnapshotKey PK
        int DateKey FK
        int EmployeeKey FK
        decimal MonthlyBaseSalaryUSD
        bit IsActiveHeadcount
        decimal FlightRiskScore
    }
```

---

## 4. Multi-Region Security Architecture (Dynamic RLS)
- **Token Extraction**: When a report loads in Power BI Service or Teams embedded portals, the client security token supplies the user's `USERPRINCIPALNAME()`.
- **Dynamic Lookup**: The model filters `sec.UserSecurityBridge` where `UserPrincipalName = USERPRINCIPALNAME()`.
- **Inherited Filtering**: The resulting set of permissible regions cascades through `dw.Dim_Geography`. Because all fact tables (`Fact_Sales`, `Fact_FinancialLedger`, `Fact_SupplyChainInventory`, `Fact_HRMonthlySnapshot`) maintain foreign keys to `Dim_Geography`, the entire dashboard is instantly partitioned.
- **Fail-Safe Default**: If an unmapped user accesses the workspace, the bridge yields 0 matching rows, resulting in empty visualizations (safe default / zero data leakage).

---

## 5. Performance Optimization Strategy
1. **Star Schema vs Snowflaking**: Kept dimensions denormalized (e.g. Category and Subcategory merged in `Dim_Product`) to eliminate multi-hop joins during query evaluation.
2. **Columnar Storage & Compression**: Integer surrogate keys (`DateKey`, `ProductKey`, `GeographyKey`) maximize VertiPaq dictionary compression in Power BI.
3. **Persisted Computed Columns**: Formula columns like `GrossMarginUSD` and `AvailableToPromise` are computed and persisted in SQL Server to offload runtime CPU load from DAX.
4. **Partitioning**: Fact tables partitioned by Fiscal Year to accelerate rolling window refreshes.
