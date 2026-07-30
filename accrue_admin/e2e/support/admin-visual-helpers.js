const { expect } = require("@playwright/test");

// Shared e2e helpers extracted (behavior-preserving) from admin-visuals.spec.js so
// both the capture spec and the deterministic visual-regression spec can reuse the
// exact same reset/seed/login/chrome-hide mechanics. Only the four generic helpers
// live here; capture-only concerns (captureThemes/captureBBoxes/REGION_SELECTORS/
// VIEWPORT_ONLY_SURFACES) stay local to admin-visuals.spec.js.

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  expect(response.ok()).toBeTruthy();
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  expect(response.ok()).toBeTruthy();
  return response.json();
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

async function hideCaptureOnlyChrome(page) {
  await page.evaluate(() => {
    document
      .querySelectorAll(
        [
          ".ax-dev-toolbar",
          "[data-ax-command-palette-backdrop]",
          "[data-ax-command-palette-panel]",
          "[data-ax-command-palette-shell]"
        ].join(",")
      )
      .forEach((element) => {
        element.hidden = true;
        element.setAttribute("aria-hidden", "true");
        element.setAttribute("data-open", "false");
      });
  });
}

module.exports = { reset, seed, login, hideCaptureOnlyChrome };
