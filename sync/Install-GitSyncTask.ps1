[CmdletBinding()]
param(
    [string]$MemoryRoot = 'D:\CodexSharedMemory',
    [int]$IntervalMinutes = 2
)

$ErrorActionPreference = 'Stop'
if ($IntervalMinutes -lt 1) { throw 'IntervalMinutes must be at least 1.' }
$script = Join-Path $MemoryRoot 'sync\Sync-SharedMemory.ps1'
if (-not (Test-Path -LiteralPath $script)) { throw "Missing sync script: $script" }

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $script)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName 'Codex Shared Memory Git Sync' -Action $action -Trigger $trigger -Settings $settings -Description 'Validate, commit, pull/rebase and push Codex shared memory.' -Force | Out-Null
Write-Host "Scheduled task installed: every $IntervalMinutes minute(s)."
