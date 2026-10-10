// @ts-check
const { execFileSync } = require("node:child_process");
const { spawn } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { test, expect } = require("@playwright/test");

const previewProject = process.env.ACCRUE_HOST_PREVIEW_INSTANCE || "accrue-host";
const operatorEmail = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com";
const operatorPassword = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;
const hostRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(hostRoot, "..", "..");
const custodyTool = path.join(repoRoot, "scripts/ci/accrue_host_preview_custody.sh");
const composeFile = path.join(hostRoot, "docker-compose.yml");
const compose = (...args) => ["compose", "-p", previewProject, "-f", composeFile, ...args];

function capturePreviewSnapshot(mode, snapshotPath) {
  execFileSync("node", [custodyTool, mode], {
    stdio: "inherit",
    env: { ...process.env, ACCRUE_HOST_PREVIEW_INSTANCE: previewProject, ACCRUE_HOST_PREVIEW_SNAPSHOT: snapshotPath }
  });
}

async function warmRecoverAndWait(snapshotPath) {
  const logPath = path.join(os.tmpdir(), `accrue-host-phase243-warm-${process.pid}.log`);
  const logFd = fs.openSync(logPath, "w", 0o600);
  const warm = spawn("make", ["up", `INSTANCE=${previewProject}`], {
    cwd: hostRoot,
    env: { ...process.env, ACCRUE_HOST_SKIP_SEEDS: "1", ACCRUE_HOST: `${previewProject}.localhost`, COMPOSE_PROJECT_NAME: previewProject },
    detached: true,
    stdio: ["ignore", logFd, logFd]
  });

  if (!warm.pid) throw new Error("warm preview make process did not start");
  const deadline = Date.now() + 180_000;
  let ready = false;
  let bannerPrinted = false;
  try {
    while (Date.now() < deadline) {
      if (warm.exitCode !== null) throw new Error(`warm preview make up exited ${warm.exitCode}: ${fs.readFileSync(logPath, "utf8")}`);
      try {
        const response = await fetch(process.env.ACCRUE_HOST_PREVIEW_BASE_URL);
        if (response.ok) { ready = true; break; }
      } catch {}
      const launchOutput = fs.readFileSync(logPath, "utf8");
      if (launchOutput.includes(`http://${previewProject}.localhost/admin`)) { bannerPrinted = true; break; }
      await new Promise((resolve) => setTimeout(resolve, 750));
    }
    if (!ready) throw new Error(`warm preview did not become ready within 180s: ${fs.readFileSync(logPath, "utf8")}`);
    while (!bannerPrinted && Date.now() < deadline) {
      if (warm.exitCode !== null) throw new Error(`warm preview make up exited ${warm.exitCode}: ${fs.readFileSync(logPath, "utf8")}`);
      bannerPrinted = fs.readFileSync(logPath, "utf8").includes(`http://${previewProject}.localhost/admin`);
      if (!bannerPrinted) await new Promise((resolve) => setTimeout(resolve, 500));
    }
    if (!bannerPrinted) throw new Error(`warm preview did not print its stable URL: ${fs.readFileSync(logPath, "utf8")}`);
  } finally {
    try { process.kill(-warm.pid, "SIGTERM"); } catch {}
    await new Promise((resolve) => {
      if (warm.exitCode !== null || warm.signalCode !== null) return resolve();
      const timeout = setTimeout(resolve, 3_000);
      warm.once("exit", () => { clearTimeout(timeout); resolve(); });
    });
    fs.closeSync(logFd);
  }

  const launchOutput = fs.readFileSync(logPath, "utf8");
  expect(launchOutput).toContain(`http://${previewProject}.localhost/admin`);
  const containerLogs = execFileSync("docker", compose("logs", "--since=5m", "web"), { cwd: hostRoot, encoding: "utf8" });
  expect(containerLogs).toContain("seeds skipped (ACCRUE_HOST_SKIP_SEEDS=1)");
  capturePreviewSnapshot("assert-preserved", snapshotPath);
  fs.rmSync(logPath, { force: true });
}

test("fresh Fake preview authenticates and retains seeded Admin evidence after warm recovery", async ({ page }) => {
  test.setTimeout(180_000);
  test.skip(!process.env.ACCRUE_HOST_PREVIEW_BASE_URL, "requires the explicitly selected disposable preview instance");
  if (!operatorPassword) throw new Error("ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD is required; password values are never attached to test output");

  const processor = execFileSync("docker", compose("exec", "-T", "web", "mix", "run", "--no-start", "-e", "IO.write(inspect(Application.fetch_env!(:accrue, :processor)))"), { cwd: hostRoot, encoding: "utf8" }).trim();
  expect(processor).toBe("Accrue.Processor.Fake");

  await page.goto("/users/log-in");
  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");
  expect(csrfToken).toBeTruthy();
  const response = await page.request.post("/users/log-in", {
    form: { _csrf_token: csrfToken, "user[email]": operatorEmail, "user[password]": operatorPassword }
  });
  expect(response.ok(), `operator sign in returned ${response.status()}`).toBeTruthy();

  await page.goto("/admin");
  await expect(page).toHaveURL(/\/admin$/);
  await expect(page.locator("body")).toContainText(/billing|invoice|event/i);
  await page.goto("/admin/invoices?view=all");
  await expect(page.locator("body")).toContainText("DEMO-PAID-0003");
  const invoiceId = execFileSync("docker", compose("exec", "-T", "db", "psql", "-U", "postgres", "-d", "accrue_host_dev", "-Atc", "SELECT id FROM billing.accrue_invoices WHERE processor = 'fake' AND processor_id = 'in_showcase_paid_usd'"), { cwd: hostRoot, encoding: "utf8" }).trim();
  expect(invoiceId).toMatch(/^[0-9a-f-]{36}$/i);
  const snapshotPath = path.join(os.tmpdir(), `accrue-host-phase243-${process.pid}.snapshot.json`);
  capturePreviewSnapshot("snapshot", snapshotPath);

  await page.goto(`/admin/invoices/${invoiceId}`);
  await expect(page.getByText(/invoice detail/i).first()).toBeVisible();
  await page.goto("/admin/events?q=invoice.paid");
  await expect(page.getByRole("heading", { name: "Trace billing activity" })).toBeVisible();

  await warmRecoverAndWait(snapshotPath);
  fs.rmSync(snapshotPath, { force: true });
  await page.goto("/admin/invoices?view=all");
  await expect(page.locator("body")).toContainText("DEMO-PAID-0003");
  await page.goto(`/admin/invoices/${invoiceId}`);
  await expect(page.getByText(/invoice detail/i).first()).toBeVisible();
  await page.goto("/admin/events?q=invoice.paid");
  await page.reload();
  await expect(page.getByRole("heading", { name: "Trace billing activity" })).toBeVisible();
});
