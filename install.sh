#!/bin/bash
set -e

# Global installer. Each project owns its own install script; this just runs them
# in dependency order and reports what happened.
#
#   sonare-piped-backend  docker only  - the catalog upstream
#   sonare-backend        local node   - needs local postgres + redis
#   sonare-frontend       local node   - desktop/web and mobile

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    echo "Usage: ./install.sh [all|piped|be|fe]"
    echo ""
    echo "  all     Install everything, in order (default)"
    echo "  piped   Piped backend only (docker images)"
    echo "  be      Sonare backend only (npm, .env, database migrations)"
    echo "  fe      Frontend only (npm for desktop/web and mobile)"
    exit 1
}

TARGET="${1:-all}"

run_step() {
    local name="$1" dir="$2" script="$3"
    echo ""
    echo "############################################################"
    echo "# $name"
    echo "############################################################"
    if [ ! -x "$SCRIPT_DIR/$dir/$script" ]; then
        echo "Missing or not executable: $dir/$script"
        return 1
    fi
    ( cd "$SCRIPT_DIR/$dir" && "./$script" )
}

case "$TARGET" in
    all)
        run_step "Piped backend (docker)" sonare-piped-backend installPiped.sh
        run_step "Sonare backend"         sonare-backend       installBE.sh
        run_step "Frontend"               sonare-frontend      installFE.sh
        ;;
    piped) run_step "Piped backend (docker)" sonare-piped-backend installPiped.sh ;;
    be)    run_step "Sonare backend"         sonare-backend       installBE.sh ;;
    fe)    run_step "Frontend"               sonare-frontend      installFE.sh ;;
    *)     usage ;;
esac

echo ""
echo "############################################################"
echo "Install complete. Start everything with ./run.sh"
echo "############################################################"
