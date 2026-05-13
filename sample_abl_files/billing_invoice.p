/* billing_invoice.p - Invoice Generation Module */

DEFINE VARIABLE vCustomerId AS INTEGER NO-UNDO.
DEFINE VARIABLE vInvoiceTotal AS DECIMAL NO-UNDO.
DEFINE VARIABLE vTaxRate AS DECIMAL INITIAL 0.18 NO-UNDO.
DEFINE VARIABLE vInvoiceNo AS CHARACTER NO-UNDO.

DEFINE TEMP-TABLE ttInvoiceLine NO-UNDO
    FIELD item_code    AS CHARACTER
    FIELD description  AS CHARACTER
    FIELD quantity     AS INTEGER
    FIELD unit_price   AS DECIMAL
    FIELD line_total   AS DECIMAL.

PROCEDURE GenerateInvoice:
    DEFINE INPUT PARAMETER piCustomerId AS INTEGER.
    DEFINE OUTPUT PARAMETER pcInvoiceNo AS CHARACTER.

    DEFINE VARIABLE vSeq AS INTEGER NO-UNDO.

    /* Get next invoice sequence */
    FIND LAST Invoice NO-LOCK NO-ERROR.
    IF AVAILABLE Invoice THEN
        vSeq = Invoice.invoice_seq + 1.
    ELSE
        vSeq = 1000.

    pcInvoiceNo = "INV-" + STRING(TODAY, "99999999") + "-" + STRING(vSeq).

    CREATE Invoice.
    ASSIGN
        Invoice.invoice_no   = pcInvoiceNo
        Invoice.customer_id  = piCustomerId
        Invoice.invoice_date = TODAY
        Invoice.status       = "PENDING".

    /* Add billing lines */
    FOR EACH ttInvoiceLine:
        CREATE InvoiceLine.
        ASSIGN
            InvoiceLine.invoice_no  = pcInvoiceNo
            InvoiceLine.item_code   = ttInvoiceLine.item_code
            InvoiceLine.quantity    = ttInvoiceLine.quantity
            InvoiceLine.unit_price  = ttInvoiceLine.unit_price
            InvoiceLine.line_total  = ttInvoiceLine.quantity * ttInvoiceLine.unit_price.

        vInvoiceTotal = vInvoiceTotal + InvoiceLine.line_total.
    END.

    /* Apply tax */
    ASSIGN
        Invoice.subtotal    = vInvoiceTotal
        Invoice.tax_amount  = vInvoiceTotal * vTaxRate
        Invoice.total_due   = vInvoiceTotal + (vInvoiceTotal * vTaxRate).

    /* Send invoice to customer */
    RUN SendInvoiceEmail(pcInvoiceNo, piCustomerId).

END PROCEDURE.

PROCEDURE CalculateLateFee:
    DEFINE INPUT PARAMETER pcInvoiceNo AS CHARACTER.
    DEFINE OUTPUT PARAMETER pdLateFee AS DECIMAL.

    FIND Invoice WHERE Invoice.invoice_no = pcInvoiceNo NO-LOCK NO-ERROR.
    IF AVAILABLE Invoice AND Invoice.due_date < TODAY THEN DO:
        pdLateFee = Invoice.total_due * 0.02.  /* 2% late fee */
        ASSIGN
            Invoice.late_fee   = pdLateFee
            Invoice.total_due  = Invoice.total_due + pdLateFee.
    END.
    ELSE pdLateFee = 0.
END PROCEDURE.
