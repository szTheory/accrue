const fs = require("fs");
const path = require("path");
const { expect } = require("@playwright/test");

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE200_EVIDENCE_DIR = path.join(
  REPO_ROOT,
  ".planning",
  "phases",
  "200-idempotent-verification-sign-off",
  "evidence"
);
const STORYBOOK_PATH_FRAGMENT = "/dev/storybook";

function phase200EvidencePath(fileName) {
  return path.join(PHASE200_EVIDENCE_DIR, fileName);
}

async function discoverStorybookStoryUrls(
  page,
  { rootPath = "/billing/dev/storybook", loginPath = "/__e2e__/login" } = {}
) {
  const mountedRoot = new URL(rootPath, "http://phase200.local").pathname.replace(/\/$/, "");

  await page.goto(rootPath);
  await normalizeMountedStorybookUrl(page, mountedRoot);

  if (!new URL(page.url()).pathname.includes(STORYBOOK_PATH_FRAGMENT)) {
    await page.goto(`${loginPath}?to=${encodeURIComponent(rootPath)}`);
    await normalizeMountedStorybookUrl(page, mountedRoot);
  }

  await expect(page.locator("a[href]").first(), "Storybook root should expose navigable story links").toBeVisible();

  const hrefs = await page.locator("a[href]").evaluateAll((links) =>
    links.map((link) => link.getAttribute("href")).filter(Boolean)
  );

  const base = new URL(page.url());
  const root = new URL(rootPath, base);
  const rootPrefix = root.pathname.replace(/\/$/, "");
  const candidates = new Set();

  for (const href of hrefs) {
    const url = new URL(href, base);
    const pathname = mountedStorybookPath(url.pathname, rootPrefix).replace(/\/$/, "");
    const isMountedStorybook = pathname.startsWith(`${rootPrefix}/`);
    const isAsset = pathname.includes("/assets/");
    const isAnchorOnly = pathname === rootPrefix && url.hash;

    if (!isMountedStorybook || isAsset || isAnchorOnly) continue;

    candidates.add(pathname);
  }

  return [...candidates]
    .filter((url) => url.includes(STORYBOOK_PATH_FRAGMENT))
    .sort((left, right) => left.localeCompare(right));
}

async function normalizeMountedStorybookUrl(page, mountedRoot) {
  const current = new URL(page.url());
  const mounted = mountedStorybookPath(current.pathname, mountedRoot);

  if (mounted !== current.pathname) {
    await page.goto(`${mounted}${current.search}${current.hash}`);
  }
}

function mountedStorybookPath(pathname, mountedRoot) {
  if (pathname === STORYBOOK_PATH_FRAGMENT || pathname.startsWith(`${STORYBOOK_PATH_FRAGMENT}/`)) {
    return `${mountedRoot}${pathname.slice(STORYBOOK_PATH_FRAGMENT.length)}`;
  }

  return pathname;
}

