#!/bin/bash
set -e

# Brings everything up to date and runs it. The root repo is pulled first; then each project
# pulls its own branch (sonare-*/update*.sh), installs what changed and is started.
#
#   dev   all three for development: Piped, the backend and the web app (./run.sh all)
#   prod  this machine's part of production: Piped, published through Tailscale Funnel when
#         that is set up. The backend and the web app run on Render, which deploys from
#         GitHub; --be also runs the backend here, compiled, for hosting without Render.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: ./update.sh [dev|prod] [--be]"
    echo ""
    echo "  dev (default)  Pull everything, then Piped, backend and web app (./run.sh all)"
    echo "  prod           Pull everything, then Piped (+ Funnel); the backend and web run on Render"
    echo "  --be           prod: also build and run the backend on this machine"
    echo ""
    echo "Each project refuses to pull over uncommitted changes."
    exit 1
}

MODE="dev"
BE=0
for arg in "$@"; do
    case "$arg" in
        dev|prod) MODE="$arg" ;;
        --be) BE=1 ;;
        *) usage ;;
    esac
done
[ "$BE" = "0" ] || [ "$MODE" = "prod" ] || usage

# Submodule pointers move as the projects get new commits; only real changes block a pull.
if [ -n "$(git status --porcelain --untracked-files=no --ignore-submodules=all)" ]; then
    echo "Uncommitted changes in the root repo - commit or stash them before updating:"
    git status --short --untracked-files=no --ignore-submodules=all
    exit 1
fi
echo "=== Pulling the root repo ($(git rev-parse --abbrev-ref HEAD)) ==="
git pull --ff-only

step() {
    echo ""
    echo "############################################################"
    echo "# $1"
    echo "############################################################"
}

if [ "$MODE" = "dev" ]; then
    step "Piped backend"
    ./sonare-piped-backend/updatePiped.sh --no-run
    step "Sonare backend"
    ./sonare-backend/updateBE.sh dev --no-run
    step "Frontend"
    ./sonare-frontend/updateFE.sh web dev --no-run
    step "Starting everything"
    exec ./run.sh all
fi

step "Piped backend"
./sonare-piped-backend/updatePiped.sh
if [ "$BE" = "1" ]; then
    step "Sonare backend"
    exec ./sonare-backend/updateBE.sh prod
fi
echo ""
echo "Piped is up. The backend and the web app deploy on Render from GitHub: push to update them."
