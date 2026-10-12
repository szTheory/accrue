import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { validateIntegratedProof } from './verify_phase248_integrated_proof.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const proofPath = '.planning/phases/248-reproducible-scenarios-and-integrated-proof/248-PROOF.md';
const manifestPath = '.planning/phases/248-reproducible-scenarios-and-integrated-proof/captures/phase248-current-proof/manifest.json';
const proof = fs.readFileSync(path.join(root, proofPath), 'utf8');
const valid = () => validateIntegratedProof({ root, proofPath, manifestPath });

test('accepts all canonical owner topics and accepted findings with current asset provenance', () => {
  assert.deepEqual(valid(), { topicCount: 13, findingCount: 5, currentCaptureCount: 10 });
});

test('rejects an omitted canonical owner topic', () => {
  const modified = proof.replace(/\| Search control and dialog \|[^\n]*\n/, '');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /topic keys mismatch/);
});

test('rejects a duplicate accepted finding key', () => {
  const row = proof.match(/^\| F05 \|[^\n]*$/m)[0];
  const modified = proof.replace(row, `${row}\n${row}`);
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /duplicate finding key/);
});

test('rejects stale source SHA', () => {
  const testedSha = proof.match(/^Tested source revision: `([a-f0-9]{40})`$/m)[1];
  const modified = proof.replace(testedSha, '0000000000000000000000000000000000000000');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /tested source SHA/);
});

test('rejects stale served asset byte count', () => {
  const modified = proof.replace('134234 bytes', '134235 bytes');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /css digest\/bytes/);
});

test('rejects an owner query that differs from the canonical source', () => {
  const modified = proof.replace('AccrueAdmin.Components.GlobalSearch; assets/js/hooks/command_palette.js; assets/css/app.css', 'AccrueAdmin.UnrelatedOwner');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /owner query mismatch/);
});

test('rejects a PASS row without an executed result', () => {
  const modified = proof.replace('Phase 246 records pass for both owners; current Phase 248 screenshots do not inspect the search dialog or activation/focus matrix.', 'pending; no test was run.');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /PASS without a concrete executed result/);
});

test('rejects evidence paths that traverse outside the repository', () => {
  const modified = proof.replace('.planning/phases/246-collection-controls-and-search/246-VALIDATION.md', '../../etc/passwd');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /path escapes repository/);
});

test('rejects a finding linked to an unknown owner topic', () => {
  const modified = proof.replace('| F03 | page-specific SubscriptionLive detail composition plus shared Detail components | Subscriptions collection |', '| F03 | page-specific SubscriptionLive detail composition plus shared Detail components | Invented topic |');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /unknown topic/);
});
