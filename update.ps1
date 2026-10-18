# PowerShell version of update.sh: pull the root repo, then each project pulls its own
# branch (sonare-*\update*.ps1), installs what changed and is started.
#
#   dev   Piped, the backend and the web app for development (.\run.ps1 all)
#   prod  this machine's part of production: Piped, published through Tailscale Funnel when
#         that is set up (sonare-piped-backend\funnel.ps1). The backend and the web app run
#         on Render, which deploys from GitHub; --be also runs the backend here, compiled.

$ScriptDir = $PSScriptRoot
Push-Location $ScriptDir
try {

function Show-Usage {
    Write-Host "Usage: .\update.ps1 [dev|prod] [--be]"
    Write-Host ""
    Write-Host "  dev (default)  Pull everything, then Piped, backend and web app (.\run.ps1 all)"
    Write-Host "  prod           Pull everything, then Piped (+ Funnel); the backend and web run on Render"
    Write-Host "  --be           prod: also build and run the backend on this machine"
    Write-Host ""
    Write-Host "Each project refuses to pull over uncommitted changes."
    exit 1
}

$Mode = 'dev'
$Be = $false
foreach ($a in $args) {
    switch ("$a") {
        { $_ -in 'dev', 'prod' } { $Mode = $_ }
        '--be' { $Be = $true }
        default { Show-Usage }
    }
}
if ($Be -and $Mode -ne 'prod') { Show-Usage }

function Invoke-Step([string]$Title, [scriptblock]$Block) {
    Write-Host ""
    Write-Host "############################################################"
    Write-Host "# $Title"
    Write-Host "############################################################"
    & $Block
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# Submodule pointers move as the projects get new commits; only real changes block a pull.
if (git status --porcelain --untracked-files=no --ignore-submodules=all) {
    Write-Host "Uncommitted changes in the root repo - commit or stash them before updating:"
    git status --short --untracked-files=no --ignore-submodules=all
    exit 1
}
Write-Host "=== Pulling the root repo ($(git rev-parse --abbrev-ref HEAD)) ==="
git pull --ff-only
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Mode -eq 'dev') {
    Invoke-Step 'Piped backend' { & .\sonare-piped-backend\updatePiped.ps1 --no-run }
    Invoke-Step 'Sonare backend' { & .\sonare-backend\updateBE.ps1 dev --no-run }
    Invoke-Step 'Frontend' { & .\sonare-frontend\updateFE.ps1 web dev --no-run }
    Invoke-Step 'Starting everything' { & .\run.ps1 all }
    exit 0
}

Invoke-Step 'Piped backend' { & .\sonare-piped-backend\updatePiped.ps1 }
if ($Be) {
    Invoke-Step 'Sonare backend' { & .\sonare-backend\updateBE.ps1 prod }
    exit 0
}
Write-Host ""
Write-Host "Piped is up. The backend and the web app deploy on Render from GitHub: push to update them."

} finally {
    Pop-Location
}
