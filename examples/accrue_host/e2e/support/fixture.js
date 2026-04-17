// @ts-check
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const defaultFixturePath = path.join(os.tmpdir(), "accrue-host-e2e-fixture.json");

function readFixture() {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE || defaultFixturePath;

  if (!fs.existsSync(fixturePath)) {
    throw new Error(`ACCRUE_HOST_E2E_FIXTURE is missing at ${fixturePath}`);
  }

  return JSON.parse(fs.readFileSync(path.resolve(fixturePath), "utf8"));
}

function reseedFixture() {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE || defaultFixturePath;
  const repoRoot = path.resolve(process.cwd(), "..", "..");

  execFileSync("mix", ["run", path.join(repoRoot, "scripts/ci/accrue_host_seed_e2e.exs")], {
    cwd: process.cwd(),
    stdio: "inherit",
    env: {
      ...process.env,
      MIX_ENV: "test",
      ACCRUE_HOST_E2E_FIXTURE: fixturePath
    }
  });

  process.env.ACCRUE_HOST_E2E_FIXTURE = fixturePath;
}

/**
 * @param {import('@playwright/test').Page} page
 * @param {Record<string, unknown>} fixture
 * @param {string} email
 */
async function login(page, fixture, email) {
  await page.goto("/users/log-in");

  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");

  if (!csrfToken) {
    throw new Error(`missing CSRF token on login page for ${email}`);
  }

  const response = await page.request.post("/users/log-in", {
    form: {
      _csrf_token: csrfToken,
      "user[email]": email,
      "user[password]": fixture.password
    }
  });

  if (!response.ok()) {
    throw new Error(`login POST failed for ${email}: ${response.status()} ${response.statusText()}`);
  }

  await page.goto("/");

  try {
    await page.getByRole("link", { name: "Go to billing" }).waitFor({ state: "visible", timeout: 10_000 });
  } catch (error) {
    console.error(`login did not reach authenticated home for ${email}`);
    console.error(`url: ${page.url()}`);
    console.error((await page.locator("body").innerText()).slice(0, 2000));
    throw error;
  }
}

/**
 * @param {import('@playwright/test').Page} page
 */
async function waitForLiveView(page) {
  try {
    await page.waitForFunction(
      () => Boolean(document.querySelector("[data-phx-main].phx-connected")),
      null,
      { timeout: 5_000 }
    );
  } catch (error) {
    console.error("LiveView client did not connect");
    console.error(
      await page.evaluate(() => ({
        classes: document.documentElement.className,
        liveSocket: Boolean(window.liveSocket),
        scripts: Array.from(document.scripts).map((script) => script.src || "[inline]")
      }))
    );
    throw error;
  }
}

module.exports = {
  defaultFixturePath,
  readFixture,
  reseedFixture,
  login,
  waitForLiveView
};
