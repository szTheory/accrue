const { test, expect } = require("@playwright/test");
const {
  assertStorybookAssetsLoaded,
  discoverStorybookStoryUrls,
} = require("./phase200-storybook-helpers.js");

test("owned review server identity and production-backed subscription story are available", async ({ page, request }) => {
  const healthResponse = await request.get("/__e2e__/health");
  expect(healthResponse.ok(), "owned launcher health should respond successfully").toBeTruthy();
  const health = await healthResponse.json();
  expect(health).toMatchObject({
    ok: true,
    ready: true,
    nonce: process.env.PHASE252_E2E_NONCE,
    database: process.env.PHASE252_E2E_DATABASE,
    role: process.env.PHASE252_E2E_ROLE,
    address: process.env.PHASE252_E2E_ADDRESS,
    port: Number(process.env.PHASE252_E2E_PORT),
    partition: process.env.PHASE252_E2E_PARTITION,
  });
  expect(Number.isInteger(health.pid) && health.pid > 0, "health must report the server process identity").toBeTruthy();

  const storyUrls = await discoverStorybookStoryUrls(page, {
    rootPath: "/billing/dev/storybook",
    loginPath: "/__e2e__/login",
  });
  const subscriptionStory = storyUrls.find((url) => /subscription[_-]detail/i.test(url));
  expect(subscriptionStory, "mounted Storybook should expose the subscription detail story").toBeTruthy();

  await page.goto(subscriptionStory);
  await assertStorybookAssetsLoaded(page, subscriptionStory);
  const storySandbox = page.locator(".psb-sandbox").first();
  await expect(storySandbox).toBeVisible();
  await expect(storySandbox).toContainText("Acme Research");
});