async function setSettledThemeForScan(page, theme) {
  if (!["light", "dark"].includes(theme)) {
    throw new Error(`Unsupported settled scan theme: ${theme}`);
  }

  // PhoenixStorybook registers its `psb:set-color-mode` window listener in the
  // ColorModeHook `mounted()` callback, i.e. only once the LiveView has joined. An
  // event dispatched on the statically rendered page is dropped, and the join then
  // re-renders the sandbox from the `psb_selected_color_mode` localStorage value left
  // by the previous story, so a one-shot dispatch settles on the wrong mode. Wait for
  // the join, then dispatch inside the poll: the event is idempotent (it stores the
  // mode and pushes the same assign), so repeating it until the sandbox reports the
  // requested mode is deterministic rather than a sleep.
  await page.waitForFunction(() => document.querySelector(".phx-connected") !== null, undefined, {
    timeout: 15_000,
  });

  const sandboxMode = () =>
    page.evaluate(() => {
      const sandboxes = [...document.querySelectorAll(".psb-sandbox.accrue-admin")].filter(
        // A page story's sandbox is never driven by the color-mode event (see below).
        (element) => element.closest(".psb-variation-block") || !element.closest("#psb-story-live")
      );
      if (sandboxes.length === 0) return "no-driven-sandbox";
      const dark = sandboxes.filter((element) => element.classList.contains("ax-theme-dark-shim"));
      if (dark.length === 0) return "light";
      return dark.length === sandboxes.length ? "dark" : "mixed";
    });

  const hasDrivenSandbox = (await sandboxMode()) !== "no-driven-sandbox";

  if (hasDrivenSandbox) {
    // Component stories (variation blocks) and direct preview routes: PhoenixStorybook
    // itself applies the backend's `color_mode_sandbox_dark_class` (`ax-theme-dark-shim`),
    // so the production color-mode path is what must settle.
    await expect
      .poll(
        async () => {
          await page.evaluate((value) => {
            window.dispatchEvent(new CustomEvent("psb:set-color-mode", { detail: { mode: value } }));
          }, theme);
          return sandboxMode();
        },
        {
          message: `PhoenixStorybook color mode settles to ${theme}`,
          intervals: [100, 250, 500, 1000],
        }
      )
      .toBe(theme);
  } else {
    // Still run the production event so the page-level Storybook mode (html `psb:dark`,
    // localStorage) matches the requested mode before the sandbox is mirrored.
    await page.evaluate((value) => {
      window.dispatchEvent(new CustomEvent("psb:set-color-mode", { detail: { mode: value } }));
    }, theme);
  }

  // Page stories: StoryLive.render_content(:page) renders the sandbox without the
  // color-mode class (upstream only passes `color_mode_class` to component/example
  // tabs), so the production hook can never drive it. Mirror the requested mode onto
  // that sandbox with the same class the backend applies everywhere else.
  await page.evaluate((value) => {
    for (const sandbox of document.querySelectorAll("#psb-story-live .psb-sandbox.accrue-admin")) {
      if (sandbox.closest(".psb-variation-block")) continue;
      sandbox.classList.toggle("ax-theme-dark-shim", value === "dark");
    }
  }, theme);
}

// Group stories (for example the subscription collection states) host every variation in
// its own preview iframe, so the main document has no `.psb-sandbox` to scan. The iframe
// `src` values PhoenixStorybook emits are rooted at `/dev/storybook` rather than at the
// host mount, so they cannot be loaded as embedded frames under a mounted router. The
// production preview route itself is served at the mounted path and takes the theme as
// its `color_mode` query parameter, so the scan opens each preview route directly.
async function storybookPreviewRoutes(page) {
  const pathname = new URL(page.url()).pathname;
  const mountedRoot = pathname.slice(0, pathname.indexOf(STORYBOOK_PATH_FRAGMENT) + STORYBOOK_PATH_FRAGMENT.length);
  const sources = await page.locator("iframe[src]").evaluateAll((frames) => frames.map((frame) => frame.getAttribute("src")));

  return sources
    .map((source) => {
      const url = new URL(source, page.url());
      url.searchParams.delete("color_mode");
      return `${mountedStorybookPath(url.pathname, mountedRoot)}${url.search}`;
    })
    .filter((route) => route.includes("/iframe/"));
}

// Opens one preview route in its own page (same browser context, so the login carries
// over) in the requested mode and waits until the production route reports that mode.
async function openStorybookPreviewRoute(context, route, theme) {
  const url = new URL(route, "http://phase200.local");
  url.searchParams.set("color_mode", theme);

  const previewPage = await context.newPage();
  await previewPage.emulateMedia({ reducedMotion: "reduce" });
  await previewPage.goto(`${url.pathname}${url.search}`);
  // The production preview route applies the backend's dark class to the story container
  // that sits inside the `.psb-sandbox` body, not to the sandbox itself, while the
  // design-system tokens are keyed on `.psb-sandbox.accrue-admin.ax-theme-dark-shim`.
  // Wait for the production route to report the mode, then mirror it onto the sandbox the
  // same way the Phase 253 composition helpers do, and assert the sandbox carries it.
  await expect
    .poll(
      () =>
        previewPage.evaluate(() =>
          document.querySelector(".psb-sandbox.accrue-admin") === null
            ? "no-sandbox"
            : document.querySelector(".ax-theme-dark-shim") !== null
              ? "dark"
              : "light"
        ),
      { message: `${route} preview route settles to ${theme}` }
    )
    .toBe(theme);

  await previewPage.evaluate((value) => {
    for (const sandbox of document.querySelectorAll(".psb-sandbox.accrue-admin")) {
      sandbox.classList.toggle("ax-theme-dark-shim", value === "dark");
    }
  }, theme);
  await expect(previewPage.locator(".psb-sandbox.accrue-admin").first()).toHaveClass(
    theme === "dark" ? /ax-theme-dark-shim/ : /^(?!.*ax-theme-dark-shim)/
  );
  return previewPage;
}

