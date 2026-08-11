#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

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

if (import.meta.url === `file://${process.argv[1]}`) {
  try { main(); } catch (error) { console.error(`provider summary: FAIL: ${error.message}`); process.exitCode = 1; }
}
