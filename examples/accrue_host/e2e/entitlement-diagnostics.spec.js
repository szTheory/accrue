// @ts-check
const path = require("path");
const fs = require("fs");
const { test, expect } = require("./support/test.js");
const AxeBuilder = require("@axe-core/playwright").default;
const { readFixture, reseedFixture, login, waitForLiveView } = require("./support/fixture.js");

const copyStrings = JSON.parse(
  fs.readFileSync(path.join(__dirname, "generated", "copy_strings.json"), "utf8")
);

test("operator diagnostic has a keyboard-safe bounded unavailable state", async ({ page, sandboxId }) => {
  if (process.env.ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED !== "1") reseedFixture();

  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);
  await page.goto("/app/entitlements/diagnostics", { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  await expect(page.getByRole("heading", { name: "Access diagnostic" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "Access check unavailable" })).toBeVisible();
  await page.keyboard.press("Tab");
  await expect(page.locator(":focus")).toBeVisible();

  const results = await new AxeBuilder({ page }).include("[data-testid='entitlement-diagnostic']").analyze();
  const serious = results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
  expect(serious, JSON.stringify(serious, null, 2)).toEqual([]);

  // Keep the current generated copy contract loaded so this rendered proof stays
  // complementary to the semantic ExUnit tests rather than becoming a new oracle.
  expect(copyStrings).toBeTruthy();
});
