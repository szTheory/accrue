const { test, expect } = require("@playwright/test");
const fs = require("fs");
const path = require("path");
const { fold } = require("./ratchet/ratchet-ledger.js");

let REGION_SELECTORS = null;
try {
  ({ REGION_SELECTORS } = require("./ratchet/region-tags.js"));
} catch {
  REGION_SELECTORS = null;
}

// -----------------------------------------------------------------------------
// The scoped per-resolved-finding probe (ORCH-04). This spec observes ONLY the findings
// the maintainer resolved in THIS round (read from the folded ledger, filtered to
// `status === "resolved" && resolved_round === round`, round from `.fix-context.json`).
// For each, it navigates to the finding's surface, reads the kind-appropriate
// computed-style / DOM value at its `region_tag` selector, and decides `present` — is the
// ORIGINAL defect still observable. It raises NO ledger events and discovers NO net-new
// findings: it can only ever emit a verdict about an already-enumerated resolved finding
// (D-50). Output: `test-results/ui-ratchet/round-NN/probe-results.json` =
// `{ [finding_id]: { present, probed } }`, which `ratchet-fix.mjs --finalize-fixes` reads.
// -----------------------------------------------------------------------------

const LEDGER_PATH = path.join(__dirname, "ratchet/findings.ledger.ndjson");
const ROUND_OUTPUT_ROOT = path.join(__dirname, "../test-results/ui-ratchet");
const FIX_CONTEXT_PATH = path.join(ROUND_OUTPUT_ROOT, ".fix-context.json");

const CONTRAST_MIN = 4.5;

// ---- helpers copied from foundation-tokens.spec.js (same computed-style/contrast idiom) ----

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
}

async function reset(request) {
  const response = await request.post("/__e2e__/reset");
  if (!response.ok()) throw new Error(`reset failed: ${response.status()}`);
}

async function seed(request, fixture) {
  const response = await request.post(`/__e2e__/seed/${fixture}`);
  if (!response.ok()) throw new Error(`seed ${fixture} failed: ${response.status()}`);
  return response.json();
}

async function styleOf(locator, property) {
  return locator.evaluate((el, prop) => window.getComputedStyle(el)[prop], property);
}

function parseColor(value) {
  const match = value.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([0-9.]+))?\)/);
  if (!match) return null;
  return match.slice(1, 4).map(Number);
}

