/* monthly_report.p - Monthly Sales and Revenue Reporting */

DEFINE VARIABLE vReportMonth  AS INTEGER NO-UNDO.
DEFINE VARIABLE vReportYear   AS INTEGER NO-UNDO.
DEFINE VARIABLE vTotalRevenue AS DECIMAL NO-UNDO.
DEFINE VARIABLE vTotalOrders  AS INTEGER NO-UNDO.
DEFINE VARIABLE vAvgOrderVal  AS DECIMAL NO-UNDO.

DEFINE TEMP-TABLE ttRegionSummary NO-UNDO
    FIELD region_name    AS CHARACTER
    FIELD total_sales    AS DECIMAL
    FIELD order_count    AS INTEGER
    FIELD top_product    AS CHARACTER
    FIELD growth_pct     AS DECIMAL.

DEFINE TEMP-TABLE ttProductPerf NO-UNDO
    FIELD product_code   AS CHARACTER
    FIELD product_name   AS CHARACTER
    FIELD units_sold     AS INTEGER
    FIELD revenue        AS DECIMAL
    FIELD return_rate    AS DECIMAL.

PROCEDURE GenerateMonthlyReport:
    DEFINE INPUT PARAMETER piMonth AS INTEGER.
    DEFINE INPUT PARAMETER piYear  AS INTEGER.

    vReportMonth = piMonth.
    vReportYear  = piYear.

    RUN CollectSalesData.
    RUN CollectRegionData.
    RUN CollectProductPerformance.
    RUN CalculateKPIs.
    RUN ExportReportToExcel.
    RUN EmailReportToManagement.

END PROCEDURE.

PROCEDURE CollectSalesData:

    vTotalRevenue = 0.
    vTotalOrders  = 0.

    FOR EACH SalesOrder
        WHERE MONTH(SalesOrder.order_date) = vReportMonth
          AND YEAR(SalesOrder.order_date)  = vReportYear
          AND SalesOrder.status <> "CANCELLED"
        NO-LOCK:

        vTotalRevenue = vTotalRevenue + SalesOrder.order_total.
        vTotalOrders  = vTotalOrders + 1.
    END.

    IF vTotalOrders > 0 THEN
        vAvgOrderVal = vTotalRevenue / vTotalOrders.

END PROCEDURE.

PROCEDURE CollectRegionData:

    FOR EACH Region NO-LOCK:
        CREATE ttRegionSummary.
        ttRegionSummary.region_name = Region.region_name.

        FOR EACH SalesOrder
            WHERE SalesOrder.region_id  = Region.region_id
              AND MONTH(SalesOrder.order_date) = vReportMonth
              AND YEAR(SalesOrder.order_date)  = vReportYear
            NO-LOCK:
            ttRegionSummary.total_sales  = ttRegionSummary.total_sales + SalesOrder.order_total.
            ttRegionSummary.order_count  = ttRegionSummary.order_count + 1.
        END.

        /* Calculate growth vs previous month */
        DEFINE VARIABLE vPrevMonthSales AS DECIMAL NO-UNDO.
        RUN GetPrevMonthSales(Region.region_id, vReportMonth, vReportYear, OUTPUT vPrevMonthSales).
        IF vPrevMonthSales > 0 THEN
            ttRegionSummary.growth_pct = ((ttRegionSummary.total_sales - vPrevMonthSales) / vPrevMonthSales) * 100.
    END.

END PROCEDURE.

PROCEDURE ExportReportToExcel:
    /* Export all report data to formatted Excel file */
    DEFINE VARIABLE vFileName AS CHARACTER NO-UNDO.
    vFileName = "MonthlyReport_" + STRING(vReportYear) + "_" + STRING(vReportMonth, "99") + ".xlsx".

    /* Write header */
    RUN WriteExcelHeader(vFileName, "Monthly Sales Report - " + STRING(vReportMonth) + "/" + STRING(vReportYear)).

    /* Write summary data */
    RUN WriteExcelRow(vFileName, "Total Revenue", STRING(vTotalRevenue)).
    RUN WriteExcelRow(vFileName, "Total Orders",  STRING(vTotalOrders)).
    RUN WriteExcelRow(vFileName, "Avg Order Value", STRING(vAvgOrderVal)).

    /* Write region breakdown */
    FOR EACH ttRegionSummary BY ttRegionSummary.total_sales DESCENDING:
        RUN WriteRegionRow(vFileName, ttRegionSummary.region_name,
                           ttRegionSummary.total_sales, ttRegionSummary.order_count,
                           ttRegionSummary.growth_pct).
    END.

END PROCEDURE.
