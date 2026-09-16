// scripts/ci/main_module.mjs
//
// D-29: shared, correct module-boundary guard. Both idioms it replaces
// (an argv[1]-to-file-URL pathname comparison, and its file:// URL-template
// counterpart) silently evaluate false when
// the repository checkout path contains a space -- a merge-blocking gate's
// main() never runs, the script prints nothing, and it exits 0. This helper
// resolves both sides through realpath so a space, symlink, or relative
// argv[1] all still compare correctly, and it throws rather than returning a
// silent false when process.argv[1] is empty (D-29). Do not read the
// import-meta "main" boolean here (D-30): it is undefined on the Node line
// this repo pins, and it is unfactorable inside a helper -- it would
// describe this helper's own invocation, not the caller's.
//
// This file is a library module only: it exports isMainModule and nothing
// else, and it has no CLI entrypoint / main() of its own.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";

export function isMainModule(moduleUrl) {
  const invoked = process.argv[1];
  if (!invoked) {
    throw new Error("isMainModule: process.argv[1] is empty -- cannot determine the invoking entrypoint");
  }
  const modulePath = realpathSync(fileURLToPath(moduleUrl));
  const invokedPath = realpathSync(invoked);
  return modulePath === invokedPath;
}

if (process.env.NODE_TEST_CONTEXT) {
  const SELF_SOURCE = fs.readFileSync(fileURLToPath(import.meta.url), "utf8");

  function withScratch(prefix, fn) {
    const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), prefix));
    try {
      return fn(dir);
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }

  // Copies this file's own source into the scratch dir as main_module.mjs so
  // a probe script placed alongside it can `import { isMainModule } from
  // "./main_module.mjs"` -- the same methodology the Task 1 verify block
  // uses (232-RESEARCH.md DRIFT-3's probe approach).
  function seedHelper(dir) {
    fs.writeFileSync(path.join(dir, "main_module.mjs"), SELF_SOURCE);
  }

  function writeProbe(dir, filename = "probe.mjs") {
    const probePath = path.join(dir, filename);
    fs.writeFileSync(
      probePath,
      [
        'import { isMainModule } from "./main_module.mjs";',
        'process.stdout.write(isMainModule(import.meta.url) ? "MAIN" : "NOT_MAIN");',
        ""
      ].join("\n")
    );
    return probePath;
  }

  // NODE_TEST_CONTEXT must NOT propagate to the spawned probe process: node:test
  // auto-runs any registered tests when a file that imports "node:test" is
  // executed directly (not just under `node --test`), so an inherited
  // NODE_TEST_CONTEXT would make the probe's own copied main_module.mjs
  // recursively register and spawn its own probes. Clear it explicitly.
  function runNode(args, options = {}) {
    const result = spawnSync(process.execPath, args, {
      encoding: "utf8",
      timeout: 20000,
      ...options,
      env: { ...process.env, NODE_TEST_CONTEXT: "", ...options.env }
    });
    if (result.error) throw result.error;
    return result;
  }

  test("a probe script invoked directly from a space-containing directory reports itself as the main module", () => {
    withScratch("gsd main_module space test ", (dir) => {
      seedHelper(dir);
      const probePath = writeProbe(dir);
      const result = runNode([probePath]);
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.stdout, "MAIN");
    });
  });

  test("the same probe script, imported by a different entrypoint, reports it is NOT the main module", () => {
    withScratch("gsd-main-module-import-test-", (dir) => {
      seedHelper(dir);
      writeProbe(dir);
      const importerPath = path.join(dir, "importer.mjs");
      fs.writeFileSync(importerPath, 'import "./probe.mjs";\n');
      const result = runNode([importerPath]);
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.stdout, "NOT_MAIN");
    });
  });

  test("a symlink to the probe script, invoked through the symlink path, reports itself as the main module", () => {
    withScratch("gsd-main-module-symlink-test-", (dir) => {
      seedHelper(dir);
      const probePath = writeProbe(dir);
      const linkPath = path.join(dir, "link.mjs");
      fs.symlinkSync(probePath, linkPath);
      const result = runNode([linkPath]);
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.stdout, "MAIN");
    });
  });

  test("the probe script invoked through a relative argv[1] reports itself as the main module", () => {
    withScratch("gsd-main-module-relative-test-", (dir) => {
      seedHelper(dir);
      writeProbe(dir);
      const result = runNode(["./probe.mjs"], { cwd: dir });
      assert.equal(result.status, 0, result.stderr);
      assert.equal(result.stdout, "MAIN");
    });
  });

  test("isMainModule throws naming process.argv[1] when it is empty, rather than returning a silent false", () => {
    const original = process.argv[1];
    try {
      process.argv[1] = "";
      assert.throws(() => isMainModule(import.meta.url), /process\.argv\[1\]/);
      process.argv[1] = undefined;
      assert.throws(() => isMainModule(import.meta.url), /process\.argv\[1\]/);
    } finally {
      process.argv[1] = original;
    }
  });
}
