# Quick SFC scan — run manually or via weekly scheduled task
. "$PSScriptRoot\_config.ps1"

$logFile = Join-Path $LogDir ("sfc-{0:yyyy-MM-dd-HHmm}.log" -f (Get-Date))
$statusFile = Join-Path $LogDir 'last-sfc.txt'

"SFC started at $(Get-Date)" | Tee-Object -FilePath $logFile
sfc /scannow *>&1 | Tee-Object -FilePath $logFile -Append
$exitCode = $LASTEXITCODE
"SFC finished at $(Get-Date) - exit code $exitCode" | Tee-Object -FilePath $logFile -Append
"SFC last run: $(Get-Date) - exit $exitCode" | Out-File $statusFile
