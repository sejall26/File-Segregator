DEFINE VARIABLE vTotal AS DECIMAL NO-UNDO.

OUTPUT TO final_output.txt.

FOR EACH sales_data NO-LOCK:
vTotal = vTotal + sales_data.sales_amt.

PUT UNFORMATTED
    sales_data.region "|"
    sales_data.sales_amt SKIP.

END.

PUT UNFORMATTED
"TOTAL:" vTotal SKIP.

OUTPUT CLOSE.