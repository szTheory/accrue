// @ts-check
const { expect } = require("@playwright/test");

/**
 * @param {import('@playwright/test').Locator} locator
 * @param {string} label
 */
async function expectVisibleInViewport(locator, label) {
  await locator.scrollIntoViewIfNeeded();
  await expect(locator, `${label} should be visible`).toBeVisible();

  const box = await locator.boundingBox();
  expect(box, `${label} should have a bounding box`).not.toBeNull();

  if (!box) {
    return;
  }

  const viewport = locator.page().viewportSize();
  expect(viewport, `${label} should have a viewport`).not.toBeNull();

  if (!viewport) {
    return;
  }

  expect(box.x, `${label} should not be clipped on the left`).toBeGreaterThanOrEqual(0);
  expect(box.y, `${label} should not be clipped above the viewport`).toBeGreaterThanOrEqual(0);
}

/**
 * @param {import('@playwright/test').Page} page
 * @param {string} label
 */
async function expectNoHorizontalOverflow(page, label) {
  const overflow = await page.evaluate(() => ({
    documentWidth: document.documentElement.scrollWidth,
    viewportWidth: window.innerWidth
  }));

  expect(
    overflow.documentWidth,
    `${label} should not hide text or actions behind horizontal overflow`
  ).toBeLessThanOrEqual(overflow.viewportWidth + 1);
}

module.exports = { expectNoHorizontalOverflow, expectVisibleInViewport };
