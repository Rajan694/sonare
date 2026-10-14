#!/bin/bash
set -e

# Publishes a release: tags this repo's current commit and pushes the tag, which starts the
# Release workflow (.github/workflows/release.yml) that builds every app and attaches them to
# a GitHub release. The submodule pointers in that commit say which frontend gets built.
#
#   ./release.sh            # bumps the patch of the latest tag: v1.1.0 -> v1.1.1
#   ./release.sh 1.2.0      # or v1.2.0
#   ./release.sh -n 1.2.0   # dry run: checks and prints, tags nothing

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: ./release.sh [-n|--dry-run] [version]"
    echo ""
    echo "  version        1.2.0 or v1.2.0; without it the latest tag's patch is bumped"
    echo "  -n, --dry-run  Run the checks and show the commands, but tag and push nothing"
    exit 1
}

DRY=0
VERSION=""
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY=1 ;;
        -h|--help) usage ;;
        -*) usage ;;
        *) [ -z "$VERSION" ] || usage; VERSION="${arg#v}" ;;
    esac
done

git fetch --quiet --tags origin

if [ -z "$VERSION" ]; then
    LATEST="$(git tag --list 'v*.*.*' --sort=-v:refname | head -n1)"
    if [ -z "$LATEST" ]; then
        echo "No v*.*.* tag yet - pass the first version, e.g. ./release.sh 1.0.0"
        exit 1
    fi
    IFS=. read -r MAJOR MINOR PATCH <<< "${LATEST#v}"
    VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
fi
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Versions look like 1.2.0, not $VERSION"
    exit 1
fi
TAG="v$VERSION"

if git rev-parse -q --verify "refs/tags/$TAG" > /dev/null; then
    echo "$TAG already exists - pick another version."
    exit 1
fi

# The release builds what this commit records, so anything not committed would be left out,
# and submodule commits that aren't on GitHub would fail the workflow's checkout.
if [ -n "$(git status --porcelain --untracked-files=no --ignore-submodules=dirty)" ]; then
    echo "Uncommitted changes in the root repo (submodule pointers included) - commit them first:"
    git status --short --untracked-files=no --ignore-submodules=dirty
    exit 1
fi
while read -r _ path; do
    if [ -n "$(git -C "$path" status --porcelain --untracked-files=no)" ]; then
        echo "Note: $path has uncommitted changes, which this release leaves out."
    fi
    sha="$(git rev-parse "HEAD:$path")"
    git -C "$path" fetch --quiet origin
    if [ -z "$(git -C "$path" branch -r --contains "$sha" 2>/dev/null)" ]; then
        echo "$path is at $sha, which isn't pushed - push $path first."
        exit 1
    fi
done < <(git config --file .gitmodules --get-regexp '\.path$')

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Releasing $TAG from $BRANCH at $(git log -1 --format='%h %s')"
if ! git merge-base --is-ancestor HEAD origin/main 2>/dev/null; then
    echo "Note: this commit isn't on origin/main yet."
fi

if [ "$DRY" = "1" ]; then
    echo "Dry run - would run:"
    echo "  git tag $TAG && git push origin $TAG"
    exit 0
fi

git tag "$TAG"
# A tag that didn't reach GitHub would block the next try, so it goes again.
git push origin "$TAG" || { git tag -d "$TAG" > /dev/null; exit 1; }
echo ""
echo "Pushed $TAG - the build runs at https://github.com/Rajan694/sonare/actions"
