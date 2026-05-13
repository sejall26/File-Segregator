/* inventory_check.p - Inventory Management and Stock Control */

DEFINE VARIABLE vWarehouseId  AS INTEGER NO-UNDO.
DEFINE VARIABLE vReorderLevel AS INTEGER NO-UNDO.
DEFINE VARIABLE vCurrentStock AS INTEGER NO-UNDO.

DEFINE TEMP-TABLE ttLowStockItems NO-UNDO
    FIELD item_code     AS CHARACTER
    FIELD item_name     AS CHARACTER
    FIELD current_qty   AS INTEGER
    FIELD reorder_qty   AS INTEGER
    FIELD warehouse     AS CHARACTER.

PROCEDURE CheckStockLevels:
    DEFINE INPUT PARAMETER piWarehouseId AS INTEGER.

    EMPTY TEMP-TABLE ttLowStockItems.

    FOR EACH Inventory WHERE Inventory.warehouse_id = piWarehouseId NO-LOCK:
        IF Inventory.quantity_on_hand <= Inventory.reorder_level THEN DO:
            CREATE ttLowStockItems.
            ASSIGN
                ttLowStockItems.item_code   = Inventory.item_code
                ttLowStockItems.item_name   = Inventory.item_name
                ttLowStockItems.current_qty = Inventory.quantity_on_hand
                ttLowStockItems.reorder_qty = Inventory.reorder_quantity
                ttLowStockItems.warehouse   = Inventory.warehouse_name.
        END.
    END.

    IF CAN-FIND(FIRST ttLowStockItems) THEN
        RUN GeneratePurchaseOrders.

END PROCEDURE.

PROCEDURE UpdateStockOnReceipt:
    DEFINE INPUT PARAMETER pcItemCode    AS CHARACTER.
    DEFINE INPUT PARAMETER piQtyReceived AS INTEGER.
    DEFINE INPUT PARAMETER piWarehouseId AS INTEGER.

    FIND Inventory WHERE
        Inventory.item_code    = pcItemCode AND
        Inventory.warehouse_id = piWarehouseId
        EXCLUSIVE-LOCK NO-ERROR.

    IF AVAILABLE Inventory THEN DO:
        ASSIGN
            Inventory.quantity_on_hand  = Inventory.quantity_on_hand + piQtyReceived
            Inventory.last_received_dt  = TODAY
            Inventory.last_received_qty = piQtyReceived.
    END.

END PROCEDURE.

PROCEDURE TransferStock:
    DEFINE INPUT PARAMETER pcItemCode      AS CHARACTER.
    DEFINE INPUT PARAMETER piQty           AS INTEGER.
    DEFINE INPUT PARAMETER piFromWarehouse AS INTEGER.
    DEFINE INPUT PARAMETER piToWarehouse   AS INTEGER.

    DEFINE VARIABLE vAvailable AS INTEGER NO-UNDO.

    /* Check source warehouse */
    FIND Inventory WHERE
        Inventory.item_code    = pcItemCode AND
        Inventory.warehouse_id = piFromWarehouse
        NO-LOCK NO-ERROR.

    IF AVAILABLE Inventory THEN
        vAvailable = Inventory.quantity_on_hand.

    IF vAvailable >= piQty THEN DO:
        RUN UpdateStockOnReceipt(pcItemCode, -piQty, piFromWarehouse).
        RUN UpdateStockOnReceipt(pcItemCode, piQty, piToWarehouse).
        /* Log the transfer */
        CREATE StockTransferLog.
        ASSIGN
            StockTransferLog.item_code    = pcItemCode
            StockTransferLog.quantity     = piQty
            StockTransferLog.from_wh      = piFromWarehouse
            StockTransferLog.to_wh        = piToWarehouse
            StockTransferLog.transfer_dt  = TODAY.
    END.
    ELSE
        MESSAGE "Insufficient stock for transfer." VIEW-AS ALERT-BOX.

END PROCEDURE.
