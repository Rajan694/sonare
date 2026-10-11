# In-app YouTube fetching

Started 2026-10-11 on `generic-branch`. Implements the TODO.md item "Long term: fetch from
YouTube inside the apps".

## Goal

The Android and desktop apps talk to YouTube themselves, from the user's own IP:
Android through NewPipeExtractor, desktop through youtubei.js. This covers search,
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
| Waveforms | Placeholder first, then filled in on device from the audio being played (no extra download), uploaded to the backend cache once complete. See "Waveforms" |

## Architecture

```
                 ┌──────────── shared/catalog (pure TS) ────────────┐
 Android  ──►  NewPipeExtractor (Kotlin) ─┐                         │
                                          ├─► YouTubeSource ─► catalog functions ─► Sonare API shapes
 Desktop  ──►  youtubei.js + curl ────────┘   (Piped-shaped JSON)    (same output as the backend routes)
                 └──────────────────────────────────────────────────┘
        on failure ─► backend /api/v1/... (backend ─► Piped, URL set in admin)
 Web      ──►  backend /api/v1/... (unchanged)
```

- **`YouTubeSource`** is the in-app equivalent of the backend's `Piped` client
  (`sonare-backend/src/upstream/piped.ts`): `getStream`, `search`, `searchNextPage`,
  `suggestions`, `trending`, `channel`, `channelTabs`, `playlist`, `playlistNextPage`. It
  returns **Piped-shaped JSON** (`sonare-backend/src/upstream/piped.types.ts`). Piped is itself
  NewPipeExtractor turned into JSON, so the Android mapping is close to one-to-one, and one
  shape lets both apps share a single catalog layer.
- **`shared/catalog`** ports the backend's route logic and normalizers (`catalog.routes.ts`,
  `normalize/index.ts`, `ids.ts`) into pure TypeScript with no Express, undici or Redis. It
  takes a `YouTubeSource` and returns exactly what the matching backend endpoint returns
  (`shared/apiTypes.ts`). Fixture-based tests pin both to the same output.
- **Images** load straight from YouTube's CDNs in the apps (no backend `/artwork` proxy).
- **Stream URLs** are bound to the IP and client that extracted them, so the app that extracts
  a URL is also the one that plays it. The backend relay is used only on fallback.
- **License:** NewPipeExtractor is GPL-3.0. The Android APK that bundles it is distributed
  under GPL-3.0 as a whole (source must be available; the repos are public). youtubei.js,
  bgutils-js: MIT. Don't copy code from Piped (AGPL); write our own mapping.

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
4. **Peaks.** `PUT /tracks/:id/peaks` (signed in, validated: N bars, values 0–1, kept only if
   none are cached). `GET` returns cached peaks or `{ peaks: null }`. Server-side ffmpeg
   extraction is removed.

## App changes

- **Desktop (Neutralino builds only; the web build is untouched).**
  - youtubei.js with a custom `fetch` that runs `curl` through `Neutralino.os` (curl ships
    with Windows 10+ and nearly every Linux).
  - PoToken from bgutils-js inside the webview.
  - Linux playback fetches audio bytes for WebCodecs, so googlevideo must allow that request
    from the app's origin. **Spike first.**
- **Android.**
  - A `SonareYouTube` Kotlin module wrapping NewPipeExtractor (pinned to the same commit as
    `sonare-piped-backend`), with an OkHttp `Downloader`, returning Piped-shaped JSON.
  - A WebView PoToken provider, as the NewPipe app does.
  - ExoPlayer plays the extracted URL directly; downloads refresh URLs through the module.
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

Desktop risk: with direct googlevideo URLs, a `MediaElementSource` on a cross-origin
`<audio>` outputs silence unless googlevideo sends CORS headers. That would break the EQ as
well as waveforms. Check it in the D0 spike.

## Phases

| # | Repo | Work | Who |
|---|---|---|---|
| B1 | backend + desktop admin | Admin Piped URL setting | opencode A |
| S1 | frontend/shared | `YouTubeSource` + `shared/catalog` port with fixture tests | opencode B |
| D0 | desktop | Spike: youtubei.js through curl, googlevideo from the webview, PoToken | Claude |
| B2 | backend | Stored metadata + hydration order + lyrics params | opencode A |
| B3 | backend | Peaks upload, drop ffmpeg extraction | opencode A |
| D1 | desktop | youtubei.js `YouTubeSource`, local-first api with backend fallback | opencode B |
| A1 | mobile/android | NewPipeExtractor module + JS `YouTubeSource` | opencode C |
| A2 | mobile | Direct playback, downloads, PoToken | opencode C |
| W1 | desktop + mobile | On-device waveforms + upload; snapshots on save/play | opencode |
| Z | root | TODO.md, api-contract.md, release notes | Claude |

Claude reviews every diff, runs typecheck/tests/builds, checks behavior in the running app,
and commits each phase on `generic-branch` once it passes.
