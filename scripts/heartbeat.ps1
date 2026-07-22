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

# Critical low-battery warning: persistent toast + alarm sound, re-shown every
# heartbeat cycle (every 2 min) while on battery and at/below the threshold,
# so it can't be missed and the battery never drains to 0%.
if ($ac -eq 'Offline' -and $batteryPct -le $LowBatteryThreshold) {
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $xmlText = @"
<toast scenario="urgent">
  <visual>
    <binding template="ToastGeneric">
      <text>Battery Critical: $batteryPct%</text>
      <text>Plug in the charger now. Do not let it drain to 0%.</text>
    </binding>
  </visual>
  <audio src="ms-winsoundevent:Notification.Looping.Alarm2" loop="true"/>
</toast>
"@
        $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xmlDoc.LoadXml($xmlText)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xmlDoc
        $toast.Tag = 'LowBatteryWarning'
        $toast.Group = 'WindowsHealthCheck'

        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        Add-Content -Path $logFile -Value "  -> Low battery warning shown ($batteryPct%)"
    }
    catch {
        Add-Content -Path $logFile -Value "  -> WARN: failed to show low-battery toast: $_"
    }
}

# Keep the log lightweight — trim once it passes ~512KB
if ((Test-Path $logFile) -and (Get-Item $logFile).Length -gt 512KB) {
    $tail = Get-Content $logFile -Tail 3000
    Set-Content -Path $logFile -Value $tail
}
