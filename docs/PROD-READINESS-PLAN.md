# Sonare — production-readiness plan (for a coding agent)

This file is the full brief. Work through it top to bottom. Everything you need is here; where
it says "decided", the owner has already chosen — do not re-open it.

---

## 0. Ground rules

### Repositories and branch

Sonare is a root repo with three git submodules:

| Path                    | GitHub repo                     | What it is                                                                                                               |
| ----------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `.` (root)              | `Rajan694/sonare`               | scripts (`run.sh`, `install.sh`), `docs/`                                                                                |
| `sonare-backend/`       | `Rajan694/sonare-backend`       | Express 5 + TypeScript API, Postgres (Drizzle), Redis                                                                    |
| `sonare-frontend/`      | `Rajan694/sonare-frontend`      | two apps: `mobile/` (React Native 0.87) and `other-screens/` (React 19 + Vite + NeutralinoJS: desktop, web and `/admin`) |
| `sonare-piped-backend/` | `Rajan694/sonare-piped-backend` | fork of Piped (Java), run with docker compose                                                                            |

**All work happens on the branch `generic-branch` in every repo you touch.** It already exists in
root, backend and frontend. Create it from `main` in `sonare-piped-backend` only if a task there
needs it. The owner merges `generic-branch` into `main` himself.

- Never commit to or push `main`. Never force-push. Never rewrite history that is already pushed.
- One commit per task (or per numbered sub-step where the task says so), Conventional Commits
  style (`feat:`, `fix:`, `refactor:`, `style:`, `chore:`, `ci:`, `docs:`, `test:`).
- Push `generic-branch` of each repo after each finished task, so progress is never lost.
- The root repo's submodule pointers are updated **once, at the end** (task R3).

### Setup

```bash
git clone --recurse-submodules https://github.com/Rajan694/sonare.git
cd sonare
git checkout generic-branch
for r in sonare-backend sonare-frontend; do
  git -C "$r" fetch origin && git -C "$r" checkout generic-branch && git -C "$r" pull --ff-only
done
```

Node 22 (`nvm use 22`). Install: `npm ci` in `sonare-backend`, `sonare-frontend/other-screens`,
`sonare-frontend/mobile`.

Backend tests need **Postgres 17 and Redis 7** on localhost. Either:

```bash
docker run -d --name pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:17-alpine
docker run -d --name redis -p 6379:6379 redis:7-alpine
```

or `apt-get install -y postgresql redis-server` and set the `postgres` user's password to
`postgres`. Then:

```bash
cd sonare-backend
sed 's#postgres://postgres:yourpassword@#postgres://postgres:postgres@#' .env.test.example > .env.test
```

The test setup refuses any database except `sonare_test` and uses Redis db 15 — that is on purpose.
If you truly cannot get Postgres/Redis running, say so in the report and still run lint, typecheck
and the unit tests (`npx vitest run test/unit`).

### Checks — run before every commit

| App           | Directory                                         | Command                                                                                  |
| ------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Backend       | `sonare-backend`                                  | `npm run format:check && npm run lint && npm run typecheck && npm test && npm run build` |
| Desktop / web | `sonare-frontend/other-screens` (later `desktop`) | `npm run format:check && npm run lint && npm run typecheck && npm test && npm run build` |
| Mobile        | `sonare-frontend/mobile`                          | `npm run format:check && npm run lint && npm run typecheck && npm test`                  |

Starting state (verified 2026-10-03): all of these pass. Backend 339 tests, desktop/web 480 + 1
expected fail (`WEB-TAG-015`, `it.fails`), mobile 218 tests (5 of them `test.failing` known bugs).
**Every commit must leave all three green.** CI (`.github/workflows/ci.yml` in backend and
frontend) runs the same commands.

### Rules that are easy to get wrong

1. **Test-plan check.** `npm test` first runs `scripts/check-test-plan.mjs`. Every test title must
   start with an id (`BE-…`, `WEB-…`, `DSK-…`, `MOB-…`) and every id must be listed in that app's
   `TEST-PLAN.md`, and the other way round. Add a row for each new test; when you rename or
   delete a test, update the row.
2. **No fake tests.** No `expect(true)`, no tests that only check something exists or is defined,
   no loops that generate tests to raise the count. Each test asserts real behaviour.
