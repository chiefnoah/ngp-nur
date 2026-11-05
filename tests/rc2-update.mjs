import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, cpSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';

const OLD_REV = '1'.repeat(40);
const NEW_REV = '2'.repeat(40);
const NEW_HASH = 'sha256-new';
const SOURCE = new URL('../pkgs/rc2/', import.meta.url);

function fixture(t, mode) {
  const root = mkdtempSync(join(tmpdir(), 'rc2-update-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const bin = join(root, 'bin');
  mkdirSync(bin);
  cpSync(SOURCE, join(root, 'package'), { recursive: true });
  const file = join(root, 'package/source.json');
  const pin = {
    url: 'https://example.invalid/rc',
    rev: OLD_REV,
    hash: 'sha256-old',
    version: '0-unstable-1111111',
  };
  writeFileSync(file, JSON.stringify(pin));

  // Stub network tools so the real rc script updates only the temporary pin.
  const tools = {
    git: `
      if (process.env.MODE === 'git-error') process.exit(1);
      if (process.env.MODE !== 'empty') {
        console.log((process.env.MODE === 'current' ? '${OLD_REV}' : '${NEW_REV}') + '\\tHEAD');
      }
    `,
    nix: `
      if (process.env.MODE === 'current') process.exit(99);
      if (process.env.MODE === 'fetch-error') process.exit(1);
      console.log(JSON.stringify({hash: '${NEW_HASH}'}));
    `,
  };
  for (const [name, code] of Object.entries(tools)) {
    writeFileSync(join(bin, name), `#!${process.execPath}\n${code}`, { mode: 0o755 });
  }
  const result = spawnSync('rc', [join(root, 'package/update.rc')], {
    env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, MODE: mode },
    encoding: 'utf8',
  });
  assert.ifError(result.error);
  return { result, pin, actual: JSON.parse(readFileSync(file, 'utf8')) };
}

test('update replaces the revision, hash, and version together', t => {
  const { result, pin, actual } = fixture(t, 'update');
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(actual, { ...pin, rev: NEW_REV, hash: NEW_HASH, version: '0-unstable-2222222' });
});

test('current pin needs no archive fetch', t => {
  const { result, pin, actual } = fixture(t, 'current');
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(actual, pin);
});

for (const mode of ['empty', 'git-error', 'fetch-error']) {
  test(`${mode} preserves the pin`, t => {
    const { result, pin, actual } = fixture(t, mode);
    assert.notEqual(result.status, 0);
    assert.deepEqual(actual, pin);
  });
}
