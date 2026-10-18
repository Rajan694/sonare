# Sonare

**A music player for Android, Linux, Windows and the web.** Sonare streams music from YouTube
without ads or tracking. It also plays the music files already on your device, and it keeps
your library in sync across all of them.

[Website](https://sonare.vip) · [Download](https://github.com/Rajan694/sonare/releases/latest) ·
[Get started](get-started.md) · [Deployment](docs/DEPLOYMENT.md) · [TODO](docs/TODO.md)

---

## What it does

- **Streams YouTube music:** songs, albums, artists and playlists, without ads. The desktop
  and Android apps fetch from YouTube themselves, from your own IP, using
  [youtubei.js](https://github.com/LuanRT/YouTube.js). The web app, and the other apps when
  that fails, go through Sonare's own private [Piped](https://github.com/TeamPiped/Piped)
  instance.
- **Plays files on your device** next to streamed music, in the same queue and player.
- **Downloads music for offline listening**, at the quality and format you choose. A paused
  download resumes where it stopped.
- **A Sonare account syncs** your favourites, playlists, play history, settings and player
  state across your devices. Guests can browse and play without an account.
- **Synced lyrics** come from [LRCLIB](https://lrclib.net).
- **Updates itself:** the desktop and Android apps check the latest GitHub release.
- **Has an admin page** at `/admin` on the web build, with usage, API metrics, errors and
  crash reports.

## Platforms

| Platform | Built with                              | Get it                                             |
| -------- | --------------------------------------- | -------------------------------------------------- |
| Android  | React Native 0.87, native Kotlin player | `sonare-android-arm64.apk` from the latest release |
| Linux    | React 19 + Vite inside NeutralinoJS     | `.AppImage`, `.deb` or `.tar.gz` from the release  |
| Windows  | React 19 + Vite inside NeutralinoJS     | `sonare-windows-x64.exe` from the release          |
| Web      | The same React app, in the browser      | [sonare.vip](https://sonare.vip)                   |

## How it fits together

```
 Android app ─┐
 Desktop app ─┼──► Sonare API (/api/v1) ──► Postgres   accounts, library, playlists, logs
 Web app ─────┘    sonare-backend          ──► Redis      cache, rate limits
                                            ──► Resend     account email
                                            ──► LRCLIB     lyrics
                                            ──► Piped      YouTube data and audio
                                                sonare-piped-backend (Docker)
```

The API turns Piped's YouTube data into Sonare's own catalog (tracks, albums, artists,
playlists) and relays the audio. Piped is never exposed to the apps. The desktop window and the
Android app can also fetch YouTube directly (youtubei.js), and fall back to the API.

| Where                      | Sonare API                | Database / cache                 | Piped                                           |
| -------------------------- | ------------------------- | -------------------------------- | ----------------------------------------------- |
| Development (your machine) | `localhost:3010`          | local Postgres 17 + Redis 7      | Docker on `localhost:8090` / `8091`             |
| Production                 | Render (`api.sonare.vip`) | Neon Postgres + Render Key Value | Docker at home, published with Tailscale Funnel |

Piped runs on a home connection because YouTube blocks datacenter IPs.

## Repository layout

This root repo holds the scripts, the docs and the deployment config. The code lives in three
git submodules, each with its own README.

| Folder                                                    | What it is                                                                              |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| [`sonare-backend/`](sonare-backend/README.md)             | The Sonare API: Express 5 + TypeScript, Postgres (Drizzle), Redis                       |
| [`sonare-frontend/`](sonare-frontend/README.md)           | Both apps, plus `shared/` (API types and catalog code they share)                       |
| ↳ [`desktop/`](sonare-frontend/desktop/README.md)         | The desktop, web and admin app: React 19 + Vite + TypeScript in NeutralinoJS            |
| ↳ [`mobile/`](sonare-frontend/mobile/README.md)           | The Android app: React Native, NativeWind, Zustand                                      |
| [`sonare-piped-backend/`](sonare-piped-backend/README.md) | Sonare's fork of Piped (Java), run with Docker Compose                                  |
| `docs/`                                                   | Deployment and the TODO list                                                            |
| `scripts/`                                                | `sync-shared-catalog.mjs`: copies `sonare-frontend/shared` into the backend (see below) |
| `render.yaml`                                             | The Render Blueprint for the production API and web app                                 |
| `.github/workflows/release.yml`                           | Builds every app and attaches it to a GitHub release when a `v*` tag is pushed          |

## Quick start

You'll need Node 22, Docker, and Postgres 17 + Redis 7 on localhost.
[get-started.md](get-started.md) lists every tool for Linux and Windows, with the commands.

```bash
git clone --recurse-submodules https://github.com/Rajan694/sonare.git
cd sonare
./install.sh                  # Piped images, backend (npm, .env, database), both apps
./run.sh                      # Piped, the API and the web app, each in its own terminal
```

Then open <http://localhost:5183>. The admin page is at <http://localhost:5183/admin>, and API
health at <http://localhost:3010/api/v1/healthz>.

```bash
./run.sh fe --fe=linux        # the desktop window instead of the browser
./run.sh fe --fe=mobile       # Metro + the Android app (emulator or USB phone)
./run.sh be --here            # one part only, in this terminal
```

Ports: Piped 8090, Piped's proxy 8091, API 3010, web 5183, desktop window 5184, Metro 8081.

## Root scripts

Every script has a PowerShell twin (`install.ps1`, `run.ps1`, …) that takes the same arguments.

| Script                               | What it does                                                                                                                                                         |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `./install.sh [all\|piped\|be\|fe]`  | First-time setup: runs each project's installer. Creates the `.env` files and the database, installs packages, builds Piped                                          |
| `./run.sh [all\|piped\|be\|fe]`      | Starts the parts for development, each in its own terminal. Closing the launcher stops them all                                                                      |
| `./update.sh [dev\|prod] [--be]`     | Pulls every repo, reinstalls what changed, migrates, then starts things. `dev` runs `./run.sh all`. `prod` starts this machine's part of production (Piped + Funnel) |
| `./build.sh <dev\|prod> <platforms>` | Builds installable apps into `sonare-frontend/dist/releases/` (`android`, `linux`, `windows`, `web`, `all`)                                                          |
| `./release.sh [version]`             | Tags a version and pushes the tag; GitHub Actions then builds every app and publishes the release                                                                    |

`install` comes first on a new machine, and `update` uses `run` to start things. So all three
stay. Each project also has its own scripts (`installBE`, `runFE`, `runPiped`, …), described
in its README.

### `scripts/sync-shared-catalog.mjs`

The apps and the backend turn Piped's answers into Sonare tracks with the same code
(`sonare-frontend/shared/catalog/*` and `shared/apiTypes.ts`). The backend deploys from its own
repository, so it can't import that code from the frontend. This script copies the files into
`sonare-backend/src/shared/`, each marked "GENERATED, do not edit".

After changing anything in `sonare-frontend/shared/catalog` or `shared/apiTypes.ts`, run:

```bash
node scripts/sync-shared-catalog.mjs           # write the copies
node scripts/sync-shared-catalog.mjs --check   # exit 1 if a copy is out of date
```

## Documentation

| Read this                                                              | For                                                                                 |
| ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [get-started.md](get-started.md)                                       | Setting up a fresh Linux or Windows machine, step by step                           |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)                               | Production: Render, Neon, Funnel, how a change ships, releasing the apps            |
| [docs/TODO.md](docs/TODO.md)                                           | Open work and known risks                                                           |
| [sonare-backend/README.md](sonare-backend/README.md)                   | The API: environment variables, scripts, admin, Docker production stack             |
| [sonare-frontend/README.md](sonare-frontend/README.md)                 | Both apps: install, run, build, configuration, checks                               |
| [sonare-frontend/desktop/README.md](sonare-frontend/desktop/README.md) | The desktop/web app's layout and NeutralinoJS details                               |
| [sonare-frontend/mobile/README.md](sonare-frontend/mobile/README.md)   | The Android app: setup, layout, native modules                                      |
| [sonare-piped-backend/README.md](sonare-piped-backend/README.md)       | Piped: settings, what to do when YouTube breaks something                           |
| [sonare-piped-backend/HOSTING.md](sonare-piped-backend/HOSTING.md)     | Running Piped: up, down, update, Funnel for Render, moving devices, troubleshooting |

Each project's `TEST-PLAN.md` lists every test by ID. `npm test` refuses to run if the tests and
the plan disagree.

## Contributing

- Work happens on `generic-branch` in every repo. Changes reach `main` through a pull request
  from `generic-branch`, merged once CI is green.
- Push the submodules first, then bump their pointers in this repo.
- Render deploys `main` after its GitHub checks pass. A `v*` tag (`./release.sh`) publishes new
  app builds.

## Licence

MIT for this repo, the backend and the frontend; see [LICENSE](LICENSE).
`sonare-piped-backend` is a fork of Piped and stays under AGPL-3.0, with its own licence.
