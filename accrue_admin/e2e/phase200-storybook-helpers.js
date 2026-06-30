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

  await page.evaluate((value) => {
    const root = document.documentElement;
    root.dataset.theme = value;
    root.setAttribute("data-theme", value);
    root.dataset.phase200SettledScanBypass = "true";

    for (const sandbox of document.querySelectorAll(".psb-sandbox, .accrue-admin")) {
      sandbox.classList.add("accrue-admin");
      sandbox.classList.toggle("ax-theme-dark-shim", value === "dark");
      sandbox.dataset.theme = value;
      sandbox.setAttribute("data-theme", value);
      sandbox.dataset.phase200SettledScanBypass = "true";
    }
  }, theme);

  await expect
    .poll(() => page.locator("html").evaluate((element) => element.dataset.theme || ""), {
      message: `settled scan theme ${theme}`,
    })
    .toBe(theme);
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
  writePhase200Evidence,
};
