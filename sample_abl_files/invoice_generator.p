/* Invoice Generation */

DEFINE VARIABLE vTotal AS DECIMAL NO-UNDO.

FOR EACH order_line NO-LOCK:
vTotal = vTotal + order_line.amount.
END.

CREATE invoice.
ASSIGN
invoice.invoice_date = TODAY
invoice.total_amount = vTotal.

MESSAGE "Invoice created successfully" VIEW-AS ALERT-BOX.