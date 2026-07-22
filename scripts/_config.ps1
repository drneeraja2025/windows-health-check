# Shared paths — works from any clone location on any Windows laptop
$Script:HealthCheckRoot = Split-Path -Parent $PSScriptRoot
$Script:LogDir = Join-Path $env:LOCALAPPDATA 'WindowsHealthCheck\logs'
New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null

# Warn (persistent toast + alarm sound) when running on battery at/below this %.
$Script:LowBatteryThreshold = 3
