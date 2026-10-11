// @ts-check
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { test, expect } = require("@playwright/test");

const ordinaryProject = "accrue-host-phase245-ordinary";
const operatorEmail = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com";
const operatorPassword = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;
const repoRoot = path.resolve(__dirname, "../../..");
const hostRoot = path.join(repoRoot, "examples/accrue_host");
const captureDir = process.env.PHASE245_CAPTURE_DIR || path.join(
  repoRoot,
  ".planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-tracer"
);
const compose = (...args) => [
  "compose", "-p", ordinaryProject, "-f", path.join(hostRoot, "docker-compose.yml"), ...args
];
const sourcePaths = [
  "accrue_admin/lib/accrue_admin/live/invoices_live.ex",
  "accrue_admin/lib/accrue_admin/live/invoice_live.ex",
  "accrue_admin/lib/accrue_admin/router.ex",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/assets/js/app.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/accrue_admin.js",
  "examples/accrue_host/lib/accrue_host_web/router.ex",
  "examples/accrue_host/priv/repo/seeds/helpers.exs",
  "examples/accrue_host/priv/repo/seeds/ordinary.exs",
  "examples/accrue_host/priv/repo/seeds/hero_accounts.exs",
  "examples/accrue_host/priv/repo/seeds/background_data.exs",
  "examples/accrue_host/priv/repo/seeds/showcase.exs"
];

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function dockerEval(expression) {
  return execFileSync("docker", compose(
    "exec", "-T", "web", "mix", "run", "--no-start", "-e", expression
  ), { cwd: hostRoot, encoding: "utf8" }).trim();
}

function compiledAssetBytes(assetName) {
  const expression = [
    `path = Path.join(:code.priv_dir(:accrue_admin), "static/${assetName}")`,
    "path |> File.read!() |> Base.encode64() |> IO.write()"
  ].join("; ");
  return Buffer.from(dockerEval(expression), "base64");
}

async function assetEvidence(page, selector, assetName, packagePath) {
  const attribute = selector.startsWith("script") ? "src" : "href";
  const href = await page.locator(selector).getAttribute(attribute);
  expect(href, `${assetName} URL should be present`).toBeTruthy();
  const evidence = await page.evaluate(async (assetURL) => {
    const response = await fetch(assetURL, { cache: "no-store" });
    const bytes = Array.from(new Uint8Array(await response.arrayBuffer()));
    const pathname = new URL(assetURL, location.href).pathname;
    return {
      status: response.status,
      bytes,
      requestedByDocument: performance.getEntriesByType("resource")
        .some((entry) => new URL(entry.name).pathname === pathname)
    };
  }, href);
  const served = Buffer.from(evidence.bytes);
  const packageBytes = fs.readFileSync(path.join(repoRoot, packagePath));
  const compiledBytes = compiledAssetBytes(assetName);
  const hashes = {
    package: sha256(packageBytes),
    compiled: sha256(compiledBytes),
    served: sha256(served)
  };

  expect(evidence.status, `${assetName} HTTP status`).toBe(200);
  expect(evidence.requestedByDocument, `${assetName} was requested by the page`).toBe(true);
  expect(hashes.compiled, `${assetName} compiled bytes match package bytes`).toBe(hashes.package);
  expect(hashes.served, `${assetName} served bytes match package bytes`).toBe(hashes.package);
  return { path: new URL(href, page.url()).pathname, bytes: served.length, ...hashes };
}

test("authenticated ordinary invoice list and detail match current served assets", async ({ page }) => {
  test.skip(!operatorPassword, "set ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD from the local operator credential source");

  const processor = dockerEval("IO.write(inspect(Application.fetch_env!(:accrue, :processor)))");
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

  await page.goto("/admin/invoices?view=all");
  await expect(page).toHaveURL(/\/admin\/invoices\?view=all$/);
  await expect(page.getByRole("link", { name: "PORTAL-LAUNCH-001", exact: true })).toBeVisible();

  const invoiceId = execFileSync("docker", compose(
    "exec", "-T", "db", "psql", "-U", "postgres", "-d", "accrue_host_dev", "-Atc",
    "SELECT id FROM billing.accrue_invoices WHERE processor = 'fake' AND processor_id = 'in_seed_healthy_portal_launch_paid'"
  ), { cwd: hostRoot, encoding: "utf8" }).trim();
  expect(invoiceId).toMatch(/^[0-9a-f-]{36}$/i);
  const assets = {
    css: await assetEvidence(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin.css", "accrue_admin/priv/static/accrue_admin.css"),
    js: await assetEvidence(page, 'script[src*="/admin/assets/js-"]', "accrue_admin.js", "accrue_admin/priv/static/accrue_admin.js")
  };

  await page.goto(`/admin/invoices/${invoiceId}`);
  await expect(page.getByText(/invoice detail/i).first()).toBeVisible();
  await expect(page.getByRole("heading", { name: "PORTAL-LAUNCH-001", exact: true })).toBeVisible();
  const screenshot = await page.screenshot({ fullPage: true, animations: "disabled" });
  const sources = Object.fromEntries(sourcePaths.map((relativePath) => [
    relativePath,
    sha256(fs.readFileSync(path.join(repoRoot, relativePath)))
  ]));
  const manifest = {
    phase: "245-rendered-baseline-and-realistic-preview",
    capture: "authenticated invoice detail rendered from the isolated ordinary Fake preview",
    captured_at: new Date().toISOString(),
    source_revision: execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim(),
    source_digests: sources,
    scenario: "ordinary paid USD invoice linked to the healthy demo customer's active subscription",
    route: `/admin/invoices/${invoiceId}`,
    state: "populated invoice detail",
    invoice_identity: {
      processor: "fake",
      processor_id: "in_seed_healthy_portal_launch_paid",
      invoice_number: "PORTAL-LAUNCH-001",
      database_id: invoiceId
    },
    browser: { name: "chromium", version: page.context().browser()?.version() },
    viewport: { width: 1280, height: 900 },
    theme: "light",
    assets,
    screenshot: { file: "invoice-detail.png", bytes: screenshot.length, sha256: sha256(screenshot) }
  };

  fs.mkdirSync(captureDir, { recursive: true });
  fs.writeFileSync(path.join(captureDir, "invoice-detail.png"), screenshot, { mode: 0o600 });
  fs.writeFileSync(path.join(captureDir, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600 });
  await test.info().attach("phase245-capture-manifest.json", {
    body: Buffer.from(JSON.stringify(manifest, null, 2)),
    contentType: "application/json"
  });
});
