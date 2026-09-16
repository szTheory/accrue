#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

function escapeMarkdown(value) {
  return String(value ?? "not recorded")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/`/g, "&#96;")
    .replace(/[\\*_#[\]|]/g, (character) => `&#${character.codePointAt(0)};`)
    .replace(/:/g, "&#58;")
    .replace(/[\r\n]/g, " ")
    .replace(/[\u0000-\u001F\u007F]/g, "");
}

export function renderProviderSummary(record) {
  const fields = [
    ["Trigger", record.trigger], ["SHA", record.sha], ["Policy", record.policy], ["Proof state", record.proof_state],
    ["Reason", record.reason_code], ["Raw job conclusion", record.raw_job_conclusion],
    ["Selected / passed / skipped", `${record.selected_count} / ${record.passed_count} / ${record.skipped_count}`],
    ["Manifest written", record.manifest_written], ["Latest proved SHA", record.latest_proved_sha], ["Latest proved at", record.latest_proved_at],
    ["Freshness", record.stale ? "stale" : "fresh"], ["Evidence", record.evidence_url], ["Next command", record.next_command],
  ];
  return `## Provider proof\n\n${fields.map(([label, value]) => `- **${label}:** ${escapeMarkdown(value)}`).join("\n")}\n`;
}

function main() {
  const args = process.argv.slice(2);
  const recordIndex = args.indexOf("--record");
  if (recordIndex === -1 || !args[recordIndex + 1]) throw new Error("--record is required");
  const summary = renderProviderSummary(JSON.parse(fs.readFileSync(args[recordIndex + 1], "utf8")));
  const outputIndex = args.indexOf("--out");
  if (outputIndex !== -1) fs.mkdirSync(path.dirname(args[outputIndex + 1]), { recursive: true }), fs.writeFileSync(args[outputIndex + 1], summary);
  else process.stdout.write(summary);
}

// D-31: this file previously registered no real node:test case -- the broken
// file-URL-template guard always evaluated false, so its only TAP line was
// the file path itself. Guard fix and first real test land in the same
// commit.
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  test("renderProviderSummary escapes Markdown-significant characters and reports freshness from the stale boolean", () => {
    const rendered = renderProviderSummary({
      trigger: "push", sha: "a".repeat(40), policy: "required", proof_state: "proved",
      reason_code: "complete_provider_evidence", raw_job_conclusion: "success",
      selected_count: 3, passed_count: 3, skipped_count: 0, manifest_written: true,
      latest_proved_sha: "a".repeat(40), latest_proved_at: "2026-09-16T00:05:00.000Z",
      stale: false, evidence_url: "https://example.invalid/run|with*markdown_chars", next_command: "cd accrue && mix test.live",
    });
    assert.match(rendered, /^## Provider proof\n/);
    assert.match(rendered, /\*\*Freshness:\*\* fresh/);
    // Markdown-significant characters in the evidence URL must be escaped,
    // never pass through raw -- an unescaped pipe would corrupt a Markdown
    // table this summary might later be embedded in.
    assert.ok(!rendered.includes("run|with*markdown_chars"));
    assert.match(rendered, /run&#124;with&#42;markdown&#95;chars/);

    // Negative control: inverting the stale boolean must flip the rendered
    // label, proving the renderer actually reads the field rather than
    // hardcoding "fresh".
    const staleRendered = renderProviderSummary({ trigger: "push", sha: "a".repeat(40), policy: "required", proof_state: "proved", stale: true });
    assert.match(staleRendered, /\*\*Freshness:\*\* stale/);
  });
} else if (invokedAsEntrypoint) {
  try { main(); } catch (error) { console.error(`provider summary: FAIL: ${error.message}`); process.exitCode = 1; }
}
