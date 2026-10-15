# Sonare audit (2026-10-14)

A read-only review of the desktop/web app, the Android app and the backend: every screen and
store compared between the two apps, plus each project's checks. Nothing was changed.

Snapshot: root `6d92ec4`, sonare-backend `e61dfe2`, sonare-frontend `5ff6d15`, all on
`generic-branch`. Line numbers refer to these commits.

## How to use this file

1. Tick one box per item by replacing the space with `x`: `[x] fix`, `[x] leave` or `[x] later`.
   Some items offer their own choices instead.
2. Write anything else after **Notes** (for example "desktop only" or "do it like this: …").
3. Parity items (P) ask whether both apps should match: `[x] same on both`, or `[x] leave as is`
   when the difference is your choice.
4. Answer the questions at the end after **Answer**.
5. Tell me when you're done. I'll work through everything marked fix / same on both, in the order
   you give in Q6.

"Reproduced" means I confirmed it by running something. Everything else comes from reading the
code.

## Status (2026-10-15)

Everything marked fix (or "same on both") is done on `generic-branch` and committed, not pushed.
Commits: `be` sonare-backend, `fe` sonare-frontend, `root` this repo.
Checks on 2026-10-15: backend 500 of 500 tests, desktop / web 742 of 742, Android 405 of 405;
typecheck clean in all three. I3 still needs a listen in the Linux window.

