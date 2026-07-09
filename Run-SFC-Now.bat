@echo off
title SFC Scan
echo Running SFC scan (10-20 minutes). Admin required.
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0scripts\run-sfc.ps1""'"
if exist "%LOCALAPPDATA%\WindowsHealthCheck\logs\last-sfc.txt" type "%LOCALAPPDATA%\WindowsHealthCheck\logs\last-sfc.txt"
pause
