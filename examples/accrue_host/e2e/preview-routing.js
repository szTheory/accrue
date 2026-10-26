// @ts-check
const preservationProject = "accrue-host-phase243-preview";

function validatePreviewSelection(requested) {
  const expectedSpec = "e2e/phase243-preview-preservation.spec.js";
  if (requested.length === 0 || requested[0] !== expectedSpec) {
    throw new Error(`select exactly ${expectedSpec} as the first argument`);
  }
  for (let index = 1; index < requested.length; index += 1) {
    const arg = requested[index];
    if (arg === "--project") {
      if (requested[index + 1] !== "chromium-desktop") throw new Error("only --project chromium-desktop is supported");
      index += 1;
    } else if (arg === "--workers") {
      if (requested[index + 1] !== "1") throw new Error("only --workers 1 is supported");
      index += 1;
    } else if (!/^--(project|workers)=(chromium-desktop|1)$/.test(arg)) {
      throw new Error(`unsupported preview runner argument: ${arg}`);
    }
  }
}

function assertPreviewRouting(argv = process.argv, env = process.env) {
  const previewURL = env.ACCRUE_HOST_PREVIEW_BASE_URL;
  const previewMode = env.ACCRUE_HOST_PREVIEW_MODE === "preservation";
  if (!previewMode && !previewURL) return false;
  if (!previewMode) {
    throw new Error("ACCRUE_HOST_PREVIEW_BASE_URL requires ACCRUE_HOST_PREVIEW_MODE=preservation");
  }
  if (env.npm_lifecycle_event !== "e2e:preview" || env.ACCRUE_HOST_PREVIEW_SELECTION !== "phase243-preview-preservation") {
    throw new Error("preview preservation mode must be launched by the explicit e2e:preview selector");
  }
  if (!previewURL) throw new Error("preview preservation mode requires ACCRUE_HOST_PREVIEW_BASE_URL");
  if (env.ACCRUE_HOST_PREVIEW_INSTANCE !== preservationProject) {
    throw new Error(`preview preservation mode requires ACCRUE_HOST_PREVIEW_INSTANCE=${preservationProject}`);
  }
  if (env.ACCRUE_HOST_REUSE_SERVER === "1") {
    throw new Error("preview preservation mode cannot reuse a proof server");
  }

  let actualURL;
  try {
    actualURL = new URL(previewURL);
  } catch {
    throw new Error("preview preservation mode requires a valid preview base URL");
  }
  if (actualURL.origin !== `http://${preservationProject}.localhost` || actualURL.pathname !== "/" || actualURL.search || actualURL.hash || actualURL.username || actualURL.password) {
    throw new Error("preview base URL does not match the dedicated Phase 243 preview origin");
  }

  // The preview runner validates its complete argument list before launching
  // Playwright. Config loaders also run in workers where CLI argv is omitted.
  void argv;
  return true;
}

module.exports = { assertPreviewRouting, validatePreviewSelection };