async function assertStorybookAssetsLoaded(page, storyUrl = page.url()) {
  const assets = await page.evaluate(() => {
    const stylesheets = [...document.querySelectorAll('link[rel="stylesheet"][href]')].map((link) => link.href);
    const scripts = [...document.querySelectorAll("script[src]")].map((script) => script.src);
    const resources = performance.getEntriesByType("resource").map((entry) => entry.name);

    return { stylesheets, scripts, resources };
  });

  const cssHref =
    assets.stylesheets.find((href) => href.includes("/dev/storybook/assets/storybook-css-")) ||
    assets.resources.find((href) => href.includes("/dev/storybook/assets/storybook-css-"));

  const jsHref =
    assets.scripts.find((href) => href.includes("/dev/storybook/assets/storybook-js-")) ||
    assets.resources.find((href) => href.includes("/dev/storybook/assets/storybook-js-"));

  expect(cssHref, `${storyUrl}: committed Storybook CSS asset should load`).toBeTruthy();
  expect(jsHref, `${storyUrl}: committed Storybook JS asset should load`).toBeTruthy();

  const cssResponse = await page.request.get(cssHref);
  const jsResponse = await page.request.get(jsHref);

  expect(cssResponse.ok(), `${storyUrl}: committed Storybook CSS route`).toBeTruthy();
  expect(jsResponse.ok(), `${storyUrl}: committed Storybook JS route`).toBeTruthy();
  expect(cssResponse.headers()["content-type"], `${storyUrl}: Storybook CSS content type`).toContain("text/css");
  expect(jsResponse.headers()["content-type"], `${storyUrl}: Storybook JS content type`).toContain(
    "application/javascript"
  );

  expect(await cssResponse.text(), `${storyUrl}: CSS committed-bundle marker`).toContain("committed");
  expect(await jsResponse.text(), `${storyUrl}: JS committed-bundle marker`).toContain("committed");

  return { cssHref, jsHref };
}

function axeFailureDetails(violation, { storyUrl, theme, route } = {}) {
  const node = violation.nodes?.[0];
  const check = [...(node?.any || []), ...(node?.all || []), ...(node?.none || [])].find((item) => item?.data);
  const contrast = check?.data
    ? ` contrast=${JSON.stringify({
        fg: check.data.fgColor,
        bg: check.data.bgColor,
        ratio: check.data.contrastRatio,
        expected: check.data.expectedContrastRatio,
      })}`
    : "";
  const target = node?.target?.join(" ") || "no-target";
  const surface = storyUrl || route || "unknown-surface";

  return `${surface} [${theme || "unknown-theme"}] ${violation.id} ${violation.impact || "unknown-impact"} target=${target}${contrast}`;
}

function writePhase200Evidence(fileName, rows) {
  fs.mkdirSync(PHASE200_EVIDENCE_DIR, { recursive: true });

  const payload = {
    generated_at: new Date().toISOString(),
    rows,
  };

  fs.writeFileSync(phase200EvidencePath(fileName), `${JSON.stringify(payload, null, 2)}\n`);
  return payload;
}

module.exports = {
  assertStorybookAssetsLoaded,
  axeFailureDetails,
  discoverStorybookStoryUrls,
  phase200EvidencePath,
  setSettledThemeForScan,
  openStorybookPreviewRoute,
  storybookPreviewRoutes,
  writePhase200Evidence,
};
