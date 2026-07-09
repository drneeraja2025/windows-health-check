@echo off
title Windows Health Check Setup
echo.
echo ============================================
echo   Windows Health Check - ADMIN REQUIRED
echo ============================================
echo.
echo Clone location: %~dp0
echo Logs go to:     %LOCALAPPDATA%\WindowsHealthCheck\logs
echo.
echo A UAC prompt will appear. Click YES to continue.
echo.
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show('Click YES on the UAC prompt to register weekly/monthly health tasks and run SFC now.','Windows Health Check','OK','Warning')"
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0scripts\setup-schedule.ps1""'"
echo.
if exist "%LOCALAPPDATA%\WindowsHealthCheck\logs\setup-log.txt" (
    echo --- Setup Log ---
    type "%LOCALAPPDATA%\WindowsHealthCheck\logs\setup-log.txt"
) else (
    echo Setup did not run. UAC was declined or timed out.
)
echo.
pause
