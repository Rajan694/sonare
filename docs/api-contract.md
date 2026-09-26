# Sonare — API Contract & Piped Comparison

Status: draft 1 · 2026-09-22
Scope: what `sonare-backend` (Node + Express) must expose, what `sonare-piped-backend` (your Piped instance) already gives us, and where the two do not line up.

---

## 0. Decisions on record

| # | Decision |
|---|---|
| D1 | `sonare-backend` exposes a **Sonare-native API** shaped like the UI's `Track / Album / Artist / Playlist` types (`src/data/types.ts`). |
| D2 | `sonare-piped-backend` is a **private upstream**, not a public API. The frontends never call it directly. Express calls it server-side and normalises. |
| D3 | Lyrics come from **Genius** (your keys) for metadata + plain lyrics, with **LRCLIB** for time-synced `.lrc`. See §4 — Genius alone cannot satisfy the Lyrics screen. |
| D4 | **Local player / offline mode is native-only.** The web build ships without it. See §1. |
| D5 | User data (favourites, play counts, playlists, history) lives in **Sonare's own DB**, not in Piped's. Piped's `/user/*` and `/feed` endpoints are not used. |

---

## 1. Platform matrix

Three UI targets exist today:

- **web** — `sonare-frontend/other-screens` built by Vite, served in a browser
- **desktop** — the same bundle wrapped in Neutralino (`neutralino.config.json`)
- **mobile** — `sonare-frontend/mobile`, React Native

| Capability | web | desktop (Neutralino) | mobile (RN) |
|---|---|---|---|
| Server catalog (search / album / artist / trending) | ✅ | ✅ | ✅ |
| Server streaming | ✅ | ✅ | ✅ |
| Lyrics (synced + plain) | ✅ | ✅ | ✅ |
| Local folder scan & tag read | ❌ | ✅ `os.*` / `filesystem.*` | ✅ native module |
| Local file playback | ❌ | ✅ | ✅ |
| **Offline mode toggle** | ❌ hidden | ✅ | ✅ |
| `Folders` screen | ❌ hidden | ✅ | ✅ |
| `ModeSwitch` screen | ❌ hidden | ✅ | ✅ |
| Download-for-offline | ❌ | ✅ | ✅ |
| Equalizer | ⚠️ Web Audio `BiquadFilter` chain only | ✅ native | ✅ native |
| Output device / Cast | ❌ | ⚠️ limited | ✅ |
| Waveform peaks | ✅ (server-computed) | ✅ | ✅ |

**Consequence for the API.** Everything in §6.6 (local library) is a **device-local API, not HTTP**. Express must not own folder scanning, tag reading, or EQ. What Express *does* own is the **merge**: playlists, favourites and play counts that span local and server tracks. Those endpoints accept local-track fingerprints (§8.3).

In the web build the UI must hard-gate on a build flag:

```ts
export const CAPS = {
  localLibrary: false,   // true on desktop + mobile
  offlineMode:  false,
  downloads:    false,
  nativeEq:     false,
} as const
```

`mode` is forced to `'online'`, the `Offline` segment in `SegmentedControl` is not rendered, `Folders` / `ModeSwitch` routes are not registered, and `SourceGlyph` never shows a `local` badge.

---

## 2. Screen → data requirements

Derived from the actual screens in both frontends. "L" = device-local, "S" = server (`sonare-backend`).

### Home (`screens/Home.tsx`, both)

| What it renders | Src | Endpoint |
|---|---|---|
| "Welcome back, Rajan" | S | `GET /me` |
| "Continue listening" card (track + 38% progress + `1:24`) | S/L | `GET /me/player-state` |
| "Jump back in" tiles (4) | S | `GET /me/recently-played?limit=8` |
| "Made for you" carousel (online only) | S | `GET /discover/made-for-you` |
| "Trending locally this week" / "Trending now" | S | `GET /trending?region=IN` |
| "Recently played" song rows (5) | S | `GET /me/recently-played?limit=5` |
| "2 new releases from artists you follow" | S | `GET /me/new-releases` |
| `Sync now` button | S | `POST /me/sync` |
| offline: "On this device" | L | local index |

### Search (`screens/Search.tsx`, both)

