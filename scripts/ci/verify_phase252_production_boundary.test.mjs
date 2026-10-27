import assert from "node:assert/strict";
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import {
  nodeExecutablesOnPath,
  supportedHexPackageOptions,
  verifyProductionBoundary,
} from "./verify_phase252_production_boundary.mjs";

function cleanAdminPackage() {
  return {
    packageName: "accrue_admin",
    files: [
      "mix.exs",
      "lib/accrue_admin/live/subscription_live.ex",
      "priv/static/accrue_admin.css",
      "priv/static/accrue_admin.js",
      "priv/static/storybook.css",
      "priv/static/storybook.js",
      "priv/static/fonts/geist-sans-vf.woff2",
      "priv/static/fonts/geist-mono-vf.woff2",
    ],
    compilePaths: ["lib"],
    dependencies: [{ name: "phoenix_storybook", only: ["dev", "test"], runtime: true }],
    compiledModules: ["accrue_admin_live_subscription_live"],
    sourceFiles: [
      {
        path: "lib/accrue_admin/live/subscription_live.ex",
        content: "defmodule AccrueAdmin.Live.SubscriptionLive do\nend\n",
      },
    ],
    pathEntries: [],
  };
}

test("rejects a known leaked scenario manifest from the actual package file set", () => {
  const input = cleanAdminPackage();
  input.files.push("storybook/phase252-manifest.json");

  const result = verifyProductionBoundary(input);

  assert.equal(result.ok, false);
  assert.match(result.errors.join("\n"), /phase252-manifest\.json/);
});

test("rejects a production source import of the Storybook fixture adapter", () => {
  const input = cleanAdminPackage();
  input.sourceFiles[0].content =
    "alias AccrueAdmin.Storybook.SubscriptionScenarios\n" + input.sourceFiles[0].content;

  const result = verifyProductionBoundary(input);

  assert.equal(result.ok, false);
  assert.match(result.errors.join("\n"), /SubscriptionScenarios/);
});

test("rejects PhoenixStorybook in production dependency scope", () => {
  const input = cleanAdminPackage();
  input.dependencies = [{ name: "phoenix_storybook", only: ["prod"], runtime: true }];

  const result = verifyProductionBoundary(input);

  assert.equal(result.ok, false);
  assert.match(result.errors.join("\n"), /phoenix_storybook/);
});

test("rejects Node and npm executables from the production compile PATH", () => {
  const directory = mkdtempSync(path.join(tmpdir(), "phase252-node-path-"));

  try {
    writeFileSync(path.join(directory, "node"), "#!/bin/sh\nexit 0\n", { mode: 0o755 });
    chmodSync(path.join(directory, "node"), 0o755);
    const input = cleanAdminPackage();
    input.pathEntries = [directory];

    const result = verifyProductionBoundary(input);

    assert.equal(result.ok, false);
    assert.match(result.errors.join("\n"), /Node|node/);
    assert.deepEqual(nodeExecutablesOnPath([directory]), ["node"]);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test("accepts a clean package with inert Storybook assets and supported Hex extraction flags", () => {
  const result = verifyProductionBoundary(cleanAdminPackage());

  assert.equal(result.ok, true, result.errors.join("\n"));
  assert.equal(
    supportedHexPackageOptions("mix hex.build\n  * --unpack\n  * -o, --output PATH"),
    true,
  );
  assert.equal(supportedHexPackageOptions("mix hex.build\n  * --output PATH"), false);
});
