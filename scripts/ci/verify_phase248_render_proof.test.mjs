import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const manifestRelative = '.planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof/manifest.json';
const canonicalManifest = path.join(repo, manifestRelative);
const canonicalRoot = path.dirname(canonicalManifest);
const validator = path.join(repo, 'scripts/ci/verify_phase248_render_proof.mjs');

function fixture(t, mutate = () => {}) {
  const scratch = fs.mkdtempSync(path.join(repo, '.phase248-render-proof-test-'));
  t.after(() => fs.rmSync(scratch, { recursive: true, force: true }));
  const manifest = JSON.parse(fs.readFileSync(canonicalManifest, 'utf8'));
  const captureRoot = path.join(scratch, 'captures');
  fs.mkdirSync(captureRoot);
  for (const capture of manifest.captures) {
    fs.copyFileSync(path.join(canonicalRoot, capture.file), path.join(captureRoot, capture.file));
  }
  mutate(manifest, captureRoot);
  const fixtureManifest = path.join(captureRoot, 'manifest.json');
  fs.writeFileSync(fixtureManifest, JSON.stringify(manifest, null, 2));
  return path.relative(repo, fixtureManifest);
}

function runValidator(t, mutate, expectedError) {
  const manifestPath = fixture(t, mutate);
  const result = spawnSync(process.execPath, [validator, '--manifest', manifestPath], {
    cwd: repo,
    encoding: 'utf8'
  });
  assert.notEqual(result.status, 0, `validator unexpectedly accepted the mutated manifest\n${result.stdout}`);
  assert.match(`${result.stdout}\n${result.stderr}`, expectedError);
}

test('rejects a manifest capture whose PNG file is missing', (t) => {
  runValidator(t, (_manifest, captureRoot) => {
    fs.unlinkSync(path.join(captureRoot, 'ordinary-ordinary-invoice-review-wide-light.png'));
  }, /missing, unsafe, or symlink image/);
});

test('rejects a capture that has not been inspected', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures[0].inspection_status = 'pending';
  }, /lacks documented full-size visual inspection/);
});

test('rejects a scenario routed to another scenario owner path', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures[0].route = '/admin/customers/9b0e36e4-28ce-46ae-9f64-96e94bc8ac61?return_to=%2Fadmin%2Fcustomers';
  }, /route does not match scenario/);
});

test('rejects a held-out scenario assigned to the ordinary lane', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures[0].origin_lane = 'ordinary';
  }, /unknown scenario\/lane/);
});

test('rejects a genuine-empty claim with a nonzero underlying record count', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures[0].checks.underlying_scoped_record_count = 1;
  }, /not proved as a genuine unfiltered zero-record collection/);
});

test('rejects an image whose bytes differ from the recorded digest', (t) => {
  runValidator(t, (_manifest, captureRoot) => {
    fs.appendFileSync(path.join(captureRoot, 'ordinary-ordinary-invoice-review-wide-light.png'), Buffer.from([0]));
  }, /image hash\/size mismatch/);
});

test('rejects served asset bytes that differ from the manifest digest', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures[0].assets.css.sha256 = '0'.repeat(64);
  }, /served css digest does not match the built package/);
});