| Item | Status | Commits |
| :--- | :--- | :--- |
| H0 email tests outside their describe | done | be `de25544` |
| H1 offline plays thrown away | done: batches of 100, a refused batch is split, bigger body limit | fe `ffc4c78`, be `b34e927` |
| H2 desktop liked songs not shown | done: `GET /me/favourites/ids`, hearts in both apps | be `b34e927`, fe `7fe1578` `d550b64` |
| H3 waveforms and lyrics only in Redis | done: Postgres (bytea / jsonb) behind Redis, pruned to fit Neon | be `a12d52c` |
| H4 desktop signs out on any refresh failure | done | fe `930d40d` |
| H5 Android search | done | fe `d550b64` |
| M1 desktop Up next ignores shuffle | done: shuffle reorders the queue (shared/player/queue.ts) | fe `3ca0030` |
| M2 Android queue by id | done: by position | fe `80a2ece` |
| M3 desktop gapless switch | done | fe `e14c198` |
| M4 desktop EQ distortion | done: limiter | fe `698f917` |
| M5 Android plays without song details | done | fe `ffc4c78` |
| M6 unbounded Piped bursts | done | be `b34e927` |
| M7 refresh tokens pile up | done: 90 days, rotated rows deleted, pruned | be `c5555f8` |
| M8 playlist endpoints | done: transactions, entryId, reorder / remove by row | be `c5555f8` |
| M9 favourites fail while Piped is down | done | be `b34e927` |
| L1 L2 L3 Android repeat-one icon, guest heart, artist link | done | fe `80a2ece` |
| L4 Android remove from playlist hides failures | done | fe `6ce72e7` |
| L5 L6 L7 L8 desktop search label, Library Songs, Home, phone-width rows | done | fe `10f2d25` |
| L9 PLAYS column | done: Library and Most played only | fe `7fe1578` |
| L10 shuffle | done: Fisher-Yates, Shuffle buttons start shuffled | fe `3ca0030` `80a2ece` |
| L11 lyrics timing saves | done: one save 600 ms after the last tap | fe `7fe1578` `d550b64` |
| L12 monthly listeners | removed | fe `80a2ece` `10f2d25` |
| P1 queue comes back, across devices | done | fe `f7378d1` `fb35d00`, be `c5555f8` |
| P2 lock-screen controls and media keys (desktop / web) | done: Media Session | fe `f7378d1` |
| P3 P5 crossfade, next song looked up ahead (desktop) | done | fe `e14c198` |
| P4 sleep timer | removed from both, intro page too | fe `80a2ece` `3dc670c` |
| P6 Playing from | done | fe `3ca0030` |
| P7 favourites in the song menu (desktop) | done | fe `10f2d25` |
| P8 save a YouTube playlist (desktop) | done | fe `7fe1578` |
| P9 reorder songs in an own playlist (Android) | done: drag handles | fe `6ce72e7` |
| P10 Add songs (Android) | done | fe `6ce72e7` |
| P11 P12 lyrics import / auto-scroll | no import anywhere; Auto-scroll for synced lyrics only; Lyrics button disabled when none found | fe `7fe1578` `d550b64` |
| P13 All search tab (desktop) | done | fe `10f2d25` |
| P14 local music folders (Android) | done: music and audio permission asked from Offline Mode and downloads | fe `504cfc9` `57e9f00` |
| P15 stream cache | 300 MB on both, size and Clear in Settings | fe `4b8a194` `c3fa372` |
| P16 settings kept on the device | done, synced when signed in | fe `b515e4e` `80a2ece` |
| P17 Retry (Android) | done | fe `80a2ece` |
| P18 favourites shelf | left as is | - |
| P19 Up next (Android) | done | fe `d550b64` |
| P20 save the queue as a playlist | Queue 1, Queue 2 ... without asking | fe `80a2ece` `3ca0030` |
| P21 artist Popular | 5 songs | fe `80a2ece` |
| I1 shared code | done: shared/api/client, settings, sync/playSync, player/queue, savedQueue, autoplay, net/serverWake, search/recentSearches, downloads/fileNames | fe `3ca0030` `11fbf6f` `10b08ba` `3801667` and others |
| I2 backend uses shared/catalog | done: generated copy via scripts/sync-shared-catalog.mjs | be `8113b3d`, root `f70cac5` |
| I3 desktop plays while downloading | done for the Linux window (Opus / WebM); Windows still waits for the file | fe `cfd71b7` |
| I4 long lists drawn only where visible | done: Android Queue (FlatList), desktop Library and queue panel (useVirtualRows) | fe `49eed06` `9b4fb0d` |
| I5 forgot password by emailed code (no deep links) | done in both apps | be `91df705`, fe `b99ee09` `198f888` |
| I6 Load more | done in both: search chips, albums over 100 songs, YouTube playlists (and the desktop artist albums) | fe `ee802e9` `49eed06` |
| I7 playlists in Offline Mode | done in both: songs on the device play, the rest are left out with a count | fe `49eed06` `9b4fb0d` |
| I8 rename a playlist | done in both | fe `7fe1578` `d550b64` |
| I9 read-only lyrics, edit routes removed | done | be `c5555f8`, fe `7fe1578` `d550b64` |
| I10 request timeouts, "waking up" notice | done in both | fe `cf3813b` |
| I11 keep playing similar songs | done in both, Autoplay switch (on) | be `91df705`, fe `59b3daa` |
| I12 recent searches (10) | done in both | fe `d550b64` `ee802e9` |
| I13 change password, name, delete account | done in both | be `91df705`, fe `b99ee09` `198f888` |
| I14 downloads after a reinstall | done in both: files are named `Artist - Title [id]`, and a scan links them back (no hidden manifest) | fe `504cfc9` `e1c57b2` `9b4fb0d` `2fe9020` |
| I15 per-IP rate limit | later: in TODO | root `3e45533` |
| I16 cached auth users | done | be `b34e927` |

## Checks

- Desktop / web: typecheck clean, 649 of 649 tests pass.
- Android: typecheck clean, 311 of 311 tests pass.
- Backend: typecheck of the test files fails, 462 of 466 tests pass (see H0).

---

## Bugs: high

### H0. Backend CI is red on `generic-branch`

Reproduced: 4 failures in a local `npm test`, and the log of CI run 38594718864 (it fails at
`npm run typecheck`).

