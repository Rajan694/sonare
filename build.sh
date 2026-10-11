#!/bin/bash
set -e

# Global build script. The apps live in sonare-frontend, which owns the actual build
# (buildFE.sh); this just passes the arguments on, like install.sh and run.sh do.
#
#   ./build.sh <dev|prod> <android|linux|windows|web|all> [version]
#
#   ./build.sh prod android              # bumps the patch version: 1.0.1 -> 1.0.2
#   ./build.sh prod linux windows 1.2.0  # sets the version
#   ./build.sh dev web
#
# Builds land in sonare-frontend/dist/releases/; upload them on /admin/releases.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    exec "$SCRIPT_DIR/sonare-frontend/buildFE.sh" --help
fi

exec "$SCRIPT_DIR/sonare-frontend/buildFE.sh" "$@"
