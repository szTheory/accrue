#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const STRIPE_API_BASE = "https://api.stripe.com/v1";

export const FIXTURES = Object.freeze([
  Object.freeze({
    envName: "ACCRUE_LIVE_BASIC_PRICE",
    label: "basic",
    lookupKey: "accrue_ci_basic_v1",
    productName: "Accrue CI Basic",
    unitAmount: 1_000,
  }),
  Object.freeze({
    envName: "ACCRUE_LIVE_PRO_PRICE",
    label: "pro",
    lookupKey: "accrue_ci_pro_v1",
    productName: "Accrue CI Pro",
    unitAmount: 2_000,
  }),
]);

function fail(message) {
  throw new Error(message);
}

function requiredTestKey(value) {
  const key = value?.trim();
  if (!key) fail("STRIPE_TEST_SECRET_KEY is required");
  if (!key.startsWith("sk_test_")) fail("STRIPE_TEST_SECRET_KEY must be a sandbox standard secret key beginning with sk_test_");
  return key;
}

function priceId(value) {
  if (typeof value !== "string" || !/^price_[A-Za-z0-9_]+$/.test(value)) fail("Stripe returned an invalid Price id");
  return value;
}

export function validateFixturePrice(price, fixture) {
  if (!price || typeof price !== "object" || Array.isArray(price)) fail(`${fixture.label} fixture is not a Stripe Price object`);
  const id = priceId(price.id);
  if (price.livemode !== false) fail(`${fixture.label} fixture must belong to a Stripe sandbox`);
  if (price.active !== true) fail(`${fixture.label} fixture must be active`);
  if (price.lookup_key !== fixture.lookupKey) fail(`${fixture.label} fixture lookup key drifted`);
  if (price.currency !== "usd") fail(`${fixture.label} fixture currency must be usd`);
  if (price.unit_amount !== fixture.unitAmount) fail(`${fixture.label} fixture amount drifted`);
  if (price.type !== "recurring" || price.recurring?.interval !== "month" || price.recurring?.interval_count !== 1) {
    fail(`${fixture.label} fixture must recur monthly`);
  }
  return id;
}

async function stripeRequest(fetchImpl, secretKey, pathname, options = {}) {
  const response = await fetchImpl(`${STRIPE_API_BASE}${pathname}`, {
    ...options,
    headers: {
      Authorization: `Basic ${Buffer.from(`${secretKey}:`).toString("base64")}`,
      "Content-Type": "application/x-www-form-urlencoded",
      ...options.headers,
    },
  });
  if (!response.ok) fail(`Stripe fixture request failed: method=${options.method || "GET"} path=${pathname.split("?")[0]} http=${response.status}`);
  const body = await response.json().catch(() => null);
  if (!body || typeof body !== "object") fail("Stripe fixture request returned invalid JSON");
  return body;
}

async function findFixture(fetchImpl, secretKey, fixture) {
  const query = new URLSearchParams();
  query.set("active", "true");
  query.set("type", "recurring");
  query.set("limit", "2");
  query.append("lookup_keys[]", fixture.lookupKey);
  const result = await stripeRequest(fetchImpl, secretKey, `/prices?${query}`);
  if (!Array.isArray(result.data)) fail("Stripe Price lookup did not return a data array");
  if (result.data.length > 1) fail(`${fixture.label} fixture lookup key resolved more than one active Price`);
  return result.data[0] || null;
}

async function createFixture(fetchImpl, secretKey, fixture) {
  const body = new URLSearchParams();
  body.set("currency", "usd");
  body.set("unit_amount", String(fixture.unitAmount));
  body.set("recurring[interval]", "month");
  body.set("recurring[interval_count]", "1");
  body.set("lookup_key", fixture.lookupKey);
  body.set("product_data[name]", fixture.productName);
  body.set("metadata[accrue_fixture]", "ci_provider_parity");
  return stripeRequest(fetchImpl, secretKey, "/prices", { method: "POST", body });
}

export async function resolveStripeTestFixtures({
  fetchImpl = globalThis.fetch,
  secretKey = process.env.STRIPE_TEST_SECRET_KEY,
} = {}) {
  if (typeof fetchImpl !== "function") fail("fetch implementation is required");
  const key = requiredTestKey(secretKey);
  const resolved = {};

  for (const fixture of FIXTURES) {
    const existing = await findFixture(fetchImpl, key, fixture);
    const price = existing || await createFixture(fetchImpl, key, fixture);
    resolved[fixture.envName] = validateFixturePrice(price, fixture);
  }

  if (resolved.ACCRUE_LIVE_BASIC_PRICE === resolved.ACCRUE_LIVE_PRO_PRICE) fail("basic and pro fixtures must use distinct Price ids");
  return resolved;
}

export function appendGitHubEnvironment(file, values) {
  if (!file?.trim()) fail("--github-env requires a path");
  const lines = FIXTURES.map(({ envName }) => `${envName}=${priceId(values[envName])}`);
  fs.appendFileSync(file, `${lines.join("\n")}\n`, { encoding: "utf8", mode: 0o600 });
}

function option(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}

async function main() {
  const githubEnvironment = option("--github-env");
  if (!githubEnvironment) fail("usage: stripe_test_fixtures.mjs --github-env PATH");
  const values = await resolveStripeTestFixtures();
  appendGitHubEnvironment(githubEnvironment, values);
  console.log("stripe test fixtures: resolved 2 sandbox Prices");
}

// D-29 (232-08): replaces the vacuous file-URL-template guard
// (`import.meta.url === \`file://${process.argv[1]}\``), which silently
// evaluates false when the checkout path contains a space -- main() never
// runs, the script prints nothing, and it exits 0. isMainModule() throws
// (never returns a silent false) when there is no invoking entrypoint; that
// throw must not crash a bare import, so it is caught and treated as "not
// the entrypoint" (established pattern, main_module.mjs).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  // Non-vacuity: at least one real named node:test registration so
  // `node --test --test-reporter=tap scripts/ci/stripe_test_fixtures.mjs`
  // never reports only the file's own implicit entry.
  test("validateFixturePrice accepts a well-formed sandbox recurring Price and rejects a live-mode one", () => {
    const price = {
      id: "price_basic_fixture",
      object: "price",
      active: true,
      currency: "usd",
      livemode: false,
      lookup_key: FIXTURES[0].lookupKey,
      recurring: { interval: "month", interval_count: 1 },
      type: "recurring",
      unit_amount: FIXTURES[0].unitAmount,
    };
    assert.equal(validateFixturePrice(price, FIXTURES[0]), "price_basic_fixture");
    assert.throws(() => validateFixturePrice({ ...price, livemode: true }, FIXTURES[0]), /sandbox/);
  });
} else if (invokedAsEntrypoint) {
  main().catch((error) => {
    console.error(`stripe test fixtures: FAIL: ${error.message}`);
    process.exitCode = 1;
  });
}
