/* string_utils.p - General Utility Procedures for String and Date Operations */

DEFINE VARIABLE vDateFormat AS CHARACTER INITIAL "99/99/9999" NO-UNDO.

PROCEDURE TrimAndUppercase:
    DEFINE INPUT  PARAMETER pcInput  AS CHARACTER.
    DEFINE OUTPUT PARAMETER pcOutput AS CHARACTER.
    pcOutput = TRIM(CAPS(pcInput)).
END PROCEDURE.

PROCEDURE PadLeft:
    DEFINE INPUT  PARAMETER pcInput   AS CHARACTER.
    DEFINE INPUT  PARAMETER piLength  AS INTEGER.
    DEFINE INPUT  PARAMETER pcPadChar AS CHARACTER.
    DEFINE OUTPUT PARAMETER pcOutput  AS CHARACTER.

    pcOutput = pcInput.
    DO WHILE LENGTH(pcOutput) < piLength:
        pcOutput = pcPadChar + pcOutput.
    END.
END PROCEDURE.

PROCEDURE FormatCurrency:
    DEFINE INPUT  PARAMETER pdAmount  AS DECIMAL.
    DEFINE INPUT  PARAMETER pcSymbol  AS CHARACTER.
    DEFINE OUTPUT PARAMETER pcFormatted AS CHARACTER.
    pcFormatted = pcSymbol + STRING(pdAmount, ">>>,>>9.99").
END PROCEDURE.

PROCEDURE GetCurrentTimestamp:
    DEFINE OUTPUT PARAMETER pcTimestamp AS CHARACTER.
    pcTimestamp = STRING(TODAY) + " " + STRING(TIME, "HH:MM:SS").
END PROCEDURE.

PROCEDURE IsValidEmail:
    DEFINE INPUT  PARAMETER pcEmail   AS CHARACTER.
    DEFINE OUTPUT PARAMETER plValid   AS LOGICAL.
    plValid = (INDEX(pcEmail, "@") > 1) AND (INDEX(pcEmail, ".") > 2).
END PROCEDURE.

PROCEDURE SplitString:
    DEFINE INPUT  PARAMETER pcInput     AS CHARACTER.
    DEFINE INPUT  PARAMETER pcDelimiter AS CHARACTER.
    DEFINE OUTPUT PARAMETER pcPart1     AS CHARACTER.
    DEFINE OUTPUT PARAMETER pcPart2     AS CHARACTER.

    DEFINE VARIABLE vPos AS INTEGER NO-UNDO.
    vPos   = INDEX(pcInput, pcDelimiter).
    pcPart1 = SUBSTRING(pcInput, 1, vPos - 1).
    pcPart2 = SUBSTRING(pcInput, vPos + LENGTH(pcDelimiter)).
END PROCEDURE.

PROCEDURE GenerateUUID:
    DEFINE OUTPUT PARAMETER pcUUID AS CHARACTER.
    DEFINE VARIABLE vRand AS INTEGER NO-UNDO.

    /* Simple pseudo-UUID using random and timestamp */
    vRand  = RANDOM(10000, 99999).
    pcUUID = STRING(TODAY, "99999999") + "-" + STRING(TIME) + "-" + STRING(vRand).
END PROCEDURE.
