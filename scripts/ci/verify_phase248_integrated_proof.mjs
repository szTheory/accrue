#!/usr/bin/env node
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import assert from 'node:assert/strict';
import { isMainModule } from './main_module.mjs';
import { resolvePhaseEvidencePath } from './phase_evidence_path.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const PHASE245_SLUG = '245-rendered-baseline-and-realistic-preview';
const OWNER_RE = /<!-- owner-items-json:start -->\s*([\s\S]*?)\s*<!-- owner-items-json:end -->/;
const FINDING_RE = /<!-- findings-json:start -->\s*([\s\S]*?)\s*<!-- findings-json:end -->/;

function fail(message) { throw new Error(message); }
export function resolveEvidenceFile(root, relative) {
  if (!relative || path.isAbsolute(relative) || relative.includes('\\')) fail(`unsafe path: ${relative}`);
  const resolved = path.resolve(root, relative);
  if (resolved !== root && !resolved.startsWith(`${root}${path.sep}`)) fail(`path escapes repository: ${relative}`);
  let cursor = root;
  for (const part of path.relative(root, resolved).split(path.sep)) {
    cursor = path.join(cursor, part);
    if (fs.existsSync(cursor) && fs.lstatSync(cursor).isSymbolicLink()) fail(`symlink path is not allowed: ${relative}`);
  }
  if (!fs.existsSync(resolved)) {
    const phasePath = relative.match(/^\.planning\/phases\/([0-9]+-[^/]+)\/(.+)$/);
    if (phasePath && !relative.split('/').some((part) => part === '..' || part === '.')) {
      const archiveRoot = path.join(root, '.planning/milestones');
      if (fs.existsSync(archiveRoot)) {
        if (fs.lstatSync(archiveRoot).isSymbolicLink()) fail(`symlink path is not allowed: ${relative}`);
        const candidates = fs.readdirSync(archiveRoot).filter((entry) => /^v[0-9]+(?:\.[0-9]+)*-phases$/.test(entry))
          .map((entry) => `.planning/milestones/${entry}/${phasePath[1]}/${phasePath[2]}`)
          .filter((candidate) => fs.existsSync(path.join(root, candidate)));
        if (candidates.length > 1) fail(`ambiguous archived evidence path: ${relative}`);
        if (candidates.length === 1) return resolveEvidenceFile(root, candidates[0]);
      }
    }
    fail(`missing evidence path: ${relative}`);
  }
  if (!fs.statSync(resolved).isFile()) fail(`missing evidence path: ${relative}`);
  return resolved;
}
function sourceKeys(root) {
  const ownerSource = path.relative(root, resolvePhaseEvidencePath(PHASE245_SLUG, '245-FINDINGS.md', { root })).split(path.sep).join('/');
  const source = fs.readFileSync(resolveEvidenceFile(root, ownerSource), 'utf8');
  const ownerBlock = source.match(OWNER_RE)?.[1];
  const findingBlock = source.match(FINDING_RE)?.[1];
  if (!ownerBlock || !findingBlock) fail('canonical topic/finding JSON blocks are missing');
  const ownerRows = JSON.parse(ownerBlock);
  const findingRows = JSON.parse(findingBlock);
  const topics = ownerRows.map((row) => row.topic);
  const findings = findingRows.map((row) => row.id);
  return { topics: [...new Set(topics)], findings: [...new Set(findings)], ownerRows, findingRows };
}
function tableRows(markdown, heading) {
  const section = markdown.split(`${heading}\n`)[1]?.split('\n## ')[0];
  if (!section) fail(`missing section: ${heading}`);
  return section.split('\n').filter((line) => line.startsWith('|') && !/^\|\s*:?-{3,}/.test(line))
    .slice(1).map((line) => line.split('|').slice(1, -1).map((cell) => cell.trim()));
}
function checkRow(row, root, captures) {
  const [key, owner, scope, disposition, command, result, evidence, captureRefs] = row;
  if (!key || !owner || !scope || !disposition || !command || !result || !evidence || !captureRefs) fail(`incomplete row: ${key || '(unknown)'}`);
  resolveEvidenceFile(root, evidence.split('#')[0].replaceAll('`', ''));
  if (disposition === 'PASS' && (!/\b(?:0 failures|\d+ passed|\d+ tests?\s*\/\s*0 failures|validated \d+ inspected captures|pass(?:ed)?)\b/i.test(result) || /pending|not run|unverified/i.test(result))) {
    fail(`${key} claims PASS without a concrete executed result`);
  }
  if (disposition === 'LIMITED' && !/(?:unverified|not exercised|historical|not captured|evidence gap|source-observed|no-change|no (?:current|phase 248))/i.test(result)) fail(`${key} needs an explicit bounded-evidence result`);
  if (captureRefs !== '—') {
    for (const capture of captureRefs.split(',').map((value) => value.trim())) {
      if (!captures.has(capture)) fail(`${key} references unresolved current capture: ${capture}`);
    }
  }
  return { key, command, disposition };
}

