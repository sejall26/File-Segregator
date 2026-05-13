/* sales_order.p - Sales Order Processing and Fulfillment */

DEFINE VARIABLE vOrderId     AS INTEGER   NO-UNDO.
DEFINE VARIABLE vCustomerId  AS INTEGER   NO-UNDO.
DEFINE VARIABLE vOrderTotal  AS DECIMAL   NO-UNDO.
DEFINE VARIABLE vDiscount    AS DECIMAL   NO-UNDO.

DEFINE TEMP-TABLE ttOrderLines NO-UNDO
    FIELD product_code AS CHARACTER
    FIELD product_name AS CHARACTER
    FIELD ordered_qty  AS INTEGER
    FIELD unit_price   AS DECIMAL
    FIELD discount_pct AS DECIMAL.

PROCEDURE CreateSalesOrder:
    DEFINE INPUT  PARAMETER piCustomerId AS INTEGER.
    DEFINE INPUT  PARAMETER pcSalesRep   AS CHARACTER.
    DEFINE OUTPUT PARAMETER piOrderId    AS INTEGER.

    DEFINE VARIABLE vNextOrderId AS INTEGER NO-UNDO.

    /* Get next order ID */
    FIND LAST SalesOrder NO-LOCK NO-ERROR.
    IF AVAILABLE SalesOrder THEN
        vNextOrderId = SalesOrder.order_id + 1.
    ELSE
        vNextOrderId = 10001.

    CREATE SalesOrder.
    ASSIGN
        SalesOrder.order_id      = vNextOrderId
        SalesOrder.customer_id   = piCustomerId
        SalesOrder.sales_rep     = pcSalesRep
        SalesOrder.order_date    = TODAY
        SalesOrder.status        = "DRAFT"
        SalesOrder.payment_terms = "NET30".

    piOrderId = vNextOrderId.

    /* Add order lines */
    FOR EACH ttOrderLines:
        /* Check stock availability */
        IF NOT RUN CheckStockAvailability(ttOrderLines.product_code, ttOrderLines.ordered_qty) THEN DO:
            MESSAGE "Product " + ttOrderLines.product_code + " is out of stock."
                VIEW-AS ALERT-BOX WARNING.
            NEXT.
        END.

        CREATE SalesOrderLine.
        ASSIGN
            SalesOrderLine.order_id      = vNextOrderId
            SalesOrderLine.product_code  = ttOrderLines.product_code
            SalesOrderLine.ordered_qty   = ttOrderLines.ordered_qty
            SalesOrderLine.unit_price    = ttOrderLines.unit_price
            SalesOrderLine.discount_pct  = ttOrderLines.discount_pct
            SalesOrderLine.line_total    = ttOrderLines.ordered_qty *
                                           ttOrderLines.unit_price *
                                           (1 - ttOrderLines.discount_pct / 100).

        vOrderTotal = vOrderTotal + SalesOrderLine.line_total.
    END.

    ASSIGN SalesOrder.order_total = vOrderTotal.

END PROCEDURE.

PROCEDURE ConfirmAndShipOrder:
    DEFINE INPUT PARAMETER piOrderId AS INTEGER.

    FIND SalesOrder WHERE SalesOrder.order_id = piOrderId EXCLUSIVE-LOCK NO-ERROR.
    IF NOT AVAILABLE SalesOrder THEN RETURN.

    IF SalesOrder.status <> "APPROVED" THEN DO:
        MESSAGE "Order must be approved before shipping." VIEW-AS ALERT-BOX.
        RETURN.
    END.

    /* Reserve stock and generate shipment */
    FOR EACH SalesOrderLine WHERE SalesOrderLine.order_id = piOrderId NO-LOCK:
        RUN ReserveStock(SalesOrderLine.product_code, SalesOrderLine.ordered_qty).
    END.

    ASSIGN
        SalesOrder.status       = "SHIPPED"
        SalesOrder.ship_date    = TODAY
        SalesOrder.tracking_no  = RUN GenerateTrackingNumber().

    /* Trigger invoice creation */
    RUN GenerateInvoice(SalesOrder.customer_id, piOrderId).

END PROCEDURE.
