const fs = require("node:fs");
const path = require("node:path");

const EXPECTED_BASELINES = Object.freeze([
  "dashboard.png",
  "dashboard-dark.png",
  "subscriptions.png",
  "subscriptions-dark.png",
  "subscription-detail.png",
  "subscription-detail-dark.png",
  "component-kitchen.png",
  "component-kitchen-dark.png",
  "invoices.png",
  "invoices-dark.png",
  "invoice-detail.png",
  "invoice-detail-dark.png"
]);

// Playwright derives the snapshot file name from the toHaveScreenshot name with its own
// sanitizeForFilePath: every run of control characters, punctuation and symbols (underscore
// included) becomes one hyphen. A case key such as phase254-page-scheduled_cancellation-w320-light
// is therefore stored as phase254-page-scheduled-cancellation-w320-light.png.
function snapshotFileName(key) {
  return `${key.replace(/[\x00-\x2C\x2E-\x2F\x3A-\x40\x5B-\x60\x7B-\x7F]+/g, "-")}.png`;
}

function checkBaselineSet(directory) {
  const missing = EXPECTED_BASELINES.filter((name) => {
    try {
      return !fs.statSync(path.join(directory, name)).isFile();
    } catch {
      return true;
    }
  });
  return { expected: EXPECTED_BASELINES, missing };
}

if (require.main === module) {
  const directory = process.argv[2];
  if (!directory) {
    console.error("Usage: node visual-baseline-set.cjs <baseline-directory>");
    process.exitCode = 2;
  } else {
    const { missing } = checkBaselineSet(directory);
    if (missing.length > 0) {
      console.error(
        `Missing required visual baselines (${missing.length}/${EXPECTED_BASELINES.length}):\n${missing.map((name) => `- ${name}`).join("\n")}`
      );
      process.exitCode = 1;
    } else {
      console.log(`Found all ${EXPECTED_BASELINES.length} required visual baselines in ${directory}.`);
    }
  }
}

module.exports = { EXPECTED_BASELINES, checkBaselineSet, snapshotFileName };
