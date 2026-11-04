// Phase 254 CIQ-03 (D-15..D-20, D-33): deterministic subscription visual baselines in the existing
// visual-desktop owner. Story cases capture the .psb-sandbox element of the DB-free Cadence story
// routes; mounted cases capture one element of the seeded production page (the review drawer and an open
// disclosure with its summary focused).
//
// The case list is the tracked accrue_admin/storybook/phase254-visual-cases.json, which only
// scripts/ci/phase254_selection.mjs project writes and drift-checks against the compiled manifests. Each
// test title is its case key. Before any pixel is compared the case proves its own determinism (timezone,
// locale, reduced motion, a fixed clock, loaded Geist faces served byte-identically, no running
// animation, a light/dark surface-token difference) and the identity, money, state and action facts.
// New cases carry an empty mask allowlist and maxDiffPixels 0 in the call; thresholds stay in the config.
//
// Baselines are Linux-only: never run this with --update-snapshots outside the workflow_dispatch mint job.

const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { test, expect } = require("@playwright/test");
const { reset, seed, login, hideCaptureOnlyChrome } = require("./support/admin-visual-helpers");
const { snapshotFileName } = require("./visual-baseline-set.cjs");

const ADMIN_ROOT = path.resolve(__dirname, "..");
const REPO_ROOT = path.resolve(ADMIN_ROOT, "..");
const CASES_FILE = JSON.parse(fs.readFileSync(path.join(ADMIN_ROOT, "storybook", "phase254-visual-cases.json"), "utf8"));
const IDENTITY_DIR = path.join(ADMIN_ROOT, "tmp", "phase254", "visual-identity");
const FIXED_CLOCK = CASES_FILE.determinism.fixed_clock;
const TIME_DISPLAY_KEY = "accrue_admin_time_display";
const PLAYWRIGHT_VERSION = require("@playwright/test/package.json").version;

const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const readStatic = (relative) => fs.readFileSync(path.join(ADMIN_ROOT, "priv", "static", relative));

test.use({ timezoneId: CASES_FILE.determinism.timezone, locale: CASES_FILE.determinism.locale, reducedMotion: CASES_FILE.determinism.reduced_motion });

// --- determinism ---------------------------------------------------------------------------------------

async function prepare(page, { width, theme }) {
  recordFontResponses(page);
  await page.setViewportSize({ width, height: 900 });
  await page.emulateMedia({ colorScheme: theme, reducedMotion: "reduce" });
  // Before navigation: a fixed clock and a cleared time-display preference.
  await page.clock.setFixedTime(FIXED_CLOCK);
  await page.addInitScript((key) => {
    try { window.localStorage.removeItem(key); } catch { /* storage unavailable: nothing to clear */ }
  }, TIME_DISPLAY_KEY);
}

async function waitForLiveSocket(page) {
  await page.waitForFunction(() => Boolean(window.liveSocket && window.liveSocket.isConnected()), null, { timeout: 15_000 });
}

// Time elements are rewritten by the TimeDisplay hook after the socket connects; wait until every one of
// them shows the fixed-zone en-US text so no capture can see the server-rendered intermediate form.
async function waitForTimeDisplay(page) {
  await page.waitForFunction(() => {
    const format = (iso, dateOnly) => new Intl.DateTimeFormat("en-US", {
      year: "numeric", month: "short", day: "2-digit",
      ...(dateOnly ? {} : { hour: "2-digit", minute: "2-digit", second: "2-digit", timeZoneName: "short" }),
      timeZone: "UTC",
    }).format(new Date(iso));
    return [...document.querySelectorAll("[data-time-display]")].every((element) => {
      const time = element.querySelector("time");
      return !time || time.textContent === format(element.dataset.iso, element.dataset.timeFormat === "date");
    });
  }, null, { timeout: 15_000 });
}

async function assertFonts(page) {
  const faces = await page.evaluate(async () => {
    await document.fonts.ready;
    return [...document.fonts].filter((face) => face.family.replaceAll('"', "") === "Geist" || face.family.replaceAll('"', "") === "Geist Mono")
      .map((face) => ({ family: face.family.replaceAll('"', ""), status: face.status }));
  });
  expect(faces.map((face) => face.family).sort(), "both Geist faces are declared").toEqual(["Geist", "Geist Mono"]);
  for (const face of faces) expect(face.status, `${face.family} FontFace status`).toBe("loaded");
  return faces;
}

async function assertNoAnimations(page) {
  await expect.poll(() => page.evaluate(() => document.getAnimations().length), { message: "no animation is running" }).toBe(0);
}

function assertThemeTokensDiffer(light, dark) {
  if (!light || !dark || light === dark) {
    throw new Error(`the light and dark surface tokens resolve the same value (${JSON.stringify({ light, dark })})`);
  }
}

