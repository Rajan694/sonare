# TODO

# MY FINDINGS

- [ ] I have to add download feature tell me what is the possible ways and what are your suggestions(i am going to download only audio)(preferred download quality will be saved through settings screen, also the preferred download location). I will prefer if this current setup supports download then use it or use ytdlp for it. We will have downloads section with pause, resume, delete(will try to delete from folder it downloaded(if got error or file have moved to other place then only delete from downloaded list) options
- [x] Add admin feature page so that editing configurations can be done(for example, not sure about it, includes stream partners, the commit hash i am referring too), also add analytics and error logs. for this in the web only add a /admin route that will ask a username and password when access(it will be openroute but nobody will know it. make a flyway to add username:rajanadmin and password:sonare694(obviousely it will be stored in db hashed)) and when logged in add a section to change password.Add a table in db named system_configuration(it will store the system wide configurations)
      Done 2026-09-26: `/admin` on the web build (Overview, API, Errors, Configuration, Account).
      Editable: Piped API URL (live), proxy URL and NewPipeExtractor commit (applied by
      `sonare-piped-backend/runPiped.sh`). See the Admin section of `sonare-backend/README.md`.
- [ ] Add a product logo in the web favicon, mobile app icon and linux app icon. i have added icons file in system-design, take whats needed and put it in respected UI's assets folder.
- [ ] While playing in online mode, song is getting cutted/lagged(i guess the stream size is not enough)

## Now

- [ ] Make the app runnable end to end with all UI working properly (desktop + mobile)

### Found in the 2026-09-24 UI audit, not fixed yet

- [x] ~~Mobile has no backend at all.~~ Connected 2026-09-24: sign in / sign up, catalog,
      favourites, playlists, play history, lyrics and streaming playback.
- [x] ~~Background playback + lock-screen controls~~ Done 2026-09-24 with the app's own Media3
      module (`mobile/android/app/src/main/java/com/mobile/player`); react-native-video is gone.
- [x] ~~Guest mode~~ Done 2026-09-24 on mobile and desktop: guests browse and play; favourites,
      playlists, follows, lyric edits and history need an account (`accountGate.ts` in each app).
- [ ] **Mobile follow-ups:**
  - The native player is **Android only**. iOS needs the same bridge on AVFoundation +
    MPNowPlayingInfoCenter / MPRemoteCommandCenter (`src/native/SonarePlayer.ts` is the contract).
  - Queue restore: after the app process dies, the queue and position are gone (the server has
    `/me/player-state` for this).
  - API host is hardcoded to `10.0.2.2:3010` (emulator) in `mobile/src/data/config.ts`; a
    physical phone needs the machine's LAN IP, and release builds need HTTPS (cleartext is
    only allowed in debug).
  - Offline mode has nothing to show yet: there are no downloads / local files on mobile.
  - Settings rows other than Account (crossfade, folders, cache size) are still static.
  - Artist `monthlyListeners` is actually YouTube subscriber count.
- [ ] **Accounts:** no password reset, email verification or login rate limiting yet; tokens
      are stored in AsyncStorage (fine for dev, use Keychain/Keystore storage for release).
- [ ] Desktop guest gate resumes the like / follow / new playlist after sign-in, but for "Add to
      playlist…" in the track menu and lyric edits it only brings you back to the same screen.
- [ ] Album-cover size hints live in an in-memory cache (`albumThumbFor` in
      `sonare-backend/src/normalize/index.ts`); after a backend restart, covers fall back to
      the ~2 MB signed image until the album shows up in a search again.
- [ ] **Linux build can't play AAC.** WebKitGTK decodes through GStreamer, and the AAC decoder
      (`gstreamer1.0-libav`) isn't installed. Opus/MP3 play; the muxed AAC fallback stream
      and the `.m4a` files in the local library won't. Also a packaging note for users.
- [x] ~~Track art at size=640 404s when `maxresdefault.jpg` is missing~~ The backend now probes
      maxresdefault → hq720 → mqdefault once per video (`largestThumb` in `app.ts`).
- [ ] **Neutralino 6.9.0 aborts on rejected WebSocket handshakes** (`websocketpp ... invalid
state`). Only hit when a second client attaches without a connect token (testing);
      worth rechecking on a newer Neutralino.
- [ ] Linux window opens with the Web Inspector docked (`enableInspector: true`) - fine for
      dev, make sure release builds turn it off.

## Later: external dependencies that may break

Parked until the app runs cleanly. Rajan has ideas for fixing these.

### High risk

- [ ] **YouTube scraping via NewPipeExtractor.** Piped scrapes YouTube, so any YouTube
      change (signature/n-param, layout changes like `lockupViewModel`) breaks search,
      playlists or playback. The extractor is pinned to a commit in
      `sonare-piped-backend/build.gradle` (`NewPipeExtractor:13a655fe…`), so upstream fixes
      only arrive when we bump it and rebuild.
- [ ] **Bot detection (PoToken / BotGuard via `bg-helper`).** Google changes this often;
      when it breaks, streams fail or return "Sign in to confirm you're not a bot".
      Worse from datacenter IPs than home connections.
      _Already seen 2026-09-24:_ some `c=VISIONOS` stream URLs serve only the first ~1 MB
      and 403 the rest (no `pot=` token on that client). The backend relay now swaps in a
      fresh URL on 403, but that's a workaround, not a fix.
- [ ] **Artist pages depend on search.** The extractor returns nothing for auto-generated
      "- Topic" artist channels, so top tracks / albums now come from YouTube Music search
      filtered by channel id (`searchArtistCatalog` in `sonare-backend/src/app.ts`).
- [ ] **Expiring / hardcoded YouTube URLs.**
  - `googlevideo.com` stream URLs expire after ~6h; anything caching them longer
    (Redis, waveform extraction in `sonare-backend/src/peaks.ts`) hands out dead links.
  - Thumbnails are built by hand as `https://i.ytimg.com/vi/${id}/...` in
    `sonare-backend/src/app.ts`; should come from the Piped response instead.

### Medium risk

- [ ] **`:latest` Docker images.** `1337kavin/piped-proxy:latest` and
      `1337kavin/bg-helper-server:latest` in `sonare-piped-backend/docker-compose.yml`
      can change incompatibly or stop being published (single-maintainer project).
      Pin to digests.
- [ ] **JitPack.** NewPipeExtractor is fetched from `jitpack.io` by commit hash. If JitPack
      is down or purges the build, `docker compose build piped` fails. Keep a backup with
      `docker save sonare-piped:local`.
- [ ] **Lyrics providers.**
  - LRCLIB (`lrclib.net`): free community service, no SLA, no key.
  - Genius API: needs `GENIUS_CLIENT_ACCESS_TOKEN`; token can be revoked or rate-limited.

### Low risk

- [ ] **Piped's default public endpoints** in `config.properties` (`kavin.rocks` RYD proxy,
      SponsorBlock, Matrix, capmonster). Sonare doesn't appear to use them; consider
      `DISABLE_RYD:true` etc.
- [ ] **Toolchain drift.**
  - Neutralino 6.9.0 binaries are downloaded from GitHub on install.
  - Google Play raises the required Android target SDK yearly; RN / Reanimated 4 /
    NativeWind / JDK upgrades are tightly coupled.
  - npm deps use `^` ranges; safe while the lockfiles are kept.
  - ffmpeg must be on the host, otherwise waveforms silently fall back to fake peaks.

### Non-technical

- [ ] Pulling YouTube content through Piped is against YouTube's ToS. Personal use: risk
      is IP blocking. Public release: possible takedown requests.
