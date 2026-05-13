/* Sales Reporting */

DEFINE VARIABLE vSales AS DECIMAL NO-UNDO.

FOR EACH sales NO-LOCK:
vSales = vSales + sales.amount.
END.

DISPLAY vSales LABEL "Total Sales".

OUTPUT TO sales_report.txt.
PUT UNFORMATTED "Total Sales: " vSales.
OUTPUT CLOSE.