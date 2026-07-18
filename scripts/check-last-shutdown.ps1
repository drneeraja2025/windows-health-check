# Runs at every logon. If the previous shutdown was unexpected (Event ID 6008),
# records the event plus the last few heartbeats leading up to it, so we have
# power/battery/CPU context even though no crash dump gets written.
. "$PSScriptRoot\_config.ps1"

$summaryFile = Join-Path $LogDir 'crash-summary.log'
$heartbeatFile = Join-Path $LogDir 'heartbeat.log'
$stateFile = Join-Path $LogDir '.last-checked-6008.txt'

$event = Get-WinEvent -FilterHashtable @{LogName = 'System'; Id = 6008 } -MaxEvents 1 -ErrorAction SilentlyContinue
if (-not $event) { exit 0 }

$eventKey = $event.TimeCreated.Ticks.ToString()
$lastChecked = if (Test-Path $stateFile) { (Get-Content $stateFile -Raw).Trim() } else { '' }
if ($eventKey -eq $lastChecked) { exit 0 }  # already recorded this crash

Add-Content -Path $summaryFile -Value "=== Unexpected shutdown detected (boot logged $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) ==="
Add-Content -Path $summaryFile -Value $event.Message

if (Test-Path $heartbeatFile) {
    Add-Content -Path $summaryFile -Value '--- Last 5 heartbeats before this crash ---'
    Get-Content $heartbeatFile -Tail 5 | Add-Content -Path $summaryFile
}
else {
    Add-Content -Path $summaryFile -Value '(no heartbeat history yet)'
}
Add-Content -Path $summaryFile -Value ''

Set-Content -Path $stateFile -Value $eventKey
