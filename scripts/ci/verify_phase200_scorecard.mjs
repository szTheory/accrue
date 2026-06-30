import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export function verifyPhase200Scorecard() {
  throw new Error("Phase 200 scorecard verifier is not implemented yet.");
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-verifier-red-"));
  try {
    const failures = [];
    try {
      verifyPhase200Scorecard({ root });
    } catch (error) {
      failures.push(error.message);
    }

    assertSelfTest("valid passing artifacts are covered", failures.some((message) => /valid/i.test(message)));
    assertSelfTest("non-empty regressions fail", failures.some((message) => /regressions/i.test(message)));
    assertSelfTest("missing evidence fails", failures.some((message) => /evidence/i.test(message)));
    assertSelfTest("bad manifest refs fail", failures.some((message) => /manifest/i.test(message)));
    assertSelfTest("stale pending p193 rows fail", failures.some((message) => /p193/i.test(message)));
    assertSelfTest("malformed JSON fails", failures.some((message) => /json/i.test(message)));
    assertSelfTest("duplicate cell IDs fail", failures.some((message) => /duplicate/i.test(message)));
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (const arg of argv) {
    if (arg === "--self-test") options.selfTest = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return options;
}

export function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.selfTest) {
    runSelfTest();
    return { ok: true };
  }

  return verifyPhase200Scorecard(options);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 scorecard verifier crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
