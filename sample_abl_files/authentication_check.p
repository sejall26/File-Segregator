/* Authentication Module */

DEFINE INPUT PARAMETER ipUser AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER ipPass AS CHARACTER NO-UNDO.

FIND users
WHERE users.username = ipUser
AND users.password = ipPass
NO-LOCK NO-ERROR.

IF AVAILABLE users THEN
MESSAGE "Login successful".
ELSE
MESSAGE "Invalid credentials".