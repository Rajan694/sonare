# TODO

Open items only; finished ones are in the git history.

## Now

- [ ] Make the app runnable end to end with all UI working properly (desktop + mobile)
- [ ] Test the in-app YouTube work and today's changes, then merge `generic-branch` into `main`
      (backend, frontend, piped-backend, root).
- [ ] Work through [AUDIT.md](AUDIT.md) (Rajan's fix / leave decisions, 2026-10-14).
- [ ] The Kotlin player (`PlaybackEngine`, `SonarePlayerModule`) has no JVM tests: it needs
      Android's AudioManager (Robolectric) and hasn't been built here.

## Deployment (sonare.vip) - steps in [DEPLOYMENT.md](DEPLOYMENT.md)

- [x] Neon Postgres (project `sonare`, branch `production`, Singapore): migrations applied.
- [x] Piped at home behind Tailscale Funnel with the key-checking gate.
- [x] `render.yaml` (API on Docker free, static web, Key Value) deploying `main` after CI passes.
- [x] Release workflow: a `vX.Y.Z` tag builds every app and publishes the GitHub release.
- [ ] Merge `generic-branch` into `main` (backend, frontend, piped-backend, root).
- [ ] Render: create the Blueprint from `Rajan694/sonare`, fill `DATABASE_URL`, `RESEND_API_KEY`,
      `PIPED_KEY` (`GITHUB_TOKEN` optional).
- [ ] Dynadot DNS: `@` A (Render's IP), `www` and `api` CNAMEs; Resend's records; verify both.
- [ ] Change `admin@sonare.dev`'s password on the production admin page.
- [ ] Release signing secrets in `Rajan694/sonare`, then tag the first release.
- [ ] Check `TRUST_PROXY=1` against Render's proxies (login rate limits per client IP).

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

## Later

- [ ] **Per-IP rate limit on the catalog and stream routes** (audit I15), to protect the home
      Piped from one client hammering it. Not needed while Sonare is for family and friends.

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
