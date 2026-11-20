/*
 ==============================================================================
 Enterprise Business Intelligence Suite (Multi-Region)
 Power Query (M Code) Transformation Library: Conformed Dimensions
 ==============================================================================
*/

// Section 1: Parameters
let
    // Parameter definitions for enterprise environments
    ServerName = "sql-enterprise-dw-prod.database.windows.net" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true],
    DatabaseName = "EnterpriseDW" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
in
    ServerName;

// Section 2: Dim_Geography Query (M Code)
let
    Source = Sql.Database(#"ServerName", #"DatabaseName"),
    dw_Dim_Geography = Source{[Schema="dw",Item="Dim_Geography"]}[Data],
    #"Trimmed Text" = Table.TransformColumns(dw_Dim_Geography, {
        {"OperatingRegion", Text.Trim, type text},
        {"GlobalRegion", Text.Trim, type text},
        {"Country", Text.Trim, type text},
        {"City", Text.Trim, type text}
    }),
    #"Replaced Null Postal Codes" = Table.ReplaceValue(#"Trimmed Text", null, "N/A", Replacer.ReplaceValue, {"PostalCode"}),
    #"Added Region Display Column" = Table.AddColumn(#"Replaced Null Postal Codes", "RegionCountryDisplay", each [OperatingRegion] & " - " & [Country], type text),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Region Display Column",{
        {"GeographyKey", Int64.Type},
        {"GeographyID", type text},
        {"GlobalRegion", type text},
        {"OperatingRegion", type text},
        {"SubRegion", type text},
        {"Country", type text},
        {"CountryCode", type text},
        {"StateProvince", type text},
        {"City", type text},
        {"PostalCode", type text},
        {"RegionalDirectorEmail", type text},
        {"CurrencyCode", type text},
        {"IsActive", type logical}
    })
in
    #"Changed Type"

// Section 3: Dim_Product Query (M Code)
let
    Source = Sql.Database(#"ServerName", #"DatabaseName"),
    dw_Dim_Product = Source{[Schema="dw",Item="Dim_Product"]}[Data],
    #"Filtered Active Products" = Table.SelectRows(dw_Dim_Product, each ([IsCurrent] = true)),
    #"Calculated Profit Class" = Table.AddColumn(#"Filtered Active Products", "ProfitClass", each 
        if [TargetMarginPct] >= 55 then "High Margin (>=55%)"
        else if [TargetMarginPct] >= 30 then "Standard Margin (30-54%)"
        else "Low Margin (<30%)", type text),
    #"Changed Type" = Table.TransformColumnTypes(#"Calculated Profit Class",{
        {"ProductKey", Int64.Type},
        {"ProductSKU", type text},
        {"ProductName", type text},
        {"ProductCategory", type text},
        {"ProductSubcategory", type text},
        {"Brand", type text},
        {"Color", type text},
        {"StandardUnitCost", Currency.Type},
        {"ListUnitPrice", Currency.Type},
        {"TargetMarginPct", Percentage.Type},
        {"ProductStatus", type text},
        {"EffectiveStartDate", type date},
        {"IsCurrent", type logical}
    })
in
    #"Changed Type"

// Section 4: Bridge_UserSecurity Query (M Code)
let
    Source = Sql.Database(#"ServerName", #"DatabaseName"),
    sec_UserSecurityBridge = Source{[Schema="sec",Item="UserSecurityBridge"]}[Data],
    #"Lowercased UPN" = Table.TransformColumns(sec_UserSecurityBridge, {{"UserPrincipalName", Text.Lower, type text}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Lowercased UPN",{
        {"SecurityMappingID", Int64.Type},
        {"UserPrincipalName", type text},
        {"DisplayName", type text},
        {"RoleTitle", type text},
        {"GlobalRegion", type text},
        {"OperatingRegion", type text},
        {"AllowHRConfidential", type logical},
        {"AllowFinancialExecutive", type logical}
    })
in
    #"Changed Type"