| What it renders | Src | Endpoint |
|---|---|---|
| As-you-type suggestions | S | `GET /search/suggestions?q=` |
| Results, filterable: Songs / Albums / Artists / Playlists / Genres | S | `GET /search?q=&type=&cursor=` |
| Local results interleaved, `source` badge per row | L+S | local index + above |
| Browse categories grid (Ambient, Electronica, Post-rock, Indie, Jazz, Classical, Hip-hop, Folk) | S | `GET /genres` |
| "N more results not available offline" | — | client-computed |

### Library (`screens/Library.tsx`, both)

| What it renders | Src | Endpoint |
|---|---|---|
| Tabs: Songs / Albums / Artists / Genres / Folders / Favourites / Most played | S+L | `GET /me/library/{tracks,albums,artists,genres}` |
| Sort: Recently added / Most played / A-Z | S | `?sort=addedAt\|playCount\|title&order=` |
| Row columns: `#`, art, TITLE, ALBUM, **SOURCE**, **PLAYS**, duration | S+L | same |
| Total count ("412 songs") | S+L | `meta.total` |
| Play all / Shuffle all | — | client |

### Album (`screens/Album.tsx`, both)

`title, artist, artistId, year, trackCount, genre, source, downloaded` + track list + Play / Shuffle / **Download** / Favourite.
→ `GET /albums/:id`, `GET /albums/:id/tracks`, `PUT|DELETE /me/favourites/albums/:id`, `POST /downloads` (native only).

### Artist (`screens/Artist.tsx`, both)

`name, monthlyListeners (online only), albumCount, localTrackCount, following` + popular tracks + album grid + Follow.
→ `GET /artists/:id`, `GET /artists/:id/top-tracks`, `GET /artists/:id/albums`, `PUT|DELETE /me/following/artists/:id`.

### Playlist / Playlists (`screens/Playlist.tsx`, `Playlists.tsx`)

`name, kind (local|synced|online), trackCount, downloadedCount, updatedAt` + tracks.
→ `GET /me/playlists`, `GET /playlists/:id`, `GET /playlists/:id/tracks`, plus full CRUD (§6.5).

### NowPlaying (`screens/NowPlaying.tsx`, both)

Needs `title, artist, durationMs, source, codec, bitrateKbps, favourite, peaks[]` **and a playable URL**.
→ `GET /tracks/:id`, **`GET /tracks/:id/stream`** (§6.3), `GET /tracks/:id/peaks`, `PUT /me/favourites/tracks/:id`.
Waveform in the desktop build reads `currentTrack.peaks` (150 bars) — that array has to come from somewhere; see §8.4.

### Lyrics (`screens/Lyrics.tsx`, both)

Synced lines `[{ atMs, text }]`, plain-text fallback, `.lrc` source badge, per-track **offset** (`Offset -0.3s`), auto-scroll, "Import lyrics".
→ `GET /tracks/:id/lyrics`, `POST /tracks/:id/lyrics` (manual import), `PATCH /tracks/:id/lyrics/offset`.

### Queue (`screens/Queue.tsx`, both)

Queue list, now-playing index, "N songs · 2 from server", clear, reorder. **Client state** (`store/player.ts`), optionally mirrored to `PUT /me/player-state` for cross-device resume.

### Equalizer (`screens/Equalizer.tsx`, both)

9 bands `32 / 64 / 125 / 250 / 500 / 1K / 2K / 8K / 16K`; presets `Flat, Bass Boost, Classical, Electronic, Hip-Hop, Jazz, Pop, Rock`; bass boost, volume normalization, gapless, playback speed `0.5×–2.0×`; output device picker.
**All device-local.** Only persisted server-side: `GET|PUT /me/settings`.

### Folders (`screens/Folders.tsx`, both)

Device storage breakdown (Albums / Downloads), "Last scan 12 min ago · 6 new songs found", scanned folders (`name, path, trackCount, bytes, included`), excluded folders, Add / Rescan / Remove.
**100% device-local** (§6.6). Never an HTTP endpoint.

### Settings / ModeSwitch

Toggles + copy only. `GET|PUT /me/settings`, `POST /auth/logout`.

---

## 3. Piped backend — complete exposed API

Read from `forReference/Piped/backend/src/main/java/me/kavin/piped/server/ServerLauncher.java`, cross-checked against `backend/testing/api-test.sh` in the same clone. **56 route registrations.**

### 3.1 Meta

