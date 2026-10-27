import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  accessSync,
  chmodSync,
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  realpathSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const SCRIPT_PATH = fileURLToPath(import.meta.url);
const REPO_ROOT = path.resolve(path.dirname(SCRIPT_PATH), "../..");
const NODE_TOOL_NAMES = ["node", "npm", "npx"];

const PACKAGE_POLICY = Object.freeze({
  accrue: {
    requiredFiles: [
      "mix.exs",
      "lib/accrue/application.ex",
      "lib/accrue/billing/subscription.ex",
      "priv/static/brand.css",
    ],
  },
  accrue_admin: {
    requiredFiles: [
      "mix.exs",
      "lib/accrue_admin/live/subscription_live.ex",
      "priv/static/accrue_admin.css",
      "priv/static/accrue_admin.js",
      "priv/static/storybook.css",
      "priv/static/storybook.js",
      "priv/static/fonts/geist-sans-vf.woff2",
      "priv/static/fonts/geist-mono-vf.woff2",
    ],
  },
  accrue_portal: {
    requiredFiles: [
      "mix.exs",
      "lib/accrue_portal/router.ex",
      "priv/static/accrue_portal.css",
      "priv/static/accrue_portal.js",
    ],
  },
});

const FORBIDDEN_PACKAGE_PATHS = [
  /(^|\/)dev_support\/ui_scenarios\//i,
  /(^|\/)cadence_subscriptions\.exs$/i,
  /(^|\/)storybook\/_support\/subscription_scenarios\.ex$/i,
  /(^|\/)storybook\/components\/subscription_detail\.story\.exs$/i,
  /(^|\/)phase252-manifest\.json$/i,
  /(^|\/)phase252_lab\.mjs$/i,
  /(^|\/)verify_phase252_production_boundary(?:\.test)?\.mjs$/i,
  /(^|\/)phase252-story-helpers\.js$/i,
  /(^|\/)subscription-stories-phase252\.spec\.js$/i,
  /(^|\/)test\/accrue_admin\/dev\/subscription_production_boundary_test\.exs$/i,
];

const FORBIDDEN_SOURCE_TOKENS = [
  "CadenceSubscriptionFacts",
  "AccrueAdmin.Storybook.SubscriptionScenarios",
  "AccrueAdmin.Storybook.SubscriptionManifest",
  "cadence_subscriptions.exs",
  "subscription_scenarios.ex",
  "phase252-manifest.json",
  "phase252_lab.mjs",
  "phase252-story-helpers.js",
  "subscription-stories-phase252.spec.js",
];

const FORBIDDEN_MODULES = [
  "cadence_subscription_facts",
  "subscription_scenarios",
  "subscription_manifest",
];

const NODE_FREE_TOOLS = [
  "bash",
  "sh",
  "env",
  "git",
  "make",
  "cc",
  "clang",
  "gcc",
  "cargo",
  "rustc",
  "cmake",
  "pkg-config",
  "python3",
  "tar",
  "gzip",
  "xz",
  "bzip2",
  "sed",
  "grep",
  "awk",
  "find",
  "dirname",
  "basename",
  "mkdir",
  "cp",
  "rm",
  "chmod",
  "ln",
  "touch",
  "date",
  "uname",
  "ps",
  "perl",
  "rebar3",
  "curl",
  "openssl",
  "ar",
  "ld",
  "as",
  "which",
];

const SYSTEM_PATH_CANDIDATES = ["/usr/bin", "/bin", "/usr/sbin", "/sbin"];

function executable(filePath) {
  try {
    accessSync(filePath, 1);
    return true;
  } catch {
    return false;
  }
}

