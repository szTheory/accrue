import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export function generatePhase200JudgeFindings() {
  throw new Error("Phase 200 judge generator is not implemented yet.");
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-judge-red-"));
  try {
    const failures = [];
    try {
      generatePhase200JudgeFindings({ phaseDir: root, dryRun: true, write: false });
    } catch (error) {
      failures.push(error.message);
    }

    assertSelfTest("positive fixture produces zero blocking findings", failures.some((message) => /positive/i.test(message)));
    assertSelfTest("missing artifacts produce BLOCKER findings", failures.some((message) => /missing artifact/i.test(message)));
    assertSelfTest("non-empty regressions produce BLOCKER findings", failures.some((message) => /regression/i.test(message)));
    assertSelfTest("coverage downgrade produces BLOCKER findings", failures.some((message) => /coverage/i.test(message)));
    assertSelfTest("host leak evidence produces BLOCKER findings", failures.some((message) => /host leak/i.test(message)));
    assertSelfTest("invalid lens is rejected", failures.some((message) => /lens/i.test(message)));
    assertSelfTest("blocking findings without locked refs are rejected", failures.some((message) => /locked reference/i.test(message)));
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

  return generatePhase200JudgeFindings(options);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 judge generator failed: ${error.message}`);
    process.exitCode = 1;
  }
}
