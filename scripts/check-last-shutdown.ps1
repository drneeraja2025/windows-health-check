# If the previous shutdown was unexpected (Event ID 6008), record the event plus
# heartbeats, power transitions, and any logging gap before the crash.
. "$PSScriptRoot\_config.ps1"

$summaryFile = Join-Path $LogDir 'crash-summary.log'
$heartbeatFile = Join-Path $LogDir 'heartbeat.log'
$powerLog = Join-Path $LogDir 'power-events.log'
$stateFile = Join-Path $LogDir '.last-checked-6008.txt'

$event = Get-WinEvent -FilterHashtable @{LogName = 'System'; Id = 6008 } -MaxEvents 1 -ErrorAction SilentlyContinue
if (-not $event) { exit 0 }

$eventKey = $event.TimeCreated.Ticks.ToString()
$lastChecked = if (Test-Path $stateFile) { (Get-Content $stateFile -Raw).Trim() } else { '' }
if ($eventKey -eq $lastChecked) { exit 0 }

Add-Content -Path $summaryFile -Value "=== Unexpected shutdown detected (boot logged $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) ==="
Add-Content -Path $summaryFile -Value $event.Message

# Parse shutdown time from the event message when possible.
$shutdownTime = $null
if ($event.Message -match 'shutdown at (.+?) on') {
    $raw = $Matches[1].Trim()
    try { $shutdownTime = [datetime]::Parse($raw) } catch { }
}

if (Test-Path $heartbeatFile) {
    Add-Content -Path $summaryFile -Value '--- Last 10 heartbeats before this crash ---'
    Get-Content $heartbeatFile -Tail 10 | Add-Content -Path $summaryFile

    $lastHbLine = (Get-Content $heartbeatFile -Tail 1)
    if ($lastHbLine -match '^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
        $lastHbTime = [datetime]::Parse($Matches[1])
        $gapMin = [math]::Round(((Get-Date) - $lastHbTime).TotalMinutes, 1)
        Add-Content -Path $summaryFile -Value "--- Heartbeat gap: last sample $lastHbTime ($gapMin min before boot check) ---"
        if ($gapMin -gt 10) {
            Add-Content -Path $summaryFile -Value 'WARNING: logger gap > 10 min — laptop may have been off/asleep or task stopped.'
        }
    }
}
else {
    Add-Content -Path $summaryFile -Value '(no heartbeat history yet)'
}

if (Test-Path $powerLog) {
    Add-Content -Path $summaryFile -Value '--- Last 10 power events (plug/unplug) ---'
    Get-Content $powerLog -Tail 10 | Add-Content -Path $summaryFile
}
else {
    Add-Content -Path $summaryFile -Value '(no power-event history yet)'
}

Add-Content -Path $summaryFile -Value ''

Set-Content -Path $stateFile -Value $eventKey
