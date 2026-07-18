# No admin required — registers one lightweight task under the current user.
# Each run first checks for a new unexpected shutdown (Event ID 6008), then
# records a heartbeat. Runs every 2 minutes, so a crash is detected within
# ~2 minutes of the next logon.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_config.ps1"

$setupLog = Join-Path $LogDir 'crash-logger-setup.log'
function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content $setupLog $line
    Write-Host $msg
}

$heartbeatBat = Join-Path $HealthCheckRoot 'run-heartbeat-task.bat'

Log 'Registering crash logger task...'
cmd /c "schtasks /Delete /TN WinHealth-Heartbeat /F >nul 2>&1"
cmd /c "schtasks /Delete /TN WinHealth-BootCheck /F >nul 2>&1"
schtasks /Create /TN 'WinHealth-Heartbeat' /TR $heartbeatBat /SC MINUTE /MO 2 /F
if ($LASTEXITCODE -ne 0) { throw "Failed to create WinHealth-Heartbeat (exit $LASTEXITCODE)" }
Log 'Created WinHealth-Heartbeat (crash-check + heartbeat every 2 minutes)'

Log 'Running now to verify...'
& (Join-Path $PSScriptRoot 'check-last-shutdown.ps1')
& (Join-Path $PSScriptRoot 'heartbeat.ps1')

Log 'CRASH_LOGGER_SETUP_COMPLETE'
