# In-app YouTube fetching

Started 2026-10-11 on `generic-branch`. Implements the TODO.md item "Long term: fetch from
YouTube inside the apps".

## Goal

The Android and desktop apps talk to YouTube themselves, from the user's own IP, both
through youtubei.js. This covers search,
suggestions, trending, albums, artists, playlists, streams and downloads. The server then
stops touching YouTube for them. The web build can't do this (CORS), so it keeps using
backend → Piped exactly as today.

When the in-app layer fails (YouTube changed something and the extractor in the installed
app is too old, or the network blocks it), the apps fall back to the backend's existing
endpoints. The backend's Piped URL is set on the admin page, so the fallback can be
repointed without a redeploy.

## Decisions (Rajan, 2026-10-11)

| Question | Answer |
|---|---|
| What moves into the apps | Everything YouTube, not just playback |
| Fallback | The backend's own endpoints. The admin page stores the Piped URL the backend uses (DB value overrides `.env` `PIPED_API_URL`) |
| Browser extension for web | No: more likely to get blocked |
| Android extractor | **youtubei.js on both apps** (after the D0 spike), not NewPipeExtractor: one shared TypeScript source. Both would break together anyway, since both depend on the VISIONOS client |
| YouTube client | Ordered list set on the admin page (default `VISIONOS`), served by a public backend endpoint, cached by the apps. Switching clients needs no app release. A kill switch turns in-app fetching off for everyone |
| Waveforms | Placeholder first, then filled in on device from the audio being played (no extra download), uploaded to the backend cache once complete. See "Waveforms" |

## Architecture

```
            ┌──────────────────────── shared/ (pure TS, no deps) ────────────────────────┐
 Android ─► │ youtubei.js (react-native build, RN fetch) ─┐                              │
            │                                             ├─► youtubeiSource ─► catalog ─► Sonare API shapes
 Desktop ─► │ youtubei.js (web build, fetch over curl) ───┘   (Piped-shaped JSON)         (same as backend routes)
            └────────────────────────────────────────────────────────────────────────────┘
        on failure ─► backend /api/v1/... (backend ─► Piped, URL set in admin)
 Web     ─► backend /api/v1/... (unchanged)
```

Each app creates its own `Innertube` instance (its platform build plus transport) and passes
it in. `shared/` describes the parts of youtubei.js it uses with its own small structural
types (`shared/youtube/innertubeLike.ts`), so it still imports nothing.

- **`YouTubeSource`** is the in-app equivalent of the backend's `Piped` client
  (`sonare-backend/src/upstream/piped.ts`): `getStream`, `search`, `searchNextPage`,
  `suggestions`, `trending`, `channel`, `channelTabs`, `playlist`, `playlistNextPage`. It
  returns **Piped-shaped JSON** (`sonare-backend/src/upstream/piped.types.ts`). Piped is itself
  NewPipeExtractor turned into JSON, so matching that shape keeps the in-app output identical
  to the backend's, and live Piped can serve as the reference in parity tests
  (`desktop/scripts/youtubeParity.ts`).
- **`shared/catalog`** ports the backend's route logic and normalizers (`catalog.routes.ts`,
  `normalize/index.ts`, `ids.ts`) into pure TypeScript with no Express, undici or Redis. It
  takes a `YouTubeSource` and returns exactly what the matching backend endpoint returns
  (`shared/apiTypes.ts`). Fixture-based tests pin both to the same output.
- **Images** load straight from YouTube's CDNs in the apps (no backend `/artwork` proxy).
- **Stream URLs** are bound to the IP and client that extracted them, so the app that extracts
  a URL is also the one that plays it. The backend relay is used only on fallback.
- **License:** youtubei.js is MIT, so the apps stay MIT. Don't copy code from Piped (AGPL)
  or NewPipeExtractor (GPL); write our own mapping.

## Backend changes

1. **Admin Piped URL.** A key/value `app_settings` table (migration), admin
   `GET/PUT /admin/settings`, and a "Piped" card on the admin page with a "Test" button
   that runs `/healthcheck` against the entered URL. The Piped client reads the DB value
   (cached in memory and refreshed on save), falling back to `.env`.
2. **Stored metadata, so the library stops calling YouTube.** Today every library listing
   rebuilds each track from Piped `/streams/:id` (`db/hydrate.ts`), and library albums and
   artists call `/playlists` and `/channel`.
   - A `catalog_items` table (`kind`, `id`, `data jsonb`, `updated_at`) is written only by
     the server, from Piped results it already fetched.
   - A nullable `meta jsonb` snapshot on each user ref row (favourite tracks/albums, artist
     follows, playlist tracks, play history, player state queue) is written by the client
     when it saves, plays or adds an item. It is per user, so one client can't change what
     another user sees.
   - Hydration order: the user's snapshot → `catalog_items` → Piped (then stored).
3. **Lyrics** accept `title`, `artist` and `durationMs` from the client, so they don't need
   `/streams` to look the song up.
4. **Peaks.** `PUT /tracks/:id/peaks` (signed in, `yt:` ids only, exactly 150 values in 0–1,
   first upload wins, rate-limited). `GET` returns the uploaded waveform resampled to `bars`,
   or the shared deterministic placeholder with `placeholder: true` (released apps read only
   `peaks`, so it stays an array). Server-side ffmpeg extraction is removed.
5. **App config.** Public `GET /app-config` → `{ inAppYoutube, youtubeClients, updatedAt }`,
   edited on the admin Settings page.

## App changes

- **Desktop (Neutralino builds only; the web build is untouched).**
  - youtubei.js with a custom `fetch` that runs `curl` through `Neutralino.os` (curl ships
    with Windows 10+ and nearly every Linux). curl reads URL, headers and body from a `-K`
    config file, so nothing passes through a shell.
  - Audio is downloaded by curl (always with a `Range` header) into a stream cache and
    played through the local-file path. See "D0 spike results".