- Where: [email.test.ts:295](../sonare-backend/test/integration/email.test.ts#L295)
- Why: the `describe(...)` block closes at line 295, and tests BE-EMAIL-019 to 022 come after it,
  so the `register` helper and `app` defined inside the block don't exist for them.
- Effect: CI fails, which blocks the merge to `main`, and Render only deploys after checks pass.
- Fix: move that closing `});` to the end of the file.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### H1. Plays recorded offline can be thrown away

Reproduced: the local backend answered `413 PAYLOAD_TOO_LARGE` to a 110 KB `POST /me/sync`.

- Where: [app.ts:69](../sonare-backend/src/app.ts#L69) (`express.json()`, 100 KB limit),
  [desktop sync.ts:80](../sonare-frontend/desktop/src/api/sync.ts#L80),
  [mobile sync.ts:138](../sonare-frontend/mobile/src/data/sync.ts#L138), and the 1000-play limit
  in [me.routes.ts:104](../sonare-backend/src/routes/me.routes.ts#L104).
- Why: both apps upload every waiting play in one request. Desktop sends a song snapshot with
  each play (about 450 bytes), so roughly 230 plays go over 100 KB and get 413. Android drops the
  snapshot (see M5), so it hits the 1000-play limit instead and gets 400. Both apps treat any 4xx
  except 401/403/408/429 as "the server will never accept these" and delete the whole batch.
- Effect: a long offline stretch loses the play history for that whole time. The same 100 KB
  limit hits `PUT /me/player-state` at about 210 queued songs; Android saves up to 300 and the
  failure is silent.
- Fix: upload at most 100 plays per request, split the batch on 413 instead of dropping it, and
  raise the body limit for `/me/sync` and `/me/player-state` to 1 MB.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### H2. Desktop shows liked songs as not liked

- Where: [favourites.ts:81](../sonare-frontend/desktop/src/api/favourites.ts#L81), the backend's
  [catalog.routes.ts](../sonare-backend/src/routes/catalog.routes.ts) and the shared
  [normalize.ts](../sonare-frontend/shared/catalog/normalize.ts) (`favourite` defaults to false).
- Why: songs from search, albums, artists, playlists and trending always arrive with
  `favourite: false`, from the backend and from in-app YouTube alike. Desktop draws the heart
  from that value plus changes made in this session. Android loads the liked ids once at sign-in
  ([store/library.ts](../sonare-frontend/mobile/src/store/library.ts)) and gets it right.
- Effect: on the web and in the Linux window a liked song shows an empty heart everywhere except
  the Library's own lists, including the player bar and Now Playing. Tapping it likes it again.
- Fix: a liked-ids store on desktop like Android's. Better: a cheap backend endpoint
  `GET /me/favourites/ids` (no metadata lookups) used by both apps.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### H3. Waveforms and lyrics are kept only in Redis

- Where: `PermanentCache` in [cache.ts:202](../sonare-backend/src/services/cache.ts#L202), and the
  Key Value service in [render.yaml](../render.yaml) (free plan, `allkeys-lru`).
- Why: Render's free Key Value holds 25 MB, evicts old keys when full, and loses everything on a
  restart. The search and stream caches share that space.
- Effect: waveforms uploaded by devices ("first upload wins, for everyone") disappear and have to
  be measured again; lyrics have to be fetched from LRCLIB again, which has no uptime guarantee.
- Fix: Postgres tables for waveforms (150 values, storable as 150 bytes) and for found lyrics,
  with Redis kept as a cache in front.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:** But keep in mind that we only got 0.5GB of database space for Neon's free tier.

### H4. Desktop signs you out when a token refresh fails for any reason

- Where: [auth.ts:243](../sonare-frontend/desktop/src/api/auth.ts#L243) and
  [auth.ts:257](../sonare-frontend/desktop/src/api/auth.ts#L257). Test WEB-AUTH-013 expects this.
- Why: any non-OK answer (429, 5xx, Render waking up) or a network error during the refresh clears
  the session. Android only ends the session on 401.
- Also: with two tabs of the web app, tab A renews the refresh token, tab B still holds the old
  one, its refresh gets 401, and B's `clearSession()` removes the tokens tab A saved, so both tabs
  end up signed out.
- Fix: Android's rule (only 401 ends the session; update WEB-AUTH-013), re-read the refresh token
  from localStorage before refreshing, follow the `storage` event, and let only one tab refresh at
  a time (Web Locks).

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### H5. Android search

- Where: [Search.tsx:103](../sonare-frontend/mobile/src/screens/Search.tsx#L103) and
  [Search.tsx:359](../sonare-frontend/mobile/src/screens/Search.tsx#L359)
- (a) Results are drawn as "Top result" + Songs + Artists only. The Albums and Playlists tabs
  return albums (playlists come back as albums too), so only the top one ever shows.
- (b) Offline, the screen shows a fixed message and never searches, although the field says
  "Search music on this device". Desktop searches local files offline.
- Fix: proper lists for album and playlist results; offline search over downloaded songs (title,
  artist, album).

**Decision:** [x] fix both [ ] fix (a) only [ ] fix (b) only [ ] leave [ ] later
**Notes:**

---

## Bugs: medium

### M1. Desktop "Up next" ignores shuffle

- Where: [NowPlaying.tsx:76](../sonare-frontend/desktop/src/screens/NowPlaying.tsx#L76) and
  [QueuePanel.tsx:52](../sonare-frontend/desktop/src/components/layout/QueuePanel.tsx#L52)
- Why: the shuffle order lives in a ref inside `App.tsx`. Up next and the queue panel show the
  queue's own order, and hide songs before the current one that shuffle will still play.
- Fix: keep the play order in `PlayerState` and draw from it. (How shuffle should behave is Q2.)

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M2. Android's queue identifies songs by id

- Where: [player.ts:156](../sonare-frontend/mobile/src/store/player.ts#L156) (`findIndex` by id in
  next, previous and track end)
- Effect: a playlist with the same song twice (A, B, A, C; the backend allows duplicates) plays
  A, B, A, B … and never reaches C. "Add to queue" on the playing song moves it to the end, so the
  app thinks the queue is over.
- Fix: track the current position by index, like desktop.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M3. Desktop's "Gapless playback" switch does nothing

- Where: [Equalizer.tsx:172](../sonare-frontend/desktop/src/screens/Equalizer.tsx#L172) and
  [Settings.tsx:261](../sonare-frontend/desktop/src/screens/Settings.tsx#L261)
- Why: the setting is saved, to the account too, but the desktop player never reads it.

**Decision:** [x] make gapless work on desktop [ ] remove the switch from desktop [ ] leave [ ] later
**Notes:**

### M4. Desktop's equalizer can distort

- Where: [dsp.ts:119](../sonare-frontend/desktop/src/audio/dsp.ts#L119)
- Why: with normalization off the compressor passes everything through and nothing limits the
  output. The Bass preset (+6 dB) plus full bass boost (+12 dB) clips. Android has a look-ahead
  limiter at −1 dBFS.
- Fix: a limiter at the end of the Web Audio chain.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M5. Android leaves out the song details when it uploads plays

Found while writing this file; not in the chat report.

- Where: [api.ts:321](../sonare-frontend/mobile/src/data/api.ts#L321)
- Why: plays are queued with a song snapshot (`meta`), but `reportPlays` sends only `trackRef`,
  `at` and `ms`. Desktop sends the snapshot.
- Effect: songs found in-app on the phone have no stored details on the backend, so Recently
  played and Most played have to look them up through Piped, and fail (502) while the home Piped
  is off.
- Fix: send `meta` too (fits into the H1 fix).

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M6. The backend sends unbounded bursts to Piped

- Where: [me.routes.ts:329](../sonare-backend/src/routes/me.routes.ts#L329) (up to 150 lookups at
  once in `/me/library/artists`) and `hydrateTracks` in
  [hydrate.ts](../sonare-backend/src/db/hydrate.ts) (`Promise.all` over every song without stored
  details).
- Effect: with a cold cache one Library visit can fire dozens of extractions at the home Piped at
  the same moment, which is the pattern that gets an IP flagged by YouTube.
- Fix: at most about 4 Piped lookups at a time.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M7. Refresh tokens pile up

- Where: [auth.routes.ts:172](../sonare-backend/src/routes/auth.routes.ts#L172) and the
  `refresh_tokens` table in [schema.ts:29](../sonare-backend/src/db/schema.ts#L29)
- Why: every refresh inserts a row and marks the old one revoked; nothing deletes rows and tokens
  never expire. Access tokens last 15 minutes, so an app left open adds about 96 rows a day.
- Fix: a 90-day expiry checked on refresh, and a daily cleanup of revoked and expired rows.
  Neon's free plan has 0.5 GB.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M8. Playlist endpoints

- Where: [me.routes.ts:573](../sonare-backend/src/routes/me.routes.ts#L573),
  [me.routes.ts:697](../sonare-backend/src/routes/me.routes.ts#L697) and the add / remove /
  reorder routes after them.
- (a) `GET /me/playlists` has no ORDER BY, so the order can change between loads.
- (b) A description can't be cleared (`description || undefined`).
- (c) Add, remove and reorder run one query per song, outside a transaction.
- (d) Remove works by position, so a device showing an old order (after another device reordered
  the playlist) removes the wrong song.
- Fix: order by `updatedAt` (newest first), allow an empty description, use transactions, and
  remove by entry id.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

### M9. Favourites can fail while Piped is down

- Where: [hydrate.ts:37](../sonare-backend/src/db/hydrate.ts#L37)
- Why: `failIfPipedDown` defaults to `true`, but its comment (and the 2026-09-26 decision) says
  favourites should fall back to placeholder rows, because Android loads its hearts from
  `/me/favourites/tracks` once.
- Effect: home Piped off + any old favourite without stored details = 502, and Android's hearts
  stay empty for the session. The ids endpoint from H2 removes this risk.
- Fix: pass `{ failIfPipedDown: false }` for favourites and the library, or rely on the H2
  endpoint.

**Decision:** [x] fix [ ] leave [ ] later
**Notes:**

---

## Bugs: low

- **L1** Android Now Playing never shows the repeat-one icon (the Queue screen does).
  [NowPlaying.tsx:312](../sonare-frontend/mobile/src/screens/NowPlaying.tsx#L312)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L2** Android's mini-player heart doesn't ask a guest to sign in; it flips on and back off.
  [MiniPlayer.tsx:120](../sonare-frontend/mobile/src/components/music/MiniPlayer.tsx#L120)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L3** Android Now Playing: tapping the artist opens a broken Artist page when the song has no
  artist id. [NowPlaying.tsx:184](../sonare-frontend/mobile/src/screens/NowPlaying.tsx#L184)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** If song has no artist id then dont show the artist button
- **L4** Android: removing a song from your own playlist hides failures, and the list only
  changes after it reloads. [PlaylistDetail.tsx:57](../sonare-frontend/mobile/src/screens/PlaylistDetail.tsx#L57)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L5** Desktop search labels playlist results "Playlist · album".
  [Search.tsx:428](../sonare-frontend/desktop/src/screens/Search.tsx#L428)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L6** Desktop Library → Songs shows trending songs as "N songs in your library" when the
  library is empty. [Library.tsx:109](../sonare-frontend/desktop/src/screens/Library.tsx#L109)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L7** Desktop Home shows the same trending list three times (tiles, cards, table), and offline
  "Jump back in" is songs 6–26 of the local library, not recent plays.
  [Home.tsx:47](../sonare-frontend/desktop/src/screens/Home.tsx#L47)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** What you thinks suits you
- **L8** Web app at phone width: song rows hide the heart and the song menu has no favourite item,
  so a song can't be liked from a list.
  [SongRow.tsx:183](../sonare-frontend/desktop/src/components/music/SongRow.tsx#L183)
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** It should be responsive.
- **L9** The PLAYS column shows 0 for every catalog song (search, trending, albums).
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L10** Shuffle buttons use `sort(() => Math.random() - 0.5)`, which isn't evenly random:
  desktop [Album.tsx:41](../sonare-frontend/desktop/src/screens/Album.tsx#L41),
  [Artist.tsx:44](../sonare-frontend/desktop/src/screens/Artist.tsx#L44),
  [Library.tsx:179](../sonare-frontend/desktop/src/screens/Library.tsx#L179),
  [PlaylistDetail.tsx:50](../sonare-frontend/desktop/src/screens/PlaylistDetail.tsx#L50); Android
  [Library.tsx:140](../sonare-frontend/mobile/src/screens/Library.tsx#L140) and
  [player.ts:63](../sonare-frontend/mobile/src/store/player.ts#L63). Desktop `App.tsx` already
  has an even (Fisher–Yates) shuffle.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L11** Lyrics timing: each Earlier / Later tap saves at once (both apps), so saves can arrive
  out of order. Save about 600 ms after the last tap instead.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **L12** "Monthly listeners" on artist pages is really the YouTube subscriber count (both apps).
  Rename it to "subscribers"?
  **Decision:** [ ] fix [ ] leave [ ] later **Notes:** remove monthly listeners

---

## Parity: one app has it, the other doesn't

`same on both` brings the missing side in line; `leave as is` keeps the difference on purpose.

- **P1** Queue and position come back after a restart. Desktop: no. Android: yes (on the phone
  and in the account).
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
  Also continue the same queue on another device (start on the phone, carry on on desktop)?
  [x] yes [ ] no
- **P2** Lock-screen controls and media keys. Desktop / web: none (no Media Session API; the tray
  menu only has Version and Quit). Android: yes. Media Session gives lock-screen controls to the
  web app on phones and media keys in Chrome; whether the Linux window gets media keys from it
  needs a test.
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
- **P3** Crossfade. Desktop: no. Android: yes (fixed at 6 s, no length setting).
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
- **P4** Sleep timer. Desktop: no. Android: yes (the intro page says "On Android").
  **Decision:** [ ] same on both [ ] leave as is **Notes:** remove from both
- **P5** The next song's stream is looked up ahead of time, so skipping starts at once. Desktop:
  no. Android: yes.
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
- **P6** "Playing from …" on Now Playing. Desktop: the album name only. Android: where the queue
  came from (album, playlist, search …).
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
- **P7** "Add to favourites" in the song menu. Desktop: no. Android: yes.
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
- **P8** Save a YouTube playlist (heart). Desktop: no. Android: yes, stored as an album
  (Library → Albums).
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as android have
  If same on both: [x] keep storing them as albums [ ] show them on the Playlists page (new table)
- **P9** Reorder your own playlist. Desktop: drag and drop. Android: no.
  **Decision:** [x] same on both [ ] leave as is **Notes:** reorder playlist means reordering songs inside it then add drag and drop and if it means reordering playlists then dont do it, show the playlist alphabetically.
- **P10** "Add songs" to your own playlist (search with + buttons). Desktop: yes. Android: no
  (the Queue's "Add songs" only opens Search).
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as desktop
- **P11** Lyrics: import a .lrc file. Desktop: yes. Android: no.
  **Decision:** [x] same on both [ ] leave as is **Notes:** no import lyrics button, if lrclib/genius fails to load lyrics then disable the lyrics button(with tooltip on desktop as well they lyrics is not available at moment)
- **P12** Lyrics: auto-scroll switch. Desktop: yes, remembered. Android: no (it pauses while you
  scroll).
  **Decision:** [x] same on both [ ] leave as is **Notes:** If it is synched, then autoscroll switch, if not synched, then no need of autoscroll switch
- **P13** The "All" search tab. Desktop: songs only, plus artists taken from them. Android: songs,
  albums, artists and playlists (4 YouTube searches per query).
  **Decision:** [x] same on both [ ] leave as is **Notes:** keep as android have
  If same on both: [ ] songs only [x] all four
- **P14** Local music folders. Desktop: yes. Android: no (already in TODO).
  **Decision:** [x] same on both [ ] leave as is **Notes:** want local music folders on both(in android add permission for storage, if denied then i guess download will not work and offline music player will not work(in this case give user option to add storage permission whenever it taps on offline music player or tries to download a song))
- **P15** Stream cache. Desktop window: 500 MB, with no size shown and no Clear button. Android:
  none, so every replay downloads the song again.
  **Decision:** [x] same on both [ ] leave as is **Notes:** add cache of 300MB in both
  Android cache size if added: 300 MB (300 suggested)
- **P16** Settings kept on the device. Desktop: only the equalizer; stream and download quality,
  normalization, gapless and stay-offline reset at every launch for guests and while offline.
  Android: all kept.
  **Decision:** [x] same on both [ ] leave as is **Notes:** keep settings offline and if user signs in the sync them or user goes online then sync them
- **P17** Retry button after a playback error. Desktop: yes (player bar, Now Playing). Android:
  no (just a message on Now Playing).
  **Decision:** [x] same on both [ ] leave as is **Notes:** keep as desktop have
- **P18** Favourites shelf on Home. Desktop: no. Android: yes.
  **Decision:** [ ] same on both [x] leave as is **Notes:**
- **P19** "Up next" preview on Now Playing. Desktop: the next 4 songs. Android: no (Queue button).
  **Decision:** [x] same on both [ ] leave as is **Notes:** same as desktop have
- **P20** Save the queue as a playlist. Desktop: asks for a name. Android: names it
  "Queue · date".
  **Decision:** [x] same on both [ ] leave as is **Notes:** dont ask for name, save as queue 1, queue 2 ...
- **P21** Artist page "Popular". Desktop: 5 songs. Android: 20.
  **Decision:** [x] same on both [ ] leave as is **Notes:** 5 songs

---

## Improvements (neither app has these, or internal)

- **I1** Shared code for both apps: move the API client core (`request`, `localFirst`, `paged`,
  `ApiError`), the play queue and sync, the settings defaults and EQ presets, and the queue logic
  (next, previous, shuffle, repeat as plain functions) into `shared/`, with fetch-vs-XHR and the
  storage passed in. Most bugs above exist because one feature is written twice.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **I2** The backend uses `shared/catalog` instead of its own copy of the catalog code (normalize,
  stream picking); today the two copies can drift apart.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **I3** Desktop in-app YouTube starts playing while the song downloads. Today it waits for the
  whole file ([player.ts:337](../sonare-frontend/desktop/src/audio/player.ts#L337)), which on a
  slow connection is a long silence.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:**
- **I4** Long lists drawn only where visible: the desktop Library with thousands of local songs,
  and the Android Queue screen.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** add virtualisation(in both)
- **I5** Android opens from the verify-email and reset-password links (deep links) instead of the
  browser.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** i didnot get it(verify email(sends otp so no link used) and reset password(user can change password from there, in case of forgot password then an otp is sent to email, after entering otp and verifiying it, it can set the new password))
- **I6** "Load more" for search results, albums over 100 songs and long YouTube playlists (the
  paging cursors exist and are unused).
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** use paging in both
- **I7** Playlists in Offline Mode (your own playlists with their downloaded songs). Today both apps
  show none offline.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** if playlist have downloaded songs/on-device songs then show them, online songs will not be shown in offline mode(or if possible will remain disabled)
- **I8** Rename a playlist and edit its description (the backend supports it; neither app has the
  screen for it).
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** add support to rename playlist
- **I9** Restore the original lyrics after editing them (the backend's
  `DELETE /tracks/:id/lyrics` exists and is unused).
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** dont add option to edit the playlist on first place, it will be read only as it is not getting linked with song permanently, remove the backend support too.
- **I10** Request timeouts and a "server is waking up" message. Render's free plan sleeps after
  15 minutes and the first request can take 30–60 s; desktop requests have no timeout at all.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** add timeout in both
- **I11** Keep playing similar songs when the queue ends, instead of stopping.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** keep playing similar songs
- **I12** Recent searches.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** store top 10 searches
- **I13** Account settings: change password while signed in, edit display name, delete account.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** add option for it. Added change password flow in I5
  Play Store planned? [ ] yes (Google then requires in-app account deletion) [x] no, GitHub APK only
- **I14** Downloads survive a reinstall or cleared app data. Both apps keep the download list only
  in app storage, so the files in the download folder are forgotten (desktop could still add the
  folder as a music folder, but the songs lose their link to the catalog). A manifest file in the
  download folder could bring them back.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** the downloaded songs will remain, so in offline mode, songs will be scanned from that folder so, yours choice, add a manifest file if want(try to create a hidden file if possible)
- **I15** Backend: a per-IP rate limit on the catalog and stream routes, to protect the home Piped.
  **Decision:** [ ] fix [ ] leave [x] later **Notes:** add it in TODO(not important for now)
- **I16** Backend: `requireAuth` reads the user from the database on every request; cache that
  for about a minute.
  **Decision:** [x] fix [ ] leave [ ] later **Notes:** yes sure

## Capacity notes (no decision needed)

- Web-app audio is relayed through Render; check your plan's bandwidth cap.
- Neon free plan: 0.5 GB of storage (see M7).
- Render free Key Value: 25 MB, nothing kept across restarts (see H3).
- Render's free web service sleeps after 15 minutes without requests (see I10).

---

## Questions

### Q1. Library "Songs" vs "Favourites"

Both show the same server list (your liked songs; on desktop "Songs" adds local files). What should
"Songs" be: everything you saved (liked, in playlists, downloaded)? Or should one tab go?

**Answer:** If favourites and Liked re different page then one of them will go, preferable favourites, and i think Songs can show it, so remove the favourites tab

### Q2. Shuffle

Desktop keeps the real order and follows a shuffled order beside it, so turning shuffle off
carries on in the real order. Android reorders the queue itself, so turning it off can't bring the
order back. Which should both apps do?

And the Shuffle button on an album or playlist: play a shuffled copy and leave shuffle mode alone
(desktop), or turn shuffle mode on (Android)?

**Answer:** Once a list is shuffled, it should be shuffled.

### Q3. Defaults for guests

Desktop: Flat EQ, gapless off, normalization on, stay-offline off
([settings.ts:24](../sonare-frontend/desktop/src/storage/settings.ts#L24)).
Android: Sonare EQ, gapless on, normalization off, stay-offline on
([settings.ts:115](../sonare-frontend/mobile/src/data/settings.ts#L115)).
Which set should both use?

**Answer:** Sonare EQ, gapless on, normalization on, stay-offline off

### Q4. Who uses Sonare?

Just you and family or friends, or the public? This decides rate limits, paid hosting and Piped
capacity.

**Answer:** For now me and and family and friends, in future will buy a small server and host all on there.

### Q5. App language

English only, or Hindi (or other languages) too?

**Answer:** English only for now,In future may be hindi at most

### Q6. Order and workflow

Suggested order: H0, H1 with M5, H2, H3, H4, H5, then medium, parity, low, improvements. One
commit per item on `generic-branch` in each repo. Should I push after each item (and bump the
submodules in the root repo), or leave the commits for you to push?

**Answer:** Use the opencode multiple sessions(and you will author the code and fix it, if needed), and commit time to time
