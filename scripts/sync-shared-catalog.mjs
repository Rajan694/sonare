#!/usr/bin/env node
// Copies the catalog code both apps share (sonare-frontend/shared) into the backend, so the
// backend normalizes Piped results and picks streams with the very same code (audit I2).
// The backend is deployed from its own repository, so it gets a copy rather than an import.
//
//   node scripts/sync-shared-catalog.mjs          write the copies
//   node scripts/sync-shared-catalog.mjs --check  exit 1 if a copy is out of date
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const from = join(root, 'sonare-frontend/shared');
const to = join(root, 'sonare-backend/src/shared');
const FILES = [
  'apiTypes.ts',
  'catalog/ids.ts',
  'catalog/images.ts',
  'catalog/normalize.ts',
  'catalog/pipedTypes.ts',
  'catalog/streams.ts',
  'catalog/titleFixes.ts',
];

const header = (file) =>
  `// GENERATED from sonare-frontend/shared/${file} by scripts/sync-shared-catalog.mjs (root repo).\n` +
  `// Do not edit here: change the frontend file and run the script again.\n\n`;

const check = process.argv.includes('--check');
const stale = [];
for (const file of FILES) {
  const wanted = header(file) + readFileSync(join(from, file), 'utf8');
  const target = join(to, file);
  const current = existsSync(target) ? readFileSync(target, 'utf8') : null;
  if (current === wanted) continue;
  if (check) {
    stale.push(file);
    continue;
  }
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, wanted);
  console.log(`updated src/shared/${file}`);
}

if (stale.length) {
  console.error(`Out of date in sonare-backend/src/shared: ${stale.join(', ')}. Run node scripts/sync-shared-catalog.mjs`);
  process.exit(1);
}
