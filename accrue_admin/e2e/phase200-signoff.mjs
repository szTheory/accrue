import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export function generatePhase200Signoff() {
  throw new Error("Phase 200 sign-off generator is not implemented yet.");
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-signoff-red-"));
  try {
    const failures = [];
    try {
      generatePhase200Signoff({ phaseDir: root, dryRun: true, write: false });
    } catch (error) {
      failures.push(error.message);
    }

    assertSelfTest("generator writes verifier-clean REJECT when final evidence is absent", failures.some((message) => /reject/i.test(message)));
    assertSelfTest("generator references every locked Phase 200 artifact", failures.some((message) => /artifact/i.test(message)));
    assertSelfTest("generator names blocking repair IDs", failures.some((message) => /repair/i.test(message)));
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (const arg of argv) {
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--dry-run") options.dryRun = true;
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

  return generatePhase200Signoff(options);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 sign-off generator failed: ${error.message}`);
    process.exitCode = 1;
  }
}
