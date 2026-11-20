# Enterprise BI Suite: One-Page Executive User Guide

## Quick Reference & Navigation Overview

The **Enterprise Business Intelligence Suite** provides real-time, multi-region reporting across Sales, Finance, Supply Chain, and HR. Access is governed dynamically by your corporate single-sign-on (SSO) email.

---

### Dashboard Layout & Navigation Flow

```
+-----------------------------------------------------------------------------------+
|  [Logo] Enterprise Multi-Region Executive Command Center       [Region: Dynamic]  |
+-----------------------------------------------------------------------------------+
|  [P1: Exec KPIs]  |  [P2: Sales & Margin]  |  [P3: Finance]  |  [P4: Supply Chain]|
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  [KPI Card 1]           [KPI Card 2]           [KPI Card 3]         [KPI Card 4]  |
|  Net Revenue YTD        Gross Margin %         Operating EBITDA     OTIF Delivery |
|  $14.2M (+18.4% YoY)    46.2% (+140 bps)       $4.8M (33.8% Margin) 94.8%         |
|                                                                                   |
+-----------------------------------------------------------------------------------+
|  [Global Map & Territory Distribution]    |  [Monthly Trend: Revenue vs Margin]   |
|  - Interactive bubble map                 |  - Solid bar: Net Revenue ($M)        |
|  - Color coded by margin tier             |  - Cyan curve: 3-Month Rolling Trend  |
|  - Click any country to filter page       |  - Orange line: Gross Margin %        |
+-----------------------------------------------------------------------------------+
|  [Action Grid / Quick Slicers]                                                    |
|  - Year: [2026 v]  Quarter: [All v]  Channel: [All v]  Product: [Cloud / HW v]    |
+-----------------------------------------------------------------------------------+
```

---

### 1. Executive Top 4 Actions
1. **Filter by Time & Territory**:
   - Use the top-right slicer bar to switch between Fiscal and Calendar periods.
   - Click on any bar or country bubble to instantly cross-filter all other visuals on the page.
2. **Drill-Through into Forensic Details**:
   - Right-click any Customer, Product Category, or Warehouse in Page 1 or Page 2.
   - Select **Drill through -> Transaction Detail Report**.
   - Review line-item transaction IDs, SKU quantities, shipping freight, and discounts.
3. **Analyze YoY Growth & Rolling Averages**:
   - Switch to **Page 2 (Commercial Sales & Margin Analytics)** to view the waterfall chart dissecting where growth originated (e.g. Server hardware vs Cloud cybersecurity).
   - Review the 3-Month and 12-Month moving averages to filter out seasonality spikes.
4. **Export & Subscribe**:
   - Click **Export -> Summarized Data** in the upper toolbar to export CSV/Excel extracts.
   - Click **Subscribe to Report** to receive an automated PDF summary in your inbox every Monday at 08:00 AM local time.

---

### 2. Understanding Your Security Access (RLS)
Your corporate identity automatically controls what data displays:
- **Regional Directors (NA, EMEA, APAC, LATAM)**: You will only see customers, transactions, warehouses, and personnel residing in your operating region.
- **Global Leadership (CEO / CFO / COO)**: You have unrestricted global visibility across all 11 operating countries and 4 regional hubs.
- **HR Confidentiality**: Individual employee compensation is strictly masked unless you belong to the authorized executive HR governance group.

---

### 3. Metric Definition Cheat-Sheet
- **Net Revenue**: Gross billing minus contractual discounts (`Gross Revenue - Discounts`).
- **Gross Margin %**: `(Net Revenue - Cost of Goods Sold) / Net Revenue`. Target benchmark: **>= 40.0%**.
- **OTIF %**: **On-Time In-Full delivery rate**. Percentage of customer orders delivered on the promised schedule with 100% quantity fulfilled. Target benchmark: **>= 95.0%**.
- **Annualized Attrition Rate**: Voluntary and involuntary departures scaled annually over average headcount. Target benchmark: **< 12.0%**.

---

### 4. Technical Support & Help Desk
- **Dataset Refresh Schedule**: Daily at 02:00 AM UTC via Azure Data Factory.
- **Report Owner**: Enterprise Data Analytics & Engineering CoE.
- **Incident Escalation**: Submit a ticket via Jira Service Desk under project `DATA-BI-SUPPORT`.