function normalizePackagePath(value) {
  return String(value).replaceAll("\\", "/").replace(/^\.\//, "");
}

function pathContainsNodeTool(pathEntry, name) {
  return executable(path.join(pathEntry, name));
}

export function nodeExecutablesOnPath(pathEntries) {
  return NODE_TOOL_NAMES.filter((name) =>
    (pathEntries || []).some((entry) => pathContainsNodeTool(entry, name)),
  );
}

export function supportedHexPackageOptions(helpText) {
  return /--unpack\b/.test(helpText) && /(?:-o\s*,\s*)?--output\b/.test(helpText);
}

export function verifyProductionBoundary(input) {
  const errors = [];
  const packageName = String(input?.packageName || "");
  const policy = PACKAGE_POLICY[packageName];

  if (!policy) {
    errors.push(`unknown package policy: ${packageName || "<missing>"}`);
    return { ok: false, errors };
  }

  const packageFiles = Array.isArray(input.files) ? input.files.map(normalizePackagePath) : [];
  const fileSet = new Set(packageFiles);
  for (const requiredFile of policy.requiredFiles) {
    if (!fileSet.has(requiredFile)) errors.push(`required production package file is missing: ${requiredFile}`);
  }

  for (const packageFile of packageFiles) {
    if (path.posix.isAbsolute(packageFile) || packageFile.split("/").includes("..")) {
      errors.push(`unsafe package path: ${packageFile}`);
    }
    const pattern = FORBIDDEN_PACKAGE_PATHS.find((candidate) => candidate.test(packageFile));
    if (pattern) errors.push(`forbidden tooling or scenario package file: ${packageFile}`);
  }

  const compilePaths = Array.isArray(input.compilePaths)
    ? input.compilePaths.map(normalizePackagePath).sort()
    : [];
  if (compilePaths.length !== 1 || compilePaths[0] !== "lib") {
    errors.push(`production compile roots must be exactly lib; found ${compilePaths.join(", ") || "none"}`);
  }

  for (const dependency of Array.isArray(input.dependencies) ? input.dependencies : []) {
    if (String(dependency?.name).toLowerCase() !== "phoenix_storybook") continue;
    const scope = Array.isArray(dependency.only)
      ? dependency.only.map((entry) => String(entry).toLowerCase())
      : [];
    if (scope.length === 0 || scope.includes("prod") || scope.includes("production")) {
      errors.push("phoenix_storybook is present in the production dependency scope");
    }
  }

  for (const moduleName of Array.isArray(input.compiledModules) ? input.compiledModules : []) {
    const normalized = String(moduleName).replace(/\.beam$/i, "").toLowerCase();
    if (FORBIDDEN_MODULES.some((token) => normalized.includes(token))) {
      errors.push(`scenario or Storybook adapter module was compiled for production: ${moduleName}`);
    }
  }

  const runtimeMetadata = String(input.runtimeMetadata || "").toLowerCase();
  if (runtimeMetadata.includes("phoenix_storybook")) {
    errors.push("production application metadata includes phoenix_storybook");
  }
  for (const token of FORBIDDEN_MODULES) {
    if (runtimeMetadata.includes(token)) errors.push(`production application metadata includes ${token}`);
  }

  for (const sourceFile of Array.isArray(input.sourceFiles) ? input.sourceFiles : []) {
    const content = String(sourceFile?.content || "");
    for (const token of FORBIDDEN_SOURCE_TOKENS) {
      if (content.includes(token)) {
        errors.push(`production source ${sourceFile.path || "<unknown>"} references tooling or scenario token ${token}`);
      }
    }
  }

  const nodeTools = nodeExecutablesOnPath(input.pathEntries || []);
  if (nodeTools.length > 0) {
    errors.push(`Node build tools are available on the production compile PATH: ${nodeTools.join(", ")}`);
  }

  return { ok: errors.length === 0, errors };
}

function findExecutable(pathEntries, name) {
  for (const entry of pathEntries) {
    if (/(^|[\\/])\.asdf[\\/]shims$/i.test(entry)) continue;
    const candidate = path.join(entry, name);
    if (executable(candidate)) return candidate;
  }
  return null;
}

function asdfInstallRoot(root, plugin) {
  const originalPath = (process.env.PATH || "").split(path.delimiter);
  const asdf = findExecutable(originalPath, "asdf") || "/opt/homebrew/bin/asdf";
  const result = spawnSync(asdf, ["where", plugin], {
    cwd: root,
    env: process.env,
    encoding: "utf8",
    shell: false,
    stdio: ["ignore", "pipe", "ignore"],
    maxBuffer: 1024 * 1024,
  });
  if (result.error || result.status !== 0) return null;
  const resolved = result.stdout.trim();
  return resolved && path.isAbsolute(resolved) ? resolved : null;
}

function linkExecutable(binDirectory, name, target) {
  if (!target || !executable(target)) return false;
  const destination = path.join(binDirectory, name);
  if (!existsSync(destination)) symlinkSync(target, destination);
  return true;
}

function createNodeFreeEnvironment(root, temporaryRoot) {
  const originalPathEntries = (process.env.PATH || "").split(path.delimiter).filter(Boolean);
  const elixirRoot = asdfInstallRoot(root, "elixir");
  const erlangRoot = asdfInstallRoot(root, "erlang");
  const binDirectory = path.join(temporaryRoot, "node-free-bin");
  mkdirSync(binDirectory, { recursive: true });

  const required = [
    ["mix", elixirRoot && path.join(elixirRoot, "bin", "mix")],
    ["elixir", elixirRoot && path.join(elixirRoot, "bin", "elixir")],
    ["elixirc", elixirRoot && path.join(elixirRoot, "bin", "elixirc")],
    ["erl", erlangRoot && path.join(erlangRoot, "bin", "erl")],
    ["erlc", erlangRoot && path.join(erlangRoot, "bin", "erlc")],
    ["escript", erlangRoot && path.join(erlangRoot, "bin", "escript")],
  ];
  const missing = required.filter(([name, target]) => !linkExecutable(binDirectory, name, target)).map(([name]) => name);
  if (missing.length > 0) {
    throw new Error(`cannot construct a Node-free BEAM tool path; missing ${missing.join(", ")}`);
  }

  for (const name of NODE_FREE_TOOLS) {
    const target = findExecutable(originalPathEntries, name);
    if (target) linkExecutable(binDirectory, name, target);
  }

  const safeSystemDirectories = SYSTEM_PATH_CANDIDATES.filter(
    (entry) => existsSync(entry) && nodeExecutablesOnPath([entry]).length === 0,
  );
  const pathEntries = [binDirectory, ...safeSystemDirectories];
  const nodeTools = nodeExecutablesOnPath(pathEntries);
  if (nodeTools.length > 0) {
    throw new Error(`could not remove Node tools from the production PATH: ${nodeTools.join(", ")}`);
  }

  return {
    binDirectory,
    pathEntries,
    pathValue: pathEntries.join(path.delimiter),
    mixPath: path.join(binDirectory, "mix"),
    elixirPath: path.join(binDirectory, "elixir"),
  };
}

function mixEnvironment(nodeFreePath, buildPath) {
  return {
    ...process.env,
    MIX_ENV: "prod",
    MIX_BUILD_PATH: buildPath,
    PATH: nodeFreePath.pathValue,
  };
}

function seedDependencyHeaders(projectRoot, buildPath) {
  // JOSE resolves its checked-in record headers through :code.lib_dir(:jose)
  // while it is being compiled. A clean external MIX_BUILD_PATH has no app
  // directory yet, so expose only the source header tree there; all BEAM and
  // app artifacts are still compiled into this run's isolated build path.
  const joseHeaders = path.resolve(projectRoot, "deps", "jose", "include");
  if (!existsSync(joseHeaders)) return;

  const destination = path.join(buildPath, "lib", "jose", "include");
  mkdirSync(path.dirname(destination), { recursive: true });
  if (!existsSync(destination)) cpSync(joseHeaders, destination, { recursive: true });
}

function safeDiagnostic(output) {
  const home = os.homedir();
  return String(output || "")
    .replaceAll(home, "<home>")
    .split("\n")
    .slice(-30)
    .join("\n")
    .trim();
}

function runTool(command, args, options) {
  const result = spawnSync(command, args, {
    cwd: options.cwd,
    env: options.env,
    encoding: "utf8",
    shell: false,
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 32 * 1024 * 1024,
    timeout: options.timeout || 10 * 60 * 1000,
  });

  if (result.error) throw new Error(`${options.label} could not run: ${result.error.message}`);
  if (result.status !== 0) {
    const details = safeDiagnostic(`${result.stdout || ""}\n${result.stderr || ""}`);
    throw new Error(`${options.label} failed with exit ${result.status}${details ? `:\n${details}` : "."}`);
  }
  return result.stdout || "";
}

function projectProbe(projectRoot, nodeFreePath, env) {
  const projectFile = path.join(projectRoot, "mix.exs");
  const code = String.raw`
Mix.start()
Mix.env(:prod)
[{module, _bytecode}] = Code.compile_file(System.fetch_env!("PHASE252_MIX_PROJECT_FILE"))
config = apply(module, :project, [])
IO.puts("app=#{config[:app]}")
IO.puts("compile_paths=#{Enum.join(config[:elixirc_paths], "|")}")
IO.puts("package_files=#{Enum.join(config[:package][:files], "|")}")
storybook = Enum.find(config[:deps], fn dep -> elem(dep, 0) == :phoenix_storybook end)
{scope, runtime} = case storybook do
  nil -> {"absent", "absent"}
  {_, _, opts} ->
    {opts |> Keyword.get(:only, []) |> Enum.map_join(",", &to_string/1),
     opts |> Keyword.get(:runtime, true) |> to_string()}
end
IO.puts("storybook_scope=#{scope}")
IO.puts("storybook_runtime=#{runtime}")
`;
  const output = runTool(nodeFreePath.elixirPath, ["-e", code], {
    cwd: projectRoot,
    env: { ...env, PHASE252_MIX_PROJECT_FILE: projectFile },
    label: `${path.basename(projectRoot)} production Mix metadata probe`,
  });
  const values = Object.fromEntries(
    output
      .split("\n")
      .filter((line) => line.includes("="))
      .map((line) => {
        const split = line.indexOf("=");
        return [line.slice(0, split), line.slice(split + 1)];
      }),
  );
  return {
    app: values.app,
    compilePaths: (values.compile_paths || "").split("|").filter(Boolean),
    packageFiles: (values.package_files || "").split("|").filter(Boolean),
    dependencies:
      values.storybook_scope && values.storybook_scope !== "absent"
        ? [
            {
              name: "phoenix_storybook",
              only: values.storybook_scope.split(",").filter(Boolean),
              runtime: values.storybook_runtime === "true",
            },
          ]
        : [],
  };
}

function walkFiles(directory, baseDirectory = directory) {
  if (!existsSync(directory)) return [];
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...walkFiles(absolute, baseDirectory));
    else if (entry.isFile()) files.push(path.relative(baseDirectory, absolute).split(path.sep).join("/"));
  }
  return files.sort();
}

