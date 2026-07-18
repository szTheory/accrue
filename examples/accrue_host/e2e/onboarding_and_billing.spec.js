const { test, expect } = require("./support/test.js");
const { readFixture, login, workspaceBillingLink, waitForLiveView } = require("./support/fixture.js");

test.describe("Core User Journeys", () => {
  // Use serial mode to prevent any possible collision between browser runs
  test.describe.configure({ mode: 'serial' });

  test("onboarding, subscribe, upgrade, cancel", async ({ page, sandboxId }) => {
    const fixture = readFixture();
    const currentSubscription = page.getByTestId("current-subscription");

    await login(page, fixture, fixture.normal_email, sandboxId);
    await workspaceBillingLink(page).click();
    await waitForLiveView(page);
    await expect(page.getByRole("heading", { name: "Workspace billing" })).toBeVisible();

    // 1. Start basic subscription
    const startBasic = page.locator("[data-plan-id='price_basic']").getByRole("button", { name: "Choose Launch" });
    await startBasic.click();
    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
    await expect(currentSubscription.getByText("Launch", { exact: true })).toBeVisible();
    await waitForLiveView(page);

    // 2. Cancel subscription
    await page.getByRole("button", { name: "Cancel workspace subscription" }).click();
    await expect(page.getByRole("button", { name: "Confirm cancellation" })).toBeVisible();
    await page.getByRole("button", { name: "Confirm cancellation" }).click();
    await expect(page.getByText(/Subscription canceled now/)).toBeVisible({ timeout: 15_000 });
    await waitForLiveView(page);

    // 3. Upgrade to Studio
    const chooseStudio = page.locator("[data-plan-id='price_pro']").getByRole("button", { name: "Choose Studio" });
    await chooseStudio.click();
    
    // Check for potential confirmation button
    const confirmButton = page.getByRole("button", { name: "Confirm plan change" });
    if (await confirmButton.isVisible()) {
      await confirmButton.click();
    }
    
    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
    await expect(currentSubscription.getByText("Studio", { exact: true })).toBeVisible();
    await waitForLiveView(page);

    // 4. Downgrade back to Launch
    await page.locator("[data-plan-id='price_basic']").getByRole("button", { name: "Choose Launch" }).click();

    const confirmDowngradeButton = page.getByRole("button", { name: "Confirm plan change" });
    if (await confirmDowngradeButton.isVisible()) {
      await confirmDowngradeButton.click();
    }

    await expect(page.getByText("Subscription started.")).toBeVisible({ timeout: 15_000 });
    await expect(currentSubscription.getByText("Launch", { exact: true })).toBeVisible();
    await waitForLiveView(page);

    // 5. Payment method management surface
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
  });
});