3. **No mock or sample data in the app**, and no controls that do nothing (a switch kept in local
   state, a button that only shows an alert). If a feature has no backend, show an honest empty state.
4. **Never read `.env`, `.env.test` or any real secrets file.** Use the `*.example` files.
5. **Desktop app styling:** Tailwind's named sizes are overridden by the spacing theme, so
   `max-w-sm` is about 6px there. Use arbitrary values (`max-w-[384px]`).
6. **Animation libraries:** the desktop app uses `motion` (framer-motion); mobile uses Moti. Don't
   mix them.
7. **Desktop global state goes in Redux** (`src/store/`, Redux Toolkit slices).
8. **React effects in tests:** when a test checks something an effect does, wrap the assertion in
   `waitFor` (an effect runs after the render that shows the new state).
9. **iOS is out of scope** (no macOS here). Don't touch `mobile/ios` beyond what a rename forces.
10. **Android:** you probably have no Android SDK. Mobile changes are verified with jest,
    `tsc` and a Metro bundle:
    `npx react-native bundle --platform android --dev false --entry-file index.js --bundle-output /tmp/sonare.bundle`.
    If a task adds a native dependency, stop and leave it for the owner.

### Owner decisions (final)

- Rename `sonare-frontend/other-screens` → `sonare-frontend/desktop`.
- Desktop production CORS: pin Neutralino to the fixed port **47823**; the backend lists
  `http://localhost:47823` in `CORS_ORIGINS`.
- Licence: **MIT** for root, backend and frontend (Piped stays AGPL-3.0 in its own repo).
- Prettier: unify on the backend/web style (Prettier 3, `printWidth` 120, `singleQuote`,
  `semi`, `trailingComma: all`, `tabWidth` 2, `arrowParens: always`) for mobile too.
- Production domain (not registered yet): web `https://sonare.dev`, API `https://api.sonare.dev`.
- Email: Mailpit in development, Resend over SMTP in production (already implemented).

---

## 1. Backend — `sonare-backend`, branch `generic-branch`

### B1. Dependency fixes — `chore(deps): …`

- `@types/express` is `^4` but Express is `^5`: change it to `^5`, fix any type errors.
- Remove `@types/pino` (deprecated; pino ships its own types).
- Add `"engines": { "node": ">=22" }` to `package.json`.

Done when: checks pass; `npm ls @types/express` shows 5.x.

### B2. Folder structure and file names — `refactor: …` (pure moves first, then the split)

Today `src/` is flat and `src/app.ts` is ~1050 lines holding about 24 routes inline, while auth,
me, admin and client-errors routes live in `src/routes/`.

**B2a — move files (one commit, no logic changes):**

```
src/
  app.ts                  # createApp: middleware, router mounting, 404, error handler only
  server.ts
  config.ts
  errors.ts
  ids.ts
  types.ts
  middleware/
    auth.ts               # was src/auth.ts (requireAuth, optionalAuth, token helpers)
    adminAuth.ts          # was src/adminAuth.ts
    rateLimit.ts          # was src/rateLimit.ts
    errorHandler.ts       # the final error handler, moved out of app.ts
  services/
    cache.ts              # was src/cache.ts
    emailTokens.ts
    lyrics.ts
    mail.ts
    peaks.ts
    systemConfig.ts
    telemetry.ts
    token.ts              # stream tokens
  routes/
    auth.routes.ts  me.routes.ts  admin.routes.ts  clientErrors.routes.ts
  db/
    index.ts schema.ts create.ts hydrate.ts userData.ts   # user-data.ts → userData.ts
  normalize/index.ts
  upstream/genius.ts lrclib.ts piped.ts piped.types.ts
```

**File naming convention (decided): camelCase file names, `*.routes.ts` for routers.** The only
offender today is `src/db/user-data.ts` → `src/db/userData.ts`.

Update every import in `src/` and `test/`. Mirror the moves in test file names only where a test
file is named after a moved module (e.g. `test/unit/rateLimit.test.ts` can stay where it is).

**B2b — split `app.ts` routes into routers (one commit):**