function readProductionSources(projectRoot) {
  const libraryRoot = path.join(projectRoot, "lib");
  return walkFiles(libraryRoot)
    .filter((entry) => entry.endsWith(".ex") || entry.endsWith(".exs"))
    .map((relativePath) => ({
      path: `lib/${relativePath}`,
      content: readFileSync(path.join(libraryRoot, relativePath), "utf8"),
    }));
}

function locateUnpackedPackage(outputDirectory) {
  const candidates = [outputDirectory, ...walkDirectories(outputDirectory)];
  const roots = candidates.filter((candidate) => existsSync(path.join(candidate, "mix.exs")));
  if (roots.length !== 1) {
    throw new Error(`Hex package extraction produced ${roots.length} package roots; expected exactly one.`);
  }
  return roots[0];
}

function walkDirectories(directory) {
  if (!existsSync(directory)) return [];
  const directories = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const absolute = path.join(directory, entry.name);
    directories.push(absolute, ...walkDirectories(absolute));
  }
  return directories;
}

function compiledMetadata(buildPath, appName) {
  const ebin = path.join(buildPath, "lib", appName, "ebin");
  const appFile = path.join(ebin, `${appName}.app`);
  if (!existsSync(appFile)) throw new Error(`${appName} production application metadata was not built.`);
  return {
    compiledModules: readdirSync(ebin)
      .filter((file) => file.endsWith(".beam"))
      .map((file) => file.slice(0, -5)),
    runtimeMetadata: readFileSync(appFile, "utf8"),
  };
}

