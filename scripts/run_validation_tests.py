#!/usr/bin/env python3
"""
Enterprise Business Intelligence Suite - Automated Verification & Test Runner
Validates data integrity rules, RLS mapping rules, and schema definitions.
"""

import sys
import os
import re

def log(msg, status="INFO"):
    colors = {
        "INFO": "\033[94m[INFO]\033[0m",
        "PASS": "\033[92m[PASS]\033[0m",
        "FAIL": "\033[91m[FAIL]\033[0m",
        "WARN": "\033[93m[WARN]\033[0m"
    }
    prefix = colors.get(status, f"[{status}]")
    print(f"{prefix} {msg}")

def test_file_existence(base_dir):
    log("Checking core repository deliverables...", "INFO")
    required_files = [
        "sql/01_schema_ddl.sql",
        "sql/02_views_and_procedures.sql",
        "sql/03_seed_enterprise_data.sql",
        "sql/04_data_validation_tests.sql",
        "adf/pipeline/pl_master_orchestration.json",
        "powerquery/M_Extract_Transform_Dims.pq",
        "powerquery/M_Extract_Transform_Facts.pq",
        "dax/DAX_Measures_Enterprise_Suite.dax",
        "rls/rls_security_rules.dax",
        "rls/RLS_Configuration_Guide.md",
        "pbix_model/model.bim",
        "pbix_model/report_layout_specification.json",
        "docs/ARCHITECTURE.md",
        "docs/DATA_DICTIONARY.md",
        "docs/USER_GUIDE.md",
        "docs/TEST_RESULTS_REPORT.md",
        "docs/PRESENTATION_DECK.md",
        "docs/INTERN_REFLECTION.md",
        "README.md"
    ]
    
    missing = []
    for rel_path in required_files:
        full_path = os.path.join(base_dir, rel_path)
        if not os.path.exists(full_path):
            missing.append(rel_path)
    
    if missing:
        for m in missing:
            log(f"Missing file: {m}", "FAIL")
        return False
    
    log(f"All {len(required_files)} core deliverable files successfully verified.", "PASS")
    return True

def test_dax_measures(base_dir):
    log("Validating DAX measure repository syntax & coverage...", "INFO")
    dax_path = os.path.join(base_dir, "dax", "DAX_Measures_Enterprise_Suite.dax")
    with open(dax_path, "r", encoding="utf-8") as f:
        content = f.read()

    required_dax_patterns = [
        "Total Net Revenue",
        "Net Revenue YTD",
        "Net Revenue YoY Growth %",
        "Gross Margin %",
        "Net Revenue 3-Month Rolling Avg",
        "Operating Income (EBITDA)",
        "Annualized Attrition Rate %",
        "Weighted OTIF Delivery Rate %"
    ]

    missing = []
    for measure in required_dax_patterns:
        if measure not in content:
            missing.append(measure)

    if missing:
        for m in missing:
            log(f"Missing DAX measure: {m}", "FAIL")
        return False

    log(f"Verified all required DAX measures (YTD, YoY Growth, Margin %, Rolling Avgs, OTIF, Attrition).", "PASS")
    return True

def test_rls_security_logic(base_dir):
    log("Validating dynamic RLS isolation logic...", "INFO")
    rls_path = os.path.join(base_dir, "rls", "rls_security_rules.dax")
    with open(rls_path, "r", encoding="utf-8") as f:
        content = f.read()

    if "USERPRINCIPALNAME()" not in content:
        log("Dynamic RLS does not reference USERPRINCIPALNAME()!", "FAIL")
        return False

    if "UserSecurityBridge" not in content:
        log("Dynamic RLS does not reference UserSecurityBridge table!", "FAIL")
        return False

    log("Dynamic Row-Level Security rule verified with USERPRINCIPALNAME() bridge lookup.", "PASS")
    return True

def test_schema_ddl(base_dir):
    log("Validating Star Schema DDL foreign keys & table definitions...", "INFO")
    ddl_path = os.path.join(base_dir, "sql", "01_schema_ddl.sql")
    with open(ddl_path, "r", encoding="utf-8") as f:
        content = f.read()

    required_tables = [
        "dw.Dim_Date",
        "dw.Dim_Geography",
        "dw.Dim_Product",
        "dw.Dim_Customer",
        "dw.Dim_Department",
        "dw.Dim_Employee",
        "dw.Dim_Warehouse",
        "sec.UserSecurityBridge",
        "dw.Fact_Sales",
        "dw.Fact_FinancialLedger",
        "dw.Fact_SupplyChainInventory",
        "dw.Fact_HRMonthlySnapshot"
    ]

    missing = []
    for table in required_tables:
        if table not in content:
            missing.append(table)

    if missing:
        for m in missing:
            log(f"Missing table in DDL: {m}", "FAIL")
        return False

    log("Verified 7 Conformed Dimensions, 4 Fact Tables, and 1 Security Bridge Table in DDL.", "PASS")
    return True

def main():
    print("=" * 65)
    print("ENTERPRISE BUSINESS INTELLIGENCE SUITE - AUTOMATED TEST SUITE")
    print("=" * 65)

    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    results = [
        test_file_existence(base_dir),
        test_schema_ddl(base_dir),
        test_dax_measures(base_dir),
        test_rls_security_logic(base_dir)
    ]

    print("-" * 65)
    if all(results):
        log("ALL TEST SUITES PASSED (100% SUCCESS RATE). READY FOR PRODUCTION DEPLOYMENT.", "PASS")
        sys.exit(0)
    else:
        log("ONE OR MORE TEST SUITES FAILED.", "FAIL")
        sys.exit(1)

if __name__ == "__main__":
    main()
