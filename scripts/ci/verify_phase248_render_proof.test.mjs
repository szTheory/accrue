import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { resolveEvidenceFile } from './verify_phase248_integrated_proof.mjs';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const manifestRelative = '.planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof/manifest.json';
const canonicalManifest = resolveEvidenceFile(repo, manifestRelative);
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
  runValidator(t, (manifest, captureRoot) => {
    const capture = manifest.captures.find((row) => row.scenario === 'ordinary-invoice-review' && row.frame === 'overview' && row.viewport.width === 1280);
    fs.unlinkSync(path.join(captureRoot, capture.file));
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
    manifest.captures.find((row) => row.scenario === 'empty-subscriptions').origin_lane = 'ordinary';
  }, /unknown scenario\/lane/);
});

test('rejects a genuine-empty claim with a nonzero underlying record count', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures.find((row) => row.scenario === 'empty-subscriptions').checks.underlying_scoped_record_count = 1;
  }, /not proved as a genuine unfiltered zero-record collection/);
});

test('rejects an empty-state capture without visible explanation framing', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures.find((row) => row.scenario === 'empty-subscriptions' && row.viewport.width === 320).checks.empty_explanation_visible = false;
  }, /does not assert visible heading, explanation and zero-row context/);
});

test('rejects a boundary capture without the full seeded Unicode identity', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures.find((row) => row.scenario === 'long-name-boundary').checks.expected_identity = 'E2E Edge LongName';
  }, /missing its exact-identity or overflow assertion/);
});

test('rejects invoice drawer captures that do not assert visible record context', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures.find((row) => row.scenario === 'ordinary-invoice-review' && row.frame === 'action-review').checks.record_status_visible = false;
  }, /invoice capture lacks asserted identity and status/);
});

test('rejects an image whose bytes differ from the recorded digest', (t) => {
  runValidator(t, (manifest, captureRoot) => {
    const capture = manifest.captures.find((row) => row.scenario === 'ordinary-invoice-review' && row.frame === 'overview' && row.viewport.width === 1280);
    fs.appendFileSync(path.join(captureRoot, capture.file), Buffer.from([0]));
  }, /image hash\/size mismatch/);
});

test('rejects served asset bytes that differ from the manifest digest', (t) => {
  runValidator(t, (manifest) => {
    manifest.captures[0].assets.css.sha256 = '0'.repeat(64);
  }, /served css digest does not match the built package/);
});
