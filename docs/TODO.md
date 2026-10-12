# TODO

Open items only; finished ones are in the git history.

## Now

- [ ] Make the app runnable end to end with all UI working properly (desktop + mobile)
- [ ] Test the in-app YouTube work and today's changes, then merge `generic-branch` into `main`
      (backend, frontend, piped-backend, root).
- [ ] The Kotlin side of the output picker and sleep timer (`OutputDevices`, `PlaybackEngine`,
      `SonarePlayerModule`) has no JVM tests: they need Android's AudioManager (Robolectric) and
      haven't been built here.

## Deployment (sonare.vip, bought 2026-10-12 on Dynadot)

- [ ] **Render:** backend as a web service (its Dockerfile), Postgres and Key Value, and the web
      build as a static site with a `/* -> /index.html` rewrite. Free-plan limits to keep in mind:
      the web service sleeps after 15 min idle, free Postgres expires after 30 days, and outbound
      SMTP ports are blocked (hence Resend's HTTP API).
- [ ] **DNS at Dynadot:** `sonare.vip` -> the Render static site, `api.sonare.vip` -> the backend.
      Production env: `APP_URL=https://sonare.vip`, `CORS_ORIGINS=https://sonare.vip,http://localhost:47823`.
- [ ] **Mail:** verify `sonare.vip` in Resend (its DNS records go in at Dynadot), then set
      `RESEND_API_KEY` (and `MAIL_FROM="Sonare <no-reply@sonare.vip>"`). Without it the backend
      sends to SMTP, which is Mailpit in development (inbox: http://localhost:8025).
- [ ] **Piped at home:** `sonare-piped-backend/funnel.sh install` then `up` (Tailscale Funnel + the
      key-checking gate); set `PIPED_API_URL` and `PIPED_KEY` on Render. `loginctl enable-linger`
      keeps it up after logging out.
- [ ] **Releases:** `./build.sh prod all`, then a GitHub release of `Rajan694/sonare` tagged
      `v<version>` with every file in `sonare-frontend/dist/releases/github/`. The intro page's
      download buttons and the apps' update check read the latest release, so each release must
      carry every platform. Optional `GITHUB_TOKEN` on the backend lifts GitHub's 60 calls/hour.
- [ ] **CI/CD:** GitHub Actions for tests on every push, the release build + GitHub release on a
      tag, and the Render deploys.

## App follow-ups

- [ ] **Linux build can't play AAC.** WebKitGTK decodes through GStreamer, and the AAC decoder
      (`gstreamer1.0-libav`) isn't installed. Opus/MP3 play; the muxed AAC fallback stream
      and the `.m4a` files in the local library won't. Also a packaging note for users.
- [ ] **Neutralino 6.9.0 aborts on rejected WebSocket handshakes** (`websocketpp ... invalid
      state`). Only hit when a second client attaches without a connect token (testing);
      worth rechecking on a newer Neutralino.
- [ ] **Mobile:**
  - Offline mode shows downloaded songs only; there is no local-folder scan on mobile yet
    (the Folders screen says so).
  - The playlist heart (MOB-PL-004): the backend has no endpoint for saving a YouTube playlist.
  - Settings rows other than Account (crossfade, folders, cache size) are still static.
  - Artist `monthlyListeners` is actually YouTube subscriber count.

## Later: external dependencies that may break

- [ ] **Production network.** Datacenter IPs get flagged far more than home ones. Plan since
      2026-10-12: the backend on Render, Piped at home behind Tailscale Funnel, and the apps
      fetching YouTube themselves. If the home IP gets blocked: a new IP or IPv6 first, then an
      outgoing residential proxy for Piped and piped-proxy (`REQWEST_PROXY`; stream urls are
      bound to the IP that fetched them).
  - [ ] Maybe later: a small "Sonare helper" browser extension. Extensions can make
        cross-site requests, so it could fetch from YouTube for the web app from the
        user's own IP. One more thing to build and publish, and few users would install it.
- [ ] **JitPack.** A _new_ NewPipeExtractor commit can't be built while JitPack is down (the last
      good image is kept in `image-backup/`).
- [ ] **Lyrics.** LRCLIB has no SLA: a long outage means no lyrics for songs nobody has opened yet.
- [ ] **Toolchain drift.**
  - Neutralino 6.9.0 binaries are downloaded from GitHub on install.
  - Google Play raises the required Android target SDK yearly; RN / Reanimated 4 /
    NativeWind / JDK upgrades are tightly coupled.
  - npm deps use `^` ranges; safe while the lockfiles are kept.

### Non-technical

- [ ] Pulling YouTube content through Piped is against YouTube's ToS. Personal use: risk
      is IP blocking. Public release: possible takedown requests.
