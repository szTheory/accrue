// @ts-check
const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

test("Phase 238 queues one selected webhook only after confirmation and fresh step-up", async ({ page, sandboxId }) => {
  const fixture = readFixture();
  await login(page, fixture, fixture.admin_email, sandboxId);

  const owner = encodeURIComponent(fixture.admin_org_alpha_slug);
  await page.goto(`/admin/webhooks?org=${owner}&status=failed,dead`, { waitUntil: "domcontentloaded" });
  await waitForLiveView(page);

  const row = page.locator(`input[data-role="toggle-row"][data-row-id="${fixture.webhook_id}"]`).first();
  await expect(row).toBeVisible();
  await row.check();
  await page.locator("[data-role='bulk-action']").click();

  const confirmation = page.locator("[data-role='bulk-replay-confirm']");
  await expect(confirmation).toContainText("Replay 1 selected delivery?");
  await expect(confirmation).toContainText("Only deliveries still eligible when confirmed will be queued");
  await expect(confirmation).toContainText("Queue acceptance does not mean processing is complete");
  await confirmation.getByRole("button", { name: "Queue eligible deliveries" }).click();

  const stepUp = page.getByRole("dialog", { name: "Step-up required" });
  await expect(stepUp).toBeVisible();
  await stepUp.getByRole("textbox", { name: "Verification code" }).fill("123456");
  await stepUp.getByRole("button", { name: "Verify identity" }).click();

  await expect(stepUp).toBeHidden();
  await expect(page.locator("[role='status'], [role='alert']").filter({ hasText: "Queued 1 delivery" }).first()).toBeVisible();
  await expect(page.locator("body")).not.toContainText(/processed successfully/i);
});
