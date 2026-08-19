# Shared paths — works from any clone location on any Windows laptop
$Script:HealthCheckRoot = Split-Path -Parent $PSScriptRoot
$Script:LogDir = Join-Path $env:LOCALAPPDATA 'WindowsHealthCheck\logs'
New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null

# Warn (persistent toast + alarm sound) when running on battery at/below this %.
# 3% was only for the manufacturer first-run after a new battery; ongoing use = 20%.
$Script:LowBatteryThreshold = 20

# Overnight plug-in reminder: alert if still on battery during these hours (local time).
$Script:OvernightStartHour = 22   # 10:00 PM
$Script:OvernightEndHour = 7      # 7:00 AM
