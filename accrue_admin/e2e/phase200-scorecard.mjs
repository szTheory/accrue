import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export function generatePhase200Scorecard() {
  throw new Error("Phase 200 scorecard generator is not implemented yet.");
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-scorecard-red-"));
  try {
    const failures = [];
    try {
      generatePhase200Scorecard({ root, dryRun: true, write: false });
    } catch (error) {
      failures.push(error.message);
    }

    assertSelfTest("duplicate union ID failures are covered", failures.some((message) => /duplicate/i.test(message)));
    assertSelfTest("score downgrade failures are covered", failures.some((message) => /score/i.test(message)));
    assertSelfTest("missing evidence failures are covered", failures.some((message) => /evidence/i.test(message)));
    assertSelfTest("coverage downgrade failures are covered", failures.some((message) => /coverage/i.test(message)));
    assertSelfTest("p193 pending closure failures are covered", failures.some((message) => /p193/i.test(message)));
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

  return generatePhase200Scorecard(options);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 scorecard reducer failed: ${error.message}`);
    process.exitCode = 1;
  }
}
