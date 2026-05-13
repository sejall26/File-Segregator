/* Configuration Loader */

DEFINE VARIABLE vConfigPath AS CHARACTER NO-UNDO.

vConfigPath = "config/settings.ini".

INPUT FROM VALUE(vConfigPath).

REPEAT:
IMPORT UNFORMATTED vConfigPath.
END.

INPUT CLOSE.