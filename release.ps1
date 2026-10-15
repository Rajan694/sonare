# PowerShell version of release.sh. Publishes a release: tags this repo's current commit and
# pushes the tag, which starts the Release workflow (.github/workflows/release.yml) that builds
# every app and attaches them to a GitHub release. The submodule pointers in that commit say
# which frontend gets built.
#
#   .\release.ps1            # bumps the patch of the latest tag: v1.1.0 -> v1.1.1
#   .\release.ps1 1.2.0      # or v1.2.0
#   .\release.ps1 -n 1.2.0   # dry run: checks and prints, tags nothing

Set-Location $PSScriptRoot

function Show-Usage {
    Write-Host 'Usage: .\release.ps1 [-n|--dry-run] [version]'
    Write-Host ''
    Write-Host '  version        1.2.0 or v1.2.0; without it the latest tag''s patch is bumped'
    Write-Host '  -n, --dry-run  Run the checks and show the commands, but tag and push nothing'
    exit 1
}

$Dry = $false
$Version = ''
foreach ($arg in $args) {
    switch -Regex ($arg) {
        '^(-n|--dry-run)$' { $Dry = $true; break }
        '^-' { Show-Usage }
        default {
            if ($Version) { Show-Usage }
            $Version = $arg -replace '^v', ''
        }
    }
}

git fetch --quiet --tags origin
if ($LASTEXITCODE -ne 0) { exit 1 }

if (-not $Version) {
    $Latest = git tag --list 'v*.*.*' --sort=-v:refname | Select-Object -First 1
    if (-not $Latest) {
        Write-Host 'No v*.*.* tag yet - pass the first version, e.g. .\release.ps1 1.0.0'
        exit 1
    }
    $Major, $Minor, $Patch = ($Latest -replace '^v', '').Split('.')
    $Version = "$Major.$Minor.$([int]$Patch + 1)"
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Versions look like 1.2.0, not $Version"
    exit 1
}
$Tag = "v$Version"

git rev-parse -q --verify "refs/tags/$Tag" | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "$Tag already exists - pick another version."
    exit 1
}

# The release builds what this commit records, so anything not committed would be left out,
# and submodule commits that aren't on GitHub would fail the workflow's checkout.
$Dirty = git status --porcelain --untracked-files=no --ignore-submodules=dirty
if ($Dirty) {
    Write-Host 'Uncommitted changes in the root repo (submodule pointers included) - commit them first:'
    git status --short --untracked-files=no --ignore-submodules=dirty
    exit 1
}
foreach ($line in (git config --file .gitmodules --get-regexp '\.path$')) {
    $Path = $line.Split(' ', 2)[1]
    if (git -C $Path status --porcelain --untracked-files=no) {
        Write-Host "Note: $Path has uncommitted changes, which this release leaves out."
    }
    $Sha = git rev-parse "HEAD:$Path"
    git -C $Path fetch --quiet origin
    $OnRemote = git -C $Path branch -r --contains $Sha 2>$null
    if (-not $OnRemote) {
        Write-Host "$Path is at $Sha, which isn't pushed - push $Path first."
        exit 1
    }
}

$Branch = git rev-parse --abbrev-ref HEAD
Write-Host "Releasing $Tag from $Branch at $(git log -1 --format='%h %s')"
git merge-base --is-ancestor HEAD origin/main 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Note: this commit isn't on origin/main yet."
}

if ($Dry) {
    Write-Host 'Dry run - would run:'
    Write-Host "  git tag $Tag && git push origin $Tag"
    exit 0
}

git tag $Tag
if ($LASTEXITCODE -ne 0) { exit 1 }
git push origin $Tag
if ($LASTEXITCODE -ne 0) {
    # A tag that didn't reach GitHub would block the next try, so it goes again.
    git tag -d $Tag | Out-Null
    exit 1
}
Write-Host ''
Write-Host "Pushed $Tag - the build runs at https://github.com/Rajan694/sonare/actions"