function assertBoundary(result) {
  if (!result.ok) throw new Error(result.errors.join("\n"));
}

function cleanAdminFixture(pathEntries = []) {
  return {
    packageName: "accrue_admin",
    files: PACKAGE_POLICY.accrue_admin.requiredFiles,
    compilePaths: ["lib"],
    dependencies: [{ name: "phoenix_storybook", only: ["dev", "test"], runtime: true }],
    compiledModules: ["accrue_admin_live_subscription_live"],
    runtimeMetadata: "{application, accrue_admin, [{applications, [kernel, stdlib, elixir, logger]}]}.",
    sourceFiles: [{ path: "lib/accrue_admin/live/subscription_live.ex", content: "defmodule AccrueAdmin.Live.SubscriptionLive do\nend\n" }],
    pathEntries,
  };
}

export function runSelfTest() {
  const passing = verifyProductionBoundary(cleanAdminFixture());
  assert.equal(passing.ok, true, passing.errors.join("\n"));

  const packageLeak = cleanAdminFixture();
  packageLeak.files = [...packageLeak.files, "storybook/phase252-manifest.json"];
  assert.equal(verifyProductionBoundary(packageLeak).ok, false, "manifest leak must fail");

  const sourceLeak = cleanAdminFixture();
  sourceLeak.sourceFiles[0].content = "alias AccrueAdmin.Storybook.SubscriptionScenarios";
  assert.equal(verifyProductionBoundary(sourceLeak).ok, false, "fixture import must fail");

  const dependencyLeak = cleanAdminFixture();
  dependencyLeak.dependencies = [{ name: "phoenix_storybook", only: ["prod"], runtime: true }];
  assert.equal(verifyProductionBoundary(dependencyLeak).ok, false, "production Storybook dependency must fail");

  const temporaryNodePath = mkdtempSync(path.join(os.tmpdir(), "phase252-self-test-node-"));
  try {
    const nodePath = path.join(temporaryNodePath, "node");
    writeFileSync(nodePath, "#!/bin/sh\nexit 0\n");
    chmodSync(nodePath, 0o755);
    assert.deepEqual(nodeExecutablesOnPath([temporaryNodePath]), ["node"]);
    const nodeLeak = cleanAdminFixture([temporaryNodePath]);
    assert.equal(verifyProductionBoundary(nodeLeak).ok, false, "Node on compile PATH must fail");
  } finally {
    rmSync(temporaryNodePath, { recursive: true, force: true });
  }

  assert.equal(supportedHexPackageOptions("mix hex.build --unpack -o, --output PATH"), true);
  assert.equal(supportedHexPackageOptions("mix hex.build --output PATH"), false);
  return { passed: 8 };
}

