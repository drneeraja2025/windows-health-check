# Shared toast helper for WinHealth alerts (silent — no console).
function Show-HealthToast {
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$Body,
        [string]$Tag = 'WinHealthAlert',
        [ValidateSet('urgent', 'reminder')]
        [string]$Scenario = 'reminder',
        [switch]$LoopAlarm
    )

    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $titleEsc = [System.Security.SecurityElement]::Escape($Title)
        $bodyEsc = [System.Security.SecurityElement]::Escape($Body)
        $audio = if ($LoopAlarm) {
            '<audio src="ms-winsoundevent:Notification.Looping.Alarm2" loop="true"/>'
        }
        else {
            '<audio src="ms-winsoundevent:Notification.Default"/>'
        }

        $xmlText = @"
<toast scenario="$Scenario">
  <visual>
    <binding template="ToastGeneric">
      <text>$titleEsc</text>
      <text>$bodyEsc</text>
    </binding>
  </visual>
  $audio
</toast>
"@
        $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xmlDoc.LoadXml($xmlText)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $xmlDoc
        $toast.Tag = $Tag
        $toast.Group = 'WindowsHealthCheck'

        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        return $true
    }
    catch {
        return $false
    }
}
