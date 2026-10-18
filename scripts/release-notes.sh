#!/bin/bash
set -e

# Prints a release's notes (Markdown) for the GitHub release body, which the apps show under
# Settings -> About -> "What's new" (shared/releaseNotes.ts reads it).
#
#   scripts/release-notes.sh v1.3.0            # since the tag before it
#   scripts/release-notes.sh v1.3.0 v1.1.0     # since a given tag
#
# docs/release-notes/v1.3.0.md, when there is one, is used as written. Otherwise the notes are
# the feat/fix/perf commit subjects of the frontend and backend between the two tags' submodule
# pointers (docs, chore, test, refactor, ci and build commits are left out).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

TAG="$1"
PREV="$2"
[ -n "$TAG" ] || { echo "Usage: scripts/release-notes.sh <tag> [previous tag]" >&2; exit 1; }

if [ -f "docs/release-notes/$TAG.md" ]; then
    cat "docs/release-notes/$TAG.md"
    exit 0
fi

if [ -z "$PREV" ]; then
    PREV="$(git tag --list 'v*.*.*' --sort=-v:refname | grep -Fxv "$TAG" |
        while read -r t; do
            if [ "$(printf '%s\n%s\n' "${t#v}" "${TAG#v}" | sort -V | head -1)" = "${t#v}" ]; then
                echo "$t"
                break
            fi
        done)"
fi

# "feat(mobile): a thing" -> "A thing (Android)"; nothing for kinds users don't see.
line() {
    local subject="$1" kind scope text
    [[ "$subject" =~ ^([a-z]+)(\(([^\)]*)\))?!?:\ (.*)$ ]] || return 0
    kind="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[3]}"
    text="${BASH_REMATCH[4]}"
    case "$scope" in
        mobile|android) scope=" (Android)" ;;
        desktop) scope=" (desktop)" ;;
        web) scope=" (web)" ;;
        linux) scope=" (Linux)" ;;
        windows) scope=" (Windows)" ;;
        scripts) return 0 ;;
        *) scope="" ;;
    esac
    echo "$kind - ${text^}$scope"
}

# Subjects of a submodule between the two tags' pointers (all of it for the first release).
subjects() {
    local path="$1" from to
    to="$(git rev-parse "$TAG:$path")"
    from="$( [ -n "$PREV" ] && git rev-parse "$PREV:$path" 2>/dev/null || true)"
    git -C "$path" log --no-merges --format=%s ${from:+"$from.."}"$to"
}

LINES="$(for path in sonare-frontend sonare-backend; do
    subjects "$path" | while read -r s; do line "$s"; done
done | awk '!seen[$0]++')"

section() {
    local items
    items="$(printf '%s\n' "$LINES" | sed -n "s/^\\($2\\) - /- /p")"
    [ -n "$items" ] && printf '## %s\n\n%s\n\n' "$1" "$items"
    return 0
}

NOTES="$(section "New" "feat"; section "Improvements" "perf"; section "Fixes" "fix")"
if [ -n "$NOTES" ]; then
    printf '%s\n' "$NOTES"
else
    echo "Maintenance release: no changes you'll notice."
fi
if [ -n "$PREV" ]; then
    echo ""
    echo "**Full Changelog**: https://github.com/Rajan694/sonare/compare/$PREV...$TAG"
fi