function projectDefinitionFailure(app, metadata) {
  const problems = [];
  if (metadata.app !== app) problems.push(`Mix project app mismatch: expected ${app}, got ${metadata.app || "<missing>"}`);
  if (metadata.compilePaths.length !== 1 || metadata.compilePaths[0] !== "lib") {
    problems.push(`${app} production Mix compile roots are not exactly lib`);
  }
  if (!metadata.packageFiles.includes("lib")) problems.push(`${app} package allowlist omits lib`);
  if (app === "accrue_admin") {
    const storybook = metadata.dependencies.find((dependency) => dependency.name === "phoenix_storybook");
    if (!storybook || storybook.only.includes("prod") || storybook.only.includes("production")) {
      problems.push("phoenix_storybook must remain scoped to dev/test");
    }
  } else if (metadata.dependencies.some((dependency) => dependency.name === "phoenix_storybook")) {
    problems.push(`${app} unexpectedly declares phoenix_storybook`);
  }
  return problems;
}

function buildPackage(appName, projectRoot, temporaryRoot, nodeFreePath, hexHelp, compileHelp) {
  const buildPath = path.join(temporaryRoot, "build", appName);
  const packageOutput = path.join(temporaryRoot, "packages", appName);
  mkdirSync(path.dirname(buildPath), { recursive: true });
  mkdirSync(packageOutput, { recursive: true });

  const env = mixEnvironment(nodeFreePath, buildPath);
  const metadata = projectProbe(projectRoot, nodeFreePath, env);
  const metadataErrors = projectDefinitionFailure(appName, metadata);
  if (metadataErrors.length > 0) throw new Error(metadataErrors.join("\n"));

  seedDependencyHeaders(projectRoot, buildPath);

  runTool(nodeFreePath.mixPath, ["compile", "--warnings-as-errors"], {
    cwd: projectRoot,
    env,
    label: `${appName} isolated MIX_ENV=prod compile --warnings-as-errors`,
  });

  if (!supportedHexPackageOptions(hexHelp) || !compileHelp.includes("--warnings-as-errors")) {
    throw new Error("installed Mix/Hex help no longer supports the required package extraction or warning flags");
  }
  const packageEnv = {
    ...env,
    ...(appName === "accrue_admin" ? { ACCRUE_ADMIN_HEX_RELEASE: "1" } : {}),
    ...(appName === "accrue_portal" ? { ACCRUE_PORTAL_HEX_RELEASE: "1" } : {}),
  };
  runTool(nodeFreePath.mixPath, ["hex.build", "--unpack", "--output", packageOutput], {
    cwd: projectRoot,
    env: packageEnv,
    label: `${appName} Hex package build and unpack`,
  });

  const packageRoot = locateUnpackedPackage(packageOutput);
  const packageFiles = walkFiles(packageRoot);
  const compile = compiledMetadata(buildPath, appName);
  const boundary = verifyProductionBoundary({
    packageName: appName,
    files: packageFiles,
    compilePaths: metadata.compilePaths,
    dependencies: metadata.dependencies,
    compiledModules: compile.compiledModules,
    runtimeMetadata: compile.runtimeMetadata,
    sourceFiles: readProductionSources(projectRoot),
    pathEntries: nodeFreePath.pathEntries,
  });
  assertBoundary(boundary);
  return { packageRoot, fileCount: packageFiles.length };
}

