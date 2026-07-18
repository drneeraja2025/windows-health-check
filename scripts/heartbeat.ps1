# Lightweight heartbeat: appends one line with AC/battery/CPU state.
# Runs every 2 minutes via scheduled task. Since hard power-loss crashes leave
# no BSOD/minidump, this gives us the last known state right before a crash.
. "$PSScriptRoot\_config.ps1"

$logFile = Join-Path $LogDir 'heartbeat.log'

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
$power = [System.Windows.Forms.SystemInformation]::PowerStatus
$ac = $power.PowerLineStatus
$batteryPct = [math]::Round($power.BatteryLifePercent * 100, 0)
$cpuLoad = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average

$line = "{0:yyyy-MM-dd HH:mm:ss} | AC={1} | Battery={2}% | CPU={3}%" -f (Get-Date), $ac, $batteryPct, $cpuLoad
Add-Content -Path $logFile -Value $line

# Keep the log lightweight — trim once it passes ~512KB
if ((Test-Path $logFile) -and (Get-Item $logFile).Length -gt 512KB) {
    $tail = Get-Content $logFile -Tail 3000
    Set-Content -Path $logFile -Value $tail
}
