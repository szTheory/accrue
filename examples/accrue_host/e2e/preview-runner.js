// @ts-check
const { spawnSync } = require("node:child_process");
const path = require("node:path");
const { validatePreviewSelection } = require("./preview-routing");

const hostRoot = path.resolve(__dirname, "..");
const requested = process.argv.slice(2);

function fail(message) {
  console.error(`[preview-runner] REFUSED: ${message}`);
  process.exit(2);
}

try { validatePreviewSelection(requested); } catch (error) { fail(error.message); }

const cli = path.join(hostRoot, "node_modules", "@playwright", "test", "cli.js");
const result = spawnSync(process.execPath, [cli, "test", ...requested], {
  cwd: hostRoot,
  stdio: "inherit",
  env: {
    ...process.env,
    ACCRUE_HOST_PREVIEW_MODE: "preservation",
    ACCRUE_HOST_PREVIEW_SELECTION: "phase243-preview-preservation"
  }
});
if (result.error) {
  console.error(`[preview-runner] ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status ?? 1);
