#!/usr/bin/env node
// Phase 250 D4 visual classification ledger checker.
//
// D4: every changed Phase 211 baseline surface is classified from the CI diff
// PNGs. A change traceable to an allowed commit is `intentional` and may be
// re-minted; anything else is a `regression` fixed in source. This checker
// enforces that mechanically:
//
//   (1) exactly 12 data rows, one per required surface x theme, unique, with the
//       expected baseline file name;
//   (2) every `intentional` / `regression` row cites `receipt:<sha>` that exists,
//       is an ancestor of HEAD and lies in an allowed range:
//         - the owner-feedback range 3d7d949d^..b4a7eeac,
//         - exactly one of the authorized CSS commits (249-01, 249-09, and the
//           250-03 quiet-link focus ring authorized by the Phase 250 orchestrator),
//         - or a commit whose subject has a v1.63-v1.66 phase scope (233..248[-NN]);
//   (3) every `regression` row cites `fix:<sha>` that exists, is an ancestor of
//       HEAD and whose subject starts with `fix(250-04)`;
//   (4) the set of PNGs changed under accrue_admin/e2e/__screenshots__/ between
//       --base and HEAD equals the set of `intentional` rows' baseline files.
//
// Usage:
//   node 250-visual-ledger-check.mjs --ledger <file> [--base <sha>] [--check-rows-only] [--repo <dir>]
//   node 250-visual-ledger-check.mjs --self-test
//
// git is invoked through spawnSync with argument arrays only.

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const SURFACES = Object.freeze([
  "dashboard",
  "invoices",
  "invoice-detail",
  "subscriptions",
  "subscription-detail",
  "component-kitchen"
]);
const THEMES = Object.freeze(["light", "dark"]);
const CLASSES = Object.freeze(["intentional", "regression", "unchanged"]);
const SCREENSHOT_ROOT = "accrue_admin/e2e/__screenshots__";
const BASELINE_DIR = `${SCREENSHOT_ROOT}/visual-desktop`;

export const PRODUCTION_RANGES = Object.freeze({
  ownerFeedback: { from: "3d7d949def2eca73bbb240784d31de0b039b8d67", to: "b4a7eeac114cb8a6d5691c55f458dd4c94ec4257" },
  exact: [
    "1a755b2da2377114d43a4f0f8ebc6ec58ed41936", // fix(249-01) admin CSS guards
    "8b9dc25871f4369ae9b3751c79c2e82f1faeb08c", // fix(249-09) topbar reflow
    "6fc488cd12253e049e105104df6ab952bf35635e" // fix(250-03) quiet-link focus ring
  ],
  phaseScope: /^[a-z]+\((?:23[3-9]|24[0-8])(?:-\d+)?\)!?:/
});

function git(repo, args) {
  const r = spawnSync("git", args, { cwd: repo, encoding: "utf8" });
  return { ok: r.status === 0, out: (r.stdout || "").trim(), err: (r.stderr || "").trim() };
}

function expectedFile(surface, theme) {
  return theme === "dark" ? `${surface}-dark.png` : `${surface}.png`;
}

export function parseLedger(text) {
  const rows = [];
  let inTable = false;
  let header = null;
  for (const line of text.split(/\r?\n/)) {
    const t = line.trim();
    if (!t.startsWith("|")) {
      if (inTable) inTable = false;
      continue;
    }
    const cells = t.replace(/^\|/, "").replace(/\|$/, "").split("|").map((c) => c.trim().replace(/^`|`$/g, ""));
    if (!inTable) {
      if (cells[0] === "surface" && cells[1] === "theme") {
        header = cells;
        inTable = true;
      }
      continue;
    }
    if (cells.every((c) => /^:?-{3,}:?$/.test(c))) continue;
    if (!header) continue;
    rows.push({
      surface: cells[0],
      theme: cells[1],
      file: cells[2],
      status: cells[3],
      diffRef: cells[4],
      classification: cells[5],
      receipt: cells[6],
      fix: cells[7],
      rationale: cells[8]
    });
  }
  return rows;
}

function resolveCommit(repo, sha) {
  if (!/^[0-9a-f]{7,40}$/.test(sha)) return null;
  if (!git(repo, ["cat-file", "-e", `${sha}^{commit}`]).ok) return null;
  const full = git(repo, ["rev-parse", `${sha}^{commit}`]);
  return full.ok ? full.out : null;
}

function isAncestor(repo, a, b) {
  return git(repo, ["merge-base", "--is-ancestor", a, b]).ok;
}

