# Full maintenance: DISM then SFC — monthly scheduled task (can take 30-90 min)
. "$PSScriptRoot\_config.ps1"

$logFile = Join-Path $LogDir ("full-repair-{0:yyyy-MM-dd-HHmm}.log" -f (Get-Date))
$statusFile = Join-Path $LogDir 'last-full-repair.txt'

"Full repair started at $(Get-Date)" | Tee-Object -FilePath $logFile

"--- DISM ---" | Tee-Object -FilePath $logFile -Append
DISM /Online /Cleanup-Image /RestoreHealth *>&1 | Tee-Object -FilePath $logFile -Append
$dismExit = $LASTEXITCODE
"DISM exit: $dismExit" | Tee-Object -FilePath $logFile -Append

"--- SFC ---" | Tee-Object -FilePath $logFile -Append
sfc /scannow *>&1 | Tee-Object -FilePath $logFile -Append
$sfcExit = $LASTEXITCODE
"SFC exit: $sfcExit" | Tee-Object -FilePath $logFile -Append

"Full repair finished at $(Get-Date)" | Tee-Object -FilePath $logFile -Append
"Last full repair: $(Get-Date) - DISM $dismExit, SFC $sfcExit" | Out-File $statusFile
