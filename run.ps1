# PowerShell version of run.sh. Each project owns its own run script; this opens each one
# in its own window so the three logs stay readable side by side instead of interleaved.
#
# Piped starts first and is waited on, because the backend's catalog and streaming
# are useless without it and the failure is confusing if it comes later.
#
# This script itself is the "launcher window": it stays in the foreground after
# starting things, and Ctrl+C tears everything back down - the Piped docker stack
# plus the backend/frontend dev servers running in their own windows - so nothing
# is left running detached in the background. (Closing the window with its X button
# skips that: PowerShell gets no chance to clean up. Use Ctrl+C.)

$ScriptDir = $PSScriptRoot
$OnWindows = $env:OS -eq 'Windows_NT'

function Show-Usage {
    Write-Host "Usage: .\run.ps1 [all|piped|be|fe] [--here] [--fe=web|mobile|linux]"
    Write-Host ""
    Write-Host "  all     Piped, backend and frontend, each in its own window (default)"
    Write-Host "  piped   Piped backend only (docker)"
    Write-Host "  be      Sonare backend only"
    Write-Host "  fe      Frontend only (desktop/web)"
    Write-Host ""
    Write-Host "  --here           Run in this window instead of opening new ones."
    Write-Host "                   Only valid with a single target."
    Write-Host ""
    Write-Host "  --fe=<target>    FE to build: web (default), mobile, or linux."
    Write-Host ""
    Write-Host "Ports: piped 8090, proxy 8091, backend 3010 (see .env), vite 5183 (web) / 5184 (linux)."
    Write-Host "The web and linux frontends use different ports, so both can run at once."
    Write-Host ""
    Write-Host "Ctrl+C in this window stops everything it started: the Piped docker"
    Write-Host "stack and the backend/frontend dev servers."
    exit 1
}

$Target = 'all'
$Here = $false
$FE = 'web'
foreach ($arg in $args) {
    $arg = "$arg"
    if ($arg -in 'all', 'piped', 'be', 'fe') { $Target = $arg }
    elseif ($arg -eq '--here') { $Here = $true }
    elseif ($arg -like '--fe=*') { $FE = $arg.Substring('--fe='.Length) }
    else { Show-Usage }
}

if ($Here -and $Target -eq 'all') {
    Write-Host "--here needs a single target, e.g. .\run.ps1 be --here"
    exit 1
}

# The PowerShell running this script, so the windows below use the same one.
$Shell = (Get-Process -Id $PID).Path

# Opens a new window running $Command in $Dir. It stays open after the command exits so a
# crash is readable rather than taking its window with it. Returns the window's process,
# which cleanup kills along with everything under it. Off Windows there is no console
# window to open, so it runs in the background with its output in a log file.
function Open-Window($Title, $Dir, $Command) {
    $q = { param($s) "'" + ($s -replace "'", "''") + "'" }
    $inner = "`$Host.UI.RawUI.WindowTitle = $(& $q $Title); Set-Location -LiteralPath $(& $q $Dir); $Command; " +
        "Write-Host ''; Write-Host $(& $q "[$Title exited]")"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
    if ($OnWindows) {
        Start-Process -FilePath $Shell -WorkingDirectory $Dir -PassThru -ArgumentList `
            '-NoLogo', '-NoExit', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encoded
    } else {
        $log = Join-Path ([IO.Path]::GetTempPath()) "sonare-$Title.log"
        Write-Host "No console windows here - running '$Title' in the background."
        Write-Host "  Logs: $log"
        Start-Process -FilePath $Shell -WorkingDirectory $Dir -PassThru -ArgumentList '-NoLogo', '-EncodedCommand', $encoded `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    }
}

# Kills a window started above, with everything running in it.
function Stop-Tree($Proc) {
    if (-not $Proc -or $Proc.HasExited) { return }
    if ($OnWindows) {
        taskkill /PID $Proc.Id /T /F *> $null
    } else {
        pkill -TERM -P $Proc.Id 2>$null
        Start-Sleep -Seconds 1
        Stop-Process -Id $Proc.Id -Force -ErrorAction SilentlyContinue
    }
}

