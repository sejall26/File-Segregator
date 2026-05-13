DEFINE INPUT PARAMETER ipName AS CHARACTER NO-UNDO.
DEFINE INPUT PARAMETER ipPwd AS CHARACTER NO-UNDO.

FIND FIRST app_users
WHERE app_users.user_name = ipName
AND app_users.user_pwd = ipPwd
NO-LOCK NO-ERROR.

IF AVAILABLE app_users THEN DO:
CREATE login_history.
ASSIGN
login_history.user_name = ipName
login_history.login_time = NOW.
END.
ELSE DO:
MESSAGE "Access denied".
END.
