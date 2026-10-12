// @ts-check
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const baseSetup = require("./global-setup.js");

const hostRoot = path.resolve(__dirname, "..");

module.exports = async () => {
  if (process.env.PHASE248_PROOF_LANE !== "heldout" || process.env.ACCRUE_HOST_BROWSER_PORT !== "4102") {
    throw new Error("Phase 248 fixture setup is restricted to the explicit heldout lane on port 4102");
  }
  if (process.env.ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX === "1") {
    throw new Error("Phase 248 fixture setup requires SQL sandbox isolation");
  }

  const teardown = await baseSetup();
  try {
    // This is the existing owner-maintained boundary fixture. The isolated
    // E2E seed cleanup removes it first, so seed it after the shared setup.
    execFileSync("mix", ["run", "priv/repo/seeds/edge_states.exs"], {
      cwd: hostRoot,
      stdio: "inherit",
      env: { ...process.env, MIX_ENV: "test" }
    });
  } catch (error) {
    if (typeof teardown === "function") await teardown();
    throw error;
  }

  return teardown;
};
