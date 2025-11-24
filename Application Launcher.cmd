@echo off
set FN="""%~f0"""
set FN=%FN:'=''%
>nul 2>&1 net session
if %errorlevel% neq 0 (
    echo Restart with administrator privileges...
    powershell -nop -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"%FN%\"' -verb runas" >nul 2>&1
    exit
)
setlocal

REM Get the full path to this script's directory
set "SCRIPT_DIR=%~dp0"

REM Remove any trailing backslash
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Run PowerShell script with full quoted path
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\ApplicationLuncher.ps1"

endlocal
exit
