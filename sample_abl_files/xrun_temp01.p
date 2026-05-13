FOR EACH session_data EXCLUSIVE-LOCK:
IF session_data.last_access < TODAY - 30 THEN
DELETE session_data.
END.

FOR EACH audit_logs EXCLUSIVE-LOCK:
IF audit_logs.created_on < TODAY - 90 THEN
DELETE audit_logs.
END.

MESSAGE "Cleanup completed".