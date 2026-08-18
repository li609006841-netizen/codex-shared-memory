[CmdletBinding()]
param(
    [string]$MemoryRoot = 'D:\CodexSharedMemory',
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'
$mutex = [System.Threading.Mutex]::new($false, 'Local\CodexSharedMemoryGitSync')
if (-not $mutex.WaitOne(0)) { exit 0 }

try {
    $runtime = Join-Path $MemoryRoot 'sync\runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    $log = Join-Path $runtime 'sync.log'

    function Write-SyncLog([string]$Message) {
        Add-Content -LiteralPath $log -Value ('{0} {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $Message)
    }

    Get-ChildItem -LiteralPath $MemoryRoot -Recurse -File -Filter '*.json' | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json | Out-Null
    }
    Get-ChildItem -LiteralPath $MemoryRoot -Recurse -File -Filter '*.jsonl' | ForEach-Object {
        $lineNumber = 0
        foreach ($line in Get-Content -LiteralPath $_.FullName) {
            $lineNumber++
            if ($line.Trim()) {
                try { $line | ConvertFrom-Json | Out-Null }
                catch { throw "JSONL invalid: $($_.FullName):$lineNumber" }
            }
        }
    }

    git -C $MemoryRoot add --all
    git -C $MemoryRoot diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git -C $MemoryRoot commit -m ('memory: sync {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')) | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Local commit failed.' }
    }

    git -C $MemoryRoot remote get-url origin | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-SyncLog 'origin is not configured; local snapshot committed only.'
        exit 0
    }

    git -C $MemoryRoot fetch origin $Branch
    if ($LASTEXITCODE -ne 0) { throw 'Fetch failed.' }

    git -C $MemoryRoot rebase "origin/$Branch"
    if ($LASTEXITCODE -ne 0) {
        git -C $MemoryRoot rebase --abort | Out-Null
        Write-SyncLog 'CONFLICT: automatic sync stopped; manual merge required.'
        exit 2
    }

    git -C $MemoryRoot push origin $Branch
    if ($LASTEXITCODE -ne 0) { throw 'Push failed.' }
    Write-SyncLog 'Sync completed.'
}
catch {
    $runtime = Join-Path $MemoryRoot 'sync\runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    Add-Content -LiteralPath (Join-Path $runtime 'sync.log') -Value ('{0} ERROR {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $_.Exception.Message)
    exit 1
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
