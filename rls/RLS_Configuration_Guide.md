# Enterprise Row-Level Security (RLS) Configuration Guide

## 1. Overview
The **Enterprise Business Intelligence Suite** enforces strict multi-tenant region isolation. Regional Directors and Operations Managers must only see data relevant to their authorized territories, while C-Suite Executives maintain unfiltered 360-degree global visibility.

```
       +---------------------------------------------+
       |   Power BI Service (Logged-in Identity)     |
       |             USERPRINCIPALNAME()             |
       +---------------------------------------------+
                              |
                              v
             [sec.UserSecurityBridge Table]
     (Maps UserPrincipalName -> Allowed Operating/Global Regions)
                              |
                              v (Bi-directional or 1-to-many relationship)
               [dw.Dim_Geography Dimension]
                              |
         +--------------------+--------------------+
         |                    |                    |
         v                    v                    v
   [Fact_Sales]     [Fact_FinancialLedger]   [Fact_SupplyChain]
```

---

## 2. Dynamic RLS Architecture
Dynamic RLS leverages the `sec.UserSecurityBridge` table. Rather than maintaining dozens of hardcoded static roles, a single **Dynamic Security Role** evaluates the user's logged-in identity against the enterprise authorization matrix.

### DAX Rule on `dw.Dim_Geography`:
```dax
VAR CurrentUserEmail = USERPRINCIPALNAME()
VAR UserAssignments = 
    FILTER(
        UserSecurityBridge,
        UserSecurityBridge[UserPrincipalName] = CurrentUserEmail
    )
VAR HasGlobalAccess = 
    COUNTROWS(
        FILTER(
            UserAssignments,
            UserSecurityBridge[OperatingRegion] = "ALL" || UserSecurityBridge[GlobalRegion] = "ALL"
        )
    ) > 0
VAR AllowedOperatingRegions = 
    SELECTCOLUMNS(
        UserAssignments,
        "AllowedRegion", UserSecurityBridge[OperatingRegion]
    )
RETURN
    HasGlobalAccess 
    || Dim_Geography[OperatingRegion] IN AllowedOperatingRegions 
    || Dim_Geography[GlobalRegion] IN AllowedGlobalRegions
```

---

## 3. Security Role Definitions

| Role Name | Table Filtered | DAX Filter Logic | Target Audience |
| :--- | :--- | :--- | :--- |
| **Dynamic_Enterprise_User** | `Dim_Geography` | Dynamic DAX using `USERPRINCIPALNAME()` | All standard enterprise regional managers |
| **Global_Executive** | None (Unfiltered) | `1=1` (All records accessible) | CEO, CFO, COO, Global VPs |
| **Regional_Director_NA** | `Dim_Geography` | `Dim_Geography[OperatingRegion] = "North America"` | North American Regional VP & Sales Leads |
| **Regional_Director_EMEA** | `Dim_Geography` | `Dim_Geography[GlobalRegion] = "EMEA"` | EMEA VP, Western & Eastern Europe Leads |
| **Regional_Director_APAC** | `Dim_Geography` | `Dim_Geography[GlobalRegion] = "APAC"` | APAC Managing Directors |
| **Regional_Director_LATAM**| `Dim_Geography` | `Dim_Geography[OperatingRegion] = "LATAM"` | Latin America Regional Director |
| **HR_Executive_Restricted** | `Dim_Employee` | `[AllowHRConfidential] = 1` | Compensation committee & CHRO |

---

## 4. Power BI Desktop Validation Steps ("View As Role")
1. Open the project in **Power BI Desktop**.
2. Navigate to the **Modeling** tab in the ribbon.
3. Click **View as** (Security group).
4. Select the checkmark next to **Dynamic_Enterprise_User**.
5. Check **Other user** and enter test identities:
   - `director.na@enterprisegroup.com`: Verify that only USA and Canada show up across charts and tables.
   - `director.emea@enterprisegroup.com`: Verify that only UK, Germany, and France show up.
   - `exec.global@enterprisegroup.com`: Verify that all 11 global territories and 4 global regions show up.
6. Verify KPI card updates: Total Net Revenue adjusts automatically based on the authorized regional slice.

---

## 5. Power BI Service Deployment Steps
1. Publish the `.pbix` file to **Power BI Service** workspace: `Enterprise-BI-Production`.
2. In the workspace, find the **Semantic Model** -> click the three dots `(...)` -> **Security**.
3. Map Azure AD Security Groups or individual user emails to the corresponding roles:
   - `SG-Enterprise-GlobalExecs` -> **Global_Executive**
   - `SG-Enterprise-AllStaff` -> **Dynamic_Enterprise_User**
4. Test with **Test as role** directly in the Power BI Service cloud portal.
