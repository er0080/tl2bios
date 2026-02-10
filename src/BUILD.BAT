@ECHO OFF
REM BUILD.BAT - Build all Port FFEA test utilities
REM Requires TASM and TLINK in PATH

ECHO ========================================
ECHO Building Port FFEA Test Utilities
ECHO ========================================

REM Clean up old files
IF EXIST *.OBJ DEL *.OBJ
IF EXIST *.COM DEL *.COM
IF EXIST *.SYS DEL *.SYS
IF EXIST *.MAP DEL *.MAP

REM Build PORTREAD.COM
ECHO Building PORTREAD.COM...
TASM PORTREAD.ASM
IF ERRORLEVEL 1 GOTO error_portread
TLINK /T PORTREAD.OBJ
IF ERRORLEVEL 1 GOTO error_portread
ECHO   SUCCESS: PORTREAD.COM created

REM Build TESTROM.COM
ECHO Building TESTROM.COM...
TASM TESTROM.ASM
IF ERRORLEVEL 1 GOTO error_testrom
TLINK /T TESTROM.OBJ
IF ERRORLEVEL 1 GOTO error_testrom
ECHO   SUCCESS: TESTROM.COM created

REM Build DIAGNOSE.COM
ECHO Building DIAGNOSE.COM...
TASM DIAGNOSE.ASM
IF ERRORLEVEL 1 GOTO error_diagnose
TLINK /T DIAGNOSE.OBJ
IF ERRORLEVEL 1 GOTO error_diagnose
ECHO   SUCCESS: DIAGNOSE.COM created

REM Build TESTBITS.COM
ECHO Building TESTBITS.COM...
TASM TESTBITS.ASM
IF ERRORLEVEL 1 GOTO error_testbits
TLINK /T TESTBITS.OBJ
IF ERRORLEVEL 1 GOTO error_testbits
ECHO   SUCCESS: TESTBITS.COM created

REM Build TESTPAT.COM
ECHO Building TESTPAT.COM...
TASM TESTPAT.ASM
IF ERRORLEVEL 1 GOTO error_testpat
TLINK /T TESTPAT.OBJ
IF ERRORLEVEL 1 GOTO error_testpat
ECHO   SUCCESS: TESTPAT.COM created

REM Build NOROM.SYS
ECHO Building NOROM.SYS...
TASM NOROM.ASM
IF ERRORLEVEL 1 GOTO error_norom
TLINK /T NOROM.OBJ
IF ERRORLEVEL 1 GOTO error_norom
REN NOROM.COM NOROM.SYS
ECHO   SUCCESS: NOROM.SYS created

REM Build NOROMBITS.SYS
ECHO Building NOROMBITS.SYS...
TASM NOROMBITS.ASM
IF ERRORLEVEL 1 GOTO error_norombits
TLINK /T NOROMBITS.OBJ
IF ERRORLEVEL 1 GOTO error_norombits
REN NOROMBITS.COM NOROMBITS.SYS
ECHO   SUCCESS: NOROMBITS.SYS created

REM Clean up intermediate files
DEL *.OBJ >NUL 2>&1
DEL *.MAP >NUL 2>&1

ECHO ========================================
ECHO Build Complete!
ECHO ========================================
ECHO Created files:
DIR /B *.COM *.SYS
ECHO Ready to test on Tandy 1000 TL/2
GOTO end

:error_portread
ECHO ERROR: Failed to build PORTREAD.COM
GOTO end

:error_testrom
ECHO ERROR: Failed to build TESTROM.COM
GOTO end

:error_diagnose
ECHO ERROR: Failed to build DIAGNOSE.COM
GOTO end

:error_testbits
ECHO ERROR: Failed to build TESTBITS.COM
GOTO end

:error_testpat
ECHO ERROR: Failed to build TESTPAT.COM
GOTO end

:error_norom
ECHO ERROR: Failed to build NOROM.SYS
GOTO end

:error_norombits
ECHO ERROR: Failed to build NOROMBITS.SYS
GOTO end

:end
