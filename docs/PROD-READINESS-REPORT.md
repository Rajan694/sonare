# Production-readiness report

Work for [`PROD-READINESS-PLAN.md`](PROD-READINESS-PLAN.md), done 2026-10-03 on `generic-branch` in
every repo. Each task was committed separately and pushed as it was finished. Nothing was
pushed to `main` and nothing was force-pushed.

> **Checks.** The §0 checks ran before every backend commit through B10. At the owner's
> request the remaining tasks were first written without running checks. Afterwards **all
> three apps were checked in full** (§3), and that turned up one bug: MOB-ALB-003, fixed in
> FE `fdc6c33`. The intermediate frontend commits between `ba44fdd` and `93cf4de` were not
> each checked on their own, and the F6 commit `6fddd6b` alone fails the mobile typecheck
> (see F6).

## 1. Tasks

Repos: **BE** = sonare-backend, **FE** = sonare-frontend, **P** = sonare-piped-backend, **R** = sonare (root).

| Task | Status | Commit(s)                                                                                                                   | What changed                                                                                                                                                                                                                                                                     |
| ---- | ------ | --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| B1   | done   | BE `e6958fb`                                                                                                                | `@types/express` ^5 (async-route request params typed as strings), `@types/pino` removed, `engines.node >=22`. `npm ls @types/express` → 5.0.6.                                                                                                                                  |
| B2   | done   | BE `f634ee1` (B2a moves), `d4327e8` (B2b split)                                                                             | `middleware/`, `services/`, `db/userData.ts`; `app.ts` 1060 → 80 lines; new `catalog/media/lyrics.routes.ts` and `middleware/errorHandler.ts`. No test assertion was edited.                                                                                                     |
| B3   | done   | BE `ae0f2c7`                                                                                                                | Removed 27 `try/catch next(e)` blocks in `me.routes.ts` (the plan said 29; there were 27), plus `asyncHandler` and admin `route()`. Deliberate try/catches kept.                                                                                                                 |
| B4   | done   | BE `c7e2231`                                                                                                                | `src/validation.ts` (`parseBody`, `parseQuery`, `queryInt`); schemas for every listed body and query, plus auth refresh/logout and lyrics search/prefer; tests BE-VAL-001…020.                                                                                                   |
| B5   | done   | BE `d773cd3`                                                                                                                | `src/logger.ts`; `pinoHttp({ logger })`; all 19 `console.*` calls replaced; `LOG_LEVEL` in config and `.env.example`; pino-http 9 → 10.                                                                                                                                          |
| B6   | done   | BE `14531a1`                                                                                                                | 0 `any` in `src/` and `test/`; new Piped/LRCLIB/Genius types; `errors.describeError`; `no-explicit-any` is now `'error'`. No `eslint-disable` was needed.                                                                                                                        |
| B7   | done   | BE `5a0ad3b`                                                                                                                | `tsconfig.test.json`; `npm run typecheck` runs both projects; fixed the 19 test type errors.                                                                                                                                                                                     |
| B8   | done   | BE `28411ca`                                                                                                                | `/playlists/:id` no longer sends an invented `updatedAt` (BE-CATALOG-022 checks it is absent); placeholder comments added (also on `/me/new-releases`). Contract updated in R1.                                                                                                  |
| B9   | partly | BE `d638552`                                                                                                                | `src/db/migrate.ts` + `db:migrate:prod`, `Dockerfile`, `.dockerignore`, `docker-compose.prod.yml`, `.env.production.example`, CI `docker` job. **`docker build .` could not be verified here** (see §2).                                                                         |
| B10  | done   | BE `7b993f1`                                                                                                                | husky + lint-staged (Prettier + ESLint on staged files; no tests). The hook ran on its own commit.                                                                                                                                                                               |
| B11  | done   | BE `c09debe`                                                                                                                | MIT `LICENSE`; README rewritten (requirements, setup, scripts, env table, layout, testing, Docker).                                                                                                                                                                              |
| F1   | done   | FE `ba44fdd` (config), `42c09c5` (reformat)                                                                                 | mobile on Prettier 3 with the desktop `.prettierrc`; `eslint-config-prettier` last and `prettier/prettier: off`.                                                                                                                                                                 |
| F2   | done   | FE `22e0f20`                                                                                                                | `other-screens` → `desktop`; package and `binaryName` are `sonare-desktop`; scripts, CI, `.gitignore`, e2e, comments; lockfile regenerated.                                                                                                                                      |
| F3   | done   | FE `a77d3ca`                                                                                                                | Neutralino `port` 47823; README explains what happens on a port clash and how to override.                                                                                                                                                                                       |
| F4   | done   | FE `e057905`, `9a95624`, `8c7b0ee`, `4319e70`                                                                               | `Settings.tsx`, `PlaylistDetail.tsx` (desktop and mobile, routes unchanged); `modeContext`/`playerContext`/`toasts` (hook names kept); `lib/cn` + `lib/format`; `admin/components/*` + `admin/useLoad.ts` + `admin/format.ts`.                                                   |
| F5   | done   | FE `999c9e4`                                                                                                                | `src/api`, `src/audio`, `src/storage`, `src/types.ts`; the worker stays next to `streamPlayback.ts`, so its `new URL(...)` path is unchanged.                                                                                                                                    |
| F6   | done   | FE `6fddd6b`                                                                                                                | `shared/apiTypes.ts`; each app's types file re-exports it with `export type *`; tsconfigs include `../shared`; Metro watches it. **This commit alone fails the mobile typecheck** (test fixtures still had `role`); fixed in F9 `358db94`.                                       |
| F7   | done   | FE `1fa9fc9`, `e03c32d`                                                                                                     | `store/playbackPosition.ts` (`useSyncExternalStore`); `positionMs` removed from `PlayerState`; memoised context value with stable actions; only time/progress components subscribe; tests WEB-PERF-001/002 (React.Profiler). The `e03c32d` follow-up loosened one count to `>=`. |
| F8   | done   | FE `c37b0a8`                                                                                                                | Home shows "Could not load recently played" + "Try again" when signed in, online, and nothing is cached; test WEB-HOME-007.                                                                                                                                                      |
| F9   | done   | FE `358db94`                                                                                                                | mobile `"strict": true`; fixed Search, Artwork, the two native emitters, Artist and `data.test.tsx` without `any` or `!`.                                                                                                                                                        |
| F10  | partly | FE `283edf5` + `fdc6c33` (ALB-003), `8b33539` (EQ-002), `dea1b38` (MODE-003), `46ff9cc` (FOLD-001), `7488a0a` (WEB-TAG-015) | 4 of 5 mobile bugs fixed and their `test.failing` removed, plus the optional WEB-TAG-015. **MOB-PL-004 not fixed**: there is no backend endpoint (see §2).                                                                                                                       |
| F11  | done   | FE `b55b5b9`                                                                                                                | All `no-void` (16) and `no-shadow` (2) warnings fixed; inline styles left alone.                                                                                                                                                                                                 |
| F12  | done   | FE `e234003`                                                                                                                | Root `package.json` (husky, lint-staged, `prepare`); a `lint-staged.config.js` in each app; `installFE.sh` installs the root first.                                                                                                                                              |
| F13  | done   | FE `93cf4de`                                                                                                                | MIT `LICENSE` at the repo root; root, desktop and mobile READMEs (mobile's replaces the RN template).                                                                                                                                                                            |
| P1   | done   | P `c6ada0b` (new `generic-branch` from `main`)                                                                              | `POSTGRES_PASSWORD=${PIPED_DB_PASSWORD:-changeme}`; README and `config.properties.example` explain the production setting. No Java changes.                                                                                                                                      |
| R1   | done   | R `b8103d2`                                                                                                                 | `TODO.md` and `TEST-PROGRESS.md` moved to `docs/` and updated; `other-screens` → `desktop`; contract covers `/healthz`, validation limits and B8.                                                                                                                                |
| R2   | done   | R `8cd86c5`                                                                                                                 | MIT `LICENSE` with the AGPL note for Piped; root README.                                                                                                                                                                                                                         |
| R3   | done   | R `93d994d`, then a second bump after the MOB-ALB-003 fix                                                                   | Submodules point at the `generic-branch` heads: BE `c09debe`, FE `fdc6c33`, P `c6ada0b`.                                                                                                                                                                                         |

## 2. Not done, or done differently

- **B9: `docker build .` not verified.** Inside `docker build` the sandbox's egress policy
  blocks plain-HTTP Debian mirrors (`apt-get update` → 403), and `npm ci` inside the container
  can't reach the registry either. A build routed through the session proxy was denied by the
  environment, so I didn't pursue it. What was checked instead:
  `docker compose -f docker-compose.prod.yml --env-file .env.production.example config` is valid.
  I also replayed the image's steps on the host: `npm ci`, `build`, `prune --omit=dev`, then
  only `dist/`, `drizzle/`, `node_modules/` and `package.json` with `NODE_ENV=production`.
  Running `node dist/db/migrate.js && node dist/server.js` against an empty database applied
  all 7 migrations; `/api/v1/healthz` returned `{"ok":true,"version":"1.0.0","db":"up","redis":"up","piped":"down"}`;
  the HEALTHCHECK command exited 0; CORS allowed `http://localhost:47823`. Please run
  `docker build .` (and the CI `docker` job) yourself.
- **MOB-PL-004 (playlist heart) is still `test.failing`.** The backend has no endpoint for
  saving a YouTube playlist (only `/me/favourites/albums/:id`, `/me/favourites/tracks/:id`,
  `/me/following/artists/:id`). As the plan asks, I didn't invent one. Options: add
  `/me/favourites/playlists/:id` (new table), or decide that YouTube playlists are saved
  as albums. The heart still does nothing until then.
- **Postgres 16** (the container's own) was used for the backend tests instead of 17.
- `docker-compose.prod.yml` marks `env_file: .env.production` as `required: false`, so the plan's
  `config` check works before that file exists. Without the file the backend still exits at start,
  because `DATABASE_URL` is required.

## 3. Last lines of the check commands

**Backend** (`npm run format:check && npm run lint && npm run typecheck && npm test && npm run build`),
last run after B10 (`7b993f1`; B11 changed only `LICENSE` and `README.md`):

```
✓ Test plan check passed: 350 tests matched perfectly between TEST-PLAN.md and test files.
 Test Files  24 passed (24)
      Tests  359 passed (359)
> sonare-backend@1.0.0 build
> tsc -p tsconfig.json
```

Lint showed 0 problems from B6 onward (it was 103 warnings at the start).

**Desktop / web** (`desktop/`: `npm run format:check && npm run lint && npm run typecheck && npm test && npm run build`), at FE `fdc6c33`:

```
All matched files use Prettier code style!
✖ 48 problems (0 errors, 48 warnings)     # all warnings were there before this work (no-explicit-any in tests)
✓ Test plan check passed: 484 tests matched perfectly between TEST-PLAN.md and test files.
 Test Files  29 passed (29)
      Tests  484 passed (484)
resources/assets/streamDecoder.worker-B_a0qOYn.js    3.56 kB
✓ built in 6.41s
```

WEB-TAG-015 is now a normal passing test, so there are no expected failures.

**Mobile** (`mobile/`: `npm run format:check && npm run lint && npm run typecheck && npm test`), at FE `fdc6c33`:

```
All matched files use Prettier code style!
✖ 38 problems (0 errors, 38 warnings)     # no no-shadow / no-void left; the rest are inline styles etc.
> tsc --noEmit                            # strict, clean
✓ Test plan check passed: 218 tests matched perfectly between TEST-PLAN.md and test files.
Test Suites: 9 passed, 9 total
Tests:       218 passed, 218 total
```

MOB-PL-004 is the only `test.failing` left.

The Metro bundle from §0
(`npx react-native bundle --platform android --dev false --entry-file index.js --bundle-output …`)
writes a 4.7 MB bundle without errors, with `../shared` in place (F6).

The other plan checks also pass:

- `grep -rn "other-screens" --exclude-dir=node_modules .` in the frontend finds nothing.
- The frontend pre-commit hook ran lint-staged on the `fdc6c33` commit.

## 4. Decisions the plan didn't cover

- **Branch.** The session's own instructions named `claude/great-meitner-a78gg9`; I followed
  your request and the plan and used `generic-branch` everywhere.
- **B1.** Express 5's types widen `req.params` to `string | string[]`; the old `asyncHandler`
  typed params as strings until B3 removed it.
- **B2.** The error handler moved in the B2b commit (with the rest of `app.ts`), not B2a. No
  helper was used by two routers, so nothing new went into `services/`. The lyrics routes are
  really `POST /tracks/:id/lyrics` and `PATCH …/offset` (the plan table said PUT); since URLs
  had to stay the same, they were kept.
- **B4 behaviour changes.**
  - An invalid `PUT /me/settings` value is now 400; before, it was silently ignored.
  - An unknown search `type` is 400; before, it fell back to `all`.
  - A lyrics override needs `lrc` or `plain`.
  - Playlist `kind` also accepts the legacy `offline`, because test BE-EXP-001 relies on it.
  - Sync plays round `ms` to an integer (the column is an integer).
- **B5.** pino-http went from 9 to 10, so it shares pino 9 (version 9 bundled pino 8 and the
  types clashed). The "database does not exist" message now names the actual database.
- **B6.** A `null` `plainLyrics` from LRCLIB is now left out of the lyrics response instead of
  being sent as `null`. `Lrclib.get`'s album argument is optional.
- **B9.**
  - The backend container gets `host.docker.internal:host-gateway`, so it can reach Piped on
    the host.
  - Piped's compose binds 8090/8091 to the host's 127.0.0.1, which containers can't reach.
    `.env.production.example` explains the options: publish on the bridge address, or give
    Piped its own hostname.
  - The backend relays Piped's media URLs, so `PROXY_PART` must also be reachable from the
    container.
  - `PIPED_PROXY_URL` is in the config schema but nothing in `src/` reads it; it is listed
    with a note.
- **F2.** The desktop dev binaries (`bin/neutralino-linux_x64`) are named by Neutralino and
  didn't change; only the release output path did (`dist/sonare-desktop/`).
- **F6.**
  - `User.createdAt` is the ISO string the server sends; mobile's unused `role` is gone.
  - `Playlist.updatedAt` is optional; `Lyrics` gained `attribution`.
  - Desktop keeps a local `Track` that adds `peaks`/`lyrics` for local files; the server
    never sends these.
  - `Mode` and `Folder` stay app-local.
- **F7.** The queue panel's "remaining time" also subscribes to the position. The context's
  actions are stable wrappers over the latest handlers. Plays are counted straight from the
  playback listener.
- **F10.**
  - The EQ preset and "stay offline" are saved in the mobile settings store and synced with
    the account fields the desktop already uses. The phone has no DSP and no automatic
    reconnect, so they are stored but not yet acted on.
  - The screens-player tests now reset the settings store before each test, because a
    Settings test swaps in a mock `update`.
- **F13.** The plan says Metro runs on 8090, but Piped's API already uses 8090. The docs say
  8081, which is `runFE.sh`'s default, with `--port` to change it. `desktop/LICENSE` (the
  NeutralinoJS template's MIT licence) was kept and is described as such.
- **R3.** `.gitmodules` still says `branch = main` for each submodule, matching the
  merge-to-main workflow.

## 5. Noticed, not changed (outside the plan)

- A request with malformed JSON gets 500 `INTERNAL_ERROR`; the body parser's error isn't mapped
  to 400.
- `BE-CACHE-DEG-002` only checks that `CachedPiped.trending` is a function. That is the kind of
  test rule 2 forbids, but it was already there.
- Mobile's Offline Mode sheet says "5 music folders and all local playlists" (hard-coded), and
  the Audio screen's bands/crossfade/gapless/normalisation/speed controls are still local state.
- Inside a Docker build, `npm ci` runs `prepare` (husky). With no `.git`, husky prints a warning
  and exits 0, so the build isn't affected.

## 6. Verification (owner's assistant, 2026-10-03)

Pulled every repo, reinstalled from the lockfiles, re-ran all §0 checks, read each task's diff
against the plan, ran the production Docker stack and used the web app against a live backend
and Piped. **All 29 tasks check out** (B9's `docker build` now verified, see below). Found and
fixed on top:

| Problem                                                                                                                                                            | Fix                                                                                                                    | Commit                  |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| `/healthz` took ~21 s when Piped was unreachable (TCP connect timeout, retried), longer than the Docker HEALTHCHECK's 5 s: the prod container never turned healthy | 2 s hard timer on the Piped probe (the abort signal alone doesn't cut a connect short), no retry; tests BE-SEC-007/008 | BE `6c864d0`, `6b9a9a3` |
| Malformed JSON body → 500 (noted in §5)                                                                                                                            | 400 `BAD_REQUEST` (413 for too large); BE-SEC-006                                                                      | BE `6c864d0`            |
| Dev request logs printed every header                                                                                                                              | one line per request: method, URL, status, time; dotenv banner off                                                     | BE `6c864d0`            |
| Backend tests reached a real Piped on localhost:8090 when one was running; BE-CATALOG-015 only passed while Piped was down                                         | tests may reach local test servers only, never Piped's ports; 015 split into 015/015B                                  | BE `6c864d0`            |
| 9 backend tests had no id (from the earlier P0 work), so the plan check didn't see them; BE-CACHE-DEG-002 only checked `typeof` (§5)                               | ids BE-AUTH-SEC-_, BE-SEC-_, BE-ERR-CLASS-009; DEG-002 checks the cache                                                | BE `6c864d0`            |
| Mobile Genres chip sent `type=genres`, which B4's validation rejects with 400                                                                                      | chips the server can't search map to `all`; MOB-SEARCH-006                                                             | FE `f995319`            |
| Mobile Offline Mode sheet promised "5 music folders" (§5)                                                                                                          | honest copy                                                                                                            | FE `f995319`            |

Also cleaned up locally: the leftover `other-screens/` folder (ignored files the rename left
behind); its `.env`, Neutralino `bin/` and `.storage/` moved to `desktop/`.

Final checks: backend 363 tests, lint 0 problems; desktop 484 tests, build OK; mobile 219 tests,
Metro bundle OK; `docker build` OK, prod compose → backend `healthy`, CORS allows
`http://localhost:47823` and blocks dev origins. Web app: search and streaming playback work,
the position advances.

Still open (owner decisions): MOB-PL-004 (no endpoint for saving a YouTube playlist); the mobile
Audio screen's bands/crossfade/gapless/normalisation/speed controls are local state with no effect.
