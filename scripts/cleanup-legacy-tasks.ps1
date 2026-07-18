# One-time cleanup: removes legacy "CursorHealth-*" tasks (pre-dating this repo)
# and (re)registers the "WinHealth-*" tasks that ship with this repo, without
# forcing an immediate SFC run. Run as Administrator.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_config.ps1"

$setupLog = Join-Path $LogDir 'setup-log.txt'
function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content $setupLog $line
    Write-Host $msg
}

try {
    Log 'Cleanup started (admin)'
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Not running as Administrator'
    }

    foreach ($legacy in 'CursorHealth-SFC-Weekly', 'CursorHealth-Full-Monthly') {
        cmd /c "schtasks /Delete /TN `"$legacy`" /F >nul 2>&1"
        Log "Removed legacy task: $legacy"
    }

    $sfcBat = Join-Path $HealthCheckRoot 'run-sfc-task.bat'
    $fullBat = Join-Path $HealthCheckRoot 'run-full-repair-task.bat'

    cmd /c "schtasks /Delete /TN WinHealth-SFC-Weekly /F >nul 2>&1"
    schtasks /Create /TN 'WinHealth-SFC-Weekly' /TR $sfcBat /SC WEEKLY /D SUN /ST 03:00 /RL HIGHEST /F
    if ($LASTEXITCODE -ne 0) { throw "Failed to create WinHealth-SFC-Weekly (exit $LASTEXITCODE)" }
    Log 'Created WinHealth-SFC-Weekly (Sundays 3:00 AM)'

    cmd /c "schtasks /Delete /TN WinHealth-Full-Monthly /F >nul 2>&1"
    schtasks /Create /TN 'WinHealth-Full-Monthly' /TR $fullBat /SC MONTHLY /D 1 /ST 03:30 /RL HIGHEST /F
    if ($LASTEXITCODE -ne 0) { throw "Failed to create WinHealth-Full-Monthly (exit $LASTEXITCODE)" }
    Log 'Created WinHealth-Full-Monthly (1st of month 3:30 AM)'

    schtasks /Query /TN 'WinHealth-SFC-Weekly' /FO LIST /V | Out-File (Join-Path $LogDir 'tasks-status.txt')
    schtasks /Query /TN 'WinHealth-Full-Monthly' /FO LIST /V | Out-File (Join-Path $LogDir 'tasks-status.txt') -Append
    Log 'CLEANUP_COMPLETE'
}
catch {
    Log "ERROR: $_"
    exit 1
}
