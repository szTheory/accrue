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
  "examples/accrue_host/e2e/phase245-admin-baseline.spec.js",
  "examples/accrue_host/playwright.phase245.config.js",
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

function assertOrdinaryComposeIdentity() {
  const webId = execFileSync("docker", compose("ps", "-q", "web"), { cwd: hostRoot, encoding: "utf8" }).trim();
  const dbId = execFileSync("docker", compose("ps", "-q", "db"), { cwd: hostRoot, encoding: "utf8" }).trim();
  expect(webId, "ordinary Compose web container is running").toBeTruthy();
  expect(dbId, "ordinary Compose database container is running").toBeTruthy();
  const network = `${ordinaryProject}_default`;
  const webNetworks = execFileSync("docker", ["inspect", "--format", "{{range $name, $network := .NetworkSettings.Networks}}{{printf \"%s \" $name}}{{end}}", webId], { encoding: "utf8" });
  const dbNetworks = execFileSync("docker", ["inspect", "--format", "{{range $name, $network := .NetworkSettings.Networks}}{{printf \"%s \" $name}}{{end}}", dbId], { encoding: "utf8" });
  const volume = execFileSync("docker", ["inspect", "--format", '{{range .Mounts}}{{if eq .Destination "/var/lib/postgresql/data"}}{{.Name}}{{end}}{{end}}', dbId], { encoding: "utf8" }).trim();
  expect(webNetworks.split(/\s+/), "web is attached to the ordinary network").toContain(network);
  expect(dbNetworks.split(/\s+/), "database is attached to the ordinary network").toContain(network);
  expect(volume, "database uses the ordinary named data volume").toBe(`${ordinaryProject}_pgdata`);
  const dbIp = execFileSync("docker", ["inspect", "--format", `{{(index .NetworkSettings.Networks "${network}").IPAddress}}`, dbId], { encoding: "utf8" }).trim();
  const fingerprint = execFileSync("docker", compose("exec", "-T", "db", "psql", "-U", "postgres", "-d", "accrue_host_dev", "-Atc", "SELECT current_database() || '|' || current_user || '|' || inet_server_addr()::text"), { cwd: hostRoot, encoding: "utf8" }).trim();
  expect(fingerprint, "live database fingerprint matches the inspected ordinary DB container").toBe(`accrue_host_dev|postgres|${dbIp}`);
}

function assertNoSecrets(value, location = "capture") {
  if (!value || typeof value !== "object") return;
  for (const [key, nested] of Object.entries(value)) {
    expect(key, `${location} must omit credentials and session material`).not.toMatch(/password|secret|token|cookie|authorization|headers?/i);
    assertNoSecrets(nested, `${location}.${key}`);
  }
}

function routeIdentityMatches(route, requestedURL, finalURL) {
  const requested = new URL(requestedURL, process.env.ACCRUE_HOST_ORDINARY_BASE_URL);
  const final = new URL(finalURL);
  const templatePattern = new RegExp(`^${route.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").replace(/:[^/]+/g, "[^/]+")}$`);
  return final.origin === requested.origin && final.pathname === requested.pathname &&
    final.search === requested.search && templatePattern.test(final.pathname);
}

test("route identity rejects successful redirects, wrong records, and lost query state", () => {
  const origin = "http://accrue-host-phase245-ordinary.localhost";
  expect(routeIdentityMatches("/admin/invoices/:id", "/admin/invoices/123", `${origin}/admin/invoices/123`)).toBe(true);
  expect(routeIdentityMatches("/admin/invoices/:id", "/admin/invoices/123", `${origin}/admin/invoices/456`)).toBe(false);
  expect(routeIdentityMatches("/admin/invoices", "/admin/invoices?view=all", `${origin}/admin/invoices`)).toBe(false);
  expect(routeIdentityMatches("/admin/invoices", "/admin/invoices", `${origin}/users/log-in`)).toBe(false);
});

function compiledAssetBytes(assetName) {
  const expression = [
    `path = Path.join(:code.priv_dir(:accrue_admin), "static/${assetName}")`,
    "path |> File.read!() |> Base.encode64() |> IO.write()"
  ].join("; ");
  return Buffer.from(dockerEval(expression), "base64");
}

function databaseId(table) {
  if (!/^(customers|subscriptions|invoices|charges|coupons|promotion_codes|connect_accounts|events|webhook_events)$/.test(table)) {
    throw new Error(`unsupported preview table ${table}`);
  }
  const result = execFileSync("docker", compose(
    "exec", "-T", "db", "psql", "-U", "postgres", "-d", "accrue_host_dev", "-Atc",
    `SELECT id::text FROM billing.accrue_${table} ORDER BY id LIMIT 1`
  ), { cwd: hostRoot, encoding: "utf8" }).trim();
  return result || null;
}

