import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export function verifyPhase200Signoff() {
  throw new Error("Phase 200 sign-off verifier is not implemented yet.");
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-signoff-verifier-red-"));
  try {
    const failures = [];
    try {
      verifyPhase200Signoff({ signoffPath: path.join(root, "200-SIGN-OFF.md") });
    } catch (error) {
      failures.push(error.message);
    }

    assertSelfTest("exact ACCEPT/REJECT final line is enforced", failures.some((message) => /Final maintainer decision/i.test(message)));
    assertSelfTest("ACCEPT with regressions fails", failures.some((message) => /regression/i.test(message)));
    assertSelfTest("ACCEPT with unresolved blocking findings fails", failures.some((message) => /BLOCKER|REPAIR-IN-PHASE/i.test(message)));
    assertSelfTest("ACCEPT with missing required artifacts fails", failures.some((message) => /artifact/i.test(message)));
    assertSelfTest("REJECT draft can be structurally verifier-clean", failures.some((message) => /REJECT/i.test(message)));
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

  return verifyPhase200Signoff(options);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 sign-off verifier failed: ${error.message}`);
    process.exitCode = 1;
  }
}
