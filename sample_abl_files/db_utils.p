/* db_utils.p - Database Utility Procedures and Connection Helpers */

DEFINE VARIABLE vDbConnected  AS LOGICAL   NO-UNDO.
DEFINE VARIABLE vDbAlias      AS CHARACTER NO-UNDO.
DEFINE VARIABLE vRetryCount   AS INTEGER   NO-UNDO.

PROCEDURE ConnectToDatabase:
    DEFINE INPUT  PARAMETER pcHost     AS CHARACTER.
    DEFINE INPUT  PARAMETER piPort     AS INTEGER.
    DEFINE INPUT  PARAMETER pcDbName   AS CHARACTER.
    DEFINE INPUT  PARAMETER pcUser     AS CHARACTER.
    DEFINE INPUT  PARAMETER pcPassword AS CHARACTER.
    DEFINE OUTPUT PARAMETER plSuccess  AS LOGICAL.

    DEFINE VARIABLE vConnString AS CHARACTER NO-UNDO.

    plSuccess   = FALSE.
    vRetryCount = 0.

    vConnString = "-H " + pcHost +
                  " -S " + STRING(piPort) +
                  " -db " + pcDbName +
                  " -U " + pcUser +
                  " -P " + pcPassword.

    REPEAT vRetryCount = 1 TO 3:
        CONNECT VALUE(vConnString) NO-ERROR.
        IF CONNECTED(pcDbName) THEN DO:
            plSuccess   = TRUE.
            vDbConnected = TRUE.
            vDbAlias     = pcDbName.
            LEAVE.
        END.
        PAUSE 2.
    END.

    IF NOT plSuccess THEN
        RUN LogDatabaseError("Failed to connect to " + pcDbName + " after 3 retries.").

END PROCEDURE.

PROCEDURE DisconnectDatabase:
    DEFINE INPUT PARAMETER pcDbName AS CHARACTER.

    IF CONNECTED(pcDbName) THEN DO:
        DISCONNECT VALUE(pcDbName).
        vDbConnected = FALSE.
        RUN LogDatabaseEvent("Disconnected from " + pcDbName).
    END.
END PROCEDURE.

PROCEDURE RunDatabaseMaintenance:
    /* Truncate expired sessions */
    FOR EACH UserSession WHERE UserSession.expiry_time < NOW EXCLUSIVE-LOCK:
        DELETE UserSession.
    END.

    /* Archive old audit logs older than 90 days */
    FOR EACH AuditLog WHERE AuditLog.log_date < (TODAY - 90) EXCLUSIVE-LOCK:
        RUN ArchiveAuditRecord(AuditLog.log_id).
        DELETE AuditLog.
    END.

    /* Update table statistics */
    RUN UpdateTableStats("Customer").
    RUN UpdateTableStats("SalesOrder").
    RUN UpdateTableStats("Invoice").
    RUN UpdateTableStats("Inventory").

    RUN LogDatabaseEvent("Database maintenance completed on " + STRING(TODAY)).
END PROCEDURE.

PROCEDURE BackupDatabase:
    DEFINE INPUT PARAMETER pcBackupPath AS CHARACTER.

    DEFINE VARIABLE vBackupFile AS CHARACTER NO-UNDO.
    vBackupFile = pcBackupPath + "\backup_" + STRING(TODAY, "99999999") + ".bak".

    OS-COMMAND SILENT
        VALUE("probkup online " + vDbAlias + " " + vBackupFile).

    IF OS-ERROR = 0 THEN
        RUN LogDatabaseEvent("Backup successful: " + vBackupFile).
    ELSE
        RUN LogDatabaseError("Backup failed for " + vDbAlias).
END PROCEDURE.