# --- graceful shutdown ---------------------------------------------------
# Unlike run.sh this gets each window's process straight from Start-Process, so
# shutdown kills those process trees. Piped is docker, so "shutting it down" is
# just `runPiped.ps1 down`.
$StartedPiped = $false
$BackendWindow = $null
$FrontendWindow = $null

function Stop-All {
    Write-Host ""
    Write-Host "=== Shutting down ==="

    if ($FrontendWindow) {
        Write-Host "Stopping frontend..."
        Stop-Tree $FrontendWindow
    }

    if ($BackendWindow) {
        Write-Host "Stopping backend..."
        Stop-Tree $BackendWindow
    }

    if ($StartedPiped) {
        Write-Host "Stopping Piped (docker)..."
        & (Join-Path $ScriptDir 'sonare-piped-backend/runPiped.ps1') down
    }

    Write-Host "=== Done ==="
}

function Start-Piped {
    # Docker, and it detaches on its own, so run it inline and wait - the backend
    # needs it up before it is worth starting. runPiped.ps1 prints its own header.
    & (Join-Path $ScriptDir 'sonare-piped-backend/runPiped.ps1') up
    $LASTEXITCODE -eq 0
}

function Wait-Forever {
    while ($true) { Start-Sleep -Seconds 1 }
}

$BeDir = Join-Path $ScriptDir 'sonare-backend'
$FeDir = Join-Path $ScriptDir 'sonare-frontend'

if ($Here) {
    switch ($Target) {
        'be' {
            & (Join-Path $BeDir 'runBE.ps1') dev
            exit $LASTEXITCODE
        }
        'fe' {
            & (Join-Path $FeDir 'runFE.ps1') $FE
            exit $LASTEXITCODE
        }
    }
}

# Ctrl+C stops Wait-Forever, and the finally block below cleans up.
try {
    switch ($Target) {
        'piped' {
            $StartedPiped = $true
            if (-not (Start-Piped)) { exit 1 }
            Write-Host ""
            Write-Host "Piped is running at http://127.0.0.1:8090."
            Write-Host "Press Ctrl+C to stop it."
            Wait-Forever
        }
        'be' {
            $BackendWindow = Open-Window 'sonare-backend' $BeDir '& ./runBE.ps1 dev'
            Write-Host ""
            Write-Host "Backend starting in its own window."
            Write-Host "Press Ctrl+C to stop it."
            Wait-Forever
        }
        'fe' {
            $FrontendWindow = Open-Window 'sonare-frontend' $FeDir "& ./runFE.ps1 $FE"
            Write-Host ""
            Write-Host "Frontend starting in its own window."
            Write-Host "Press Ctrl+C to stop it."
            Wait-Forever
        }
        'all' {
            $StartedPiped = $true
            $pipedUp = Start-Piped
            if (-not $pipedUp) {
                Write-Host "Piped did not come up - starting the rest anyway."
            }
            $BackendWindow = Open-Window 'sonare-backend' $BeDir '& ./runBE.ps1 dev'
            # Give the API a moment to bind so the frontend's first calls do not fail.
            Start-Sleep -Seconds 3
            $FrontendWindow = Open-Window 'sonare-frontend' $FeDir "& ./runFE.ps1 $FE"
            Write-Host ""
            Write-Host "Started:"
            if ($pipedUp) {
                Write-Host "  piped     http://127.0.0.1:8090   (docker, this window)"
            } else {
                Write-Host "  piped     NOT RUNNING - trending, search and playback will fail (see the errors above)"
            }
            Write-Host "  backend   see the sonare-backend window"
            switch ($FE) {
                'web' { Write-Host "  frontend  http://localhost:5183   (see the sonare-frontend window)" }
                'linux' { Write-Host "  frontend  http://localhost:5184   (the Sonare window; see the sonare-frontend window)" }
                default { Write-Host "  frontend  $FE   (see the sonare-frontend window)" }
            }
            Write-Host ""
            Write-Host "Press Ctrl+C to stop everything (piped, backend, frontend)."
            Wait-Forever
        }
    }
} finally {
    Stop-All
}
