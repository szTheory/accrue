#!/usr/bin/env node
import fs from "node:fs";
import { createRepositoryValidationContext, validateInventory } from "./collect_repository_inventory.mjs";
const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
export function renderRepositoryInventory(inventory, validationContext) {
  const value = validateInventory(inventory, validationContext);
  const refs = [...value.recovery.refs].sort((a, b) => a.original_ref.localeCompare(b.original_ref));
  const artifacts = [...value.artifacts.entries].sort((a, b) => `${a.path}\0${a.type}`.localeCompare(`${b.path}\0${b.type}`));
  return [
    "# Repository Inventory", "", "Local-only, schema-v1 recovery evidence. External paths, artifact contents, link text, environment values, actors, and raw payloads are intentionally excluded.", "",
    "## Recovery barrier", "", `**State:** verified. **Owner:** repository maintainers. **Next command:** \`PHASE229_BUNDLE=/private/bundle git bundle verify \"$PHASE229_BUNDLE\"\`.`, "", `Bundle SHA-256: \`${value.recovery.bundle_sha256}\`.`, "",
    "| Original ref | Object | Preservation ref | Bundle member |", "| --- | --- | --- | --- |", ...refs.map((ref) => `| ${escape(ref.original_ref)} | \`${ref.object}\` | ${escape(ref.encoded_ref)} | yes |`), "",
    "## Local ref truth", "", "| Fact | Full object ID |", "| --- | --- |", ...Object.entries(value.refs).sort(([a], [b]) => a.localeCompare(b)).map(([name, object]) => `| ${escape(name)} | \`${object}\` |`), "",
    "## User-owned artifact evidence", "", `Empty-directory policy: \`${value.artifacts.empty_directory_policy}\`.`, "", "| Relative path | Type | SHA-256 or marker |", "| --- | --- | --- |", ...artifacts.map((entry) => `| ${escape(entry.path)} | ${entry.type} | \`${entry.sha256}\` |`), "",
    "## Remote observation", "", "**State:** unavailable. This local-only inventory did not query remotes.", ""
  ].join("\n");
}
function main() { const [input, out, repository] = [process.argv[process.argv.indexOf("--input") + 1], process.argv[process.argv.indexOf("--out") + 1], process.argv[process.argv.indexOf("--expected-repository") + 1]]; if (!input || !out || !repository) throw new Error("--input, --out, and --expected-repository are required"); const context = createRepositoryValidationContext({ expectedRepository: repository }); fs.writeFileSync(out, renderRepositoryInventory(JSON.parse(fs.readFileSync(input, "utf8")), context)); }
if (process.argv[1] === new URL(import.meta.url).pathname) { try { main(); } catch (error) { console.error(`repository inventory render: FAIL: ${error.message}`); process.exitCode = 1; } }
