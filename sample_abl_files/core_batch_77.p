FOR EACH req_queue WHERE req_queue.flag = "P":

FIND customer_data
    WHERE customer_data.cust_id = req_queue.cust_id
    NO-LOCK NO-ERROR.

IF AVAILABLE customer_data THEN DO:
    CREATE process_log.
    ASSIGN
        process_log.proc_date = TODAY
        process_log.cust_id = customer_data.cust_id.
END.

req_queue.flag = "D".

END.