// The surface token the theme drives, read in both themes from the same element. Story pages switch the
// theme with the sandbox dark-shim class, mounted pages with the document data-theme attribute.
async function readSurfaceTokens(page, mode) {
  return page.evaluate((selected) => {
    const story = selected === "story";
    const host = story ? document.querySelector(".psb-sandbox") : document.documentElement;
    const read = () => getComputedStyle(host).getPropertyValue("--ax-base").trim().toLowerCase();
    const isDark = story ? host.classList.contains("ax-theme-dark-shim") : host.dataset.theme === "dark";
    const apply = (dark) => {
      if (story) host.classList.toggle("ax-theme-dark-shim", dark);
      else host.dataset.theme = dark ? "dark" : "light";
    };
    const current = read();
    apply(!isDark);
    const other = read();
    apply(isDark);
    return { current, other, restored: read() };
  }, mode);
}

async function applyStoryTheme(page, theme) {
  await page.locator(".psb-sandbox").first().evaluate((sandbox, selected) => {
    sandbox.classList.add("accrue-admin");
    sandbox.classList.toggle("ax-theme-dark-shim", selected === "dark");
  }, theme);
}

async function applyMountedTheme(page, theme) {
  await page.evaluate((selected) => {
    document.documentElement.dataset.theme = selected;
    document.documentElement.setAttribute("data-theme", selected);
  }, theme);
}

async function assertThemeApplied(page, mode, theme) {
  const tokens = await readSurfaceTokens(page, mode);
  const light = theme === "light" ? tokens.current : tokens.other;
  const dark = theme === "dark" ? tokens.current : tokens.other;
  assertThemeTokensDiffer(light, dark);
  expect(tokens.restored, "the probe restored the selected theme").toBe(tokens.current);
  return { light, dark };
}

// --- served asset identity -------------------------------------------------------------------------------

async function fetchSha(page, url) {
  const response = await page.request.get(new URL(url, page.url()).href);
  if (!response.ok()) throw new Error(`asset request failed (${response.status()}) for ${url}`);
  return { sha256: sha256(await response.body()), body: await response.body() };
}

// The font URLs the page really loaded, recorded from its responses (the story CSS and the admin CSS
// reference them from different mounts, so the spec never guesses a prefix).
const FONT_RESPONSES = new WeakMap();

function recordFontResponses(page) {
  const urls = new Set();
  FONT_RESPONSES.set(page, urls);
  page.on("response", (response) => {
    if (response.ok() && /geist-(?:sans|mono)-vf\.woff2$/.test(new URL(response.url()).pathname)) urls.add(response.url());
  });
}

async function loadedFontUrls(page) {
  const urls = [...(FONT_RESPONSES.get(page) ?? [])];
  const sans = urls.filter((url) => url.includes("geist-sans-vf.woff2"));
  const mono = urls.filter((url) => url.includes("geist-mono-vf.woff2"));
  if (sans.length !== 1 || mono.length !== 1) throw new Error(`expected exactly one loaded Geist sans and one Geist Mono woff2, saw ${JSON.stringify({ sans, mono })}`);
  return { sans: sans[0], mono: mono[0] };
}

