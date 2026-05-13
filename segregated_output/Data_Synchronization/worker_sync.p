DEFINE VARIABLE vCount AS INTEGER NO-UNDO.

FOR EACH sync_queue WHERE sync_queue.status = "N":

FIND FIRST ext_system
    WHERE ext_system.sys_id = sync_queue.sys_id
    NO-LOCK NO-ERROR.

IF AVAILABLE ext_system THEN DO:
    sync_queue.status = "C".
    vCount = vCount + 1.
END.

END.

MESSAGE vCount "records synced".