- **Android.**
  - youtubei.js's `react-native` build with RN `fetch` (no CORS on Android). Check Hermes first.
  - ExoPlayer plays the extracted URL directly, always with a `Range` header.
  - Downloads refresh URLs through the same source.
- **Both.**
  - `api.ts` catalog calls go `local → backend` on failure.
  - Saves and plays send the item's metadata snapshot.
  - Waveforms are computed from the playing audio and uploaded once per song.

## Waveforms

Today the server runs `ffmpeg -t 20` on the ≤64 kbps stream (`services/peaks.ts`). That costs
about 160 KB per song whatever its length (measured on a 1-hour file: 163,840 bytes read, no
seeks), but the bars show only the first 20 s stretched over the whole track.

New flow (Rajan's idea, 2026-10-11):
1. `GET /tracks/:id/peaks` has a cached real waveform → show it. Done.
2. Otherwise show `placeholderPeaks(trackId)`, deterministic and slightly dimmed.
3. While the song plays, tap the PCM the app already decodes: Android in
   `SonareAudioProcessor`, desktop in the `dsp.ts` Web Audio graph. Each bar covers a fixed
   share of `durationMs`. When the playhead passes a bar, it switches to the bar's real peak
   with a short animation. There is no second decode and no extra download. Players buffer only
   ~30–50 s ahead, so filling as the song downloads wouldn't show much more.
4. Seeks leave gaps. The partial waveform is kept on the device, and later plays fill it in.
5. Every bar real → `PUT /tracks/:id/peaks` once (canonical 150 bars; clients resample to
   their bar count). Podcasts work the same way; they upload after a full listen.

Desktop: googlevideo sends no CORS headers (D0), so the desktop app plays in-app streams from
a curl-downloaded cache file. That keeps the audio same-origin, so the EQ graph and the
waveform tap work as they do for local files.

## D0 spike results (2026-10-11, home IP, youtubei.js 18.1.0)

| Finding | Detail |
|---|---|
| Music search works in-app | `yt.music.search(q, { type: 'song' })`, 20 results |
| **VISIONOS client plays full length, no PoToken** | All 5 audio itags (251 opus …), 206 at 0 / 1.2 MB / 60 % / end, ~350 ms per `/player`. The same client Piped uses (its URLs carry `c=VISIONOS`, no `pot`) |
| Every other client stops at ~1 MB | MWEB, IOS, YTMUSIC, ANDROID_VR, TV_SIMPLY → 403 past 1 MB, even with PoTokens minted by bgutils-js (jsdom and real headless Chrome) |
| VISIONOS URLs need no deciphering | No signature cipher, no `n` param → no player JS, no `eval` in the apps |
| Throttle = missing `Range` header | Plain GET: 34 KB/s (135 s for 4.7 MB). Any `Range` header, even `bytes=0-`: 4.7 MB in ~1 s |
| googlevideo sends no CORS headers | `Access-Control-Allow-Origin` absent for app origins |
| BotGuard refuses non-YouTube origins | Signal output only on `https://www.youtube.com`, none on `http://localhost` |

Consequences:
- **Desktop:** youtubei.js requests go through `curl` (Neutralino). Audio bytes can't be
  fetched from the webview: the `<audio>` element is `crossOrigin='anonymous'` and goes through
  the EQ graph. So curl downloads the stream (always with a range) into a cache file, and
  playback reuses the local-file path (Linux decode, Windows `blob:`).
- **Android:** ExoPlayer can play the URL directly, but must always send a `Range` header (its
  default request from position 0 has none and gets throttled).
- **PoTokens aren't needed while VISIONOS works.** If YouTube closes it, the admin switches the
  client order or turns in-app off, and the apps use the backend (Piped + bg-helper).

## Phases

| # | Repo | Work | Who |
|---|---|---|---|
| B1 | backend + desktop admin | Admin Piped URL setting (done) | opencode A |
| S1 | frontend/shared | `YouTubeSource` + `shared/catalog` port with fixture tests (done) | opencode B |
| D0 | desktop | Spike (done, see results above) | Claude |
| B1b | backend + admin | YouTube client order + in-app kill switch + public `GET /app-config` (done) | opencode A |
| S2 | frontend/shared | `youtubeiSource`: youtubei.js → Piped shapes, parity script against live Piped (done: album tracks match id for id; joined fields ~100 %) | opencode B |
| B2 | backend | Stored metadata + hydration order + lyrics params (done) | opencode C |
| B3 | backend | Peaks upload, drop ffmpeg extraction (done) | opencode A |
| D1 | desktop | curl transport, cache-file playback, local-first api with backend fallback (done; limited urls are probed and the session switched, a 403 refreshes once) | opencode D, Claude |
| A1 | mobile | Hermes check, youtubei.js wiring, local-first api, ExoPlayer `Range`, downloads (done; youtubei.js runs over an XHR `fetch`, since RN's `fetch` waits on timers that stop in the background) | opencode E, Claude |
| W1 | desktop + mobile | On-device waveforms + upload (done: desktop samples a pre-EQ `AnalyserNode`; Android's audio processor sends the level with each progress event) | Claude |
| M1 | desktop + mobile | Apps send metadata snapshots on favourite, playlist add and play sync (done; backend stores play snapshots too) | Claude |
| Z | root | TODO.md, api-contract.md (done); release notes with the next release | Claude |

Claude reviews every diff, runs typecheck/tests/builds, checks behavior in the running app,
and commits each phase on `generic-branch` once it passes.