function subject(repo, sha) {
  return git(repo, ["log", "-1", "--format=%s", sha]).out;
}

function inAllowedRange(repo, full, ranges) {
  if (ranges.exact.includes(full)) return "exact";
  const { from, to } = ranges.ownerFeedback;
  const fromParent = git(repo, ["rev-parse", `${from}^`]);
  if (isAncestor(repo, full, to) && fromParent.ok && !isAncestor(repo, full, fromParent.out)) return "owner-feedback";
  if (ranges.phaseScope.test(subject(repo, full))) return "phase-scope";
  return null;
}

export function checkLedger({ repo, ledgerText, base, rowsOnly, ranges = PRODUCTION_RANGES }) {
  const errors = [];
  const rows = parseLedger(ledgerText);

  // (1) shape
  if (rows.length !== 12) errors.push(`expected exactly 12 data rows, found ${rows.length}`);
  const seen = new Set();
  for (const row of rows) {
    const key = `${row.surface}/${row.theme}`;
    if (seen.has(key)) errors.push(`duplicate surface/theme ${key}`);
    seen.add(key);
    if (!SURFACES.includes(row.surface)) errors.push(`${key}: unknown surface`);
    if (!THEMES.includes(row.theme)) errors.push(`${key}: unknown theme`);
    if (SURFACES.includes(row.surface) && THEMES.includes(row.theme) && row.file !== expectedFile(row.surface, row.theme)) {
      errors.push(`${key}: baseline file ${row.file} != ${expectedFile(row.surface, row.theme)}`);
    }
    if (!CLASSES.includes(row.classification)) errors.push(`${key}: classification ${row.classification} not in ${CLASSES.join("/")}`);
    if (!row.rationale) errors.push(`${key}: rationale is empty`);
  }
  for (const s of SURFACES) for (const t of THEMES) if (!seen.has(`${s}/${t}`)) errors.push(`missing row ${s}/${t}`);

  const head = git(repo, ["rev-parse", "HEAD"]).out;

  // (2) receipts, (3) fixes
  for (const row of rows) {
    const key = `${row.surface}/${row.theme}`;
    if (row.classification === "unchanged") {
      if (row.fix && row.fix !== "-") errors.push(`${key}: unchanged row must not cite a fix`);
      continue;
    }
    if (!CLASSES.includes(row.classification)) continue;
    const m = /^receipt:([0-9a-f]{7,40})$/.exec(row.receipt || "");
    if (!m) {
      errors.push(`${key}: ${row.classification} row needs receipt:<sha>, got ${row.receipt || "(empty)"}`);
    } else {
      const full = resolveCommit(repo, m[1]);
      if (!full) errors.push(`${key}: receipt ${m[1]} is not a commit`);
      else if (!isAncestor(repo, full, head)) errors.push(`${key}: receipt ${m[1]} is not an ancestor of HEAD`);
      else if (!inAllowedRange(repo, full, ranges)) errors.push(`${key}: receipt ${m[1]} is outside every allowed range (${subject(repo, full)})`);
    }
    if (row.classification === "regression") {
      const f = /^fix:([0-9a-f]{7,40})$/.exec(row.fix || "");
      if (!f) {
        errors.push(`${key}: regression row needs fix:<sha>, got ${row.fix || "(empty)"}`);
      } else {
        const full = resolveCommit(repo, f[1]);
        if (!full) errors.push(`${key}: fix ${f[1]} is not a commit`);
        else if (!isAncestor(repo, full, head)) errors.push(`${key}: fix ${f[1]} is not an ancestor of HEAD`);
        else if (!subject(repo, full).startsWith("fix(250-04)")) errors.push(`${key}: fix ${f[1]} subject does not start with fix(250-04)`);
      }
    } else if (row.fix && row.fix !== "-") {
      errors.push(`${key}: only regression rows cite a fix`);
    }
  }

  // (4) set equality
  if (!rowsOnly) {
    if (!base) {
      errors.push("--base <sha> is required unless --check-rows-only");
    } else if (!resolveCommit(repo, base)) {
      errors.push(`base ${base} is not a commit`);
    } else {
      const diff = git(repo, ["diff", "--name-only", base, "HEAD", "--", SCREENSHOT_ROOT]);
      if (!diff.ok) errors.push(`git diff failed: ${diff.err}`);
      const changed = new Set(diff.out.split("\n").filter((p) => p.endsWith(".png")));
      const intended = new Set(rows.filter((r) => r.classification === "intentional").map((r) => `${BASELINE_DIR}/${r.file}`));
      for (const p of changed) if (!intended.has(p)) errors.push(`changed PNG ${p} has no intentional row`);
      for (const p of intended) if (!changed.has(p)) errors.push(`intentional row ${p} did not change between ${base} and HEAD`);
    }
  }
  return { rows, errors };
}