export function validateIntegratedProof({ root = ROOT, proofPath, manifestPath, proofText }) {
  const proofFile = resolveEvidenceFile(root, proofPath);
  const manifestFile = resolveEvidenceFile(root, manifestPath);
  const markdown = proofText ?? fs.readFileSync(proofFile, 'utf8');
  const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
  if (!['248', 248].includes(manifest.phase) || !Array.isArray(manifest.captures)) fail('invalid Phase 248 capture manifest');
  const captureNames = new Set(manifest.captures.map((capture) => capture.file));
  if (captureNames.size !== manifest.captures.length) fail('manifest has duplicate capture IDs');
  const { topics, findings, ownerRows, findingRows: canonicalFindings } = sourceKeys(root);
  const sourceSha = manifest.captures[0]?.source_sha;
  if (!/^[a-f0-9]{40}$/.test(sourceSha || '') || manifest.captures.some((capture) => capture.source_sha !== sourceSha)) fail('capture manifest has stale or inconsistent source SHA');
  if (!markdown.includes(`Tested source revision: \`${sourceSha}\``)) fail('proof tested source SHA does not match current capture manifest');
  for (const kind of ['css', 'js']) {
    const asset = manifest.captures[0]?.assets?.[kind];
    if (!asset || !/^[a-f0-9]{64}$/.test(asset.sha256 || '') || !Number.isInteger(asset.bytes)) fail(`manifest missing served ${kind} digest/byte count`);
    const bytes = fs.readFileSync(resolveEvidenceFile(root, asset.path));
    if (bytes.length !== asset.bytes || crypto.createHash('sha256').update(bytes).digest('hex') !== asset.sha256) fail(`served ${kind} digest or byte count differs from manifest`);
    if (!markdown.includes(`Served ${kind.toUpperCase()}: \`${asset.sha256}\` (${asset.bytes} bytes)`)) fail(`proof served ${kind} digest/bytes do not match manifest`);
  }
  const topicRows = tableRows(markdown, '## Owner topics');
  const ledgerFindingRows = tableRows(markdown, '## Accepted findings');
  const expected = [topics, findings];
  const actual = [topicRows.map((row) => row[0]), ledgerFindingRows.map((row) => row[0])];
  for (let index = 0; index < expected.length; index += 1) {
    const label = index === 0 ? 'topic' : 'finding';
    if (new Set(actual[index]).size !== actual[index].length) fail(`duplicate ${label} key`);
    const missing = expected[index].filter((key) => !actual[index].includes(key));
    const extra = actual[index].filter((key) => !expected[index].includes(key));
    if (missing.length || extra.length) fail(`${label} keys mismatch; missing=[${missing.join(', ')}] extra=[${extra.join(', ')}]`);
  }
  const ownersByTopic = new Map(ownerRows.map((row) => [row.topic, row.owner]));
  const ownerByKey = new Map(ownerRows.map((row) => [row.topic, row]));
  const findingById = new Map(canonicalFindings.map((row) => [row.id, row]));
  for (const row of topicRows) {
    if (row[1] !== ownersByTopic.get(row[0])) fail(`owner query mismatch for topic: ${row[0]}`);
    const source = ownerByKey.get(row[0]);
    const linkedFindings = [...new Set([source.finding, ...(source.additional_findings || [])].filter(Boolean))];
    for (const finding of linkedFindings) if (!row[2].includes(finding)) fail(`${row[0]} omits canonical linked finding ${finding}`);
  }
  for (const row of ledgerFindingRows) {
    const canonical = findingById.get(row[0]);
    if (row[1] !== canonical?.owner) fail(`owner query mismatch for finding: ${row[0]}`);
    const topic = ownerByKey.get(row[2]);
    if (!topic) fail(`finding ${row[0]} links to unknown topic: ${row[2]}`);
    if (![topic.finding, ...(topic.additional_findings || [])].includes(row[0])) fail(`finding ${row[0]} is linked to a topic that does not own it: ${row[2]}`);
  }
  const normalizedFindingRows = ledgerFindingRows.map((row) => [row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8]]);
  const checked = [...topicRows, ...normalizedFindingRows].map((row) => {
    if (row.length === 9) return checkRow([row[0], row[1], `${row[2]} / ${row[3]}`, row[4], row[5], row[6], row[7], row[8]], root, captureNames);
    return checkRow(row, root, captureNames);
  });
  if (checked.length !== 18) fail(`expected 18 total ledger rows, got ${checked.length}`);
  return { topicCount: topicRows.length, findingCount: ledgerFindingRows.length, currentCaptureCount: captureNames.size };
}

function args(argv) {
  const values = {};
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--proof' || argv[i] === '--manifest') values[argv[i].slice(2)] = argv[++i];
    else fail(`unknown argument: ${argv[i]}`);
  }
  if (!values.proof || !values.manifest) fail('usage: verify_phase248_integrated_proof.mjs --proof <path> --manifest <path>');
  return values;
}

function main() {
  try {
    const options = args(process.argv.slice(2));
    const result = validateIntegratedProof({ proofPath: options.proof, manifestPath: options.manifest });
    console.log(`PASS integrated proof: ${result.topicCount} owner topics, ${result.findingCount} accepted findings, ${result.currentCaptureCount} current captures`);
  } catch (error) {
    console.error(`FAIL integrated proof: ${error.message}`);
    process.exitCode = 1;
  }
}

let entry = false;
try {
  entry = isMainModule(import.meta.url);
} catch {
  entry = false;
}
if (entry && process.env.NODE_TEST_CONTEXT) {
  test('usage is rejected when --proof and --manifest are missing', () => {
    const env = { ...process.env };
    delete env.NODE_TEST_CONTEXT;
    const result = spawnSync(process.execPath, [fileURLToPath(import.meta.url)], { encoding: 'utf8', shell: false, env });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /usage: verify_phase248_integrated_proof\.mjs/);
  });
  test('resolveEvidenceFile rejects unsafe and escaping paths', () => {
    assert.throws(() => resolveEvidenceFile(ROOT, '/etc/passwd'), /unsafe path/);
    assert.throws(() => resolveEvidenceFile(ROOT, '../outside'), /escapes repository/);
  });
} else if (entry) {
  main();
}
