[CmdletBinding()]
param(
    [string]$MemoryRoot = 'D:\CodexSharedMemory',
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'
$GitExe = 'C:\Users\60900\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe'
if (-not (Test-Path -LiteralPath $GitExe)) { throw "Git executable not found: $GitExe" }
$mutex = [System.Threading.Mutex]::new($false, 'Local\CodexSharedMemoryGitSync')
if (-not $mutex.WaitOne(0)) { exit 0 }

try {
    $runtime = Join-Path $MemoryRoot 'sync\runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    $log = Join-Path $runtime 'sync.log'

    function Write-SyncLog([string]$Message) {
        Add-Content -LiteralPath $log -Encoding UTF8 -Value ('{0} {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $Message)
    }

    function Invoke-GitRetry([string[]]$Arguments, [int]$Attempts = 3) {
        for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
            & $GitExe -C $MemoryRoot @Arguments
            if ($LASTEXITCODE -eq 0) { return $true }
            if ($attempt -lt $Attempts) { Start-Sleep -Seconds 5 }
        }
        return $false
    }

    Get-ChildItem -LiteralPath $MemoryRoot -Recurse -File -Filter '*.json' | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
    }
    Get-ChildItem -LiteralPath $MemoryRoot -Recurse -File -Filter '*.jsonl' | ForEach-Object {
        $lineNumber = 0
        foreach ($line in Get-Content -LiteralPath $_.FullName -Encoding UTF8) {
            $lineNumber++
            if ($line.Trim()) {
                try { $line | ConvertFrom-Json | Out-Null }
                catch { throw "JSONL invalid: $($_.FullName):$lineNumber" }
            }
        }
    }

    & $GitExe -C $MemoryRoot add --all
    & $GitExe -C $MemoryRoot diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        & $GitExe -C $MemoryRoot commit -m ('memory: sync {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')) | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Local commit failed.' }
    }

    & $GitExe -C $MemoryRoot remote get-url origin | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-SyncLog 'origin is not configured; local snapshot committed only.'
        exit 0
    }

    if (-not (Invoke-GitRetry -Arguments @('fetch','origin',$Branch))) { throw 'Fetch failed after retries.' }

    & $GitExe -C $MemoryRoot rebase "origin/$Branch"
    if ($LASTEXITCODE -ne 0) {
        & $GitExe -C $MemoryRoot rebase --abort | Out-Null
        Write-SyncLog 'CONFLICT: automatic sync stopped; manual merge required.'
        exit 2
    }

    if (-not (Invoke-GitRetry -Arguments @('push','origin',$Branch))) { throw 'Push failed after retries.' }
    Write-SyncLog 'Sync completed.'
}
catch {
    $runtime = Join-Path $MemoryRoot 'sync\runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    Add-Content -LiteralPath (Join-Path $runtime 'sync.log') -Encoding UTF8 -Value ('{0} ERROR {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $_.Exception.Message)
    exit 1
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
