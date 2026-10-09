@echo off
REM ==============================================================================
REM Necropsy Forensics Platform — Windows 1-Click Batch Installer
REM ==============================================================================

title Necropsy Installer
cd /d "%~dp0"

echo =======================================================
echo Necropsy Forensics Platform - Starting 1-Click Installer
echo =======================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Installation encountered an issue. See above output.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Press any key to exit installer...
pause >nul
