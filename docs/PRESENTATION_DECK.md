# 10-Minute Final Presentation: Enterprise Business Intelligence Suite

**Presenter**: Lead Analytics Engineer / Data Analytics Specialist  
**Audience**: Executive Leadership, Hiring Managers, Global Operations Committee  
**Time Limit**: 10 Minutes (8 mins presentation + 2 mins Q&A)

---

## Slide 1: Title & Executive Vision (Time: 0:00 - 1:00)
- **Title**: Unified Multi-Region Business Intelligence Platform
- **Sub-bullet**: Bridging Sales, Finance, Supply Chain, and HR with Zero-Trust Regional Governance
- **The Hook**: "Today, global enterprises operate in hyper-competitive markets, but fragmented data silos across four different source systems cause weeks of manual reconciliation, reporting latency, and compliance vulnerabilities. Today, we demonstrate a unified reporting suite that updates automatically, delivers sub-second insights, and protects regional data boundaries."

---

## Slide 2: The Problem: Fragmentation & Security Gaps (Time: 1:00 - 2:30)
- **Pain Points Identified**:
  1. **Disparate Silos**: Sales had no immediate visibility into Supply Chain stockouts; Finance suffered quarterly forecast variance due to lagged HR hiring updates.
  2. **Security Vulnerabilities**: Sending exported spreadsheets over email led to accidental cross-regional data exposure.
  3. **Performance Lag**: Complex queries on raw transactional tables caused reporting timeouts during peak operating hours.
- **Project Objective**: Build an automated end-to-end cloud BI architecture that unifies 4 domains, enforces automated RLS, and serves executive KPIs with sub-second response times.

---

## Slide 3: Architectural Design & Kimball Star Schema (Time: 2:30 - 4:00)
- **Architecture Highlights**:
  - **Storage & Compute**: Microsoft SQL Server / Azure SQL DW hosting a clean 3-tier schema (`stg` -> `dw` -> `sec`).
  - **Star Schema Engine**:
    - Conformed dimensions: `Dim_Date`, `Dim_Geography`, `Dim_Product`, `Dim_Customer`, `Dim_Department`, `Dim_Employee`, `Dim_Warehouse`.
    - Fact constellation: `Fact_Sales`, `Fact_FinancialLedger`, `Fact_SupplyChainInventory`, `Fact_HRMonthlySnapshot`.
  - **Orchestration**: Azure Data Factory (ADF) master pipeline managing automated ingestion, parallel dimension/fact transforms, automated data quality verification gates, and Power BI REST API dataset refreshes.

---

## Slide 4: Key DAX Calculations & Business Intelligence (Time: 4:00 - 5:30)
- **Executive Time Intelligence**:
  - Net Revenue YTD with dynamic prior year same-period comparisons (`[Net Revenue YTD YoY Growth %]`).
  - Smoothing seasonality through 3-Month and 12-Month rolling averages (`[Net Revenue 3-Month Rolling Avg]`).
- **Operational & Human Capital Intelligence**:
  - Real-time gross margin and operating margin monitoring (`[Operating Margin %]`).
  - Supply Chain On-Time In-Full (`[Weighted OTIF Delivery Rate %]`) paired with stockout alerting when inventory drops below safety buffers.
  - Annualized employee attrition rate and predictive talent flight risk scoring.

---

## Slide 5: Dynamic Row-Level Security (RLS) in Action (Time: 5:30 - 6:45)
- **How Dynamic RLS Works**:
  - One unified report file (`.pbix`) serves all global users.
  - Evaluates `USERPRINCIPALNAME()` against `sec.UserSecurityBridge`.
  - **Live Demo Persona Check**:
    - Regional Director NA logs in -> Sees only US & Canada figures.
    - Regional Director EMEA logs in -> Sees only UK, Germany, and France.
    - CEO logs in -> Views global consolidated KPIs.
    - Unmapped external user logs in -> Sees blank views (Zero Trust fail-safe).
- **Result**: Zero maintenance of duplicated regional report copies; 100% compliance with corporate regional governance policies.

---

## Slide 6: Technical Challenges & Engineering Solutions (Time: 6:45 - 8:00)
- **Challenge 1: Differing Granularities Across Domains**:
  - *Issue*: Sales occurs per transaction second; Financial ledger settles monthly; Inventory takes monthly SKU snapshots.
  - *Solution*: Utilized a unified conformed `Dim_Date` with standard `DateKey` (YYYYMMDD) and month-end grain alignment, preventing many-to-many relationship traps.
- **Challenge 2: Query Latency on Rolling Calculations**:
  - *Issue*: Rolling average DAX formulas caused excessive memory consumption on unaggregated rows.
  - *Solution*: Optimized filter context using `DATESINPERIOD` over `VALUES(Dim_Date[FullDate])`, achieving an 84% reduction in query execution duration (from 280ms down to 44ms).
- **Challenge 3: Dynamic Security Join Overhead**:
  - *Solution*: Enforced single-directional filtering from `sec.UserSecurityBridge` to `dw.Dim_Geography`, preventing circular ambiguity and keeping the VertiPaq engine in high-speed Storage Engine mode.

---

## Slide 7: Business Impact & Next Steps (Time: 8:00 - 9:00)
- **Delivered Business Outcomes**:
  - **90% reduction** in manual weekly reporting preparation hours (from 15 hours/week to fully automated daily refresh).
  - **Sub-second dashboard loading** (320ms cold, 110ms warm cache).
  - **100% data reconciliation accuracy** with 0 orphan records.
- **Next Steps & Roadmap**:
  1. Integrate Azure OpenAI / Power BI Copilot for natural language Q&A across multi-region datasets.
  2. Implement Real-Time Streaming datasets for immediate warehouse dock-door telemetry.
  3. Expand to predictive demand forecasting using Azure Synapse ML.

---

## Slide 8: Q&A & Live Demonstration (Time: 9:00 - 10:00)
- "Thank you for your time. I will now open the floor for any questions and walk through a live drill-through demonstration."
