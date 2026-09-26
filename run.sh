#!/bin/bash

# Global runner. Each project owns its own run script; this opens each one in its
# own terminal so the three logs stay readable side by side instead of interleaved.
#
# Piped starts first and is waited on, because the backend's catalog and streaming
# are useless without it and the failure is confusing if it comes later.
#
# This script itself is the "launcher terminal": it stays in the foreground after
# starting things, and closing it (or Ctrl+C) tears everything back down - the
# Piped docker stack plus the backend/frontend dev servers running in their own
# windows - so nothing is left running detached in the background.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    echo "Usage: ./run.sh [all|piped|be|fe] [--here] [--fe=web|mobile|linux]"
    echo ""
    echo "  all     Piped, backend and frontend, each in its own terminal (default)"
    echo "  piped   Piped backend only (docker)"
    echo "  be      Sonare backend only"
    echo "  fe      Frontend only (desktop/web)"
    echo ""
    echo "  --here           Run in this terminal instead of opening new ones."
    echo "                   Only valid with a single target."
    echo ""
    echo "  --fe=<target>    FE to build: web (default), mobile, or linux."
    echo ""
    echo "Ports: piped 8090, proxy 8091, backend 3010 (see .env), vite 5183 (web) / 5184 (linux)."
    echo "The web and linux frontends use different ports, so both can run at once."
    echo ""
    echo "Closing this terminal (or Ctrl+C) stops everything it started: the"
    echo "Piped docker stack and the backend/frontend dev servers."
    exit 1
}

TARGET="all"
HERE=0
FE="web"
for arg in "$@"; do
    case "$arg" in
        all|piped|be|fe) TARGET="$arg" ;;
        --here) HERE=1 ;;
        --fe=*) FE="${arg#--fe=}" ;;
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

# --- graceful shutdown ---------------------------------------------------
# Terminal emulators spawned above don't reliably hand back a PID we can act
# on later (gnome-terminal in particular just proxies to a background server
# process and exits immediately), so instead of tracking PIDs we find the
# backend/frontend processes at shutdown time by the unique command line each
# was launched with. Piped is simpler: it's docker, so "shutting it down" is
# just `docker compose down`.
STARTED_PIPED=0
STARTED_BE=0
STARTED_FE=0
CLEANED_UP=0

kill_group() {
    local pattern="$1" pid
    for pid in $(pgrep -f "$pattern" 2>/dev/null); do
        kill -TERM "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null
    done
    sleep 1
    for pid in $(pgrep -f "$pattern" 2>/dev/null); do
        kill -KILL "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null
    done
}

cleanup() {
    [ "$CLEANED_UP" = "1" ] && return
    CLEANED_UP=1
    trap - EXIT INT TERM HUP

    echo ""
    echo "=== Shutting down ==="

    if [ "$STARTED_FE" = "1" ]; then
        echo "Stopping frontend..."
        kill_group "runFE.sh $FE"
    fi

    if [ "$STARTED_BE" = "1" ]; then
        echo "Stopping backend..."
        kill_group "runBE.sh dev"
    fi

    if [ "$STARTED_PIPED" = "1" ]; then
        echo "Stopping Piped (docker)..."
        ( cd "$SCRIPT_DIR/sonare-piped-backend" && ./runPiped.sh down )
    fi

    echo "=== Done ==="
}
trap cleanup EXIT INT TERM HUP

start_piped() {
    # Docker, and it detaches on its own, so run it inline and wait - the backend
    # needs it up before it is worth starting. runPiped.sh prints its own header.
    ( cd "$SCRIPT_DIR/sonare-piped-backend" && ./runPiped.sh up )
}

if [ "$HERE" = "1" ]; then
    case "$TARGET" in
        piped)
            STARTED_PIPED=1
            start_piped || exit 1
            echo ""
            echo "Piped is running at http://127.0.0.1:8090."
            echo "Press Ctrl+C, or close this terminal, to stop it."
            sleep infinity
            ;;
        be)    exec "$SCRIPT_DIR/sonare-backend/runBE.sh" dev ;;
        fe)    exec "$SCRIPT_DIR/sonare-frontend/runFE.sh" "$FE" ;;
    esac
fi

case "$TARGET" in
    piped)
        STARTED_PIPED=1
        start_piped || exit 1
        echo ""
        echo "Piped is running at http://127.0.0.1:8090."
        echo "Press Ctrl+C, or close this terminal, to stop it."
        sleep infinity
        ;;
    be)
        STARTED_BE=1
        open_terminal "sonare-backend" "$SCRIPT_DIR/sonare-backend" "./runBE.sh dev"
        echo ""
        echo "Backend starting in its own terminal."
        echo "Press Ctrl+C, or close this terminal, to stop it."
        sleep infinity
        ;;
    fe)
        STARTED_FE=1
        open_terminal "sonare-frontend" "$SCRIPT_DIR/sonare-frontend" "./runFE.sh $FE"
        echo ""
        echo "Frontend starting in its own terminal."
        echo "Press Ctrl+C, or close this terminal, to stop it."
        sleep infinity
        ;;
    all)
        STARTED_PIPED=1
        PIPED_UP=1
        if ! start_piped; then
            PIPED_UP=0
            echo "Piped did not come up - starting the rest anyway."
        fi
        STARTED_BE=1
        open_terminal "sonare-backend" "$SCRIPT_DIR/sonare-backend" "./runBE.sh dev"
        # Give the API a moment to bind so the frontend's first calls do not fail.
        sleep 3
        STARTED_FE=1
        open_terminal "sonare-frontend" "$SCRIPT_DIR/sonare-frontend" "./runFE.sh $FE"
        echo ""
        echo "Started:"
        if [ "$PIPED_UP" = "1" ]; then
            echo "  piped     http://127.0.0.1:8090   (docker, this terminal)"
        else
            echo "  piped     NOT RUNNING - trending, search and playback will fail (see the errors above)"
        fi
        echo "  backend   see the sonare-backend terminal"
        case "$FE" in
            web)   echo "  frontend  http://localhost:5183   (see the sonare-frontend terminal)" ;;
            linux) echo "  frontend  http://localhost:5184   (the Sonare window; see the sonare-frontend terminal)" ;;
            *)     echo "  frontend  $FE   (see the sonare-frontend terminal)" ;;
        esac
        echo ""
        echo "Press Ctrl+C, or close this terminal, to stop everything (piped, backend, frontend)."
        sleep infinity
        ;;
esac
