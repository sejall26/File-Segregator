DEFINE VARIABLE vAmt AS DECIMAL NO-UNDO.
DEFINE VARIABLE vTax AS DECIMAL NO-UNDO.

FOR EACH trx_data NO-LOCK:
vAmt = vAmt + trx_data.amount.
END.

vTax = vAmt * 0.18.

CREATE txn_summary.
ASSIGN
txn_summary.total_amt = vAmt
txn_summary.tax_amt = vTax
txn_summary.created_on = TODAY.

DISPLAY vAmt vTax.