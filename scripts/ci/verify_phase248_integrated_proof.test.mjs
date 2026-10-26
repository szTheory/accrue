import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { validateIntegratedProof, resolveEvidenceFile } from './verify_phase248_integrated_proof.mjs';
import { resolvePhaseEvidencePath } from './phase_evidence_path.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const PHASE248 = '248-reproducible-scenarios-and-integrated-proof';
const repoRelative = (absolute) => path.relative(root, absolute).split(path.sep).join('/');
const proofPath = repoRelative(resolvePhaseEvidencePath(PHASE248, '248-PROOF.md', { root }));
const manifestPath = repoRelative(resolvePhaseEvidencePath(PHASE248, 'captures/phase248-current-proof/manifest.json', { root }));
const proof = fs.readFileSync(resolveEvidenceFile(root, proofPath), 'utf8');
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
  const modified = proof.replace('.planning/phases/246-collection-controls-and-search/246-VALIDATION.md', '../../etc/passwd'); // archive-sweep-exempt: text substituted inside the proof markdown, not a filesystem read
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /path escapes repository/);
});

test('rejects a finding linked to an unknown owner topic', () => {
  const modified = proof.replace('| F03 | page-specific SubscriptionLive detail composition plus shared Detail components | Subscriptions collection |', '| F03 | page-specific SubscriptionLive detail composition plus shared Detail components | Invented topic |');
  assert.throws(() => validateIntegratedProof({ root, proofPath, manifestPath, proofText: modified }), /unknown topic/);
});

function archiveFixture(t) {
  const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'phase248-archive-'));
  t.after(() => fs.rmSync(scratch, { recursive: true, force: true }));
  const relative = '.planning/phases/245-baseline/evidence.md'; // archive-sweep-exempt: synthetic fixture slug under an mkdtemp root, never a live repository read
  const archived = '.planning/milestones/v1.66-phases/245-baseline/evidence.md';
  const target = path.join(scratch, archived);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, 'recorded evidence');
  return { scratch, relative, archived, target };
}

test('resolves an unchanged phase evidence path after milestone archival', (t) => {
  const { scratch, relative, target } = archiveFixture(t);
  assert.equal(resolveEvidenceFile(scratch, relative), target);
});

test('rejects ambiguous archived phase evidence rather than choosing a milestone', (t) => {
  const { scratch, relative, archived } = archiveFixture(t);
  const duplicate = path.join(scratch, archived.replace('v1.66-phases', 'v1.67-phases'));
  fs.mkdirSync(path.dirname(duplicate), { recursive: true });
  fs.writeFileSync(duplicate, 'different evidence');
  assert.throws(() => resolveEvidenceFile(scratch, relative), /ambiguous archived evidence/);
});

test('rejects a symlink in the archived evidence path', (t) => {
  const { scratch, relative, target } = archiveFixture(t);
  fs.unlinkSync(target);
  fs.symlinkSync('/etc/passwd', target);
  assert.throws(() => resolveEvidenceFile(scratch, relative), /symlink path/);
});

test('does not apply archive fallback to traversal or absolute evidence paths', (t) => {
  const { scratch } = archiveFixture(t);
  assert.throws(() => resolveEvidenceFile(scratch, '../../etc/passwd'), /path escapes repository/);
  assert.throws(() => resolveEvidenceFile(scratch, '/etc/passwd'), /unsafe path/);
  assert.throws(() => resolveEvidenceFile(scratch, '.planning/phases/245-baseline/../evidence.md'), /missing evidence path/); // archive-sweep-exempt: synthetic fixture slug under an mkdtemp root, never a live repository read
});
