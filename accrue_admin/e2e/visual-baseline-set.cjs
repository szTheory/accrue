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
  "component-kitchen-dark.png"
]);

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

module.exports = { EXPECTED_BASELINES, checkBaselineSet };
