# TODO

# MY FINDINGS

- [x] in favourites page section on removing a song, i have to refresh the page to see the change, it should be removed immediately
      Done 2026-09-27: the row goes as soon as the heart is cleared; the list refetches after
      any heart change.
- [x] playlist section is not viewable in web on some screen, i have added the screenshot.
      Done 2026-09-27: the sidebar's nav, library links and playlists scroll as one area.
- [x] also what is this placeholders in Genres and in search screens(added screenshots).
      They were the design's generated-artwork squares, floated into blank cards. Genres are
      now full gradient cards (Library tab and Search).
- [x] if nothing playing, hide the bottom player(add screenshot).
- [x] make bottom player to take all the width available(right side have empty space).
- [x] add download button in main player and bottom player too.
      Done on desktop/web (bottom player + Now Playing) and mobile (Now Playing).
- [x] in offline mode, songs are still cutting(like skipping some milliseconds), playback is not smooth.
      Done 2026-09-27: files over 15 min / 60 MB (46 of the 279 in ~/Music) still went through
      the <audio> element that drops audio on WebKitGTK. They now stream through Web Audio
      (WebCodecs decoder in a worker, `streamPlayback.ts`); measured gap-free in the app.
- [x] mobile screen is not same as the pdf inside the design-system(like setting icon on left of profile). do check with the pdf
      Done 2026-09-27. Web at phone width had no top bar at all (no search field, settings or
      profile): it now has the M-series headers. Mobile app: detail screens open inside
      the tab (mini player + tab bar stay), header alignment, Library toolbar, Now Playing.
