/* Inventory Update Module */

DEFINE INPUT PARAMETER ipItemId AS INTEGER NO-UNDO.
DEFINE INPUT PARAMETER ipQty AS INTEGER NO-UNDO.

FIND inventory WHERE inventory.item_id = ipItemId EXCLUSIVE-LOCK.

IF AVAILABLE inventory THEN DO:
inventory.stock_qty = inventory.stock_qty - ipQty.
DISPLAY inventory.stock_qty.
END.