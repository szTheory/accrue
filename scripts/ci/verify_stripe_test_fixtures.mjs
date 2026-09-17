#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import {
  FIXTURES,
  appendGitHubEnvironment,
  resolveStripeTestFixtures,
  validateFixturePrice,
} from "./stripe_test_fixtures.mjs";

const secret = "sk_test_fixture_only_not_a_real_key";

function stripePrice(fixture, overrides = {}) {
  return {
    id: `price_${fixture.label}_fixture`,
    object: "price",
    active: true,
    currency: "usd",
    livemode: false,
    lookup_key: fixture.lookupKey,
    recurring: { interval: "month", interval_count: 1 },
    type: "recurring",
    unit_amount: fixture.unitAmount,
    ...overrides,
  };
}

function response(body, { ok = true, status = 200 } = {}) {
  return { ok, status, json: async () => body };
}

async function existingFixtureCase() {
  const calls = [];
  const fetchImpl = async (url, options) => {
    calls.push({ url, options });
    const fixture = url.includes(FIXTURES[0].lookupKey) ? FIXTURES[0] : FIXTURES[1];
    return response({ data: [stripePrice(fixture)] });
  };
  const values = await resolveStripeTestFixtures({ fetchImpl, secretKey: secret });
  assert.deepEqual(values, {
    ACCRUE_LIVE_BASIC_PRICE: "price_basic_fixture",
    ACCRUE_LIVE_PRO_PRICE: "price_pro_fixture",
  });
  assert.equal(calls.length, 2);
  assert.ok(calls.every(({ options }) => options.method === undefined), "existing fixtures use read-only lookup requests");
  assert.ok(calls.every(({ options }) => options.headers.Authorization.startsWith("Basic ")), "requests authenticate without putting the key in the URL");
  assert.ok(calls.every(({ url }) => !url.includes(secret)), "the key never appears in a request URL");
}

async function creationCase() {
  const calls = [];
  const remaining = new Map(FIXTURES.map((fixture) => [fixture.lookupKey, true]));
  const fetchImpl = async (url, options) => {
    calls.push({ url, options });
    if (options.method !== "POST") return response({ data: [] });
    const lookupKey = options.body.get("lookup_key");
    const fixture = FIXTURES.find((candidate) => candidate.lookupKey === lookupKey);
    assert.ok(fixture, "creation uses a known lookup key");
    assert.equal(options.body.get("recurring[interval]"), "month");
    assert.equal(options.body.get("currency"), "usd");
    assert.equal(options.body.get("unit_amount"), String(fixture.unitAmount));
    assert.equal(remaining.delete(lookupKey), true, "each fixture is created once");
    return response(stripePrice(fixture));
  };
  const values = await resolveStripeTestFixtures({ fetchImpl, secretKey: secret });
  assert.equal(calls.filter(({ options }) => options.method === "POST").length, 2);
  assert.equal(remaining.size, 0);
  assert.notEqual(values.ACCRUE_LIVE_BASIC_PRICE, values.ACCRUE_LIVE_PRO_PRICE);
}

async function rejectsCase(fetchImpl, pattern) {
  await assert.rejects(resolveStripeTestFixtures({ fetchImpl, secretKey: secret }), pattern);
}

async function negativeCases() {
  await assert.rejects(resolveStripeTestFixtures({ fetchImpl: async () => response({ data: [] }), secretKey: "" }), /required/);
  await assert.rejects(resolveStripeTestFixtures({ fetchImpl: async () => response({ data: [] }), secretKey: "rk_test_wrong_shape" }), /sk_test_/);
  await rejectsCase(async () => response({ data: [stripePrice(FIXTURES[0]), stripePrice(FIXTURES[0], { id: "price_duplicate" })] }), /more than one/);

  for (const [overrides, pattern] of [
    [{ livemode: true }, /sandbox/],
    [{ active: false }, /active/],
    [{ currency: "eur" }, /currency/],
    [{ unit_amount: 999 }, /amount/],
    [{ recurring: { interval: "year", interval_count: 1 } }, /monthly/],
    [{ lookup_key: "wrong" }, /lookup key/],
  ]) {
    await rejectsCase(async (url) => {
      const fixture = url.includes(FIXTURES[0].lookupKey) ? FIXTURES[0] : FIXTURES[1];
      return response({ data: [stripePrice(fixture, overrides)] });
    }, pattern);
  }

  let message = "";
  try {
    await resolveStripeTestFixtures({
      fetchImpl: async () => response({ error: { message: `provider echoed ${secret}` } }, { ok: false, status: 401 }),
      secretKey: secret,
    });
  } catch (error) {
    message = error.message;
  }
  assert.match(message, /http=401/);
  assert.doesNotMatch(message, /provider echoed|sk_test_/);
}

function environmentFileCase() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "stripe-fixtures-"));
  const file = path.join(directory, "github-env");
  try {
    appendGitHubEnvironment(file, {
      ACCRUE_LIVE_BASIC_PRICE: "price_basic_fixture",
      ACCRUE_LIVE_PRO_PRICE: "price_pro_fixture",
    });
    assert.equal(
      fs.readFileSync(file, "utf8"),
      "ACCRUE_LIVE_BASIC_PRICE=price_basic_fixture\nACCRUE_LIVE_PRO_PRICE=price_pro_fixture\n",
    );
    assert.throws(() => appendGitHubEnvironment(file, {
      ACCRUE_LIVE_BASIC_PRICE: "price_bad\nINJECTED=value",
      ACCRUE_LIVE_PRO_PRICE: "price_pro_fixture",
    }), /invalid Price id/);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

async function main() {
  assert.equal(validateFixturePrice(stripePrice(FIXTURES[0]), FIXTURES[0]), "price_basic_fixture");
  await existingFixtureCase();
  await creationCase();
  await negativeCases();
  environmentFileCase();
  console.log("stripe test fixture contracts: PASS");
}

// D-29 (232-08): this file previously had NO entrypoint guard at all -- its
// four assertion cases ran unconditionally as a side effect of import, via a
// bare `main().catch(...)` at module scope. isMainModule() throws (never
// returns a silent false) when there is no invoking entrypoint; that throw
// must not crash a bare import, so it is caught and treated as "not the
// entrypoint" (established pattern, main_module.mjs).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  // Non-vacuity: each existing assertion case registered as its own named
  // node:test entry, so `node --test --test-reporter=tap
  // scripts/ci/verify_stripe_test_fixtures.mjs` reports real named TAP
  // entries rather than only the file's own implicit one.
  test("validateFixturePrice accepts a well-formed basic sandbox Price", () => {
    assert.equal(validateFixturePrice(stripePrice(FIXTURES[0]), FIXTURES[0]), "price_basic_fixture");
  });
  test("resolveStripeTestFixtures reuses an existing matching Price via a read-only lookup", async () => { await existingFixtureCase(); });
  test("resolveStripeTestFixtures creates a Price for each fixture not yet present", async () => { await creationCase(); });
  test("resolveStripeTestFixtures rejects malformed keys, ambiguous lookups, and drifted fixture shapes without leaking the key", async () => { await negativeCases(); });
  test("appendGitHubEnvironment writes resolved Price ids and rejects an injected value", () => { environmentFileCase(); });
} else if (invokedAsEntrypoint) {
  main().catch((error) => {
    console.error(`stripe test fixture contracts: FAIL: ${error.message}`);
    process.exitCode = 1;
  });
}