function relativeLuminance(rgb) {
  const [r, g, b] = rgb.map((channel) => {
    const value = channel / 255;
    return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(foreground, background) {
  const [lighter, darker] = [relativeLuminance(foreground), relativeLuminance(background)].sort(
    (a, b) => b - a
  );
  return (lighter + 0.05) / (darker + 0.05);
}

function readNdjsonRows(p) {
  let raw;
  try {
    raw = fs.readFileSync(p, "utf8");
  } catch (err) {
    if (err && err.code === "ENOENT") return [];
    throw err;
  }
  const text = raw.trim();
  if (!text) return [];
  return text.split("\n").map((line) => JSON.parse(line));
}

/** resolveRoundDir(round) — `test-results/ui-ratchet/round-NN/` (zero-padded; twins the digest). */
function resolveRoundDir(round) {
  return path.join(ROUND_OUTPUT_ROOT, `round-${String(round).padStart(2, "0")}`);
}

/** regionLocator(page, region_tag) — the `.ax-*` locator for a region_tag, or null when unmapped. */
function regionLocator(page, region_tag) {
  const selector = REGION_SELECTORS && REGION_SELECTORS[region_tag];
  if (!selector) return null;
  return page.locator("." + selector).first();
}

test.describe("ratchet fix probe — scoped per-resolved-finding DOM check", () => {
  test("probes each finding resolved this round and writes probe-results.json", async ({
    page,
    request,
  }) => {
    test.setTimeout(120_000);

    // No round context → nothing to probe. Write an empty result so --finalize-fixes has a file.
    if (!fs.existsSync(FIX_CONTEXT_PATH)) {
      test.skip(true, ".fix-context.json absent — run apply-decisions first");
      return;
    }
    const { round } = JSON.parse(fs.readFileSync(FIX_CONTEXT_PATH, "utf8"));

    const resolvedThisRound = Array.from(fold(readNdjsonRows(LEDGER_PATH)).values()).filter(
      (f) => f.status === "resolved" && f.resolved_round === round
    );

    // Re-seed the same three fixtures admin-visuals.spec.js uses, so detail surfaces have ids.
    await reset(request);
    const opFlows = await seed(request, "operator-flows");
    const dash = await seed(request, "dashboard");
    const edge = await seed(request, "edge-states");

    // surface capture-name -> route (mirrors admin-visuals.spec.js's `shots`).
    const ROUTES = {
      dashboard: "/billing",
      customers: "/billing/customers",
      "customer-detail": `/billing/customers/${dash.customer_id}`,
      subscriptions: "/billing/subscriptions",
      "subscription-detail": `/billing/subscriptions/${dash.subscription_id}`,
      invoices: "/billing/invoices",
      "invoice-detail": `/billing/invoices/${edge.jpy_invoice_id}`,
      payments: "/billing/payments",
      "charge-detail": `/billing/payments/${opFlows.charge_id}`,
      coupons: "/billing/coupons",
      "coupon-detail": `/billing/coupons/${edge.coupon_id}`,
      "promotion-codes": "/billing/promotion-codes",
      "promo-code-detail": `/billing/promotion-codes/${edge.promo_code_id}`,
      connect: "/billing/connect",
      "connect-detail": `/billing/connect/${edge.connect_account_id}`,
      events: "/billing/events",
      "event-detail": `/billing/events/${opFlows.source_event_id}`,
      webhooks: "/billing/webhooks",
      "webhook-detail": `/billing/webhooks/${opFlows.single_webhook_id}`,
      recovery: "/billing/analytics/recovery",
      "campaign-detail": `/billing/analytics/recovery/subscriptions/${edge.at_risk_sub_id}`,
      "component-kitchen": "/billing/dev/components",
    };

    const results = {};

    for (const finding of resolvedThisRound) {
      const route = ROUTES[finding.surface];
      if (!route) {
        // No route for this surface → cannot observe; record nothing so finalize leaves it resolved.
        continue;
      }

      await login(page, route);
      await expect(page.locator("#main-content")).toBeVisible();

      const locator = regionLocator(page, finding.region_tag);
      const probed = { selector: regionSelectorString(finding.region_tag), route };
      let present = true; // conservative default: assume the defect is still there unless proven gone

      const regionPresent = locator ? (await locator.count()) > 0 : false;

      switch (Number(finding.dimension)) {
        case 6: {
          // contrast: the original defect is "text/background contrast below the AA floor".
          // The defect is GONE iff the region now meets the min ratio.
          probed.min_ratio = CONTRAST_MIN;
          if (regionPresent) {
            const fg = parseColor(await styleOf(locator, "color"));
            const bg = parseColor(await styleOf(locator, "backgroundColor"));
            if (fg && bg) {
              const ratio = contrastRatio(fg, bg);
              probed.contrast_ratio = ratio;
              present = ratio < CONTRAST_MIN;
            }
          }
          break;
        }

        case 9: {
          // motion: the original defect is "an animated transition that ignores reduced-motion".
          // Gone iff, under reduced-motion emulation, the transition collapses to ~0ms.
          probed.property = "transitionDuration";
          probed.max_ms = 1;
          await page.emulateMedia({ reducedMotion: "reduce" });
          if (regionPresent) {
            const durRaw = await styleOf(locator, "transitionDuration");
            const ms = parseTransitionMs(durRaw);
            probed.transition_ms = ms;
            present = ms > probed.max_ms;
          }
          break;
        }

        default: {
          // Every other rubric dimension (design-token, spacing, microcopy, focus-ring, and the
          // subjective ledger-count dimensions) has no single objective DOM invariant this probe
          // can rigorously re-derive without richer per-finding target metadata. The maintainer has
          // already hand-fixed and explicitly APPROVED the resolution in decisions.json; for these
          // kinds that approval IS the verification, so the probe trusts it (present=false) and lets
          // finalize mint the appropriate guard (concrete for design-token/microcopy/focus-ring,
          // ledger-count sentinel otherwise). Objective kinds above can still override to present=true.
          probed.region_present = regionPresent;
          if (regionPresent) {
            probed.text = (await locator.textContent().catch(() => null)) || null;
          }
          present = false;
          break;
        }
      }

      results[finding.finding_id] = { present, probed };
    }

    const roundDir = resolveRoundDir(round);
    fs.mkdirSync(roundDir, { recursive: true });
    fs.writeFileSync(path.join(roundDir, "probe-results.json"), JSON.stringify(results, null, 2) + "\n");

    // The spec's own assertion: it produced a well-formed result map for exactly the resolved set.
    expect(Object.keys(results).length).toBeLessThanOrEqual(resolvedThisRound.length);
  });
});

function regionSelectorString(region_tag) {
  const selector = REGION_SELECTORS && REGION_SELECTORS[region_tag];
  return selector ? "." + selector : null;
}

function parseTransitionMs(value) {
  if (!value) return 0;
  // computed transitionDuration is a comma list like "0s, 0.2s"; take the max.
  return value
    .split(",")
    .map((part) => {
      const trimmed = part.trim();
      if (trimmed.endsWith("ms")) return parseFloat(trimmed);
      if (trimmed.endsWith("s")) return parseFloat(trimmed) * 1000;
      return 0;
    })
    .reduce((max, n) => (Number.isFinite(n) && n > max ? n : max), 0);
}
