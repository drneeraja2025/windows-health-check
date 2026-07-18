@echo off
title Windows Health Check - Cleanup
echo.
echo ============================================
echo   Cleanup old task names - ADMIN REQUIRED
echo ============================================
echo.
echo This removes the old CursorHealth-* scheduled tasks
echo and re-registers them as WinHealth-SFC-Weekly and
echo WinHealth-Full-Monthly (same schedule, no scan runs now).
echo.
echo A UAC prompt will appear. Click YES to continue.
echo.
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0scripts\cleanup-legacy-tasks.ps1\"'"
echo.
if exist "%LOCALAPPDATA%\WindowsHealthCheck\logs\setup-log.txt" (
    echo --- Setup Log (last lines) ---
    powershell -NoProfile -Command "Get-Content '%LOCALAPPDATA%\WindowsHealthCheck\logs\setup-log.txt' -Tail 10"
) else (
    echo Cleanup did not run. UAC was declined or timed out.
)
echo.
pause
