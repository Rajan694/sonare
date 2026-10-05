#!/bin/bash
set -e

# Global build script. The apps live in sonare-frontend, which owns the actual build
# (buildFE.sh); this just passes the arguments on, like install.sh and run.sh do.
#
#   ./build.sh android
#   ./build.sh linux windows --env=prod
#   ./build.sh all --env=prod
#
# Builds land in sonare-frontend/dist/releases/; upload them on /admin/releases.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    exec "$SCRIPT_DIR/sonare-frontend/buildFE.sh" --help
fi

exec "$SCRIPT_DIR/sonare-frontend/buildFE.sh" "$@"
