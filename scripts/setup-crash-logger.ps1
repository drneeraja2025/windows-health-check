# No admin required — registers one lightweight task under the current user.
# Each run first checks for a new unexpected shutdown (Event ID 6008), then
# records a heartbeat. Runs every 2 minutes, so a crash is detected within
# ~2 minutes of the next logon.
#
# Uses a VBScript launcher (wscript //B) instead of a .bat/cmd wrapper so
# nothing ever flashes on screen — a cmd window can briefly appear every
# 2 minutes otherwise, which is disruptive during normal use.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_config.ps1"

$setupLog = Join-Path $LogDir 'crash-logger-setup.log'
function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content $setupLog $line
    Write-Host $msg
}

$vbs = Join-Path $PSScriptRoot 'heartbeat-silent.vbs'
if (-not (Test-Path $vbs)) { throw "Missing: $vbs" }

Log 'Registering crash logger task...'
cmd /c "schtasks /Delete /TN WinHealth-Heartbeat /F >nul 2>&1"
cmd /c "schtasks /Delete /TN WinHealth-BootCheck /F >nul 2>&1"
schtasks /Create /TN 'WinHealth-Heartbeat' /TR "wscript.exe //B `"$vbs`"" /SC MINUTE /MO 2 /F
if ($LASTEXITCODE -ne 0) { throw "Failed to create WinHealth-Heartbeat (exit $LASTEXITCODE)" }
Log 'Created WinHealth-Heartbeat (crash-check + heartbeat every 2 minutes, silent)'

# schtasks defaults to "stop/disallow on battery" — disable that, since battery-power
# crashes are exactly what this logger needs to catch. Also mark Hidden so it never
# shows in the visible task tray/notifications.
$task = Get-ScheduledTask -TaskName 'WinHealth-Heartbeat'
$settings = $task.Settings
$settings.DisallowStartIfOnBatteries = $false
$settings.StopIfGoingOnBatteries = $false
$settings.Hidden = $true
Set-ScheduledTask -TaskName 'WinHealth-Heartbeat' -Settings $settings | Out-Null
Log 'Disabled battery-power restrictions on WinHealth-Heartbeat, marked hidden'

Log 'Running now to verify...'
& (Join-Path $PSScriptRoot 'check-last-shutdown.ps1')
& (Join-Path $PSScriptRoot 'heartbeat.ps1')

Log 'CRASH_LOGGER_SETUP_COMPLETE'
