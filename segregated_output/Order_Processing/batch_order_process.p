/* Batch Order Processing */

FOR EACH orders WHERE orders.status = "Pending":

FIND customer WHERE customer.id = orders.customer_id NO-LOCK.

IF AVAILABLE customer THEN DO:
    orders.status = "Processed".
END.

END.

MESSAGE "Batch processing completed" VIEW-AS ALERT-BOX.