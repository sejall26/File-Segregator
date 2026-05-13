/* Utility Module */

DEFINE VARIABLE vDate AS DATE NO-UNDO.

vDate = TODAY.

DISPLAY STRING(vDate, "99/99/9999").