| Method | Path | Params | Notes |
|---|---|---|---|
| GET | `/healthcheck` | — | DB ping |
| GET | `/config` | — | instance config for the frontend |
| GET | `/version` | — | |
| OPTIONS | `/*` | — | CORS preflight |
| GET | `/` | — | 302 → `FRONTEND_URL` |
| GET | `/registered/badge` | — | shields.io redirect |

### 3.2 Content (unauthenticated) — **the part Sonare cares about**

| Method | Path | Params | Returns |
|---|---|---|---|
| GET | `/streams/:videoId` | — | `Streams` — incl. `audioStreams[]`, `videoStreams[]`, `duration`, `title`, `uploader`, `thumbnailUrl`, `hls`, `dash`, `chapters`, `subtitles`, `relatedStreams` |
| GET | `/clips/:clipId` | — | resolves clip → videoId |
| GET | `/search` | `q`, `filter` | `{ items[], nextpage, suggestion, corrected }` |
| GET | `/nextpage/search` | `q`, `filter`, `nextpage` | same, paged |
| GET | `/suggestions` | `query` | `string[]` |
| GET | `/opensearch/suggestions` | `query` | OpenSearch XML |
| GET | `/trending` | `region` | `ContentItem[]` |
| GET | `/channel/:channelId` | — | `Channel` |
| GET | `/c/:name` · `/user/:name` · `/@/:handle` | — | `Channel` (alias lookups) |
| GET | `/nextpage/channel/:channelId` | `nextpage` | `StreamsPage` |
| GET | `/channels/tabs` | `data`, `nextpage` | `ChannelTabData` — **this is how you get an artist's Albums/Singles tabs** |
| GET | `/playlists/:playlistId` | — | `Playlist` — works for YT Music album playlists (`OLAK5uy_…`) |
| GET | `/nextpage/playlists/:playlistId` | `nextpage` | paged |
| GET | `/rss/playlists/:playlistId` | — | RSS |
| GET | `/comments/:videoId` | — | `CommentsPage` |
| GET | `/nextpage/comments/:videoId` | `nextpage` | paged |
| GET | `/sponsors/:videoId` | `category`, `actionType` | SponsorBlock segments |
| GET | `/dearrow` | `videoIds` | DeArrow titles/thumbs |

