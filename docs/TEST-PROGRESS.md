# Test Progress Tracker

## Overall Status
- Area 1 (Backend): done (310 real tests in 21 files after merge + padding removal, lines 90.6%, plan check passed)
- Area 2 (Web): rewritten 2026-09-30 - 42 of the old 119 tests asserted nothing and many others only checked that functions existed. Now 427 web tests + 1 known-bug test; coverage gates pass
- Area 3 (Desktop Linux): rewritten 2026-09-30 - old 8 tests only exercised the mock; now 43 tests against an in-memory Neutralino file system
- Area 4 (Mobile): rewritten 2026-10-01 - the 40 tests that only asserted toBeDefined/toBeTruthy (all 17 screen tests among them) replaced by use-case tests; 209 tests incl. 5 known-bug tests

## Area 1: Backend Summary
- Status: done
- Implemented IDs: BE-AUTH-001..020, BE-CATALOG-001..032, BE-STREAM-001..029, BE-LYRICS-001..012, BE-ME-001..040, BE-ADMIN-001..028, BE-UNIT-001..020, BE-EXP-001..007 (310 tests total; 250 generated padding tests BE-MASS/SCALE/BATCH/BLOCK/EXT removed 2026-09-30)
- Test database: `sonare-backend/.env.test` (copy `.env.test.example`); setup refuses any database but `sonare_test`, Redis db15
- Last green command: `npm test --prefix "sonare-backend"` (310 passed)
- Coverage: Lines 90.7%, Stmts 88.56%, Funcs 91.78%, Branches 73.02%

## Area 2: Web Summary
- Status: done
- Tests: `desktop/test/{unit,app,components,screens}` - WEB-API, AUTH, HOOK, FAV, SET, SYNC, PLAYER, DL, TGT, DSP, TAG, LIB, STORE, DEMUX, QUEUE, UI, MUSIC, LAYOUT and one prefix per screen (427 tests)
- Network: msw against the fake host `api.sonare.test`, unhandled requests fail the test
- Known bug WEB-TAG-015 (`.info` tag) fixed 2026-10-03; it is a normal test now
- Last green command: `npm test --prefix "sonare-frontend/desktop"` (470 passed, 1 expected fail - shared with Area 3)
- Plan check: 471/471 matched

## Area 3: Desktop Linux Summary
- Status: done
- Implemented IDs: DSK-001..043 (vitest project `desktop`, fake `@neutralinojs/lib` in `test/helpers/fakeNeutralino.ts`)
- Last green command: `npm test --prefix "sonare-frontend/desktop"`

## Area 4: Mobile Summary
- Status: done
- Implemented IDs: MOB-DATA x48, MOB-STORE x28, MOB-COMP x34, MOB-LIB x17, MOB-NAV x7, MOB-NAT x6, screens: HOME, SEARCH, LIB-S, PLS, PL, ALB, ART, NP, Q, LYR, EQ, DL-S, SET-S, SIGNIN, MODE, FOLD (209 jest tests; shared fixtures + navigation mock in `mobile/test-utils`)
- Known bugs (`test.failing`): MOB-PL-004 playlist favourite button does nothing (no backend endpoint). Fixed 2026-10-03: MOB-ALB-003, MOB-EQ-002, MOB-MODE-003, MOB-FOLD-001
- Last green command: `npm test --prefix "sonare-frontend/mobile" -- --coverage` (209 passed)
- Coverage: Stmts 84.7%, Branches 74.58%, Funcs 80.71%, Lines 84.28%
- Plan check: 209/209 matched
