const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

const {
  assertStorybookAssetsLoaded,
  axeFailureDetails,
  discoverStorybookStoryUrls,
  setSettledThemeForScan,
  writePhase200Evidence,
} = require("./phase200-storybook-helpers.js");

test.use({ trace: "retain-on-failure" });

test.describe("Phase 200 rendered Storybook accessibility", () => {
  test("discovers mounted Storybook URLs from the DOM and scans settled light/dark modes", async ({
    page,
  }, testInfo) => {
    test.skip(testInfo.project.name !== "chromium-desktop", "Phase 200 Storybook scan runs once");
    test.setTimeout(120_000);

    await page.emulateMedia({ reducedMotion: "reduce" });

    const storyUrls = await discoverStorybookStoryUrls(page, {
      rootPath: "/billing/dev/storybook",
      loginPath: "/__e2e__/login",
    });

    expect(storyUrls.length, "Storybook scan should discover mounted story URLs").toBeGreaterThan(0);

    const evidenceRows = [];
    const failures = [];

    for (const storyUrl of storyUrls) {
      await page.goto(storyUrl);
      await assertStorybookAssetsLoaded(page, storyUrl);

      for (const theme of ["light", "dark"]) {
        await setSettledThemeForScan(page, theme);
        await expect(
          page.locator(".psb-sandbox, [data-storybook-component-registry], [data-storybook-component-groups]").first(),
          `${storyUrl} should render Storybook content before axe scan`
        ).toBeVisible();

        const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
        const blocking = results.violations.filter((violation) =>
          ["critical", "serious"].includes(violation.impact)
        );

        evidenceRows.push({
          story_url: storyUrl,
          theme,
          status: blocking.length === 0 ? "passed" : "failed",
          evidence_refs: [
            `playwright:admin-storybook-a11y-phase200:${testInfo.project.name}`,
            `storybook:${storyUrl}:${theme}`,
          ],
          violations: blocking.map((violation) => axeFailureDetails(violation, { storyUrl, theme })),
        });

        for (const violation of blocking) {
          failures.push(axeFailureDetails(violation, { storyUrl, theme }));
        }
      }
    }

    writePhase200Evidence("storybook-a11y.json", evidenceRows);

    expect(
      evidenceRows,
      "evidence rows should include story URL, theme, status, and refs"
    ).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          story_url: expect.any(String),
          theme: expect.stringMatching(/^(light|dark)$/),
          status: expect.stringMatching(/^(passed|failed)$/),
          evidence_refs: expect.any(Array),
        }),
      ])
    );

    expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
  });

  test("source contract keeps Storybook discovery dynamic", () => {
    const helperPath = path.join(__dirname, "phase200-storybook-helpers.js");
    const helperSource = fs.readFileSync(helperPath, "utf8");

    expect(helperSource).toContain("a[href]");
    expect(helperSource).toContain("/dev/storybook");
    expect(helperSource).not.toMatch(/\b(?:30|42|8)\b/);
  });
});