- [x] **Design gaps left on mobile** (features that don't exist yet, so no dead buttons were
      added): Now Playing's "Playing from <album>" eyebrow, audio output / cast card, sleep
      timer, and Settings rows for them.
      Done 2026-10-03: "Playing from" album / playlist / artist / search; output card and
      picker (speaker, wired, USB, Bluetooth via ExoPlayer's preferred device); sleep timer
      (15-90 min or end of track, counted natively); Settings rows for both. No Chromecast /
      cast — that needs the Cast SDK and a receiver app.
- [x] **Desktop re-renders every row on each position tick.**
      Done 2026-10-03 (prod-readiness F7): the position lives in its own store
      (`store/playbackPosition.ts`, `usePlaybackPosition()`), the PlayerContext value is
      memoised, and only time/progress displays subscribe.
- [x] IN mobile bounceback animation way too high.
      Done 2026-10-03: every spring settles without overshoot (`springs` in `mobile/src/lib/motion.tsx`):
      sheets, swipe-to-skip, mini player swipe, presses, toasts, segmented controls.
- [x] in search we have browse categories, it have ambient, electronica etc..., cant it have devotional, punjabi, bhojpuri, popular, top this year.
      Done 2026-10-03: `GET /genres` lists Popular, Top this year, Bollywood, Punjabi, Bhojpuri,
      Devotional, Party, Romantic, Sad, Lo-fi, Workout, Ghazal, … each with the search it opens.
- [x] add a setting in settings section for preferred lyrics language, if avalilable that songs lyrics in that laguage then use it else use the native song one(like currently it is)
      Done 2026-10-03: Settings → Lyrics language (per device). LRCLIB has no language field, so the
      backend picks the version written in the chosen script (`?script=devanagari|latin|gurmukhi|…`)
      and falls back to the song's own.
- [x] in search when we are searching a song, we show artists panel, but there we dont load thumbnails.
      Done 2026-10-03: the Artists row uses the artists' pictures and opens their pages.
- [x] when add a playlist, native modal opens to enter a playlist name, which is not good, also playback stops, which is not correct.use a custom model related to our theme
      Done 2026-10-03: themed dialogs (`desktop/src/store/dialogs.ts`) replace every window.prompt /
      window.confirm; the native ones blocked the page, which stalled the audio on WebKitGTK.
- [x] on each songs, add a option to add it to playlist( in the bottom player).
      Done 2026-10-03: bottom player and Now Playing (desktop), Now Playing's + (mobile).
- [x] in the artists panel we have option to show the artists(open question how we can follow artist, does liking a song, or adding it to a playlist showld add that songs artist in this panel or top played songs artist goes there). same question for genre(use the devotional, party, sad etc...) same question for album?
      Done 2026-10-03 (decided: automatic): Artists = followed, then the artists of liked and
      playlisted songs (with their song count). Genres = the mood / language categories.
      Albums stay the saved ones: YouTube songs don't say which album they're from.
- [x] under library in songs panel, we have 3 optnos, recently added,all sources and downlaoed, on click of them, thedropdown is native, use a custom related to our theme.
      Done 2026-10-03: `desktop/src/components/ui/Select.tsx` everywhere (Library, Settings,
      Equalizer); mobile's sort opens a themed sheet.
- [x] in some screens after song title we have - line then source(server/local) then time, what is -(its for album(confirmed from pdf file in design systems(use it for artist name, also based on the image, we have to show plays counter(page no. 23 in pdf)))).
      Done 2026-10-03: the column shows the artist when a song has no album, and a PLAYS column
      (your play count) sits before the duration.
- [x] from library, remove the folders option as we have folder option shown on top right in songs screen(folder button is shown in album, artist, genres, why???)
      Done 2026-10-03: no Folders tab (desktop and mobile); the Folders button shows on Songs only.
- [x] in page 31 in the pdf, we have option to change the speaker(we have not added it in yet)(in mobile too.)also this option is on the left of volume slider
      Done 2026-10-03: desktop output button left of the volume + Now Playing card (Linux window:
      `pactl` moves Sonare's PulseAudio / PipeWire stream, so `os.execCommand` is now allowed in
      neutralino.config.json; browsers / WebView2: setSinkId; hidden elsewhere). Mobile: see above.
- [x] remove the testcases for sonare-piped-backend(i want cleaner code in it)
      Done 2026-10-03: `testing/` and the docker-compose test workflows are gone; CI keeps the build.
- [x] in mobile, backend is unable to connect issue.(all changes you do to desktop ui above related to downloads, playlist, audio source).
      Done 2026-10-03: debug builds use localhost:3010 over `adb reverse` (runFE.sh sets it up, emulator
      and USB phones alike); Settings → Server address for a phone on Wi-Fi. The desktop changes
      above have their mobile counterparts.

## Now

- [ ] Make the app runnable end to end with all UI working properly (desktop + mobile)

- [x] **Tests behind the 2026-10-03 changes.** Done 2026-10-03: the desktop suites drive the
      themed dialogs and dropdowns (`desktop/test/helpers/dialogs.ts`), the mobile ones the sort
      sheet, browse categories and new springs. Desktop 485, mobile 237, backend 363 tests pass.
- [ ] New code with no tests of its own yet: the output pickers, the sleep timer, queue restore,
      the lyrics script choice (backend and apps), derived library artists, Add to playlist from
      the player, the Server address sheet.

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
  - [x] ~~Queue restore~~ Done 2026-10-03: queue, position, shuffle / repeat and "playing from"
        are saved on the phone and to `/me/player-state`, and come back paused (`store/playerPersist.ts`).
  - [x] ~~API host hardcoded to `10.0.2.2:3010`~~ Done 2026-10-03: localhost over `adb reverse`,
        plus Settings → Server address. Release builds still need HTTPS.
  - Offline mode shows downloaded songs only; there is no local-folder scan on mobile yet
    (the Folders screen now says so instead of showing made-up folders).
  - [x] Mobile known bugs fixed 2026-10-03 (prod-readiness F10): album heart, equalizer
        preset and "stay offline automatically" are saved; Folders has an honest empty state.
        Still open: the playlist heart (MOB-PL-004) — the backend has no endpoint for saving a
        YouTube playlist.
  - [x] ~~The Audio screen's controls are local state~~ Done before 2026-10-03: they run in the
        native player's own audio processing.
  - Settings rows other than Account (crossfade, folders, cache size) are still static.
  - Artist `monthlyListeners` is actually YouTube subscriber count.
- [x] ~~**Accounts:** no password reset, email verification or login rate limiting yet~~
      Done: password reset, email verification and login rate limiting are in the backend and
      both apps.
- [x] ~~Mobile tokens are stored in AsyncStorage~~ Already in the Keychain / Keystore
      (`react-native-keychain`, `mobile/src/data/auth.ts`).
- [x] Desktop guest gate resumes the like / follow / new playlist after sign-in, but for "Add to
      playlist…" in the track menu and lyric edits it only brings you back to the same screen.
      Done 2026-10-03: the playlist picker opens after sign-in; lyric edits / offsets carry on.
- [x] Album-cover size hints live in an in-memory cache (`albumThumbFor` in
      `sonare-backend/src/normalize/index.ts`); after a backend restart, covers fall back to
      the ~2 MB signed image until the album shows up in a search again.
      Done 2026-10-03: also kept in Redis for 30 days.
- [ ] **Linux build can't play AAC.** WebKitGTK decodes through GStreamer, and the AAC decoder
      (`gstreamer1.0-libav`) isn't installed. Opus/MP3 play; the muxed AAC fallback stream
      and the `.m4a` files in the local library won't. Also a packaging note for users.
- [x] ~~Track art at size=640 404s when `maxresdefault.jpg` is missing~~ The backend now probes
      maxresdefault → hq720 → mqdefault once per video (`largestThumb` in `routes/media.routes.ts`).
- [ ] **Neutralino 6.9.0 aborts on rejected WebSocket handshakes** (`websocketpp ... invalid
state`). Only hit when a second client attaches without a connect token (testing);
      worth rechecking on a newer Neutralino.
- [x] ~~Linux window opens with the Web Inspector docked~~ `enableInspector` is false in
      `neutralino.config.json`; only `runFE.sh linux` turns it on for development.

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
      filtered by channel id (`searchArtistCatalog` in `sonare-backend/src/routes/catalog.routes.ts`).
- [ ] **Expiring / hardcoded YouTube URLs.**
  - `googlevideo.com` stream URLs expire after ~6h; anything caching them longer
    (Redis, waveform extraction in `sonare-backend/src/services/peaks.ts`) hands out dead links.
  - Thumbnails are built by hand as `https://i.ytimg.com/vi/${id}/...` in
    `sonare-backend/src/routes/media.routes.ts`; should come from the Piped response instead.

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
