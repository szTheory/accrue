export function buildLaunchConfig() {
  return {};
}

export async function prepareLaunch() {
  return {};
}

export function ownsProcess() {
  return false;
}

export async function acquireNamespaceLock() {
  return { release: async () => {} };
}
