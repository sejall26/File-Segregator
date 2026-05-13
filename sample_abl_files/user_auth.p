/* user_auth.p - User Authentication and Session Management */

DEFINE VARIABLE vUsername     AS CHARACTER NO-UNDO.
DEFINE VARIABLE vPasswordHash AS CHARACTER NO-UNDO.
DEFINE VARIABLE vSessionToken AS CHARACTER NO-UNDO.
DEFINE VARIABLE vLoginAttempts AS INTEGER NO-UNDO.
DEFINE VARIABLE vMaxAttempts  AS INTEGER INITIAL 3 NO-UNDO.
DEFINE VARIABLE vIsLocked     AS LOGICAL NO-UNDO.

PROCEDURE AuthenticateUser:
    DEFINE INPUT  PARAMETER pcUsername AS CHARACTER.
    DEFINE INPUT  PARAMETER pcPassword AS CHARACTER.
    DEFINE OUTPUT PARAMETER pcToken    AS CHARACTER.
    DEFINE OUTPUT PARAMETER plSuccess  AS LOGICAL.

    DEFINE VARIABLE vHashedInput AS CHARACTER NO-UNDO.

    plSuccess = FALSE.
    pcToken   = "".

    /* Find user record */
    FIND UserAccount WHERE UserAccount.username = pcUsername NO-LOCK NO-ERROR.

    IF NOT AVAILABLE UserAccount THEN DO:
        RUN LogFailedAttempt(pcUsername, "USER_NOT_FOUND").
        RETURN.
    END.

    /* Check if account is locked */
    IF UserAccount.is_locked THEN DO:
        RUN LogFailedAttempt(pcUsername, "ACCOUNT_LOCKED").
        RETURN.
    END.

    /* Hash the input password and compare */
    RUN HashPassword(pcPassword, UserAccount.salt, OUTPUT vHashedInput).

    IF vHashedInput = UserAccount.password_hash THEN DO:
        /* Successful login */
        pcToken = RUN GenerateSessionToken(pcUsername).
        plSuccess = TRUE.

        /* Create session record */
        CREATE UserSession.
        ASSIGN
            UserSession.session_token  = pcToken
            UserSession.username       = pcUsername
            UserSession.login_time     = NOW
            UserSession.expiry_time    = NOW + 28800  /* 8 hours in seconds */
            UserSession.ip_address     = REQUEST:GetClientAddress()
            UserSession.is_active      = TRUE.

        /* Reset failed attempts */
        FIND UserAccount WHERE UserAccount.username = pcUsername EXCLUSIVE-LOCK NO-ERROR.
        IF AVAILABLE UserAccount THEN
            ASSIGN UserAccount.failed_attempts = 0.

        RUN LogSuccessfulLogin(pcUsername).
    END.
    ELSE DO:
        RUN IncrementFailedAttempts(pcUsername).
        RUN LogFailedAttempt(pcUsername, "WRONG_PASSWORD").
    END.

END PROCEDURE.

PROCEDURE IncrementFailedAttempts:
    DEFINE INPUT PARAMETER pcUsername AS CHARACTER.

    FIND UserAccount WHERE UserAccount.username = pcUsername EXCLUSIVE-LOCK NO-ERROR.
    IF AVAILABLE UserAccount THEN DO:
        UserAccount.failed_attempts = UserAccount.failed_attempts + 1.
        IF UserAccount.failed_attempts >= vMaxAttempts THEN DO:
            UserAccount.is_locked    = TRUE.
            UserAccount.locked_until = NOW + 1800.  /* Lock for 30 minutes */
            RUN NotifyAdminOfLockout(pcUsername).
        END.
    END.
END PROCEDURE.

PROCEDURE ValidateSession:
    DEFINE INPUT  PARAMETER pcToken    AS CHARACTER.
    DEFINE OUTPUT PARAMETER plValid    AS LOGICAL.
    DEFINE OUTPUT PARAMETER pcUsername AS CHARACTER.

    plValid    = FALSE.
    pcUsername = "".

    FIND UserSession WHERE
        UserSession.session_token = pcToken AND
        UserSession.is_active     = TRUE
        NO-LOCK NO-ERROR.

    IF AVAILABLE UserSession THEN DO:
        IF UserSession.expiry_time > NOW THEN DO:
            plValid    = TRUE.
            pcUsername = UserSession.username.
        END.
        ELSE DO:
            /* Expire the session */
            FIND UserSession WHERE UserSession.session_token = pcToken EXCLUSIVE-LOCK NO-ERROR.
            IF AVAILABLE UserSession THEN
                UserSession.is_active = FALSE.
        END.
    END.

END PROCEDURE.

PROCEDURE LogoutUser:
    DEFINE INPUT PARAMETER pcToken AS CHARACTER.

    FIND UserSession WHERE UserSession.session_token = pcToken EXCLUSIVE-LOCK NO-ERROR.
    IF AVAILABLE UserSession THEN DO:
        ASSIGN
            UserSession.is_active  = FALSE
            UserSession.logout_time = NOW.
    END.
END PROCEDURE.