| New file                   | Routes moved from `app.ts`                                                                                                                                                                                                                           |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `routes/catalog.routes.ts` | `GET /healthz`, `/search/suggestions`, `/search`, `/trending`, `/genres`, `/discover/made-for-you`, `/albums/:id`, `/albums/:id/tracks`, `/artists/:id`, `/artists/:id/top-tracks`, `/artists/:id/albums`, `/playlists/:id`, `/playlists/:id/tracks` |
| `routes/media.routes.ts`   | `/tracks/:id`, `/tracks/:id/artwork`, `/albums/:id/artwork`, `/playlists/:id/artwork`, `/artists/:id/artwork`, `/image/:token`, `/tracks/:id/stream`, `/tracks/:id/peaks`, `/stream/:token`                                                          |
| `routes/lyrics.routes.ts`  | `GET/PUT/DELETE /tracks/:id/lyrics`, `PUT /tracks/:id/lyrics/offset`, `GET /lyrics/search`                                                                                                                                                           |

Module-level helpers used by one router move with it (`selectBestAudioStream`, `largestThumb`,
`encodeCursor`/`decodeCursor`, `searchArtistCatalog`, the LRU caches). Helpers used by two or
more routers go to `src/services/` (e.g. `services/catalog.ts`). URLs and behaviour must not change.

Done when: `app.ts` is under 150 lines; all existing tests pass **without editing their
assertions** (imports may change).

### B3. Drop the async wrappers (Express 5) — `refactor: …`

Express 5 forwards rejected promises to the error handler. Remove:

- every `try { … } catch (e) { next(e); }` in `me.routes.ts` (29), `admin.routes.ts` (3);
- `asyncHandler` (from app.ts, now in the routers) and `route()` in `admin.routes.ts`.

Keep `try/catch` blocks that handle an error on purpose (fall back, return a specific status).
`auth.routes.ts` is already written this way — copy its style.

### B4. Validate every request body and query with zod — `feat(validation): …`

- Move `parseBody` from `auth.routes.ts` to `src/validation.ts`; add `parseQuery`. Both throw
  `BadRequestError` with the first issue's message (the error handler turns that into 400
  `BAD_REQUEST`). `admin.routes.ts` has its own `parseBody` — switch it to the shared one.
- Add schemas for: `/me/playlists` create/update (name 1–100 chars, description ≤ 500),
  playlist track add/remove/reorder bodies, `PUT /me/settings`, `PUT /me/player-state`,
  `POST /me/sync` (play history upload), lyrics override/offset bodies,
  `client-errors` body, search/trending query params (`q`, `type`, `cursor`, `limit`).
- Look at what the frontends send (`other-screens/src/data/api.ts`, `mobile/src/data/api.ts`) so
  valid requests keep working.
- Tests: one 400 test per endpoint with a bad body, in the existing integration files.

### B5. One logger — `refactor(logging): …`

- `src/logger.ts`: one pino instance (`level` from `LOG_LEVEL`, default `info`; `silent` when
  `NODE_ENV=test`; `pino-pretty` transport only when `NODE_ENV=development`).
- `pinoHttp({ logger })` uses it. Replace all 19 `console.*` calls in `src/` with it (keep the
  coloured "database does not exist" hint in `db/index.ts` readable — `logger.fatal` is fine).
- `services/telemetry.ts` (`requestLogger`, writes request/error logs to the DB for the admin page)
  is a different thing — keep it.
- Add `LOG_LEVEL` to `.env.example`.

### B6. Remove `any` — `refactor(types): …`

About 100 `@typescript-eslint/no-explicit-any` warnings in `src/` and `test/`. Replace them with
real types (`upstream/piped.types.ts` describes Piped's responses; use `unknown` + narrowing for
caught errors). Then set the rule to `'error'` in `eslint.config.js`. Tests may keep `as any` for
deliberately broken fixtures — use a single `// eslint-disable-next-line` with a reason.

### B7. Typecheck the tests too — `chore(ts): …`

`tsconfig.json` only includes `src/`. Add `tsconfig.test.json` (extends it, `noEmit`, includes
`src` and `test`, vitest globals types) and make `npm run typecheck` run both. Fix the errors.

### B8. Small leftovers — `fix: …`

- `src/app.ts` (now a router): the track route sets `updatedAt: Date.now()` with
  `TODO(phase3)`. Use the real value if one exists, otherwise drop the field and update the
  API contract.
- `GET /discover/made-for-you` and `GET /me/library/genres` always return empty lists. Keep them
  (the apps call them) but add a one-line comment saying they are placeholders.

### B9. Docker for production — `feat(docker): …`

