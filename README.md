# Sonare

Sonare is a music player for desktop (Linux, Windows), the web and Android. It plays music
from YouTube through a private Piped instance, plays and downloads files on the device, and
keeps favourites, playlists, play history, settings and synced lyrics in a Sonare account —
guests can browse and play without one.

## Repositories

This root repo holds the scripts and the docs; the code lives in three submodules:

| Path                    | Repo                            | What it is                                                                     |
| ----------------------- | ------------------------------- | ------------------------------------------------------------------------------ |
| `sonare-backend/`       | `Rajan694/sonare-backend`       | The Sonare API: Express 5 + TypeScript, Postgres (Drizzle), Redis              |
| `sonare-frontend/`      | `Rajan694/sonare-frontend`      | `desktop/` (React + Vite + NeutralinoJS: desktop, web, `/admin`) and `mobile/` (React Native) |
| `sonare-piped-backend/` | `Rajan694/sonare-piped-backend` | Sonare's fork of Piped (Java), run with docker compose                         |

## How the pieces talk

```
desktop / web / mobile apps
        │  HTTPS, /api/v1  (JWT for /me)
        ▼
sonare-backend :3010 ──► Postgres (accounts, library, playlists, logs)
        │             ──► Redis (cache, rate limits)
        │             ──► Resend (account emails)
        │             ──► LRCLIB (lyrics)
        ▼
Piped API :8090 ──► piped-proxy :8091 (audio and images)
```

The apps only ever call the backend. The backend turns Piped's YouTube data into Sonare's
catalog and relays audio streams; Piped is never exposed to the apps.

## Quick start

New machine? [get-started.md](get-started.md) lists every tool to install on Linux and Windows,
with the commands.

Requirements: Node 22, Docker, Postgres 17 and Redis 7 on localhost (Linux).

```bash
git clone --recurse-submodules https://github.com/Rajan694/sonare.git
cd sonare
./install.sh                 # Piped images, backend (npm, .env, database), frontend
./run.sh                     # Piped, backend and the web app, each in its own terminal
./run.sh fe --fe=linux       # the desktop window instead of the browser
./run.sh fe --fe=mobile      # Metro + the Android app
./build.sh prod linux windows        # installable builds (dev|prod, any platforms, [version])
./update.sh                  # pull everything, reinstall what changed, migrate, then ./run.sh
```

`./build.sh` makes the installable apps into `sonare-frontend/dist/releases/` (see
[sonare-frontend/README.md](sonare-frontend/README.md#build-the-apps)). `./build.sh prod all`
also prepares `sonare-frontend/dist/releases/github/`: attach those files to a GitHub release
of this repo. The web intro page (sonare.vip) links to the latest release's files.

`./run.sh piped|be|fe` starts one part; `--here` keeps it in the current terminal. Ports:
Piped 8090, proxy 8091, backend 3010, web 5183, desktop window dev server 5184.

## Branch workflow

Work happens on `generic-branch` in every repo; the owner reviews it and merges
`generic-branch` into `main`. Submodule pointers in this repo are bumped once the submodules'
branches are pushed.

## Docs

- [sonare-backend/README.md](sonare-backend/README.md) — setup, environment, Docker production stack
- [sonare-frontend/README.md](sonare-frontend/README.md) — both apps, ports, checks
- [sonare-piped-backend/README.md](sonare-piped-backend/README.md) — running Piped, database password
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — production (Render, Neon, Funnel), deploys and app releases
- [docs/api-contract.md](docs/api-contract.md) — the API
- [docs/TODO.md](docs/TODO.md) — open work and known risks
- [docs/TEST-PROGRESS.md](docs/TEST-PROGRESS.md) — test suites
- [docs/PROD-READINESS-REPORT.md](docs/PROD-READINESS-REPORT.md) — the production-readiness pass

## Licence

MIT for this repo, the backend and the frontend — see [LICENSE](LICENSE).
`sonare-piped-backend` is a fork of Piped and stays under AGPL-3.0 with its own licence.
