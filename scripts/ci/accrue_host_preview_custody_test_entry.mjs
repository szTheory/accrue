#!/usr/bin/env node
// Test-only fixture entry point. Production wrappers call the custody script directly.
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const custodyPath = path.join(path.dirname(fileURLToPath(import.meta.url)), "accrue_host_preview_custody.sh");
const fixturePath = process.argv[2];
const mode = process.argv[3];
if (!fixturePath || !["browser", "dev"].includes(mode)) {
  console.error("usage: accrue_host_preview_custody_test_entry.mjs <fixture.json> <browser|dev>");
  process.exit(2);
}
fs.accessSync(fixturePath, fs.constants.R_OK);
process.argv = [process.argv[0], custodyPath, "preflight", mode];
require(custodyPath).run({ fixturePath });
