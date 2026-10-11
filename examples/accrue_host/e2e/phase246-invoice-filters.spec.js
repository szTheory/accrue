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

async function waitForInvoiceView(page) {
  await page.locator("[data-phx-main].phx-connected").waitFor({ timeout: 10_000 });
  await expect(page.locator("[data-ax-list='invoices']")).toBeVisible();
}

test("mounted invoice controls keep URL, selection, rows, Unicode search, and browser history aligned", async ({ page }) => {
  await signIn(page);
  await page.goto("/admin/invoices", { timeout: 15_000 });
  await waitForInvoiceView(page);

  const statusGroup = page.locator("[data-filter-group='status']");
  const open = statusGroup.locator("input[value='open']");
  const uncollectible = statusGroup.locator("input[value='uncollectible']");
  const paid = statusGroup.locator("input[value='paid']");
  await expect(open).toBeChecked();
  await expect(uncollectible).toBeChecked();

  await open.uncheck();
  await uncollectible.uncheck();
  await paid.check();
  await expect.poll(() => new URL(page.url()).searchParams.get("status")).toBe("paid");
  await expect(paid).toBeChecked();
  await expect(open).not.toBeChecked();
  await expect(uncollectible).not.toBeChecked();

  const invoiceRows = page.locator("[data-ax-list='invoices'] table tbody tr");
  await expect(invoiceRows.first()).toBeVisible();
  const statuses = await invoiceRows.locator("td:nth-child(2)").allTextContents();
  expect(statuses.length).toBeGreaterThan(0);
  expect(statuses.every((status) => status.trim() === "Paid")).toBe(true);

  const search = page.locator("#invoices-filter-q");
  await search.fill("Atelier Café");
  await expect.poll(() => new URL(page.url()).searchParams.get("q")).toBe("Atelier Café");
  await expect(page.locator("[data-ax-filter-chips]")).toContainText("Atelier Café");
  await expect(page.locator("[data-ax-result-count]")).toContainText("invoices");

  const current = new URL(page.url());
  expect(current.searchParams.get("status")).toBe("paid");
  await page.reload({ timeout: 15_000 });
  await waitForInvoiceView(page);
  await expect(page.locator("#invoices-filter-q")).toHaveValue("Atelier Café");
  await expect(page.locator("[data-ax-filter-chips]")).toContainText("Atelier Café");

  await page.goBack({ timeout: 15_000 });
  await expect.poll(() => new URL(page.url()).searchParams.get("q")).toBeNull();
  await expect(page.locator("[data-ax-list='invoices'] [data-filter-group='status'] input[value='paid']")).toBeChecked();
  await page.goForward({ timeout: 15_000 });
  await expect.poll(() => new URL(page.url()).searchParams.get("q")).toBe("Atelier Café");
  await expect(page.locator("#invoices-filter-q")).toHaveValue("Atelier Café");

  await page.goto("/admin/invoices?view=all&status=paid%2Copen", { timeout: 15_000 });
  await waitForInvoiceView(page);
  await expect.poll(() => new URL(page.url()).searchParams.get("status")).toBe("open,paid");
  await expect(page.locator("[data-filter-group='status'] input[value='open']")).toBeChecked();
  await expect(page.locator("[data-filter-group='status'] input[value='paid']")).toBeChecked();
  const directStatuses = await page.locator("[data-ax-list='invoices'] table tbody tr td:nth-child(2)").allTextContents();
  expect(directStatuses.length).toBeGreaterThan(0);
  expect(directStatuses.every((status) => ["Open", "Paid"].includes(status.trim()))).toBe(true);
});
