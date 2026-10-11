# PowerShell version of build.sh. The apps live in sonare-frontend, which owns the actual
# build (buildFE.ps1); this just passes the arguments on, like install.ps1 and run.ps1 do.
#
#   .\build.ps1 <dev|prod> <android|linux|windows|web|all> [version]
#
#   .\build.ps1 prod android              # bumps the patch version: 1.0.1 -> 1.0.2
#   .\build.ps1 prod linux windows 1.2.0  # sets the version
#   .\build.ps1 dev web
#
# Builds land in sonare-frontend/dist/releases/; upload them on /admin/releases.

$BuildFE = Join-Path $PSScriptRoot 'sonare-frontend/buildFE.ps1'

if ($args.Count -eq 0 -or $args[0] -in '-h', '--help') {
    & $BuildFE --help
    exit $LASTEXITCODE
}

& $BuildFE @args
exit $LASTEXITCODE
