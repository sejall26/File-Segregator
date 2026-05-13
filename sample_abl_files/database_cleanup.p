/* Database Cleanup Utility */

FOR EACH temp_records EXCLUSIVE-LOCK:
DELETE temp_records.
END.

MESSAGE "Temporary records deleted successfully".