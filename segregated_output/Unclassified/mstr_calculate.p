DEFINE VARIABLE vValue AS DECIMAL NO-UNDO.
DEFINE VARIABLE vDiscount AS DECIMAL NO-UNDO.

FOR EACH item_master NO-LOCK:

IF item_master.qty > 100 THEN
    vDiscount = item_master.price * 0.10.
ELSE
    vDiscount = item_master.price * 0.05.

vValue = item_master.price - vDiscount.

DISPLAY item_master.item_id vValue.

END.