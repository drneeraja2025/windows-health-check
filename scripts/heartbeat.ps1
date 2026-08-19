# Lightweight heartbeat: appends one line with AC/battery/CPU state.
# Runs every 2 minutes via scheduled task. Since hard power-loss crashes leave
# no BSOD/minidump, this gives us the last known state right before a crash.
. "$PSScriptRoot\_config.ps1"
. "$PSScriptRoot\_notify.ps1"

$logFile = Join-Path $LogDir 'heartbeat.log'
$powerLog = Join-Path $LogDir 'power-events.log'
$acStateFile = Join-Path $LogDir '.last-ac-state.txt'

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
$power = [System.Windows.Forms.SystemInformation]::PowerStatus
$ac = $power.PowerLineStatus.ToString()
$batteryPct = [math]::Round($power.BatteryLifePercent * 100, 0)
$cpuLoad = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average

$line = "{0:yyyy-MM-dd HH:mm:ss} | AC={1} | Battery={2}% | CPU={3}%" -f (Get-Date), $ac, $batteryPct, $cpuLoad
Add-Content -Path $logFile -Value $line

# Log AC plug/unplug transitions so crash analysis is not blind during gaps.
$prevAc = if (Test-Path $acStateFile) { (Get-Content $acStateFile -Raw).Trim() } else { '' }
if ($prevAc -and $prevAc -ne $ac) {
    $powerLine = "{0:yyyy-MM-dd HH:mm:ss} | AC changed: {1} -> {2} | Battery={3}% | CPU={4}%" -f (Get-Date), $prevAc, $ac, $batteryPct, $cpuLoad
    Add-Content -Path $powerLog -Value $powerLine
    Add-Content -Path $logFile -Value "  -> $powerLine"
}
Set-Content -Path $acStateFile -Value $ac

# Also pull Kernel-Power 105 events since last sync (catches transitions between heartbeats).
$powerSyncFile = Join-Path $LogDir '.last-power-event-sync.txt'
$since = if (Test-Path $powerSyncFile) {
    try { [datetime](Get-Content $powerSyncFile -Raw).Trim() } catch { (Get-Date).AddMinutes(-3) }
}
else {
    (Get-Date).AddMinutes(-3)
}
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    ProviderName = 'Microsoft-Windows-Kernel-Power'
    Id = 105
    StartTime = $since
} -ErrorAction SilentlyContinue | ForEach-Object {
    $kernelLine = "{0:yyyy-MM-dd HH:mm:ss} | Kernel-Power 105 (system) | AC={1} | Battery={2}% | CPU={3}%" -f $_.TimeCreated, $ac, $batteryPct, $cpuLoad
    Add-Content -Path $powerLog -Value $kernelLine
}
Set-Content -Path $powerSyncFile -Value ((Get-Date).ToString('o'))

# Critical low-battery warning at/below threshold.
if ($ac -eq 'Offline' -and $batteryPct -le $LowBatteryThreshold) {
    $shown = Show-HealthToast -Title "Battery Critical: $batteryPct%" `
        -Body 'Plug in the charger now. Do not let it drain to 0%.' `
        -Tag 'LowBatteryWarning' -Scenario urgent -LoopAlarm
    if ($shown) {
        Add-Content -Path $logFile -Value "  -> Low battery warning shown ($batteryPct%)"
    }
    else {
        Add-Content -Path $logFile -Value "  -> WARN: failed to show low-battery toast"
    }
}

# Overnight reminder: still on battery during sleep hours — prevents overnight drain.
$hour = (Get-Date).Hour
$isOvernight = ($hour -ge $OvernightStartHour) -or ($hour -lt $OvernightEndHour)
if ($isOvernight -and $ac -eq 'Offline') {
    $urgentOvernight = $batteryPct -le 30
    $shown = Show-HealthToast -Title "Still on battery ($batteryPct%)" `
        -Body 'Plug in before sleep — unplugged overnight can drain the battery to 0%.' `
        -Tag 'OvernightBatteryWarning' `
        -Scenario $(if ($urgentOvernight) { 'urgent' } else { 'reminder' }) `
        -LoopAlarm:$urgentOvernight
    if ($shown) {
        Add-Content -Path $logFile -Value "  -> Overnight on-battery warning shown ($batteryPct%)"
    }
}

# Keep logs lightweight — trim once they pass ~512KB
foreach ($file in @($logFile, $powerLog)) {
    if ((Test-Path $file) -and (Get-Item $file).Length -gt 512KB) {
        $tail = Get-Content $file -Tail 3000
        Set-Content -Path $file -Value $tail
    }
}
