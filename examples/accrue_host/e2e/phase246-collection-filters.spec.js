// @ts-check
const { test, expect } = require("@playwright/test");

const operatorEmail = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_EMAIL || "admin@example.com";
const operatorPassword = process.env.ACCRUE_HOST_PREVIEW_OPERATOR_PASSWORD;

async function signIn(page) {
  if (!operatorPassword) throw new Error("ordinary preview operator password is required");

  await page.goto("/users/log-in", { timeout: 15_000 });
  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");
  expect(csrfToken).toBeTruthy();
  const response = await page.request.post("/users/log-in", {
    form: {
      _csrf_token: csrfToken,
      "user[email]": operatorEmail,
      "user[password]": operatorPassword
    }
  });
  expect(response.ok(), `operator sign in returned ${response.status()}`).toBeTruthy();
}

async function waitForList(page, listId) {
  await page.locator("[data-phx-main].phx-connected").waitFor({ timeout: 10_000 });
  await expect(page.locator(`[data-ax-list='${listId}']`)).toBeVisible();
}

test("mounted subscription status sets keep controls, URL, rows, and history aligned", async ({ page }) => {
  await signIn(page);
  await page.goto("/admin/subscriptions", { timeout: 15_000 });
  await waitForList(page, "subscriptions");

  const statuses = page.locator("[data-filter-group='status']");
  const pastDue = statuses.locator("input[value='past_due']");
  const canceling = statuses.locator("input[value='canceling']");
  await expect(pastDue).toBeChecked();
  await expect(canceling).toBeChecked();
  await expect.poll(() => new URL(page.url()).searchParams.get("status")).toBe("past_due,canceling");

  const rows = page.locator("[data-ax-list='subscriptions'] table tbody tr");
  const defaultStates = await rows.locator("td:nth-child(2)").allTextContents();
  expect(defaultStates.length).toBeGreaterThan(0);
  expect(defaultStates.every((state) => /past due|unpaid|cancel/i.test(state))).toBe(true);

  await canceling.uncheck();
  await expect.poll(() => new URL(page.url()).searchParams.get("status")).toBe("past_due");
  await expect(pastDue).toBeChecked();
  await expect(canceling).not.toBeChecked();
  await page.goBack({ timeout: 15_000 });
  await expect.poll(() => new URL(page.url()).searchParams.get("status")).toBe("past_due,canceling");
  await expect(canceling).toBeChecked();

  await page.getByRole("link", { name: "Apply All filter" }).click();
  await expect.poll(() => new URL(page.url()).searchParams.get("view")).toBe("all");
  await expect.poll(() => new URL(page.url()).searchParams.get("status")).toBeNull();
  await expect(pastDue).not.toBeChecked();
  await expect(canceling).not.toBeChecked();
});

test("mounted coupon All and Valid choices are singular and preserve the search query", async ({ page }) => {
  await signIn(page);
  await page.goto("/admin/coupons?q=Launch", { timeout: 15_000 });
  await waitForList(page, "coupons");

  const valid = page.getByRole("radio", { name: "Valid", exact: true });
  const all = page.getByRole("radio", { name: "All", exact: true });
  await expect(valid).toBeChecked();
  await expect(all).not.toBeChecked();
  await expect(page.locator("[data-ax-list='coupons'] tbody tr").first()).toContainText("Launch");

  await page.getByRole("radiogroup", { name: "Validity" }).getByText("All", { exact: true }).click();
  await expect.poll(() => new URL(page.url()).searchParams.get("view")).toBe("all");
  await expect.poll(() => new URL(page.url()).searchParams.get("q")).toBe("Launch");
  await expect(all).toBeChecked();
  await expect(valid).not.toBeChecked();

  await page.getByRole("radiogroup", { name: "Validity" }).getByText("Valid", { exact: true }).click();
  await expect.poll(() => new URL(page.url()).searchParams.get("valid")).toBe("true");
  await expect.poll(() => new URL(page.url()).searchParams.get("view")).toBeNull();
  await expect.poll(() => new URL(page.url()).searchParams.get("q")).toBe("Launch");
  await expect(valid).toBeChecked();
  await expect(all).not.toBeChecked();
});
