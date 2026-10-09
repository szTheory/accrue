// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");
const { expectNoHorizontalOverflow } = require("./support/overflow.js");

async function capture(testInfo, name, page) {
  await testInfo.attach(name, {
    body: await page.screenshot({ fullPage: true }),
    contentType: "image/png"
  });
}

async function expectNarrowLayouts(page, label) {
  await page.setViewportSize({ width: 640, height: 900 });
  await page.locator("html").evaluate((element) => { element.style.zoom = "2"; });
  await expectNoHorizontalOverflow(page, `${label} at 640px / 200% zoom`);
  await page.locator("html").evaluate((element) => { element.style.zoom = ""; });
  await page.setViewportSize({ width: 320, height: 900 });
  await expectNoHorizontalOverflow(page, `${label} at direct 320px`);
}

test("Phase 239 current Admin, customer Portal, and host entry render in the isolated fixture", async ({ page, sandboxId }, testInfo) => {
  const fixture = readFixture();
  const nonGetRequests = [];

  await login(page, fixture, fixture.admin_email, sandboxId);
  page.on("request", (request) => {
    if (request.method() !== "GET") nonGetRequests.push(`${request.method()} ${request.url()}`);
  });

  const adminResponse = await page.goto("/admin", { waitUntil: "domcontentloaded" });
  expect(adminResponse && adminResponse.status()).toBe(200);
  await waitForLiveView(page);
  await expect(page.getByRole("main")).toBeVisible();
  await expect(page.getByRole("heading", { level: 1, name: "Billing operations" })).toBeVisible();
  await expectNarrowLayouts(page, "Admin /admin");
  await capture(testInfo, "phase239-admin-current-render.png", page);

  await page.context().clearCookies();
  await login(page, fixture, fixture.normal_email, sandboxId);
  const portalResponse = await page.goto("/billing", { waitUntil: "domcontentloaded" });
  expect(portalResponse && portalResponse.status()).toBe(200);
  await waitForLiveView(page);
  await expect(page.locator("main.portal-shell h1")).toHaveText("Account overview");
  await expect(page.locator(".portal-wordmark")).toHaveText("Cadence");
  await expect(page.locator(".portal-billable-name")).toHaveText(fixture.normal_email);
  await expectNarrowLayouts(page, "customer Portal /billing");
  await capture(testInfo, "phase239-portal-current-render.png", page);

  const hostResponse = await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(hostResponse && hostResponse.status()).toBe(200);
  await expect(page.getByRole("heading", { level: 2, name: "Three realistic billing roles" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Workspace billing" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Customer portal" })).toBeVisible();
  await page.setViewportSize({ width: 320, height: 900 });
  await expectNoHorizontalOverflow(page, "host entry / at direct 320 CSS px");
  await page.reload();
  await expect(page.getByRole("heading", { level: 2, name: "Three realistic billing roles" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Workspace billing" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Customer portal" })).toBeVisible();
  await capture(testInfo, "phase239-host-entry-current-render.png", page);

  expect(nonGetRequests, "post-login route walkthrough must not issue writes").toEqual([]);
});
