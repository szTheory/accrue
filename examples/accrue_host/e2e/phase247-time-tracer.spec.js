// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView, workspaceBillingLink } = require("./support/fixture.js");

test("@phase247 mounted webhook received time formats locally and copies the original ISO", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);
  await workspaceBillingLink(page).click();
  await waitForLiveView(page);
  const workspace = page.locator(`button[data-organization-slug="${fixture.admin_org_alpha_slug}"]`);
  await expect(workspace, "an authorized workspace must be selectable").toBeVisible();
  await workspace.click();
  await waitForLiveView(page);
  const route = `/admin/webhooks?org=${encodeURIComponent(fixture.admin_org_alpha_slug)}`;
  await page.goto(route);
  await waitForLiveView(page);

  const detailLink = page.locator('a[href*="/admin/webhooks/"]').first();
  await expect(detailLink, "an authorized workspace must contain a webhook for the mounted tracer").toBeVisible();
  const detailPath = await detailLink.getAttribute("href");
  await page.goto(detailPath);
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();

  const container = page.locator("#webhook-received-at");
  const time = container.locator("time");
  await expect(time).toBeVisible();
  const iso = await time.getAttribute("datetime");
  expect(iso).toMatch(/^\d{4}-\d\d-\d\dT.*(?:Z|\+00:00)$/);
  await expect.poll(() => time.textContent()).not.toContain("UTC");
  await expect(container.locator("[data-time-zone]")).not.toHaveText("UTC");

  const button = container.getByRole("button", { name: `Copy timestamp ${iso}` });
  const bounds = await button.boundingBox();
  expect(bounds?.width).toBeGreaterThanOrEqual(44);
  expect(bounds?.height).toBeGreaterThanOrEqual(44);
  await page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
  await button.focus();
  await page.keyboard.press("Enter");
  await expect(button).toHaveAttribute("data-copied", "true");
  await expect(container.locator("[data-time-copy-status]")).toHaveText("Timestamp copied.");
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(iso);
});
