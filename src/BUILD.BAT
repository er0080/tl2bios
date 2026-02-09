@ECHO OFF
REM BUILD.BAT - Build all Port FFEA test utilities
REM Requires TASM and TLINK in PATH

ECHO ========================================
ECHO Building Port FFEA Test Utilities
ECHO ========================================
ECHO.

REM Clean up old files
IF EXIST *.OBJ DEL *.OBJ
IF EXIST *.COM DEL *.COM
IF EXIST *.MAP DEL *.MAP

REM Build PORTREAD.COM
ECHO Building PORTREAD.COM...
TASM PORTREAD.ASM
IF ERRORLEVEL 1 GOTO error_portread
TLINK /T PORTREAD.OBJ
IF ERRORLEVEL 1 GOTO error_portread
ECHO   SUCCESS: PORTREAD.COM created
ECHO.

REM Build TESTROM.COM
ECHO Building TESTROM.COM...
TASM TESTROM.ASM
IF ERRORLEVEL 1 GOTO error_testrom
TLINK /T TESTROM.OBJ
IF ERRORLEVEL 1 GOTO error_testrom
ECHO   SUCCESS: TESTROM.COM created
ECHO.

REM Clean up intermediate files
DEL *.OBJ >NUL 2>&1
DEL *.MAP >NUL 2>&1

ECHO ========================================
ECHO Build Complete!
ECHO ========================================
ECHO.
ECHO Created files:
DIR /B *.COM
ECHO.
ECHO Ready to test on Tandy 1000 TL/2
GOTO end

:error_portread
ECHO.
ECHO ERROR: Failed to build PORTREAD.COM
GOTO end

:error_testrom
ECHO.
ECHO ERROR: Failed to build TESTROM.COM
GOTO end

:end