async function verifyServedAssets(page, kind) {
  const links = await page.evaluate(() => {
    const stylesheets = [...document.querySelectorAll('link[rel="stylesheet"]')].map((link) => link.href);
    const imports = [...document.querySelectorAll("style")].flatMap((style) =>
      [...style.textContent.matchAll(/@import\s+(?:url\()?['"]([^'")]+)['"]/g)].map((match) => new URL(match[1], document.baseURI).href));
    return { stylesheets: [...stylesheets, ...imports], scripts: [...document.querySelectorAll("script[src]")].map((element) => element.src) };
  });
  const served = {};
  if (kind === "story") {
    const css = links.stylesheets.find((href) => href.includes("storybook-css-"));
    const js = links.scripts.find((href) => href.includes("storybook-js-"));
    if (!css || !js) throw new Error(`the story route did not load the compiled Storybook CSS and JS: ${JSON.stringify(links)}`);
    served.css_sha256 = (await fetchSha(page, css)).sha256;
    served.js_sha256 = (await fetchSha(page, js)).sha256;
    expect(served.css_sha256, "served storybook.css equals the committed file").toBe(sha256(readStatic("storybook.css")));
    expect(served.js_sha256, "served storybook.js equals the committed file").toBe(sha256(readStatic("storybook.js")));
    // D-33: a story route is only a stand-in for the production page while it embeds the production CSS.
    expect(readStatic("storybook.css").includes(readStatic("accrue_admin.css")), "storybook.css contains the exact accrue_admin.css bytes").toBe(true);
  } else {
    const css = links.stylesheets.find((href) => /\/assets\/css-[0-9a-f]{32}$/.test(href));
    const js = links.scripts.find((href) => /\/assets\/js-[0-9a-f]{32}$/.test(href));
    if (!css || !js) throw new Error(`the mounted page did not load the admin CSS and JS: ${JSON.stringify(links)}`);
    served.css_sha256 = (await fetchSha(page, css)).sha256;
    served.js_sha256 = (await fetchSha(page, js)).sha256;
    expect(served.css_sha256, "served accrue_admin.css equals the committed file").toBe(sha256(readStatic("accrue_admin.css")));
    expect(served.js_sha256, "served accrue_admin.js equals the committed file").toBe(sha256(readStatic("accrue_admin.js")));
  }
  const fontUrls = await loadedFontUrls(page);
  served.geist_sans_sha256 = (await fetchSha(page, fontUrls.sans)).sha256;
  served.geist_mono_sha256 = (await fetchSha(page, fontUrls.mono)).sha256;
  expect(served.geist_sans_sha256, "served Geist sans woff2 equals the committed font").toBe(sha256(readStatic("fonts/geist-sans-vf.woff2")));
  expect(served.geist_mono_sha256, "served Geist Mono woff2 equals the committed font").toBe(sha256(readStatic("fonts/geist-mono-vf.woff2")));
  return served;
}

// --- content assertions (identity, money, state, actions) -----------------------------------------------

// Responsive layouts render a table and cards side by side, so every lookup is filtered to the visible match.
function actionLocator(scope, action) {
  if (action.role) return scope.getByRole(action.role, { name: action.name, exact: true }).filter({ visible: true }).first();
  return scope.locator(action.selector).filter({ visible: true }).first();
}

function visibleText(scope, text, exact) {
  return scope.getByText(text, { exact }).filter({ visible: true }).first();
}

async function assertContent(scope, expected) {
  for (const text of expected.identity.texts) {
    await expect(visibleText(scope, text, false), `identity ${text} is visible`).toBeVisible();
  }
  await expect(visibleText(scope, expected.amount.text, false), `amount caveat "${expected.amount.text}" is visible`).toBeVisible();
  await expect(visibleText(scope, expected.status.text, true), `status ${expected.status.text} is visible`).toBeVisible();
  for (const text of expected.status.also) {
    await expect(visibleText(scope, text, false), `state fact ${text} is visible`).toBeVisible();
  }
  for (const action of expected.actions) {
    const locator = actionLocator(scope, action);
    await expect(locator, `action ${action.name || action.selector} is visible`).toBeVisible();
    if (action.text) await expect(locator).toContainText(action.text);
  }
}

// --- case runners --------------------------------------------------------------------------------------

function writeIdentity(testCase, page, served, extra) {
  fs.mkdirSync(IDENTITY_DIR, { recursive: true });
  const identity = {
    key: testCase.key,
    kind: testCase.kind,
    tier: testCase.tier,
    route: testCase.route,
    width: testCase.width,
    theme: testCase.theme,
    state: testCase.state,
    snapshot: snapshotFileName(testCase.key),
    served,
    scenario_file: CASES_FILE.determinism.scenario_file,
    scenario_file_sha256: sha256(fs.readFileSync(path.join(REPO_ROOT, CASES_FILE.determinism.scenario_file))),
    playwright_version: PLAYWRIGHT_VERSION,
    browser_version: page.context().browser().version(),
    fixed_clock: FIXED_CLOCK,
    ...extra,
  };
  fs.writeFileSync(path.join(IDENTITY_DIR, `${testCase.key}.json`), `${JSON.stringify(identity, null, 2)}\n`);
  return identity;
}

async function runStoryCase(page, testCase) {
  if (testCase.kind !== "story") {
    throw new Error(`${testCase.key}: sourcing.a4 is mounted-fallback but the mounted rendering of tier ${testCase.tier} is not implemented; re-run the A4 probe`);
  }
  await prepare(page, testCase);
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(testCase.route)}`);
  const target = page.locator(testCase.target).first();
  await expect(target, "the story route renders the sandbox").toBeVisible();
  await waitForLiveSocket(page);
  await applyStoryTheme(page, testCase.theme);
  await waitForTimeDisplay(page);
  const fonts = await assertFonts(page);
  expect(await page.evaluate(() => window.innerWidth), "the viewport is the case width").toBe(testCase.width);
  const served = await verifyServedAssets(page, "story");
  const tokens = await assertThemeApplied(page, "story", testCase.theme);
  await assertNoAnimations(page);
  await assertContent(target, testCase.expected);
  writeIdentity(testCase, page, served, { fonts, surface_tokens: tokens });
  await expect(target).toHaveScreenshot(`${testCase.key}.png`, { maxDiffPixels: 0, mask: [] });
}

async function openReviewDrawer(page) {
  const menu = page.locator("[data-ax-action-overflow-menu]").first();
  await expect(menu, "the overflow action menu is visible").toBeVisible();
  await menu.locator("summary").click();
  await page.getByRole("menuitem", { name: /Cancel immediately/i }).first().click();
  const drawer = page.locator("#ax-overlay-root [data-presentation='drawer']:visible").first();
  await expect(drawer).toBeVisible();
  await drawer.locator('[data-role="cancel-now-form"]').evaluate((form) => form.requestSubmit());
  await expect(page.locator("#ax-overlay-root [data-role='confirm-panel']:visible").first()).toBeVisible();
  return page.locator(CASES_FILE.mounted_fixture.review_target);
}

async function runMountedCase(page, request, testCase) {
  if (testCase.tier !== "mounted") {
    throw new Error(`${testCase.key}: the mounted rendering of tier ${testCase.tier} is not implemented`);
  }
  const fixture = CASES_FILE.mounted_fixture;
  await reset(request);
  const seeded = await seed(request, fixture.seed);
  expect(seeded.subscription_id, "the seeded subscription is the fixed fixture id").toBe(fixture.subscription_id);
  await prepare(page, testCase);
  await login(page, `/billing/subscriptions/${fixture.subscription_id}`);
  await expect(page.locator("#main-content")).toBeVisible();
  await waitForLiveSocket(page);
  await applyMountedTheme(page, testCase.theme);
  await hideCaptureOnlyChrome(page);
  await waitForTimeDisplay(page);
  const fonts = await assertFonts(page);
  expect(await page.evaluate(() => window.innerWidth), "the viewport is the case width").toBe(testCase.width);
  const served = await verifyServedAssets(page, "mounted");
  const tokens = await assertThemeApplied(page, "mounted", testCase.theme);

  let target;
  if (testCase.variation_id === "review-open") {
    target = await openReviewDrawer(page);
  } else {
    target = page.locator(fixture.disclosure_target);
    await expect(target, "the disclosure is open").toHaveJSProperty("open", true);
    await target.locator("summary").focus();
    await expect(target.locator("summary"), "the summary is keyboard-focused").toBeFocused();
    expect(await target.locator("summary").evaluate((element) => element.matches(":focus-visible")), "the summary shows its focus ring").toBe(true);
  }
  await expect(target).toBeVisible();
  await assertNoAnimations(page);
  const scope = testCase.expected.scope === "target" ? target : page.locator("#main-content");
  await assertContent(scope, testCase.expected);
  writeIdentity(testCase, page, served, { fonts, surface_tokens: tokens, mounted_target: testCase.target });
  await expect(target).toHaveScreenshot(`${testCase.key}.png`, { maxDiffPixels: 0, mask: [] });
}

// --- tests ---------------------------------------------------------------------------------------------

// D-15: the story routes must render on the legacy server before any capture is written. The negative
// control proves the probe can tell a missing story from a rendered one.
test("A4 probe: the page story route renders on the legacy server and a missing story does not", async ({ page }) => {
  await prepare(page, { width: 1280, theme: "light" });
  const active = CASES_FILE.cases.find((item) => item.kind === "story" && item.tier === "page");
  expect(active, "the visual cases list a page story").toBeTruthy();
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(active.route)}`);
  const marker = page.locator(".psb-sandbox .ax-subscription-detail-page");
  await expect(marker, "positive control: the story ready marker renders").toBeVisible();
  await expect(marker.locator("h1")).toContainText(active.expected.identity.texts[0]);

  await page.goto(`/__e2e__/login?to=${encodeURIComponent("/billing/dev/storybook/pages/phase254-no-such-story")}`);
  await page.waitForLoadState("load");
  await expect(page.locator(".psb-sandbox .ax-subscription-detail-page"), "negative control: a missing story never renders the marker").toHaveCount(0);
});

test("A4 control: equal surface tokens are rejected and different ones accepted", async ({ page }) => {
  await prepare(page, { width: 1280, theme: "light" });
  const sample = CASES_FILE.cases.find((item) => item.kind === "story");
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(sample.route)}`);
  await expect(page.locator(".psb-sandbox").first()).toBeVisible();
  await waitForLiveSocket(page);
  await applyStoryTheme(page, "light");
  const tokens = await readSurfaceTokens(page, "story");
  expect(() => assertThemeTokensDiffer(tokens.current, tokens.other), "the real light and dark tokens differ").not.toThrow();
  expect(() => assertThemeTokensDiffer(tokens.current, tokens.current), "positive control: identical tokens are rejected").toThrow(/resolve the same value/);
});

for (const testCase of CASES_FILE.cases) {
  test(testCase.key, async ({ page, request }) => {
    test.setTimeout(120_000);
    if (testCase.tier === "mounted") await runMountedCase(page, request, testCase);
    else await runStoryCase(page, testCase);
  });
}
