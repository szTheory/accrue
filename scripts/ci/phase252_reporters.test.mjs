import assert from "node:assert/strict";
import test from "node:test";
import * as reporters from "./phase252_reporters.mjs";

// Phase 254 (CIQ-04): the browser reporter must keep per-test durations while
// still rejecting every failed, skipped, retried or flaky result. The parser is
// reached through its public export so a consumer cannot depend on a private
// shape. Optional calls keep a missing export a failing assertion, not a crash.

function parse(output) {
  return reporters.parsePlaywrightJson?.(output);
}

function spec(title, { status = "passed", expectedStatus = "passed", duration = 100, results } = {}) {
  return {
    title,
    ok: status === "passed",
    tests: [{ title, expectedStatus, results: results ?? [{ status, duration }] }],
  };
}

function report({ specs, stats, errors = [], status } = {}) {
  const body = {
    suites: [{ title: "file.spec.js", specs: specs.slice(0, 1), suites: [{ title: "nested", specs: specs.slice(1) }] }],
    stats: { expected: specs.length, unexpected: 0, skipped: 0, flaky: 0, ...stats },
    errors,
  };
  if (status !== undefined) body.status = status;
  return JSON.stringify(body);
}

const passing = () => report({ specs: [spec("first", { duration: 111 }), spec("second", { duration: 222 }), spec("third", { duration: 333 })] });

test("parsePlaywrightJson returns each test's first-result duration alongside its identity", () => {
  const result = parse(passing());
  assert.deepEqual(result?.durations, [
    { identity: "first", duration_ms: 111 },
    { identity: "second", duration_ms: 222 },
    { identity: "third", duration_ms: 333 },
  ]);
});

test("parsePlaywrightJson keeps the prior identities/count/skipped/failed fields unchanged", () => {
  const result = parse(passing());
  assert.deepEqual(result?.identities, ["first", "second", "third"]);
  assert.equal(result?.count, 3);
  assert.equal(result?.skipped, 0);
  assert.equal(result?.failed, 0);
  assert.deepEqual(Object.keys(result ?? {}).sort(), ["count", "durations", "failed", "identities", "skipped"]);
});

test("parsePlaywrightJson rejects a skipped browser result", () => {
  const output = report({
    specs: [spec("kept"), spec("skipped one", { status: "skipped", expectedStatus: "skipped", results: [] })],
    stats: { expected: 1, skipped: 1 },
  });
  assert.throws(() => parse(output), /contains no expected tests, failed, skipped, or flaky tests/);
});

test("parsePlaywrightJson rejects a retried browser result", () => {
  const output = report({
    specs: [spec("retried", { results: [{ status: "failed", duration: 5 }, { status: "passed", duration: 6 }] })],
  });
  assert.throws(() => parse(output), /failed, skipped, retried, or missing a result/);
});

test("parsePlaywrightJson rejects a flaky browser summary", () => {
  const output = report({ specs: [spec("flaky")], stats: { flaky: 1 } });
  assert.throws(() => parse(output), /contains no expected tests, failed, skipped, or flaky tests/);
});

test("parsePlaywrightJson rejects a failed browser result", () => {
  const failed = report({ specs: [spec("broken", { status: "failed" })], stats: { expected: 0, unexpected: 1 } });
  assert.throws(() => parse(failed), /contains no expected tests, failed, skipped, or flaky tests/);
  const failedSpecOnly = report({ specs: [spec("broken", { status: "failed" })] });
  assert.throws(() => parse(failedSpecOnly), /browser spec did not pass: broken/);
});

test("parsePlaywrightJson positive control: the passing fixture is accepted, so the rejection tests above can fail", () => {
  assert.doesNotThrow(() => parse(passing()));
  assert.equal(typeof reporters.parsePlaywrightJson, "function");
});

test("parsePlaywrightJson keeps a result without a duration as null so older fixtures still parse", () => {
  const output = report({ specs: [spec("legacy", { results: [{ status: "passed" }] })] });
  assert.deepEqual(parse(output)?.durations, [{ identity: "legacy", duration_ms: null }]);
});
