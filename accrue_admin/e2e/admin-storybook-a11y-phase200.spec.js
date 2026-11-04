const fs = require("fs");
const path = require("path");
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

const {
  assertStorybookAssetsLoaded,
  axeFailureDetails,
  discoverStorybookStoryUrls,
  setSettledThemeForScan,
  openStorybookPreviewRoute,
  storybookPreviewRoutes,
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
        // Component and page stories carry their sandboxes in this document; group
        // stories carry them in preview routes that are opened one by one.
        const previewRoutes = await storybookPreviewRoutes(page);
        const targets = [];
        if ((await page.locator(".psb-sandbox").count()) > 0) {
          await expect(
            page.locator(".psb-sandbox").first(),
            `${storyUrl} should render Storybook content before axe scan`
          ).toBeVisible();
          targets.push({ surface: storyUrl, scanPage: page, owned: false });
        } else {
          expect(previewRoutes.length, `${storyUrl} should expose a sandbox or preview routes to scan`).toBeGreaterThan(0);
          for (const route of previewRoutes) {
            targets.push({
              surface: route,
              scanPage: await openStorybookPreviewRoute(page.context(), route, theme),
              owned: true,
            });
          }
        }

        const blocking = [];
        for (const target of targets) {
          const results = await new AxeBuilder({ page: target.scanPage })
            .include(".psb-sandbox")
            .withTags(["wcag2a", "wcag2aa"])
            .analyze();
          for (const violation of results.violations) {
            if (["critical", "serious"].includes(violation.impact)) {
              blocking.push({ violation, surface: target.surface });
            }
          }
          if (target.owned) await target.scanPage.close();
        }
        evidenceRows.push({
          story_url: storyUrl,
          theme,
          status: blocking.length === 0 ? "passed" : "failed",
          evidence_refs: [
            `playwright:admin-storybook-a11y-phase200:${testInfo.project.name}`,
            `storybook:${storyUrl}:${theme}`,
          ],
          violations: blocking.map(({ violation, surface }) =>
            axeFailureDetails(violation, { storyUrl: surface, theme })
          ),
        });

        for (const { violation, surface } of blocking) {
          failures.push(axeFailureDetails(violation, { storyUrl: surface, theme }));
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
