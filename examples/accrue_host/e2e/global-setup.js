// @ts-check
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const projectRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(projectRoot, "..", "..");
const defaultFixturePath = path.join(os.tmpdir(), "accrue-host-e2e-fixture.json");

function runMix(args, extraEnv = {}) {
  execFileSync("mix", args, {
    cwd: projectRoot,
    stdio: "inherit",
    env: { ...process.env, ...extraEnv }
  });
}

function ensureDatabase() {
  try {
    runMix(["ecto.create", "--quiet"], { MIX_ENV: "test" });
  } catch (error) {
    const output = `${error.stdout || ""}\n${error.stderr || ""}`;

    if (!output.includes("already exists")) {
      throw error;
    }
  }
}

module.exports = async () => {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE || defaultFixturePath;

  fs.mkdirSync(path.dirname(fixturePath), { recursive: true });

  ensureDatabase();
  runMix(["ecto.migrate", "--quiet"], { MIX_ENV: "test" });

  if (process.env.ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED === "1") {
    if (!fs.existsSync(fixturePath)) {
      throw new Error(
        `ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1 but fixture is missing at ${fixturePath}`
      );
    }
  } else {
    runMix(["run", path.join(repoRoot, "scripts/ci/accrue_host_seed_e2e.exs")], {
      MIX_ENV: "test",
      ACCRUE_HOST_E2E_FIXTURE: fixturePath
    });
  }

  process.env.ACCRUE_HOST_E2E_FIXTURE = fixturePath;
};
