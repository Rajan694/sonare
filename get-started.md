# Get started

Everything needed to run Sonare on a fresh Linux or Windows machine, and the commands to do
it. Linux commands are for Ubuntu / Debian; Windows commands are for PowerShell 7 (each
`.sh` script has a `.ps1` twin).

## What runs where

| Part                    | Folder                  | Runs on                    | Port(s)                       |
| ----------------------- | ----------------------- | -------------------------- | ----------------------------- |
| Piped (YouTube data)    | `sonare-piped-backend/` | Docker                     | 8090 API, 8091 proxy          |
| Sonare API              | `sonare-backend/`       | Node 22 + Postgres + Redis | 3010                          |
| Web app, desktop window | `sonare-frontend/desktop` | Node 22 (Vite, NeutralinoJS) | 5183 web, 5184 window     |
| Android app             | `sonare-frontend/mobile`  | Node 22 + JDK 17 + Android SDK | Metro 8081              |

You only need the Android tools for the Android app, and the release tools only to make
installable builds. In production the API and the web app run on Render and Piped runs at
home behind Tailscale Funnel (see [Production](#8-production)).

## 1. Install the software

| Software                  | Version          | Needed for                          |
| ------------------------- | ---------------- | ----------------------------------- |
| Git                       | any recent       | everything                          |
| Node.js                   | 22               | backend, web, desktop, Android      |
| Docker + compose plugin   | Engine 24+ / Desktop | Piped                               |
| PostgreSQL                | 17 (16 works)    | backend                             |
| Redis                     | 7 (optional)     | backend cache and rate limits       |
| WebKitGTK + GStreamer     | 4.1 / 1.0        | desktop window on Linux             |
| JDK                       | 17               | Android app                         |
| Android Studio (SDK, NDK) | SDK 37, NDK 27.1 | Android app                         |
| dpkg-deb, appimagetool    | any              | Linux release builds only           |

### Linux (Ubuntu / Debian)

```bash
# Git, curl and the build basics
sudo apt update
sudo apt install -y git curl ca-certificates build-essential

# Node 22 through nvm (the scripts load nvm themselves)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 22
nvm alias default 22

# Docker Engine + compose plugin, then use it without sudo (log out and back in after)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"

# Postgres and Redis
sudo apt install -y postgresql redis-server
sudo systemctl enable --now postgresql redis-server
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

# The desktop window (WebKitGTK) and audio codecs (AAC needs gstreamer1.0-libav)
sudo apt install -y libgtk-3-0 libwebkit2gtk-4.1-0 \
  gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-libav
```

Android (only for the app):

```bash
sudo apt install -y openjdk-17-jdk
sudo snap install android-studio --classic
```

Open Android Studio once, and in **SDK Manager** install Android SDK Platform 37, Build-Tools,
NDK 27.1.12297006, Platform-Tools and an emulator image (e.g. Pixel 6, x86_64). Then add to
`~/.bashrc`:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
```

Release builds (only for publishing): `dpkg-deb` comes with Debian / Ubuntu; put
[appimagetool](https://github.com/AppImage/appimagetool/releases) on your PATH:

```bash
mkdir -p ~/.local/bin
curl -L -o ~/.local/bin/appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x ~/.local/bin/appimagetool
```

### Windows 10 / 11

Run in PowerShell. `winget` ships with Windows 11 (on Windows 10: install "App Installer"
from the Microsoft Store).

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.PowerShell -e
winget install --id CoreyButler.NVMforWindows -e
winget install --id Docker.DockerDesktop -e
winget install --id PostgreSQL.PostgreSQL.17 -e
```

Open a new terminal, then:

```powershell
nvm install 22
nvm use 22
```

- **Docker Desktop**: start it once and let it set up WSL 2 (it asks to reboot).
- **PostgreSQL**: the installer asks for the `postgres` user's password; use it in
  `DATABASE_URL` below.
- **Scripts**: let PowerShell run the project's `.ps1` files:
  `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- **Redis** has no Windows build. It's optional (without it the cache passes through); to
  have it, run it in Docker: `docker run -d --name sonare-redis --restart unless-stopped -p 6379:6379 redis:7-alpine`.
- **Desktop window**: uses WebView2, which Windows 10 and 11 already have.

Android (only for the app):

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e
winget install --id Google.AndroidStudio -e
```

In Android Studio's **SDK Manager** install the same SDK, NDK and emulator as on Linux, then
set `ANDROID_HOME` to `%LOCALAPPDATA%\Android\Sdk` (System Properties → Environment
Variables) and add `%ANDROID_HOME%\platform-tools` to `Path`.

Installable Linux packages (.deb, .AppImage) can only be built on Linux; Windows builds the
Windows .exe and the Android APK.

## 2. Get the code

```bash
git clone --recurse-submodules https://github.com/Rajan694/sonare.git
cd sonare
git submodule foreach 'git checkout generic-branch'
git checkout generic-branch
```

Work happens on `generic-branch` in every repo; it is merged into `main` after testing.

## 3. Configure

The install step (next) creates these files from their `.example` copies; edit them after.

| File                            | Set                                                                                      |
| ------------------------------- | ---------------------------------------------------------------------------------------- |
| `sonare-backend/.env`           | `DATABASE_URL` (your Postgres user and password, database `sonare`), `JWT_SECRET` (any long string). `RESEND_API_KEY` to send verification and password-reset email (without it none is sent); `PIPED_LOCAL_PROXY_URL=http://localhost:8091` when this machine's Piped is published with Funnel |
| `sonare-piped-backend/.env`     | Nothing for development. `PIPED_DB_PASSWORD` for production                               |
| `sonare-frontend/desktop/.env`  | `VITE_API_BASE` (default `http://127.0.0.1:3010/api/v1`); optional `VITE_DEV_EMAIL` / `VITE_DEV_PASSWORD` to sign in automatically in development |

Example `DATABASE_URL`: `postgres://postgres:postgres@127.0.0.1:5432/sonare`.

## 4. Install

```bash
./install.sh            # Piped image, backend (npm, .env, database, migrations), frontend
```

```powershell
.\install.ps1
```

`./install.sh piped|be|fe` installs one part. The first Piped build takes a few minutes
(Gradle + Docker Hub + JitPack).

## 5. Run

```bash
./run.sh                    # Piped, backend and the web app, each in its own terminal
./run.sh fe --fe=linux      # the desktop window instead of the browser
./run.sh fe --fe=mobile     # Metro + the Android app (emulator or USB phone)
./run.sh be --here          # one part, in this terminal
```

```powershell
.\run.ps1
.\run.ps1 fe --fe=mobile
```

Then open:

| URL                         | What                                                    |
| --------------------------- | ------------------------------------------------------- |
| http://localhost:5183/      | intro page; **Open web app** goes to `/home`            |
| http://localhost:5183/admin | admin page (`admin@sonare.dev`)                          |
| http://localhost:3010/api/v1/healthz | backend health (database, Redis, Piped)        |

Closing the launcher terminal (or Ctrl+C) stops everything it started.

## 6. Keep it up to date

One command pulls, reinstalls only what changed, builds, migrates and starts:

```bash
./update.sh             # development: everything, then ./run.sh all
./update.sh prod        # production machine: Piped (+ Funnel); --be also runs the backend here
```

```powershell
.\update.ps1
.\update.ps1 prod
```

Or per project:

| Command                                               | Does                                                     |
| ----------------------------------------------------- | -------------------------------------------------------- |
| `sonare-backend/updateBE.sh [dev\|prod]`               | pull, `npm ci` if needed, build (prod), migrate, run     |
| `sonare-piped-backend/updatePiped.sh`                  | pull, rebuild only if Piped's source changed, start (with Funnel when set up) |
| `sonare-frontend/updateFE.sh [web\|linux\|mobile] [dev\|prod]` | pull, `npm ci` if needed, run; `web prod` builds for production and serves it on 5183 |

They refuse to pull over uncommitted changes, and `--no-run` stops after updating.

## 7. Tests and builds

```bash
cd sonare-backend && npm test                     # needs Postgres + Redis (uses sonare_test, Redis db 15)
cd sonare-frontend/desktop && npm test
cd sonare-frontend/mobile && npm test
```

Installable apps:

```bash
./build.sh prod all            # APK, Linux packages, Windows .exe and web, one version for all
```

The files to publish land in `sonare-frontend/dist/releases/github/`. Create a release at
https://github.com/Rajan694/sonare/releases/new tagged `v<version>` and attach **all** of them:
the site's download buttons and the apps' update check read the latest release. The Android
release needs the signing key in `~/.gradle/gradle.properties` (`SONARE_UPLOAD_*`).

## 8. Production

- **Piped at home, published with Tailscale Funnel** (Linux, no sudo; a free Tailscale account):

  ```bash
  cd sonare-piped-backend
  ./funnel.sh install     # downloads Tailscale, runs it as a user service, signs this machine in
  ./funnel.sh up          # key-checking gate + Funnel; prints PIPED_API_URL and where PIPED_KEY is
  loginctl enable-linger "$USER"   # keep it running after you log out
  ```

  On Windows, `.\funnel.ps1 install` installs the Tailscale app with winget and `.\funnel.ps1 up`
  does the same as above. Moving Piped to another machine: see
  `sonare-piped-backend/README.md` → "Moving Piped to another device".

  While Funnel is on, Piped's stream URLs point at the Funnel address. A backend on the same
  machine keeps `PIPED_API_URL=http://localhost:8090` and adds
  `PIPED_LOCAL_PROXY_URL=http://localhost:8091` to `sonare-backend/.env`, so development keeps
  working. `./funnel.sh down` makes Piped local-only again.
- **Backend and web on Render**, domain `sonare.vip` (API at `api.sonare.vip`). Production
  needs `NODE_ENV=production`, `APP_URL=https://sonare.vip`, `CORS_ORIGINS=https://sonare.vip`,
  `JWT_SECRET`, `RESEND_API_KEY` (with `sonare.vip` verified in Resend), `PIPED_API_URL` and
  `PIPED_KEY`. See `sonare-backend/.env.production.example` and `docs/TODO.md` → Deployment.

## Troubleshooting

| Symptom                                           | Fix                                                                       |
| ------------------------------------------------- | ------------------------------------------------------------------------- |
| Verification or reset email never arrives         | Set `RESEND_API_KEY` in `sonare-backend/.env`, verify `sonare.vip` in Resend, then check spam and the backend log |
| `EMFILE: too many open files, watch` (Vite/Metro) | `echo fs.inotify.max_user_instances=1024 \| sudo tee /etc/sysctl.d/60-inotify.conf && sudo sysctl --system` |
| A port is already in use                          | Ports are listed above; `ss -ltnp \| grep <port>` (Linux) / `Get-NetTCPConnection -LocalPort <port>` (Windows) |
| Gradle: `JAVA_COMPILER` / no `javac`              | Install the JDK 17 (not a JRE) and set `JAVA_HOME`                        |
| Android app: "Unable to load script"              | Metro isn't running or reachable: `./run.sh fe --fe=mobile` sets up `adb reverse` |
| Catalog empty, "Piped upstream: DOWN"             | `cd sonare-piped-backend && ./runPiped.sh up`, then `./runPiped.sh check` |
| `.m4a` / AAC won't play in the Linux window       | `sudo apt install gstreamer1.0-libav`                                     |
