# PowerShell version of install.sh. Each project owns its own install script; this just
# runs them in dependency order and reports what happened.
#
#   sonare-piped-backend  docker only  - the catalog upstream
#   sonare-backend        local node   - needs local postgres + redis
#   sonare-frontend       local node   - desktop/web and mobile

$ScriptDir = $PSScriptRoot

function Show-Usage {
    Write-Host "Usage: .\install.ps1 [all|piped|be|fe]"
    Write-Host ""
    Write-Host "  all     Install everything, in order (default)"
    Write-Host "  piped   Piped backend only (docker images)"
    Write-Host "  be      Sonare backend only (npm, .env, database migrations)"
    Write-Host "  fe      Frontend only (npm for desktop/web and mobile)"
    exit 1
}

$Target = if ($args.Count -gt 0) { "$($args[0])" } else { 'all' }

function Invoke-Step($Name, $Dir, $Script) {
    Write-Host ""
    Write-Host "############################################################"
    Write-Host "# $Name"
    Write-Host "############################################################"
    $path = Join-Path $ScriptDir "$Dir/$Script"
    if (-not (Test-Path $path)) {
        Write-Host "Missing: $Dir/$Script"
        exit 1
    }
    & $path
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

switch ($Target) {
    'all' {
        Invoke-Step "Piped backend (docker)" sonare-piped-backend installPiped.ps1
        Invoke-Step "Sonare backend"         sonare-backend       installBE.ps1
        Invoke-Step "Frontend"               sonare-frontend      installFE.ps1
    }
    'piped' { Invoke-Step "Piped backend (docker)" sonare-piped-backend installPiped.ps1 }
    'be'    { Invoke-Step "Sonare backend"         sonare-backend       installBE.ps1 }
    'fe'    { Invoke-Step "Frontend"               sonare-frontend      installFE.ps1 }
    default { Show-Usage }
}

Write-Host ""
Write-Host "############################################################"
Write-Host "Install complete. Start everything with .\run.ps1"
Write-Host "############################################################"
exit 0
