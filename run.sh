#!/bin/bash

# Global runner. Each project owns its own run script; this opens each one in its
# own terminal so the three logs stay readable side by side instead of interleaved.
#
# Piped starts first and is waited on, because the backend's catalog and streaming
# are useless without it and the failure is confusing if it comes later.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    echo "Usage: ./run.sh [all|piped|be|fe] [--here]"
    echo ""
    echo "  all     Piped, backend and frontend, each in its own terminal (default)"
    echo "  piped   Piped backend only (docker)"
    echo "  be      Sonare backend only"
    echo "  fe      Frontend only (desktop/web)"
    echo ""
    echo "  --here  Run in this terminal instead of opening new ones."
    echo "          Only valid with a single target."
    echo ""
    echo "Ports: piped 8080, proxy 8081, backend 3000 (see .env), vite 5173."
    exit 1
}

TARGET="all"
HERE=0
for arg in "$@"; do
    case "$arg" in
        all|piped|be|fe) TARGET="$arg" ;;
        --here) HERE=1 ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

if [ "$HERE" = "1" ] && [ "$TARGET" = "all" ]; then
    echo "--here needs a single target, e.g. ./run.sh be --here"
    exit 1
fi

# Pick a terminal emulator. gnome-terminal is the common case on this desktop;
# x-terminal-emulator is the Debian alternatives symlink and works as a fallback.
TERM_CMD=""
for t in gnome-terminal konsole xfce4-terminal tilix terminator x-terminal-emulator xterm; do
    if command -v "$t" >/dev/null 2>&1; then TERM_CMD="$t"; break; fi
done

# Keep the shell open after the command exits so a crash is readable rather than
# taking its window with it.
open_terminal() {
    local title="$1" workdir="$2" cmd="$3"
    local inner="cd '$workdir' && $cmd; echo; echo '[$title exited - press enter to close]'; read"

    case "$TERM_CMD" in
        gnome-terminal) gnome-terminal --title="$title" -- bash -lc "$inner" & ;;
        konsole)        konsole --new-tab -p tabtitle="$title" -e bash -lc "$inner" & ;;
        xfce4-terminal) xfce4-terminal --title="$title" -e "bash -lc \"$inner\"" & ;;
        tilix)          tilix --title="$title" -e bash -lc "$inner" & ;;
        terminator)     terminator --title="$title" -e "bash -lc \"$inner\"" & ;;
        xterm)          xterm -T "$title" -e bash -lc "$inner" & ;;
        x-terminal-emulator) x-terminal-emulator -T "$title" -e bash -lc "$inner" & ;;
        "")
            echo "No terminal emulator found - running '$title' in the background."
            echo "  Logs: /tmp/sonare-$title.log"
            ( cd "$workdir" && bash -lc "$cmd" > "/tmp/sonare-$title.log" 2>&1 & )
            ;;
    esac
}

start_piped() {
    # Docker, and it detaches on its own, so run it inline and wait - the backend
    # needs it up before it is worth starting.
    echo "=== Starting Piped (docker) ==="
    ( cd "$SCRIPT_DIR/sonare-piped-backend" && ./runPiped.sh up )
}

if [ "$HERE" = "1" ]; then
    case "$TARGET" in
        piped) exec "$SCRIPT_DIR/sonare-piped-backend/runPiped.sh" up ;;
        be)    exec "$SCRIPT_DIR/sonare-backend/runBE.sh" dev ;;
        fe)    exec "$SCRIPT_DIR/sonare-frontend/runFE.sh" web ;;
    esac
fi

case "$TARGET" in
    piped)
        start_piped
        ;;
    be)
        open_terminal "sonare-backend" "$SCRIPT_DIR/sonare-backend" "./runBE.sh dev"
        ;;
    fe)
        open_terminal "sonare-frontend" "$SCRIPT_DIR/sonare-frontend" "./runFE.sh web"
        ;;
    all)
        start_piped || echo "Piped did not come up - starting the rest anyway."
        open_terminal "sonare-backend" "$SCRIPT_DIR/sonare-backend" "./runBE.sh dev"
        # Give the API a moment to bind so the frontend's first calls do not fail.
        sleep 3
        open_terminal "sonare-frontend" "$SCRIPT_DIR/sonare-frontend" "./runFE.sh web"
        echo ""
        echo "Started:"
        echo "  piped     http://127.0.0.1:8080   (docker, this terminal)"
        echo "  backend   see the sonare-backend terminal"
        echo "  frontend  http://localhost:5173   (see the sonare-frontend terminal)"
        echo ""
        echo "Stop Piped with: ./sonare-piped-backend/runPiped.sh down"
        ;;
esac