function parseArgs(argv) {
  const out = { rowsOnly: false, selfTest: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--ledger") out.ledger = argv[++i];
    else if (a === "--base") out.base = argv[++i];
    else if (a === "--repo") out.repo = argv[++i];
    else if (a === "--check-rows-only") out.rowsOnly = true;
    else if (a === "--self-test") out.selfTest = true;
    else throw new Error(`unknown argument ${a}`);
  }
  return out;
}

// ---------------------------------------------------------------- self-test

function selfTest() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "visual-ledger-selftest-"));
  const run = (args) => {
    const r = spawnSync("git", args, { cwd: dir, encoding: "utf8" });
    if (r.status !== 0) throw new Error(`git ${args.join(" ")}: ${r.stderr}`);
    return r.stdout.trim();
  };
  const commit = (msg, files = {}) => {
    for (const [p, c] of Object.entries(files)) {
      fs.mkdirSync(path.dirname(path.join(dir, p)), { recursive: true });
      fs.writeFileSync(path.join(dir, p), c);
      run(["add", p]);
    }
    run(["commit", "--allow-empty", "-q", "-m", msg]);
    return run(["rev-parse", "HEAD"]);
  };
  let failures = 0;
  let checks = 0;
  try {
    run(["init", "-q", "-b", "selftest"]);
    run(["config", "user.email", ["selftest", "example.invalid"].join(String.fromCharCode(64))]); // synthetic identity, assembled so the pre-push e-mail scan stays meaningful
    run(["config", "user.name", "selftest"]);
    run(["config", "commit.gpgsign", "false"]);
    const allPngs = {};
    for (const s of SURFACES) for (const t of THEMES) allPngs[`${BASELINE_DIR}/${expectedFile(s, t)}`] = `old ${s} ${t}`;
    const root = commit("chore: baselines", allPngs);
    const outside = commit("fix(admin): before the owner-feedback range");
    const ofFrom = commit("fix(admin): owner feedback one");
    const ofTo = commit("fix(admin): owner feedback two");
    const exact = commit("fix(249-01): css guard");
    const phase = commit("feat(247-03): convert timestamps");
    const unrelated = commit("feat(admin): unrelated later change");
    const goodFix = commit("fix(250-04): dashboard visual regression");
    const badFix = commit("chore(250-04): not a fix subject");
    const base = run(["rev-parse", "HEAD"]);
    commit("test(250-04): re-mint", {
      [`${BASELINE_DIR}/dashboard.png`]: "new dashboard light",
      [`${BASELINE_DIR}/dashboard-dark.png`]: "new dashboard dark",
      [`${BASELINE_DIR}/subscriptions.png`]: "new subscriptions light"
    });
    const ranges = { ownerFeedback: { from: ofFrom, to: ofTo }, exact: [exact], phaseScope: PRODUCTION_RANGES.phaseScope };
    void root;

    const baseRows = () => {
      const rows = [];
      for (const s of SURFACES) for (const t of THEMES) {
        rows.push({ surface: s, theme: t, file: expectedFile(s, t), status: "same", diff: "-", cls: "unchanged", receipt: "-", fix: "-", why: "byte-identical" });
      }
      const set = (s, t, patch) => Object.assign(rows.find((r) => r.surface === s && r.theme === t), patch);
      set("dashboard", "light", { status: "changed", diff: "run 1 / dashboard-diff.png", cls: "intentional", receipt: `receipt:${ofTo.slice(0, 8)}`, why: "owner feedback" });
      set("dashboard", "dark", { status: "changed", diff: "run 1", cls: "intentional", receipt: `receipt:${phase.slice(0, 8)}`, why: "phase scope" });
      set("subscriptions", "light", { status: "changed", diff: "run 1", cls: "intentional", receipt: `receipt:${exact.slice(0, 8)}`, why: "exact" });
      set("invoices", "light", { status: "changed", diff: "run 1", cls: "regression", receipt: `receipt:${ofFrom.slice(0, 8)}`, fix: `fix:${goodFix.slice(0, 8)}`, why: "fixed in source" });
      return rows;
    };
    const render = (rows) => [
      "# ledger",
      "",
      "| surface | theme | baseline file | status | diff ref | classification | receipt | fix | rationale |",
      "|---|---|---|---|---|---|---|---|---|",
      ...rows.map((r) => `| ${r.surface} | ${r.theme} | ${r.file} | ${r.status} | ${r.diff} | ${r.cls} | ${r.receipt} | ${r.fix} | ${r.why} |`),
      ""
    ].join("\n");
    const expect = (name, rows, shouldPass, opts = {}) => {
      checks++;
      const { errors } = checkLedger({ repo: dir, ledgerText: render(rows), base: opts.base ?? base, rowsOnly: false, ranges });
      const passed = errors.length === 0;
      if (passed !== shouldPass) {
        failures++;
        console.error(`FAIL ${name}: expected ${shouldPass ? "pass" : "fail"}, got ${passed ? "pass" : "fail"} ${errors.join("; ")}`);
      } else {
        console.log(`ok   ${name}${passed ? "" : ` (${errors[0]})`}`);
      }
    };

    expect("all-valid fixture passes", baseRows(), true);
    expect("11 rows fails", baseRows().slice(0, 11), false);
    {
      const r = baseRows();
      r[11] = { ...r[0] };
      expect("duplicate surface fails", r, false);
    }
    {
      const r = baseRows();
      r.find((x) => x.surface === "dashboard" && x.theme === "light").receipt = "receipt:deadbeefdeadbeef";
      expect("nonexistent receipt fails", r, false);
    }
    {
      const r = baseRows();
      r.find((x) => x.surface === "dashboard" && x.theme === "light").receipt = `receipt:${outside.slice(0, 8)}`;
      expect("receipt before the owner-feedback range fails", r, false);
    }
    {
      const r = baseRows();
      r.find((x) => x.surface === "dashboard" && x.theme === "light").receipt = `receipt:${unrelated.slice(0, 8)}`;
      expect("receipt outside every allowed range fails", r, false);
    }
    {
      const r = baseRows();
      r.find((x) => x.surface === "invoices" && x.theme === "light").fix = "-";
      expect("regression row without fix fails", r, false);
    }
    {
      const r = baseRows();
      r.find((x) => x.surface === "invoices" && x.theme === "light").fix = `fix:${badFix.slice(0, 8)}`;
      expect("fix whose subject is not fix(250-04) fails", r, false);
    }
    {
      const r = baseRows();
      Object.assign(r.find((x) => x.surface === "subscriptions" && x.theme === "light"), { cls: "unchanged", receipt: "-" });
      expect("changed PNG with no intentional row fails", r, false);
    }
    {
      const r = baseRows();
      Object.assign(r.find((x) => x.surface === "invoice-detail" && x.theme === "dark"), { cls: "intentional", receipt: `receipt:${phase.slice(0, 8)}` });
      expect("intentional row whose PNG did not change fails", r, false);
    }
    {
      const r = baseRows();
      r.find((x) => x.surface === "component-kitchen" && x.theme === "dark").file = "component-kitchen.png";
      expect("wrong baseline file name fails", r, false);
    }
    {
      const all = baseRows().map((x) => ({ ...x, cls: "unchanged", receipt: "-", fix: "-" }));
      expect("all unchanged with empty change set passes", all, true, { base: run(["rev-parse", "HEAD"]) });
    }
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
  if (failures > 0) {
    console.error(`SELF-TEST FAILED (${failures}/${checks})`);
    return 1;
  }
  console.log(`SELF-TEST PASS (${checks} checks)`);
  return 0;
}

function main() {
  let args;
  try {
    args = parseArgs(process.argv.slice(2));
  } catch (e) {
    console.error(e.message);
    return 2;
  }
  if (args.selfTest) return selfTest();
  if (!args.ledger) {
    console.error("Usage: --ledger <file> [--base <sha>] [--check-rows-only] [--repo <dir>] | --self-test");
    return 2;
  }
  const repo = args.repo || git(process.cwd(), ["rev-parse", "--show-toplevel"]).out || process.cwd();
  const { rows, errors } = checkLedger({ repo, ledgerText: fs.readFileSync(args.ledger, "utf8"), base: args.base, rowsOnly: args.rowsOnly });
  if (errors.length) {
    console.error(`FAIL (${errors.length}):\n${errors.map((e) => `- ${e}`).join("\n")}`);
    return 1;
  }
  const counts = Object.fromEntries(CLASSES.map((c) => [c, rows.filter((r) => r.classification === c).length]));
  console.log(`PASS: 12 rows (${CLASSES.map((c) => `${c} ${counts[c]}`).join(", ")})${args.rowsOnly ? " [rows only]" : `; changed PNG set equals intentional rows since ${args.base}`}`);
  return 0;
}

process.exitCode = main();