1. **Migrations without drizzle-kit** (it is a devDependency): add `src/db/migrate.ts` that runs
   `migrate(db, { migrationsFolder })` from `drizzle-orm/postgres-js/migrator`, with the folder
   resolved relative to the compiled file (`dist/db/migrate.js` → `../../drizzle`). Add
   `"db:migrate:prod": "node dist/db/migrate.js"`.
2. **`Dockerfile`** (multi-stage): build stage `node:22-bookworm-slim` with `python3 make g++`
   (bcrypt is native), `npm ci`, `npm run build`, `npm prune --omit=dev`; runtime stage
   `node:22-bookworm-slim`, non-root `node` user, copies `dist/`, `drizzle/`, `node_modules/`,
   `package.json`. `CMD ["sh", "-c", "node dist/db/migrate.js && node dist/server.js"]`.
   `HEALTHCHECK` with `node -e` fetching `http://127.0.0.1:${PORT:-3010}/api/v1/healthz`
   (no curl in slim images).
3. **`.dockerignore`**: `node_modules`, `dist`, `coverage`, `.env*` (but not `.env.example`), `test`, `.git`.
4. **`docker-compose.prod.yml`**: services `backend` (build `.`, `env_file: .env.production`,
   port `127.0.0.1:3010:3010`, depends on healthy db/redis), `postgres` (`postgres:17-alpine`,
   named volume, password from env, `pg_isready` healthcheck), `redis` (`redis:7-alpine`,
   `--appendonly yes`, named volume, healthcheck). Postgres and Redis publish no ports.
5. **`.env.production.example`**: every variable the server reads, production values:
   `NODE_ENV=production`, `DATABASE_URL=postgres://sonare:CHANGE_ME@postgres:5432/sonare`,
   `REDIS_URL=redis://redis:6379/1`, `PIPED_API_URL`/`PIPED_PROXY_URL` (comment: where Piped
   runs), `JWT_SECRET=` (comment: `openssl rand -hex 48`),
   `CORS_ORIGINS=https://sonare.dev,http://localhost:47823`, `TRUST_PROXY=1`,
   `APP_URL=https://sonare.dev`, the Resend SMTP block, `MAIL_FROM`, `LOG_LEVEL=info`.
   Make sure `.gitignore` keeps `.env.production` out but lets the example in.
6. **CI**: add a `docker` job to `.github/workflows/ci.yml` that runs `docker build .` (no push).
7. Verify locally: `docker compose -f docker-compose.prod.yml --env-file .env.production.example config`
   is valid; `docker build .` succeeds; if Docker can run containers, bring the stack up with a
   throwaway env file and `curl` `/api/v1/healthz` → `db: up, redis: up`.
8. README section "Production with Docker" (see B11).

### B10. Git hooks — `chore: husky and lint-staged`

`husky` + `lint-staged`: pre-commit runs `prettier --write` and `eslint --fix` on staged files.
`prepare` script installs the hook. Hooks must not run the test suite.

### B11. LICENSE and README — `docs: …`

- `LICENSE`: MIT, `Copyright (c) 2026 Rajan Kumar`.
- `README.md` rewrite: what the backend is; requirements (Node 22, Postgres 17, Redis 7, Piped);
  setup (`installBE.sh`, `.env` from `.env.example`, `npm run db:migrate`); `runBE.sh` (starts
  Mailpit, inbox at http://localhost:8025); scripts table; environment variables table (name,
  default, required in production?, what it does); folder layout from B2; testing (`.env.test`,
  `sonare_test`, Redis db 15); production with Docker (B9); link to `../docs/api-contract.md`.

---

## 2. Frontend — `sonare-frontend`, branch `generic-branch`

Do the tasks **in this order** (renames first, so later diffs are readable).

### F1. One Prettier style — `style(mobile): …` (formatting-only commit)

