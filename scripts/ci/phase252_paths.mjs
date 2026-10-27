export const REQUIRED_OWNER = "admin-phase200-guardrails";

export const CONSUMED_ROOTS = [
  { id: "root-storybook", path: "storybook/", mode: "prefix", owner: REQUIRED_OWNER },
  { id: "brandbook-tokens", path: "brandbook/tokens/", mode: "prefix", owner: REQUIRED_OWNER },
];

export function classifyPath() {
  return null;
}

export function assertOwnerMap() {}

export function assertCiContract() {}