**`filter` accepted values** (verbatim from Piped's own frontend): `all`, `videos`, `channels`, `playlists`, `music_songs`, `music_videos`, `music_albums`, `music_playlists`, `music_artists`.
The four `music_*` filters are what make Piped usable as a music backend at all.

### 3.3 Auth & user (Piped's own accounts) — **not used by Sonare**

`POST /register` · `POST /login` · `POST /logout` · `POST /user/delete`
`POST /subscribe` · `POST /unsubscribe` · `GET /subscribed` · `GET /subscriptions` · `POST /import`
`GET /feed` · `GET /feed/rss` · `GET /feed/unauthenticated` (GET+POST) · `GET /feed/unauthenticated/rss` · `GET|POST /subscriptions/unauthenticated`
`GET /user/playlists` · `POST /user/playlists/create` · `/add` · `/remove` · `/clear` · `/rename` · `/delete` · `PATCH /user/playlists/description` · `POST /import/playlist`
`GET /storage/stat` · `POST /storage/put` · `GET /storage/get`
`GET|POST /webhooks/pubsub`

### 3.4 Piped response models (fields you will map from)

**`Streams`** — `title, description, uploadDate, uploader, uploaderUrl, uploaderAvatar, thumbnailUrl, hls, dash, lbryId, category, license, visibility, tags[], metaInfo[], uploaderVerified, duration, views, likes, dislikes, uploaderSubscriberCount, uploaded, audioStreams[], videoStreams[], relatedStreams[], subtitles[], livestream, proxyUrl, chapters[], previewFrames[]`

**`PipedStream`** (each entry of `audioStreams`) — `url, format, quality, mimeType, codec, audioTrackId, audioTrackName, audioTrackType, audioTrackLocale, videoOnly, itag, bitrate, initStart, initEnd, indexStart, indexEnd, width, height, fps, contentLength`

**`StreamItem`** — `type, title, thumbnail, uploaderName, uploaderUrl, uploaderAvatar, uploadedDate, shortDescription, duration, views, uploaded, uploaderVerified, isShort`

**`Channel`** — `id, name, avatarUrl, bannerUrl, description, nextpage, subscriberCount, verified, relatedStreams[], tabs[]`

**`Playlist`** — `name, thumbnailUrl, description, bannerUrl, nextpage, uploader, uploaderUrl, uploaderAvatar, videos, relatedStreams[]`

---

## 4. Lyrics — Genius is not enough on its own

### 4.1 Genius API (`https://api.genius.com`, `Authorization: Bearer <CLIENT_ACCESS_TOKEN>`)

| Method | Path | Params | Returns |
|---|---|---|---|
| GET | `/search` | `q` | hits → `result.id, title, primary_artist, full_title, song_art_image_url, **url**` |
| GET | `/songs/:id` | `text_format` | song meta, album, release date, media, producers |
| GET | `/artists/:id` | `text_format` | artist meta, image |
| GET | `/artists/:id/songs` | `sort`, `per_page`, `page` | artist's songs |
| GET | `/referents` | `song_id` | annotations |

### 4.2 The gap

1. **Genius' API does not return lyrics text.** It returns `song.url` — the lyrics themselves live in the HTML page. Every library that "gets lyrics from Genius" (`lyricsgenius`, `lyricist`, …) scrapes that page. That is a licensing and fragility risk, and it is the reason to treat Genius as a *metadata + fallback plain-text* source only.
2. **Genius has no timestamps.** The `Lyrics` screen renders `{ atMs, text }` lines, highlights the active line, shows an `.lrc` badge and an offset control. Genius cannot feed any of that.

### 4.3 LRCLIB (`https://lrclib.net/api`) — the synced source

No key, no auth. Send a descriptive `User-Agent` (e.g. `Sonare/1.0 (https://github.com/<you>/sonare)`).

| Method | Path | Params | Returns |
|---|---|---|---|
| GET | `/api/get` | `track_name`, `artist_name`, `album_name`, `duration` | `id, trackName, artistName, albumName, duration, instrumental, plainLyrics, **syncedLyrics**` |
| GET | `/api/get-cached` | same | cache-only, never hits providers |
| GET | `/api/get/:id` | — | same shape |
| GET | `/api/search` | `q` *or* `track_name` (+`artist_name`, `album_name`) | array of the above |
| POST | `/api/publish` | body + `X-Publish-Token` | contribute lyrics back |
| POST | `/api/request-challenge` | — | `{ prefix, target }` for the publish token |

`syncedLyrics` is an LRC string (`[00:12.34] line`). The backend parses it into `{ atMs, text }[]` so the UI never sees LRC.

### 4.4 Resolution order the backend should implement

```
1. embedded tags on the local file  (USLT / SYLT / LYRICS)  → synced or plain
2. LRCLIB /api/get  (exact: track+artist+album+duration)    → synced
3. LRCLIB /api/search (fuzzy: track+artist)                 → synced
4. Genius /search → best hit → plain lyrics                 → plain, attributed
5. user-imported .lrc / .txt                                → synced or plain
```

Response always carries `provider` and `synced` so the UI can render the badge honestly.

---

## 5. Comparison — where Piped lines up and where it doesn't

### A. Direct map — Piped already answers it

| Sonare need | Piped endpoint | Work in Express |
|---|---|---|
| Search songs | `GET /search?filter=music_songs` | rename fields |
| Search albums | `GET /search?filter=music_albums` | rename fields |
| Search artists | `GET /search?filter=music_artists` | rename fields |
| Search playlists | `GET /search?filter=music_playlists` | rename fields |
| Search suggestions | `GET /suggestions?query=` | pass through |
| Paginate any of the above | `GET /nextpage/search` | cursor ↔ `nextpage` |
| Trending | `GET /trending?region=` | filter to music, rename |
| Album detail + tracks | `GET /playlists/:OLAK5uy_…` | `Playlist` → `Album` |
| Playlist detail + tracks | `GET /playlists/:id` | rename |
| Artist detail | `GET /channel/:UC…` | `Channel` → `Artist` |
| Artist albums / singles | `GET /channels/tabs?data=…` | tab `data` blob from `Channel.tabs[]` |
| **Playable audio URL** | `GET /streams/:videoId` → `audioStreams[]` | pick best, §8.2 |
| Track duration / title / artist / artwork | `GET /streams/:videoId` | rename |

### B. Adapt — the data exists but in a YouTube shape

| Sonare field | Where it comes from | Problem |
|---|---|---|
| `Track.album` / `albumId` | not on `StreamItem`; only via the album playlist that contains it | needs a reverse index or a second call |
| `Album.year` | `Playlist.description` / YT Music metadata | often missing → nullable |
| `Album.genre` | not exposed | derive from Genius or leave null |
| `Album.trackCount` | `Playlist.videos` | direct |
| `Artist.monthlyListeners` | `Channel.subscriberCount` | **not the same number** — either relabel the UI to "subscribers" or drop it |
| `Artist.albumCount` | count of items in the Albums tab | extra call |
| `Track.durationMs` | `duration` (seconds) | `×1000` |
| `Track.codec` / `bitrateKbps` | `PipedStream.codec` / `.bitrate` | bitrate is bps → `/1000` |
| `Track.bitDepth` | **n/a for streams** | local files only; null for `source:'server'` |
| `Track.source` | — | set by Sonare, not Piped |
| `Track.favourite`, `playCount`, `addedAt`, `lastPlayedAt` | **Sonare DB** | join per request |
| `Playlist.kind` (`local\|synced\|online`) | — | Sonare concept |
| `Playlist.downloadedCount` | — | device-local count, merged client-side |

### C. No Piped equivalent — build it

| Sonare need | Owner |
|---|---|
| Lyrics (synced + plain + offset + import) | Express → LRCLIB / Genius |
| Waveform peaks | Express (§8.4) |
| Favourites (tracks / albums / artists) | Express + DB |
| Play counts & history | Express + DB |
| "Recently played", "Made for you", "New releases from artists you follow" | Express + DB |
| Sonare accounts / sessions | Express + DB (**not** Piped's `/login`) |
| Sonare playlists spanning local + server tracks | Express + DB |
| Following artists | Express + DB (Piped's `/subscribe` is tied to *its* accounts) |
| Genres / browse categories | Express (static + derived) |
| Local folder scan, tag read, storage stats | **device**, not HTTP |
| Equalizer, gapless, normalization, playback speed | **device** |
| Output device / Cast | **device** |
| Downloads for offline | **device** (URL from `/tracks/:id/stream`) |
| Sync of local state ↔ server | Express, §6.7 |

### D. Piped endpoints Sonare will never call

`/register` `/login` `/logout` `/user/delete` `/subscribe` `/unsubscribe` `/subscribed` `/subscriptions` `/subscriptions/unauthenticated` `/feed*` `/import` `/import/playlist` `/user/playlists/*` `/storage/*` `/webhooks/pubsub` `/comments/*` `/nextpage/comments/*` `/sponsors/*` `/dearrow` `/rss/*` `/opensearch/suggestions` `/clips/*` `/registered/badge` `/`

That is **~35 of Piped's 56 routes dead weight** for a music client. Worth knowing before you decide how much of Piped to keep running: you only need the content half (§3.2) plus `/healthcheck` and `/config`.

---

## 6. `sonare-backend` — the API to build

Base: `/api/v1`. JSON. Bearer auth (Sonare's own JWT) on everything under `/me`.

### 6.1 Auth

| Method | Path | Body / params |
|---|---|---|
| POST | `/auth/register` | `{ email, password, displayName }` |
| POST | `/auth/login` | `{ email, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | `{ refreshToken }` |
| POST | `/auth/logout` | — |
| GET | `/me` | → `{ id, displayName, email, createdAt }` |

### 6.2 Catalog (upstream: Piped)

| Method | Path | Params | Upstream |
|---|---|---|---|
| GET | `/search` | `q`, `type=songs\|albums\|artists\|playlists\|all`, `cursor`, `limit` | `/search`, `/nextpage/search` |
| GET | `/search/suggestions` | `q` | `/suggestions` |
| GET | `/trending` | `region`, `limit` | `/trending` |
| GET | `/genres` | — | static |
| GET | `/tracks/:id` | — | `/streams/:videoId` |
| GET | `/albums/:id` | — | `/playlists/:id` |
| GET | `/albums/:id/tracks` | `cursor` | `/playlists/:id`, `/nextpage/playlists/:id` |
| GET | `/artists/:id` | — | `/channel/:id` |
| GET | `/artists/:id/top-tracks` | `limit` | `/channel/:id` → `relatedStreams` |
| GET | `/artists/:id/albums` | `cursor` | `/channels/tabs?data=` |
| GET | `/playlists/:id` | — | `/playlists/:id` |
| GET | `/playlists/:id/tracks` | `cursor` | `/nextpage/playlists/:id` |

When Piped can't be reached (connection refused, DNS failure), these routes and
`/me/recently-played` / `/me/most-played` answer `502 { error: { code: 'UPSTREAM_UNAVAILABLE' } }`;
any other Piped failure is `502 UPSTREAM_ERROR`. `/trending` errors only when it has nothing to
return, i.e. both Piped's trending feed and its search fallback failed. Favourites, library and
playlist tracks still come back as placeholder rows, because mobile reads heart state from
`/me/favourites/tracks` once, at sign-in.

### 6.3 Playback

| Method | Path | Params | Notes |
|---|---|---|---|
| GET | `/tracks/:id/stream` | `quality=auto\|low\|high`, `format=opus\|m4a` | → `{ url, mimeType, codec, bitrateKbps, contentLength, expiresAt }` |
| GET | `/tracks/:id/peaks` | `bars=150` | → `{ peaks: number[] }` |
| GET | `/tracks/:id/artwork` | `size=64\|140\|300\|640` | 302 or proxied bytes |
| GET | `/stream/:token` | — | optional: Express proxies the audio itself, Range-aware (§8.2) |

### 6.4 Lyrics

| Method | Path | Body / params | Notes |
|---|---|---|---|
| GET | `/tracks/:id/lyrics` | `prefer=synced\|plain` | → `{ synced: boolean, provider: 'lrclib'\|'genius'\|'tags'\|'user', offsetMs, lines: [{atMs,text}], plain?: string, attribution?: { name, url } }` |
| GET | `/lyrics/search` | `track`, `artist`, `album`, `durationSec` | manual picker for the "Import lyrics" button |
| POST | `/tracks/:id/lyrics` | `{ lrc }` or `{ plain }` | user import |
| PATCH | `/tracks/:id/lyrics/offset` | `{ offsetMs }` | the `Offset -0.3s` chip |
| DELETE | `/tracks/:id/lyrics` | — | revert to auto |

### 6.5 User library & playlists

| Method | Path | Notes |
|---|---|---|
| GET | `/me/library/tracks` | `sort=addedAt\|playCount\|title`, `order`, `source=all\|server`, `cursor` |
| GET | `/me/library/albums` · `/artists` · `/genres` | Library tabs |
| GET | `/me/favourites/tracks` | the `Favourites` tab |
| PUT / DELETE | `/me/favourites/tracks/:id` | heart toggle |
| PUT / DELETE | `/me/favourites/albums/:id` | album heart |
| PUT / DELETE | `/me/following/artists/:id` | Follow / Following |
| GET | `/me/recently-played` | `limit` |
| GET | `/me/most-played` | `limit`, `window=30d` |
| GET | `/me/new-releases` | Home banner |
| GET | `/discover/made-for-you` | Home carousel |
| GET | `/me/playlists` | → `Playlist[]` with `kind`, `trackCount` |
| POST | `/me/playlists` | `{ name, kind }` |
| GET | `/me/playlists/:id` | |
| PATCH | `/me/playlists/:id` | `{ name, description }` |
| DELETE | `/me/playlists/:id` | |
| POST | `/me/playlists/:id/tracks` | `{ trackIds[] }` |
| DELETE | `/me/playlists/:id/tracks` | `{ index }` or `{ trackIds[] }` |
| PATCH | `/me/playlists/:id/tracks/order` | `{ from, to }` |

### 6.6 Device-local API — **not HTTP**

Implement once per platform behind one TS interface so the screens stay identical.

```ts
interface LocalLibrary {
  listFolders(): Promise<Folder[]>
  addFolder(path: string): Promise<Folder>       // Neutralino os.showFolderDialog / RN SAF
  removeFolder(id: string): Promise<void>
  setIncluded(id: string, included: boolean): Promise<void>
  rescan(id?: string): Promise<{ added: number; removed: number; scannedAt: number }>
  storageStats(): Promise<{ total: number; albums: number; downloads: number }>
  listTracks(q?: LocalQuery): Promise<Track[]>   // source: 'local'
  readTags(path: string): Promise<TagBlock>
  peaks(path: string, bars: number): Promise<number[]>
}

interface LocalPlayer {
  load(src: { url: string } | { path: string }): Promise<void>
  play(): void; pause(): void; seek(ms: number): void
  setVolume(v: number): void
  setEq(gains: number[]): void                   // 9 bands
  setSpeed(x: number): void
  setGapless(on: boolean): void
  setNormalization(on: boolean): void
  outputs(): Promise<AudioOutput[]>
  setOutput(id: string): Promise<void>
}
```

Web ships a stub where `localLibrary` throws `UnsupportedOnWeb` and `CAPS.localLibrary === false` keeps it unreachable.

### 6.7 Sync (the local ↔ server bridge)

| Method | Path | Body |
|---|---|---|
| POST | `/me/sync` | `{ since, plays: [{ trackRef, at, ms }], favourites: [...], playlists: [...] }` → server merge result |
| PUT | `/me/player-state` | `{ trackRef, positionMs, queue: TrackRef[], index, shuffle, repeat }` |
| GET | `/me/player-state` | resume on another device |
| GET | `/me/settings` · PUT | EQ preset, gapless, normalization, download quality, stay-offline flag |

`TrackRef` is `{ kind: 'server', id }` or `{ kind: 'local', fingerprint }` — see §8.3.

---

## 7. Field mapping (Piped → Sonare)

### `Streams` → `Track`

| Sonare | From | Transform |
|---|---|---|
| `id` | request videoId | `yt:${videoId}` |
| `title` | `title` | strip `(Official Video)` etc. |
| `artist` | `uploader` | strip trailing ` - Topic` |
| `artistId` | `uploaderUrl` | `yt:${/channel/(UC…)}` |
| `album` / `albumId` | — | from the album playlist, else null |
| `durationMs` | `duration` | `× 1000` |
| `source` | — | `'server'` |
| `codec` | `audioStreams[i].codec` | `opus` → `OPUS`, `mp4a.40.2` → `AAC` |
| `bitrateKbps` | `audioStreams[i].bitrate` | `/ 1000 \| 0` |
| `bitDepth` | — | `undefined` |
| `playCount` / `favourite` / `addedAt` / `lastPlayedAt` | Sonare DB | join |
| `peaks` | `/tracks/:id/peaks` | lazy |
| artwork | `thumbnailUrl` | rewrite to proxy |

### `Channel` → `Artist`

`id` ← `yt:${id}` · `name` ← `name` · `monthlyListeners` ← `subscriberCount` *(relabel!)* · `albumCount` ← Albums-tab count · `localTrackCount` ← device · `following` ← Sonare DB · avatar ← `avatarUrl` · banner ← `bannerUrl`

### `Playlist` → `Album`

`id` ← `yt:${playlistId}` · `title` ← `name` · `artist` ← `uploader` · `artistId` ← `uploaderUrl` · `trackCount` ← `videos` · `year` ← parse `description`, nullable · `genre` ← null or Genius · `source` ← `'server'` · `downloaded` ← device

### `ContentItem` / `StreamItem` → `Track` (list rows)

`title`, `uploaderName`→`artist`, `uploaderUrl`→`artistId`, `duration×1000`, `thumbnail`. `album`, `codec`, `bitrateKbps` are **not present in list results** — either leave them null in list views (the Library `SOURCE` column still works) or hydrate on demand.

---

## 8. Implementation notes

### 8.1 ID scheme

Namespace everything so local and server rows can live in one list and one playlist:

```
yt:dQw4w9WgXcQ            server track
yt:OLAK5uy_k…             server album (YT Music album playlist)
yt:UCxxxx…                server artist (channel)
yt:PLxxxx…                server playlist
local:<sha1 of audio>     local track   (see 8.3)
sonare:<uuid>             Sonare playlist
```

### 8.2 Streaming

- `Streams.audioStreams[]` is what you want; ignore `videoStreams`, `hls`, `dash` — progressive audio is enough for a music player.
- Selection: prefer `codec` containing `opus` at the highest `bitrate ≤ target`, fall back to `mp4a` (Safari / iOS needs AAC).
- URLs are **time-limited and IP-bound**. Return `expiresAt` and let the client re-request `/tracks/:id/stream` on 403.
- Piped rewrites stream URLs to its proxy (`PROXY_PART`, `http://localhost:8091` in your `config.properties`). Either expose that proxy, or add `GET /stream/:token` in Express that pipes it through with `Range` support — the second option keeps the Piped instance entirely private, which is D2.
- `contentLength` is on `PipedStream`, so you can answer `Content-Length` / `206` correctly.

### 8.3 Local track fingerprint

So the same file on desktop and phone is one row server-side:

```
fingerprint = sha1(`${lower(artist)}|${lower(title)}|${lower(album)}|${round(durationMs/1000)}`)
```

Plays, favourites and playlist membership key off `TrackRef`. When a local track is later matched to a server track, store the link so counts merge rather than double.

### 8.4 Waveform peaks

The `NowPlaying` waveform wants 150 bars. Three options, in order of cost:

1. **Local files** — compute on device during scan, cache in the local index. Free.
2. **Server tracks** — Express decodes the first ~N seconds with `ffmpeg`/`audiowaveform`, caches `{trackId → peaks}` permanently. Worth it; the array is ~150 bytes.
3. **Fallback** — synthesise from the envelope of a short probe, or render a flat placeholder.

Do *not* try to compute peaks in the browser from a streamed URL: CORS plus full-file decode makes it unusable.

### 8.5 Caching

| Data | TTL |
|---|---|
| search results | 5 min |
| suggestions | 1 h |
| trending | 30 min |
| album / playlist detail | 6 h |
| artist detail | 12 h |
| `/streams` (metadata only) | 1 h |
| stream URL | **do not cache past `expiresAt`** |
| lyrics | permanent (with a manual refresh route) |
| peaks | permanent |

Redis or `lru-cache` — either is fine at this stage. Cache *before* normalisation so a shape change doesn't invalidate everything.

### 8.6 Keys & config

```
PIPED_API_URL=http://localhost:8090
PIPED_PROXY_URL=http://localhost:8091
GENIUS_CLIENT_ACCESS_TOKEN=...
LRCLIB_BASE=https://lrclib.net
LRCLIB_USER_AGENT=Sonare/1.0 (+https://github.com/<you>/sonare)
JWT_SECRET=...
DATABASE_URL=postgres://...
```

Genius keys stay server-side. Never ship them into the Neutralino or RN bundle.

---

## 9. Build order

1. **`/search`, `/tracks/:id`, `/tracks/:id/stream`** over Piped — one vertical slice makes Search + NowPlaying real on all three platforms.
2. Replace `data/mock.ts` in `other-screens` with a typed API client; keep the same exported names so the screens don't change.
3. `/albums/:id`, `/artists/:id`, `/playlists/:id` — Album / Artist / Playlist screens.
4. Auth + `/me/favourites` + play counts — Library's `PLAYS`, `Favourites`, `Most played` tabs stop being decorative.
5. Lyrics (LRCLIB first, Genius second).
6. Peaks.
7. Local library on desktop, then mobile — behind `CAPS`, so web is never touched.
8. `/me/sync` last; it only matters once two devices exist.

---

## Sources

- `forReference/Piped/backend/src/main/java/me/kavin/piped/server/ServerLauncher.java` (local clone) and [the same file upstream](https://raw.githubusercontent.com/TeamPiped/Piped-Backend/master/src/main/java/me/kavin/piped/server/ServerLauncher.java)
- `forReference/Piped/backend/testing/api-test.sh` (local clone) — route cross-check
- `forReference/Piped/backend/config.properties` (local clone) — `PROXY_PART`, `API_URL`
- Piped model classes: [Streams](https://raw.githubusercontent.com/TeamPiped/Piped-Backend/master/src/main/java/me/kavin/piped/utils/obj/Streams.java), [PipedStream](https://raw.githubusercontent.com/TeamPiped/Piped-Backend/master/src/main/java/me/kavin/piped/utils/obj/PipedStream.java), [StreamItem](https://raw.githubusercontent.com/TeamPiped/Piped-Backend/master/src/main/java/me/kavin/piped/utils/obj/StreamItem.java), [Channel](https://raw.githubusercontent.com/TeamPiped/Piped-Backend/master/src/main/java/me/kavin/piped/utils/obj/Channel.java), [Playlist](https://raw.githubusercontent.com/TeamPiped/Piped-Backend/master/src/main/java/me/kavin/piped/utils/obj/Playlist.java)
- Search filter values: [Piped frontend `SearchResults.vue`](https://raw.githubusercontent.com/TeamPiped/Piped/master/src/components/SearchResults.vue)
- Genius lyrics are not served by the API — [lyricsgenius: How It Works](https://lyricsgenius.readthedocs.io/en/stable/how_it_works.html), [lyricist](https://github.com/scf4/lyricist)
- LRCLIB: [API docs](https://lrclib.net/docs), [lrclibapi reference](https://lrclibapi.readthedocs.io/en/stable/lrclib.html), [lrclib-api](https://lrclib.js.org/)