function runProductionBoundary() {
  const temporaryRoot = mkdtempSync(
    path.join(realpathSync(os.tmpdir()), "phase252-production-boundary-"),
  );
  try {
    const nodeFreePath = createNodeFreeEnvironment(REPO_ROOT, temporaryRoot);
    const helpEnv = mixEnvironment(nodeFreePath, path.join(temporaryRoot, "help-build"));
    const adminRoot = path.join(REPO_ROOT, "accrue_admin");
    const hexHelp = runTool(nodeFreePath.mixPath, ["help", "hex.build"], {
      cwd: adminRoot,
      env: helpEnv,
      label: "installed Hex package help preflight",
    });
    const compileHelp = runTool(nodeFreePath.mixPath, ["help", "compile"], {
      cwd: adminRoot,
      env: helpEnv,
      label: "installed Mix compile help preflight",
    });

    if (!supportedHexPackageOptions(hexHelp)) {
      throw new Error("installed Hex does not document both --unpack and --output; actual package proof cannot run");
    }
    if (!compileHelp.includes("--warnings-as-errors")) {
      throw new Error("installed Mix does not document --warnings-as-errors; production compile proof cannot run");
    }

    for (const appName of ["accrue", "accrue_admin", "accrue_portal"]) {
      const outcome = buildPackage(
        appName,
        path.join(REPO_ROOT, appName),
        temporaryRoot,
        nodeFreePath,
        hexHelp,
        compileHelp,
      );
      process.stdout.write(
        `PASS ${appName}: isolated production compile, actual Hex package contents, and runtime boundary (${outcome.fileCount} files).\n`,
      );
    }
    process.stdout.write("Phase 252 production package boundary verified for all three packages.\n");
  } finally {
    rmSync(temporaryRoot, { recursive: true, force: true });
  }
}

function main() {
  if (process.argv.includes("--self-test")) {
    const result = runSelfTest();
    process.stdout.write(`Phase 252 production boundary self-test passed (${result.passed} controls).\n`);
    return;
  }
  if (process.argv.length > 2) {
    throw new Error("Usage: node scripts/ci/verify_phase252_production_boundary.mjs [--self-test]");
  }
  runProductionBoundary();
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`verify_phase252_production_boundary: ${safeDiagnostic(error?.message || error)}\n`);
    process.exitCode = 1;
  }
}
