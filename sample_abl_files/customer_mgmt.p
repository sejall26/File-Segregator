/* customer_mgmt.p - Customer Profile and Account Management */

DEFINE VARIABLE vCustomerId    AS INTEGER   NO-UNDO.
DEFINE VARIABLE vCreditLimit   AS DECIMAL   NO-UNDO.

PROCEDURE CreateCustomer:
    DEFINE INPUT  PARAMETER pcFirstName   AS CHARACTER.
    DEFINE INPUT  PARAMETER pcLastName    AS CHARACTER.
    DEFINE INPUT  PARAMETER pcEmail       AS CHARACTER.
    DEFINE INPUT  PARAMETER pcPhone       AS CHARACTER.
    DEFINE INPUT  PARAMETER pcCompany     AS CHARACTER.
    DEFINE OUTPUT PARAMETER piCustomerId  AS INTEGER.

    IF CAN-FIND(Customer WHERE Customer.email = pcEmail) THEN DO:
        MESSAGE "A customer with this email already exists." VIEW-AS ALERT-BOX.
        piCustomerId = -1.
        RETURN.
    END.

    FIND LAST Customer NO-LOCK NO-ERROR.
    piCustomerId = IF AVAILABLE Customer THEN Customer.customer_id + 1 ELSE 1001.

    CREATE Customer.
    ASSIGN
        Customer.customer_id    = piCustomerId
        Customer.first_name     = pcFirstName
        Customer.last_name      = pcLastName
        Customer.email          = pcEmail
        Customer.phone          = pcPhone
        Customer.company        = pcCompany
        Customer.created_date   = TODAY
        Customer.status         = "ACTIVE"
        Customer.credit_limit   = 5000.00
        Customer.loyalty_points = 0.

    RUN SendWelcomeEmail(pcEmail, pcFirstName).
END PROCEDURE.

PROCEDURE GetCustomerPurchaseHistory:
    DEFINE INPUT  PARAMETER piCustomerId AS INTEGER.
    DEFINE OUTPUT PARAMETER pdTotalSpent AS DECIMAL.
    DEFINE OUTPUT PARAMETER piOrderCount AS INTEGER.

    pdTotalSpent = 0.
    piOrderCount = 0.

    FOR EACH SalesOrder WHERE
        SalesOrder.customer_id = piCustomerId AND
        SalesOrder.status <> "CANCELLED"
        NO-LOCK:
        pdTotalSpent = pdTotalSpent + SalesOrder.order_total.
        piOrderCount = piOrderCount + 1.
    END.
END PROCEDURE.

PROCEDURE CheckCreditLimit:
    DEFINE INPUT  PARAMETER piCustomerId   AS INTEGER.
    DEFINE INPUT  PARAMETER pdOrderAmount  AS DECIMAL.
    DEFINE OUTPUT PARAMETER plApproved     AS LOGICAL.

    FIND Customer WHERE Customer.customer_id = piCustomerId NO-LOCK NO-ERROR.
    IF NOT AVAILABLE Customer THEN DO:
        plApproved = FALSE.
        RETURN.
    END.

    DEFINE VARIABLE vOutstanding AS DECIMAL NO-UNDO.
    FOR EACH Invoice WHERE
        Invoice.customer_id = piCustomerId AND
        Invoice.status = "PENDING"
        NO-LOCK:
        vOutstanding = vOutstanding + Invoice.total_due.
    END.

    plApproved = (vOutstanding + pdOrderAmount) <= Customer.credit_limit.
END PROCEDURE.