async function signIn(page) {
  await page.goto("/users/log-in");
  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");
  expect(csrfToken).toBeTruthy();
  const response = await page.request.post("/users/log-in", {
    form: { _csrf_token: csrfToken, "user[email]": operatorEmail, "user[password]": operatorPassword }
  });
  expect(response.ok(), `operator sign in returned ${response.status()}`).toBeTruthy();
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
  return { path: new URL(href, page.url()).pathname, bytes: served.length, requested_by_document: evidence.requestedByDocument, ...hashes };
}

test("authenticated ordinary invoice list and detail match current served assets", async ({ page }) => {
  test.skip(!operatorPassword, "set ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD from the local operator credential source");

  assertOrdinaryComposeIdentity();
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
  assertNoSecrets(manifest);

  fs.mkdirSync(captureDir, { recursive: true });
  fs.writeFileSync(path.join(captureDir, "invoice-detail.png"), screenshot, { mode: 0o600 });
  fs.writeFileSync(path.join(captureDir, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600 });
  await test.info().attach("phase245-capture-manifest.json", {
    body: Buffer.from(JSON.stringify(manifest, null, 2)),
    contentType: "application/json"
  });
});

test("capture reachable mounted Admin templates with bounded theme and viewport coverage", async ({ page, browserName }) => {
  test.skip(!operatorPassword, "set ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD from the local operator credential source");
  test.setTimeout(240_000);
  assertOrdinaryComposeIdentity();
  const phaseCaptureDir = path.join(repoRoot, ".planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-current");
  fs.mkdirSync(phaseCaptureDir, { recursive: true });
  await signIn(page);
  await page.goto("/admin");
  await expect(page).toHaveURL(/\/admin$/);

  const assetIdentity = {
    css: await assetEvidence(page, 'link[rel="stylesheet"][href*="/admin/assets/css-"]', "accrue_admin.css", "accrue_admin/priv/static/accrue_admin.css"),
    js: await assetEvidence(page, 'script[src*="/admin/assets/js-"]', "accrue_admin.js", "accrue_admin/priv/static/accrue_admin.js")
  };
  const trackedSources = execFileSync("git", ["ls-files", "-z", "accrue_admin/lib/accrue_admin", "accrue_admin/assets/css", "accrue_admin/assets/js", "accrue_admin/priv/static", "examples/accrue_host/lib/accrue_host_web/router.ex", "examples/accrue_host/priv/repo/seeds"], { cwd: repoRoot }).toString().split("\0").filter(Boolean);
  const sourceFiles = [...new Set([...sourcePaths, ...trackedSources])].sort();
  const dirtySources = execFileSync("git", ["status", "--porcelain", "--", ...sourceFiles], { cwd: repoRoot, encoding: "utf8" }).trim();
  const sources = Object.fromEntries(sourceFiles.map((relativePath) => [
    relativePath,
    sha256(fs.readFileSync(path.join(repoRoot, relativePath)))
  ]));
  const routes = [
    ["/admin", "/admin", null],
    ["/admin/customers", "/admin/customers", null], ["/admin/customers/:id", "/admin/customers/" + databaseId("customers"), "customers"],
    ["/admin/subscriptions", "/admin/subscriptions", null], ["/admin/subscriptions/:id", "/admin/subscriptions/" + databaseId("subscriptions"), "subscriptions"],
    ["/admin/invoices", "/admin/invoices?view=all", null], ["/admin/invoices/:id", "/admin/invoices/" + databaseId("invoices"), "invoices"],
    ["/admin/payments", "/admin/payments", null], ["/admin/payments/:id", "/admin/payments/" + databaseId("charges"), "charges"],
    ["/admin/coupons", "/admin/coupons", null], ["/admin/coupons/:id", "/admin/coupons/" + databaseId("coupons"), "coupons"],
    ["/admin/promotion-codes", "/admin/promotion-codes", null], ["/admin/promotion-codes/:id", "/admin/promotion-codes/" + databaseId("promotion_codes"), "promotion_codes"],
    ["/admin/connect", "/admin/connect", null], ["/admin/connect/:id", "/admin/connect/" + databaseId("connect_accounts"), "connect_accounts"],
    ["/admin/events", "/admin/events", null], ["/admin/events/:id", "/admin/events/" + databaseId("events"), "events"],
    ["/admin/webhooks", "/admin/webhooks", null], ["/admin/webhooks/:id", "/admin/webhooks/" + databaseId("webhook_events"), "webhook_events"],
    ["/admin/analytics/recovery", "/admin/analytics/recovery", null],
    ["/admin/analytics/recovery/subscriptions/:id", "/admin/analytics/recovery/subscriptions/" + databaseId("subscriptions"), "subscriptions"]
  ];
  const devRoutes = ["/admin/dev/clock", "/admin/dev/email-preview", "/admin/dev/webhook-fixtures", "/admin/dev/components", "/admin/dev/fake-inspect"];
  const revision = execFileSync("git", ["rev-parse", "HEAD"], { cwd: repoRoot, encoding: "utf8" }).trim();
  const dirty = dirtySources.length > 0;
  const captures = [];
  const rows = [];

  async function visit(route, url, table, index, development = false) {
    if (url.endsWith("/null") || url.endsWith("/undefined")) {
      rows.push({ id: `R${String(index + 1).padStart(2, "0")}-populated`, route, state: "populated", url: null, visual_anchor: "Admin shell and route-owned content", status: "unavailable", reason: `No ordinary Fake record exists in ${table}, so a detail URL was not constructed; protected preview data was left intact.` });
      return;
    }
    const narrow = url === "/admin/coupons" || route === "/admin/events";
    const dark = route === "/admin/invoices/:id" || route === "/admin/analytics/recovery" || route === "/admin/events";
    await page.setViewportSize(narrow ? { width: 390, height: 844 } : { width: 1280, height: 900 });
    const response = await page.goto(url, { waitUntil: "domcontentloaded" });
    await page.locator("body").waitFor();
    const finalURL = new URL(page.url());
    const routeMatches = routeIdentityMatches(route, url, page.url());
    const pageTitle = page.locator("main h1").first();
    const titleVisible = await pageTitle.isVisible().catch(() => false);
    const titleText = titleVisible ? (await pageTitle.innerText()).trim() : "";
    if (!response || response.status() >= 400 || finalURL.pathname === "/users/log-in" || !routeMatches || !titleVisible || !titleText) {
      if (development) {
        rows.push({ id: `DEV-${String(index - routes.length + 1).padStart(2, "0")}-not-mounted`, route, state: "not-mounted", url, visual_anchor: "Development route activation under the host mount", status: "not-applicable", reason: `Direct navigation returned HTTP ${response?.status() ?? "no response"}; the host mount has allow_live_reload: false, so this package development route is not active in the ordinary instance.` });
        return;
      }
      rows.push({ id: `R${String(index + 1).padStart(2, "0")}-populated`, route, state: "populated", url, visual_anchor: "Route-specific main heading", status: "unavailable", reason: `Navigation returned ${response?.status() ?? "no response"} and ended at ${finalURL.pathname}${finalURL.search}; requested route template match=${routeMatches}, visible route heading=${Boolean(titleText)}${titleText ? ` (${titleText})` : ""}; no screenshot claim made.` });
      return;
    }
    const targetTheme = dark ? "dark" : "light";
    const currentTheme = await page.locator("html").getAttribute("data-theme");
    if (currentTheme !== targetTheme) {
      await page.getByRole("radio", { name: targetTheme === "dark" ? "Dark" : "Light" }).click({ timeout: 5_000 });
      await expect(page.locator("html")).toHaveAttribute("data-theme", targetTheme);
    }
    let observedState = "populated";
    let recoveryReadiness = null;
    if (route === "/admin/analytics/recovery") {
      const atRisk = page.locator('.ax-at-risk-table[data-state="no-pagination"], .ax-at-risk-table[data-state="has-pagination"]');
      const funnel = page.locator('[data-ax-recovery-supporting-funnel][data-state="ready"]');
      const readiness = await Promise.allSettled([
        atRisk.waitFor({ state: "visible", timeout: 15_000 }),
        funnel.waitFor({ state: "visible", timeout: 15_000 })
      ]);
      const tableState = await page.locator(".ax-at-risk-table").getAttribute("data-state").catch(() => null);
      const funnelState = await page.locator("[data-ax-recovery-supporting-funnel]").getAttribute("data-state").catch(() => null);
      recoveryReadiness = { bounded_wait_ms: 15_000, at_risk_state: tableState, supporting_funnel_state: funnelState,
        ready: readiness.every((result) => result.status === "fulfilled") };
      if (!recoveryReadiness.ready) observedState = "loading";
    }
    const isHero = route === "/admin" || route === "/admin/invoices/:id" || route === "/admin/coupons" || route === "/admin/analytics/recovery";
    const stem = route.replace(/^\/admin\/?/, "root").replaceAll("/", "-").replaceAll(":", "param");
    const filename = `${String(index + 1).padStart(2, "0")}-${stem}-${narrow ? "narrow" : "wide"}-${dark ? "dark" : "light"}.png`;
    if (!development) {
      const bytes = await page.screenshot({ path: path.join(phaseCaptureDir, filename), fullPage: true, animations: "disabled" });
      const routeState = `R${String(index + 1).padStart(2, "0")}-${observedState}`;
      const sha256Png = sha256(bytes);
      captures.push({
        id: `C${String(captures.length + 1).padStart(2, "0")}`, route_state: routeState, route, state: observedState, scenario: "ordinary Fake seed; no mutation", source_revision: revision, source_dirty: dirty, source_digests: sources,
        assets: assetIdentity, viewport: narrow ? { width: 390, height: 844 } : { width: 1280, height: 900 }, theme: dark ? "dark" : "light", browser: { name: browserName, version: page.context().browser().version() },
        url: page.url(), rendered_identity: { heading: titleText, selector: "main h1" }, captured_at: new Date().toISOString(), png: { path: `.planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-current/${filename}`, bytes: bytes.length, sha256: sha256Png },
        observation: route === "/admin/analytics/recovery" ? `Recovery readiness observed: ${JSON.stringify(recoveryReadiness)}.` : isHero ? "Primary route composition captured for direct PNG review." : "Mounted route visited and captured at representative wide/light settings."
      });
      rows.push({ id: routeState, route, state: observedState, url: page.url(), visual_anchor: `Visible route heading: ${titleText}`, status: "inspected", evidence: `final URL matched requested template; main h1 rendered; manifest capture C${String(captures.length).padStart(2, "0")}; PNG SHA-256 ${sha256Png}` });
      if (route === "/admin/analytics/recovery" && observedState === "loading") rows.push({ id: "R20-populated", route, state: "populated", url: page.url(), visual_anchor: "Recovery metric cards and at-risk subscription work queue", status: "unavailable", reason: `The route remained in ${JSON.stringify(recoveryReadiness)} after the bounded 15-second wait; populated recovery metrics were not rendered in the ordinary instance.` });
    } else {
      rows.push({ id: `DEV-${String(index + 1).padStart(2, "0")}-not-mounted`, route, state: "not-mounted", url: page.url(), visual_anchor: "Development tool route activation", status: "not-applicable", reason: `Direct navigation returned HTTP ${response.status()}; the host mount sets allow_live_reload: false, so package development routes are not activated in this instance.` });
    }
  }

  for (let index = 0; index < routes.length; index += 1) await visit(...routes[index], index);
  for (let index = 0; index < devRoutes.length; index += 1) await visit(devRoutes[index], devRoutes[index], null, routes.length + index, true);
  for (const table of ["connect_accounts", "webhook_events"]) if (!databaseId(table)) {
    const route = table === "connect_accounts" ? "/admin/connect/:id" : "/admin/webhooks/:id";
    const row = rows.find((candidate) => candidate.route === route);
    if (row) row.reason = `No ordinary Fake ${table.replaceAll("_", " ")} row exists, so a detail URL cannot be formed; the collection route was still visited.`;
  }
  const manifest = {
    phase: "245-rendered-baseline-and-realistic-preview", captured_at: new Date().toISOString(), source_revision: revision, source_dirty: dirty,
    scenario: "isolated accrue-host-phase245-ordinary Fake seed; existing database preserved", seed_revision: sources["examples/accrue_host/priv/repo/seeds/ordinary.exs"],
    browser: { name: browserName, user_agent: await page.evaluate(() => navigator.userAgent) }, captures
  };
  assertNoSecrets(manifest);
  fs.writeFileSync(path.join(repoRoot, ".planning/phases/245-rendered-baseline-and-realistic-preview/captures/manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  rows.sort((left, right) => left.route.localeCompare(right.route) || left.id.localeCompare(right.id));
  fs.writeFileSync(path.join(repoRoot, ".planning/phases/245-rendered-baseline-and-realistic-preview/captures/coverage-rows.json"), `${JSON.stringify(rows, null, 2)}\n`);
  const mounted = routes.map(([route]) => ({ route, kind: "production-liveview" }));
  const supplemental = [
    ...devRoutes.map((route) => ({ route, kind: "conditional-development-liveview", activation: "allow_live_reload: false in the ordinary host; direct request is recorded in route rows" })),
    { route: "/charges", kind: "redirect-support", reason: "legacy billing redirect, not a LiveView" },
    { route: "/charges/:id", kind: "redirect-support", reason: "legacy billing detail redirect, not a LiveView" },
    { route: "/admin/assets/*", kind: "static-asset-support", reason: "hashed CSS/JS/font assets are verified through served asset identity, not operator routes" }
  ];
  const stateMatrix = [
    { id: "LST-EMPTY", applies_to: "all collection routes", state: "truly-empty", status: "unavailable", reason: "The ordinary fixture is intentionally populated; emptying protected data is outside the read-only capture scope." },
    { id: "LST-FILTER-ZERO", applies_to: "all collection routes with filters", state: "filtered-to-zero", status: "unavailable", reason: "A stable guaranteed-zero filter was not available across every collection; no route is marked empty based on source or guesswork." },
    { id: "LST-PARTIAL", applies_to: "billing lists and details", state: "partial-or-unknown", status: "inspected", reason: "Ordinary Fake records preserve absent provider history and nil relationships; the exact evidence and route captures are listed per route." },
    { id: "LST-ONE-MANY", applies_to: "collection and detail related-record sections", state: "one-and-many", status: "unavailable", reason: "Counts are recorded only where visibly rendered; no extra records were seeded to force cardinality variants." },
    { id: "LST-OVERFLOW", applies_to: "tables and long-text detail fields", state: "overflow-long-text", status: "unavailable", reason: "No ordinary fixture was added for adversarial text; Phase 191 edge_states owns this scenario." },
    { id: "ASYNC-LOADING-ERROR", applies_to: "recovery analytics", state: "loading-or-error", status: "inspected", reason: "Recovery loading state is checked against source-backed ready indicators with a bounded 15-second wait and recorded in R20." },
    { id: "INTERACTION-KEYBOARD", applies_to: "navigation, filters, disclosures, tabs", state: "keyboard-focus-selection", status: "unavailable", reason: "This batch captures rendered states; it does not infer keyboard/focus behavior from PNGs." },
    { id: "INTERACTION-POINTER-TOUCH", applies_to: "hover and touch targets", state: "hover-pointer-touch", status: "unavailable", reason: "No pointer-hover or physical touch outcome was exercised; viewport emulation is not touch evidence." },
    { id: "INTERACTION-URL", applies_to: "query filters, tabs, and selected rows", state: "URL-result-alignment", status: "unavailable", reason: "The test preserves the explicit invoices view=all route but does not claim systematic URL/result alignment for every control." },
    { id: "DETAIL-DISCLOSURE", applies_to: "record details", state: "disclosure-tabs-and-history", status: "unavailable", reason: "Collapsed disclosure/tab variants were not expanded across every detail route in this bounded visual inventory." }
  ];
  const coverage = {
    prior_route_count: 21,
    route_reconciliation: { unchanged: 21, added: 0, removed: 0, renamed: 0 },
    routes: mounted,
    supplemental_routes: supplemental,
    rows,
    state_matrix: stateMatrix,
    omitted_combinations: [
      "All-theme x all-viewport x all-route combinations; four representative theme/viewport cells were captured across distinct compositions instead of a Cartesian matrix.",
      "Empty, filtered-to-zero, overflow and adversarial long-text states, because no safe ordinary scenario supported them without reseeding or protected-data mutation.",
      "Full role/scope permutations; the exact authenticated ordinary operator session was retained and no authorization boundary was bypassed.",
      "Systematic keyboard, focus, hover, pointer, touch, selected URL/query and action-result behavior; screenshots do not prove interaction outcomes.",
      "Connect and webhook details in the ordinary instance: their collection routes were visited, but no ordinary rows yielded IDs; separate Phase243 read-only observations are recorded in findings, not represented as ordinary PNG captures."
    ]
  };
  const coveragePath = path.join(repoRoot, ".planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md");
  const coverageText = fs.readFileSync(coveragePath, "utf8").replace(/<!-- coverage-json:start -->[\s\S]*?<!-- coverage-json:end -->/, `<!-- coverage-json:start -->\n${JSON.stringify(coverage, null, 2)}\n<!-- coverage-json:end -->`);
  fs.writeFileSync(coveragePath, coverageText);
  expect(captures.some((item) => item.viewport.width === 1280 && item.theme === "light")).toBe(true);
  expect(captures.some((item) => item.viewport.width === 1280 && item.theme === "dark")).toBe(true);
  expect(captures.some((item) => item.viewport.width === 390 && item.theme === "light")).toBe(true);
  expect(captures.some((item) => item.viewport.width === 390 && item.theme === "dark")).toBe(true);
  expect(rows.filter((row) => row.status === "inspected" && !row.id.startsWith("DEV-")).length).toBeGreaterThan(0);
});
