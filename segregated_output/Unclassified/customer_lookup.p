/* Customer Lookup Module */

DEFINE INPUT PARAMETER ipCustNum AS INTEGER NO-UNDO.

FIND customer WHERE customer.cust_num = ipCustNum NO-LOCK NO-ERROR.

IF AVAILABLE customer THEN DO:
DISPLAY
customer.cust_num
customer.name
customer.city
customer.phone.
END.
ELSE DO:
MESSAGE "Customer not found" VIEW-AS ALERT-BOX.
END.

File: i