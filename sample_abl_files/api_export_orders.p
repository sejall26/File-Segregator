/* API Export Module */

OUTPUT TO orders_export.json.

FOR EACH orders NO-LOCK:
EXPORT orders.
END.

OUTPUT CLOSE.

MESSAGE "Orders exported successfully".