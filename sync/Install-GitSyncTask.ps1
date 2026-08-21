[CmdletBinding()]
param(
    [string]$MemoryRoot = 'D:\CodexSharedMemory',
    [int]$IntervalMinutes = 2
)

$ErrorActionPreference = 'Stop'
if ($IntervalMinutes -lt 1) { throw 'IntervalMinutes must be at least 1.' }
$script = Join-Path $MemoryRoot 'sync\Sync-SharedMemory.ps1'
$launcher = Join-Path $MemoryRoot 'sync\Run-GitSyncHidden.vbs'
if (-not (Test-Path -LiteralPath $script)) { throw "Missing sync script: $script" }
if (-not (Test-Path -LiteralPath $launcher)) { throw "Missing hidden launcher: $launcher" }

$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"{0}"' -f $launcher)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName 'Codex Shared Memory Git Sync' -Action $action -Trigger $trigger -Settings $settings -Description 'Validate, commit, pull/rebase and push Codex shared memory without a console window.' -Force | Out-Null
Write-Host "Scheduled task installed hidden: every $IntervalMinutes minute(s)."
