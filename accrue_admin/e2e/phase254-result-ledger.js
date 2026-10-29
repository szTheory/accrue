"use strict";

// Phase 254 D-13/D-14: a side-effect-free per-case result ledger.
//
// The Phase 253 composition run used to append every case row to one shared results
// file with a read-modify-write cycle (read the whole file, replace or push a row,
// rewrite it). Two writers interleaving that cycle lose a row, which is harmless only
// while exactly one worker runs. This module removes the race by construction: every
// case owns its own file, written through a temp file and an atomic rename, and a
// dependent reconcile step merges the directory afterwards.
//
// There are no import-time side effects here: no manifest reads, no directory
// creation, no environment access. Every function takes its inputs explicitly.

const fs = require("node:fs");
const path = require("node:path");

const MAX_KEY_LENGTH = 200;
let temporaryCounter = 0;

function assertSafeKey(key) {
  if (typeof key !== "string" || key.length === 0) {
    throw new Error("Phase 254 case result key must be a non-empty string");
  }
  if (key.length > MAX_KEY_LENGTH) {
    throw new Error(`Phase 254 case result key is longer than ${MAX_KEY_LENGTH} characters`);
  }
  if (/[\\/\0]/.test(key)) {
    throw new Error(`Phase 254 case result key contains a path separator or NUL: ${JSON.stringify(key)}`);
  }
  if (key === "." || key === ".." || key.includes("..") || key.startsWith(".")) {
    throw new Error(`Phase 254 case result key contains a dot segment: ${JSON.stringify(key)}`);
  }
  return key;
}

// encodeURIComponent is injective, so two distinct keys can never share a file, and it
// maps the "::" separators of composition keys to filesystem-safe text.
function caseFileName(key) {
  return `${encodeURIComponent(assertSafeKey(key))}.json`;
}

/** The file one case writes. Throws for a key that could escape the directory. */
function caseResultPath(dir, key) {
  if (typeof dir !== "string" || dir.length === 0) {
    throw new Error("Phase 254 case result directory must be a non-empty string");
  }
  return path.join(dir, caseFileName(key));
}

function assertIdentity(identity) {
  if (!identity || typeof identity.runId !== "string" || typeof identity.manifestDigest !== "string" ||
      identity.runId.length === 0 || identity.manifestDigest.length === 0) {
    throw new Error("Phase 254 case result identity needs a runId and a manifestDigest");
  }
}

/**
 * Writes one case row to its own file: pid-suffixed temp file, then an atomic rename.
 * Re-running a case replaces only that case's file. The row must carry the run's identity.
 */
function writeCaseResult(dir, row, identity) {
  assertIdentity(identity);
  if (!row || typeof row !== "object") throw new Error("Phase 254 case result row must be an object");
  const filePath = caseResultPath(dir, row.key);
  if (row.run_id !== identity.runId || row.manifest_sha256 !== identity.manifestDigest) {
    throw new Error(`Phase 254 case result identity differs from this browser run: ${row.key}`);
  }
  fs.mkdirSync(dir, { recursive: true });
  temporaryCounter += 1;
  const temporaryPath = `${filePath}.${process.pid}.${temporaryCounter}.tmp`;
  fs.writeFileSync(temporaryPath, `${JSON.stringify(row, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(temporaryPath, filePath);
  return filePath;
}

/**
 * Reads every case file for one run and returns the rows sorted by key. Rejects an
 * unparsable file, a file whose run or manifest identity differs, a file that does not
 * carry the key it is named after, and a duplicate key. Temporary files are ignored.
 */
function mergeCaseResults(dir, identity) {
  assertIdentity(identity);
  let names;
  try {
    names = fs.readdirSync(dir);
  } catch (error) {
    if (error?.code === "ENOENT") return [];
    throw error;
  }
  const rows = [];
  const seen = new Map();
  const named = [];
  for (const name of names.filter((entry) => entry.endsWith(".json")).sort()) {
    const filePath = path.join(dir, name);
    let row;
    try {
      row = JSON.parse(fs.readFileSync(filePath, "utf8"));
    } catch (error) {
      throw new Error(`Phase 254 case result file is unreadable or not JSON: ${name} (${error.message})`);
    }
    if (!row || typeof row !== "object" || typeof row.key !== "string") {
      throw new Error(`Phase 254 case result file has no case key: ${name}`);
    }
    if (row.run_id !== identity.runId || row.manifest_sha256 !== identity.manifestDigest) {
      throw new Error(`Phase 254 case result belongs to a different run or manifest: ${row.key}`);
    }
    if (seen.has(row.key)) {
      throw new Error(`Phase 254 duplicate case result key: ${row.key} (${seen.get(row.key)} and ${name})`);
    }
    seen.set(row.key, name);
    named.push([name, row]);
  }
  // Names are checked after the duplicate pass so a copied file reports as a duplicate.
  for (const [name, row] of named) {
    if (caseFileName(row.key) !== name) {
      throw new Error(`Phase 254 case result file name does not match its key: ${name}`);
    }
    rows.push(row);
  }
  return rows.sort((left, right) => (left.key < right.key ? -1 : left.key > right.key ? 1 : 0));
}

module.exports = {
  caseResultPath,
  mergeCaseResults,
  writeCaseResult,
};
