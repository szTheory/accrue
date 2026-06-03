const { test, expect } = require("./support/test.js");
const { readFixture, login, waitForLiveView } = require("./support/fixture.js");

test.describe("Core User Journeys", () => {
  // Use serial mode to prevent any possible collision between browser runs
  test.describe.configure({ mode: 'serial' });

  test("onboarding, subscribe, upgrade, cancel", async ({ page, sandboxId }) => {
    const fixture = readFixture();
    await login(page, fixture, fixture.normal_email, sandboxId);
    await page.getByRole("link", { name: "Go to billing" }).click();
    await waitForLiveView(page);

    // 1. Setup tax location
    const taxForm = page.locator("#tax-location-form");
    if (await taxForm.isVisible()) {
      await taxForm.locator('[name="tax_location[line1]"]').fill("123 Test St");
      await taxForm.locator('[name="tax_location[city]"]').fill("Testville");
      await taxForm.locator('[name="tax_location[state]"]').fill("NY");
      await taxForm.locator('[name="tax_location[postal_code]"]').fill("10001");
      await taxForm.locator('[name="tax_location[country]"]').fill("US");
      await taxForm.getByRole("button", { name: "Save tax location" }).click();
      await expect(page.getByText(/Tax location saved/)).toBeVisible();
      await waitForLiveView(page);
    }

    // 2. Start basic subscription
    const startBasic = page.locator("[data-plan-id='price_basic']").getByRole("button", { name: "Start organization subscription" });
    await startBasic.click();
    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText("Basic (price_basic)")).toBeVisible();
    await waitForLiveView(page);

    // 3. Cancel subscription
    await page.getByRole("button", { name: "Cancel now for this organization" }).click();
    await expect(page.getByRole("button", { name: "Confirm cancellation" })).toBeVisible();
    await page.getByRole("button", { name: "Confirm cancellation" }).click();
    await expect(page.getByText(/Subscription canceled now/)).toBeVisible({ timeout: 15_000 });
    await waitForLiveView(page);

    // 4. Upgrade to Pro
    const startPro = page.locator("[data-plan-id='price_pro']").getByRole("button", { name: "Start organization subscription" });
    await startPro.click();
    
    // Check for potential confirmation button
    const confirmButton = page.getByRole("button", { name: "Confirm plan change" });
    if (await confirmButton.isVisible()) {
      await confirmButton.click();
    }
    
    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText("Pro (price_pro)")).toBeVisible();
    await waitForLiveView(page);

    // 5. Downgrade back to Basic
    await page.locator("[data-plan-id='price_basic']").getByRole("button", { name: "Start organization subscription" }).click();

    const confirmDowngradeButton = page.getByRole("button", { name: "Confirm plan change" });
    if (await confirmDowngradeButton.isVisible()) {
      await confirmDowngradeButton.click();
    }

    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText("Basic (price_basic)")).toBeVisible();
    await waitForLiveView(page);

    // 6. Payment method management surface
    await page.goto("/billing/payment-methods", { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);
    await expect(page.getByRole("heading", { name: "Payment methods" })).toBeVisible();
    await expect(page.getByText("visa ending in 4242")).toBeVisible();
    await expect(page.getByText("mastercard ending in 4444")).toBeVisible();
    await expect(page.getByText("Default", { exact: true })).toBeVisible();
    await expect(page.getByRole("link", { name: "Add a card" })).toHaveAttribute("href", "/billing/payment-methods/new");
    await expect(page.getByRole("button", { name: "Set default" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Delete card" })).toHaveCount(2);

    await page.getByRole("link", { name: "Add a card" }).click();
    await expect(page.getByRole("heading", { name: "Add payment method" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Save card" })).toBeVisible();

    await page.goto("/app/billing", { waitUntil: "domcontentloaded" });
    await waitForLiveView(page);

    // 7. Test Metered Usage Demo
    const simulateButton = page.getByRole("button", { name: "Simulate API Call" });
    await expect(simulateButton).toBeVisible();
    await simulateButton.click();
    await expect(page.getByText("Usage reported: 1 API call recorded.")).toBeVisible();

  });
});