- `mobile/package.json`: `prettier` `2.8.8` → `^3` (same major as `other-screens`).
- Replace `mobile/.prettierrc.js` with `mobile/.prettierrc` identical to `other-screens/.prettierrc`.
- `@react-native/eslint-config` includes prettier rules; make sure ESLint does not fight the new
  config (add `eslint-config-prettier` last in `mobile/.eslintrc.js`, or set
  `prettier/prettier: off` — format checking is Prettier's job).
- Run `npx prettier --write .` in `mobile/`. Commit config changes and the reformat **separately**:
  first `chore(mobile): prettier 3 config`, then `style(mobile): reformat with the shared prettier config`.

### F2. Rename `other-screens` → `desktop` — `refactor: rename other-screens to desktop`

`git mv other-screens desktop`, then update every reference:

- `runFE.sh`, `installFE.sh`, `.gitignore` (path-anchored rules), `.github/workflows/ci.yml`
  (job name, `working-directory`, `cache-dependency-path`).
- `desktop/package.json` `name` → `sonare-desktop`; `desktop/neutralino.config.json`
  `cli.binaryName` → `sonare-desktop` (then fix the binary paths `runFE.sh` builds from it);
  `desktop/e2e/globalSetup.ts`; `desktop/README.md`.
- Comments mentioning `other-screens` in `mobile/src/data/sync.ts` and `mobile/src/components/ui/Icon.tsx`.
- `grep -rn "other-screens" --exclude-dir=node_modules .` must return nothing (outside lockfiles,
  which `npm install` regenerates — run it in `desktop/`).
- Root repo references (`run.sh`, `install.sh`, `docs/api-contract.md`, `TEST-PROGRESS.md`) are
  handled in task R1.

### F3. Fixed Neutralino port — `feat(desktop): fixed port 47823 for the desktop window`

- `desktop/neutralino.config.json`: `"port": 47823` (was `0`, random).
- Development is unchanged: `runFE.sh linux` passes its own `--port`.
- If 47823 is taken when the app starts, Neutralino fails to start — document that in
  `desktop/README.md` (with how to override: `--port=` on the command line, plus adding that origin
  to the backend's `CORS_ORIGINS`).
- The backend side (`CORS_ORIGINS=…,http://localhost:47823`) is part of B9's `.env.production.example`.

### F4. File and folder naming — `refactor(desktop|mobile): …`

Desktop (`desktop/src`):

- `screens/SettingsScreen.tsx` → `screens/Settings.tsx` (component `Settings`).
- `screens/Playlist.tsx` → `screens/PlaylistDetail.tsx` (component `PlaylistDetail`); same in
  mobile (`mobile/src/screens/Playlist.tsx` → `PlaylistDetail.tsx`, export `PlaylistDetailScreen`).
  **Keep the route paths and React Navigation route names unchanged** — only files and components.
- `store/modeStore.ts` → `store/modeContext.ts`, `store/playerStore.ts` → `store/playerContext.ts`
  (they are React Contexts, not stores); `store/toastStore.ts` → `store/toasts.ts`. Hook names
  (`useModeStore`, `usePlayerStore`) may stay to keep the diff small, or rename consistently — pick
  one and apply it everywhere.
- `lib/utils.ts` is a grab-bag: split into `lib/cn.ts` (class-name helper) and `lib/format.ts`
  (`formatBytes`, `formatDuration`, …). Mobile already has `lib/cn.ts` and `lib/format.ts` — match.
- `admin/ui.tsx` (423 lines of components) → `admin/components/<Name>.tsx`, one per component.

### F5. Split `desktop/src/data/` — `refactor(desktop): split data/ into api, audio and storage`

`data/` mixes the API client, storage and the audio engine. Pure move (no logic changes):

```
src/api/      api.ts auth.ts accountGate.ts sync.ts favourites.ts plays.ts hooks.ts
src/audio/    player.ts streamPlayback.ts bufferPlayback.ts dsp.ts audioDemux.ts streamDecoder.worker.ts
src/storage/  local.ts downloads.ts downloadTargets.ts settings.ts tags.ts
src/types.ts  (was data/types.ts)
```

Check the worker import (`new Worker(new URL('./streamDecoder.worker.ts', import.meta.url))` or
similar) still resolves after the move, and that `npm run build` emits the worker. Update `test/`
imports and any `vi.mock('../../src/data/…')` paths.

### F6. Shared API types — `refactor: shared API types for desktop and mobile`

`desktop/src/types.ts` and `mobile/src/data/types.ts` duplicate the API shapes and have drifted
(mobile has `Lyrics`, `StreamInfo`, `SearchItem`; desktop has `PlayerState`).

- Create `sonare-frontend/shared/apiTypes.ts` with the types both apps get from the API (`User`,
  `Track`, `Album`, `Artist`, `Playlist`, `Page`, `Lyrics`, `StreamInfo`, `SearchItem`, …). Types
  only, no runtime code, no imports.
- Each app's types file re-exports them (`export type * from '../../shared/apiTypes'`) and keeps
  its app-only types (desktop `PlayerState`, …). Import with `import type` only, so Babel and Vite
  erase the import and no bundler ever loads a file outside the app.
- Include `../shared` in both `tsconfig` files. Mobile: add the folder to Metro `watchFolders` in
  `metro.config.js` in case anything is ever imported at runtime.
- Where the two apps disagree on a field, check `sonare-backend` (`src/normalize/index.ts`,
  `routes/*`) and use what the server actually returns.
- Verify: both typechecks, both test suites, desktop `npm run build`, and the mobile Metro bundle
  command from §0.

### F7. Desktop: stop re-rendering every row on each position tick — `perf(desktop): …`

`usePlayerStore()` returns one context value that changes every 250 ms during playback
(`positionMs`), so every `SongRow` re-renders. On WebKitGTK this load made audio decoding fall behind.

- Move the playback position out of `PlayerContext` into its own subscription (a small external
  store read with `useSyncExternalStore`, e.g. `usePlaybackPosition()`), or into a Redux slice
  read with a narrow selector. Only the components that show time/progress (bottom player
  progress bar, Now Playing scrubber, waveform, lyrics highlighting, mini player) subscribe to it.
- `PlayerContext`'s value must be memoised so it only changes when the track, queue, play state or
  settings change.
- Test (real assertion): render a list of `SongRow`s inside the providers, count renders with a
  wrapper or `React.Profiler`, advance the position several times, and assert the rows did not
  re-render while the progress component did.
- Remove the matching item from `TODO.md` in task R1.

### F8. Desktop: show "Recently played" failures — `fix(desktop): …`

`desktop/src/screens/Home.tsx` loads recently-played with `useRecentlyPlayed` but never shows its
error (the variable was unused and has been removed). When signed in, online, and the request
fails with nothing cached, show the same error + "Try again" pattern Home already uses for the
trending section (`trendingFailed` → find how it renders and reuse it). Add a `WEB-HOME-…` test.

### F9. Mobile: TypeScript strict mode — `chore(mobile): strict TypeScript`

`mobile/tsconfig.json` has `"strict": false`. Turn it on (consider extending
`@react-native/typescript-config` and keeping the existing overrides). `tsc --strict` currently
reports errors in `src/screens/Search.tsx` (4), `src/components/music/Artwork.tsx`,
`src/native/SonareDownloads.ts`, `src/native/SonarePlayer.ts`, `src/screens/Artist.tsx` and
`__tests__/data.test.tsx` (5). Fix them properly (no `any`, no `!` without a reason).

### F10. Mobile: fix the five known bugs — `fix(mobile): …` (one commit per bug)

Each is a `test.failing(...)` today. Fix the app, then change `test.failing` to `test` and make
sure it passes:

| Test           | File                                | Bug                                                                                                            |
| -------------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `MOB-PL-004`   | `__tests__/screens-browse.test.tsx` | the favourite (heart) button on a playlist does nothing                                                        |
| `MOB-ALB-003`  | `__tests__/screens-browse.test.tsx` | the favourite button on an album does nothing                                                                  |
| `MOB-EQ-002`   | `__tests__/screens-player.test.tsx` | the chosen equalizer preset is not selected when the screen is opened again (persist it in the settings store) |
| `MOB-MODE-003` | `__tests__/screens-player.test.tsx` | turning off "stay offline automatically" is not remembered                                                     |
| `MOB-FOLD-001` | `__tests__/screens-player.test.tsx` | Folders shows made-up folders on a phone with no scanned folders — show an honest empty state                  |

For the favourites, use the existing API (`mobile/src/data/api.ts`; the backend has
`PUT/DELETE /me/favourites/albums/:id`; for playlists check what the backend offers — if there is
no endpoint, tell the owner in the report instead of inventing one) and the account gate
(`requireAccount`) for guests, the same way the track heart works. Don't change what the tests
assert; if a test's expectation is wrong, explain why in the report.

The desktop's `WEB-TAG-015` (`it.fails`, `.info` download-site stamps not stripped from tags) can be
fixed the same way in `desktop/src/storage/tags.ts` (after F5) — optional, do it last.

### F11. Mobile ESLint warnings — `chore(mobile): …` (optional, last)

63 warnings (`no-void`, `@typescript-eslint/no-shadow`, `react-native/no-inline-styles`, …). Fix
`no-shadow` and `no-void`; inline styles may stay. No behaviour changes.

### F12. Git hooks — `chore: husky and lint-staged`

The frontend repo has no root `package.json`. Add a minimal one (private, devDependencies `husky`
and `lint-staged`, `prepare` script). lint-staged config per app (a `lint-staged.config.js` in
`desktop/` and `mobile/`, or one root config with globs that `cd` into each app) running Prettier
and ESLint on staged files with that app's own config. No tests in the hook.

### F13. LICENSE and READMEs — `docs: …`

- `LICENSE` at the frontend repo root: MIT, `Copyright (c) 2026 Rajan Kumar`.
- `README.md` at the repo root (currently empty): the two apps, how they relate to the backend,
  `installFE.sh` / `runFE.sh [web|linux|mobile]` with ports (web 5183, linux 5184, Metro 8090),
  where the env files are, how to run each test suite, link to each app's README.
- `desktop/README.md` and `mobile/README.md` (mobile's is still the React Native template): real
  setup, scripts, env (`VITE_API_BASE`; mobile `src/data/config.ts` dev vs release origin),
  release notes — desktop: fixed port 47823, `enableInspector` is off in release; mobile: release
  signing needs `SONARE_UPLOAD_*` in `~/.gradle/gradle.properties`, release builds talk to
  `https://api.sonare.dev`.

---

## 3. Piped — `sonare-piped-backend`, branch `generic-branch` (create from `main`)

### P1. No hard-coded database password — `chore: database password from the environment`

`docker-compose.yml` sets `POSTGRES_PASSWORD=changeme` and `config.properties` must match it.
Read it from the environment with a dev default (`${PIPED_DB_PASSWORD:-changeme}`) in the compose
file, and document in `README.md` / `config.properties.example` that production must set
`PIPED_DB_PASSWORD` and the matching `hibernate.connection.password`. Don't change Piped's Java code.

---

## 4. Root — `sonare`, branch `generic-branch`

### R1. Root cleanup — `docs: …`

- `run.sh`, `install.sh`, `docs/api-contract.md`, `TEST-PROGRESS.md`: `other-screens` → `desktop`.
- Move `TODO.md` and `TEST-PROGRESS.md` into `docs/` (update anything that links to them). In
  `docs/TODO.md`, tick off what this plan finished (position re-render, mobile known bugs, accounts:
  password reset / verification / rate limiting are done).
- `docs/api-contract.md`: document `/healthz` (`{ ok, version, db, redis, piped }`, 503 when the
  database is down) and any shape change from B4/B8.

### R2. LICENSE and README — `docs: …`

- `LICENSE`: MIT, `Copyright (c) 2026 Rajan Kumar`, plus a sentence that `sonare-piped-backend`
  is a fork of Piped under AGPL-3.0 with its own licence.
- `README.md` (empty today): what Sonare is; the four repos and how they talk (apps → backend
  :3010 → Piped :8090 / proxy :8091; Postgres, Redis, Mailpit :8025); quick start
  (`./install.sh`, `./run.sh`, `./run.sh fe --fe=linux|mobile`); the branch workflow
  (`generic-branch` → owner merges to `main`); links to each repo's README and `docs/`.

### R3. Submodule pointers — `chore: bump submodules` (last task)

After backend, frontend and Piped are pushed:

```bash
git -C sonare-backend checkout generic-branch && git -C sonare-frontend checkout generic-branch
git add sonare-backend sonare-frontend sonare-piped-backend
git commit -m "chore: point submodules at generic-branch"
```

---

## 5. Report

When done (or if you stop early), write `docs/PROD-READINESS-REPORT.md` in the root repo and push it:

- one row per task id (B1…R3): status (done / partly / skipped), commit SHA(s) per repo, one line
  on what changed;
- anything you could not do and why (no Postgres, native dependency needed, missing backend
  endpoint, a test whose expectation you think is wrong);
- the last lines of each check command from §0 for backend, desktop and mobile;
- any decision you had to make that this plan didn't cover.

The owner's assistant will verify every task against this plan afterwards, including re-running
all checks and reading the diffs — so keep commits focused and messages accurate.
