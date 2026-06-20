#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const root = process.env.ROOT_DIR || process.cwd();
const themePath = path.join(root, "accrue_admin/assets/css/theme.css");
const css = fs.readFileSync(themePath, "utf8").replace(/\/\*[\s\S]*?\*\//g, "");

const scopes = {
  light: /html\.accrue-admin\s*\{([\s\S]*?)\n\}/,
  dark: /html\.accrue-admin\[data-theme="dark"\]\s*\{([\s\S]*?)\n\}/,
  systemDark: /html\.accrue-admin\[data-theme="system"\]\s*\{([\s\S]*?)\n\s*\}\n\}/,
  subtreeDark: /(?:html\.accrue-admin\s+\[data-theme="dark"\][^\{]*,\s*)?\.accrue-admin\s+\[data-theme="dark"\]\s*\{([\s\S]*?)\n\}/
};

function extract(body) {
  const tokens = {};
  for (const match of body.matchAll(/--([a-z0-9-]+)\s*:\s*([^;]+);/gi)) {
    tokens[`--${match[1]}`] = match[2].trim();
  }
  return tokens;
}

const brandTokens = {
  "--accrue-ink": "#111418",
  "--accrue-slate": "#24303b",
  "--accrue-fog": "#e9eef2",
  "--accrue-paper": "#fafbfc",
  "--accrue-moss": "#5e9e84",
  "--accrue-cobalt": "#5d79f6",
  "--accrue-amber": "#c8923b"
};

const lightTokens = extract(css.match(scopes.light)[1]);
const themeTokens = Object.fromEntries(
  Object.entries(scopes).map(([name, regex]) => {
    const match = css.match(regex);
    if (!match) throw new Error(`[foundation_contrast] missing ${name} scope`);
    const tokens = name === "light" ? {...brandTokens, ...lightTokens} : {...brandTokens, ...lightTokens, ...extract(match[1])};
    return [name, tokens];
  })
);

function hexToRgb(hex) {
  const clean = hex.replace("#", "");
  const full = clean.length === 3 ? clean.split("").map((c) => c + c).join("") : clean;
  return [0, 2, 4].map((i) => Number.parseInt(full.slice(i, i + 2), 16));
}

function resolve(value, tokens, seen = new Set()) {
  let current = value.trim();
  const exactVar = current.match(/^var\((--[a-z0-9-]+)\)$/i);
  if (exactVar) {
    const name = exactVar[1];
    if (seen.has(name)) throw new Error(`[foundation_contrast] circular var ${name}`);
    seen.add(name);
    return resolve(tokens[name] || "", tokens, seen);
  }
  current = current.replace(/var\((--[a-z0-9-]+)\)/gi, (_, name) => {
    if (seen.has(name)) throw new Error(`[foundation_contrast] circular var ${name}`);
    seen.add(name);
    return resolve(tokens[name] || "", tokens, seen);
  });
  if (current === "transparent") return null;
  if (/^#[0-9a-f]{3,6}$/i.test(current)) return hexToRgb(current);
  const rgb = current.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/i);
  if (rgb) return rgb.slice(1, 4).map(Number);
  throw new Error(`[foundation_contrast] unsupported color "${value}" resolved to "${current}"`);
}

function channel(v) {
  const s = v / 255;
  return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
}

function luminance(rgb) {
  const [r, g, b] = rgb.map(channel);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contrastRatio(a, b) {
  const [l1, l2] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (l1 + 0.05) / (l2 + 0.05);
}

const basePairs = [
  ["focus ring", "--ax-focus-ring", "--ax-focus-ring-offset", 3],
  ["disabled", "--ax-disabled-text", "--ax-disabled-bg", 3],
  ["readonly", "--ax-readonly-text", "--ax-readonly-bg", 4.5],
  ["scrollbar", "--ax-scrollbar-thumb", "--ax-scrollbar-track", 3],
  ["interactive hover", "--ax-primary", "--ax-interactive-hover", 4.5],
  ["interactive active", "--ax-primary", "--ax-interactive-active", 4.5],
  ["interactive selected", "--ax-primary", "--ax-interactive-selected", 4.5]
];

const statuses = ["success", "warning", "danger", "info", "neutral"];
const failures = [];

for (const [theme, tokens] of Object.entries(themeTokens)) {
  const pairs = [...basePairs];
  for (const status of statuses) {
    pairs.push([`${status} status`, `--ax-status-${status}-text`, `--ax-status-${status}-bg`, 4.5]);
    pairs.push([`${status} solid`, `--ax-status-${status}-on-solid`, `--ax-status-${status}-solid`, 4.5]);
  }

  for (const [label, fgToken, bgToken, min] of pairs) {
    const fg = resolve(tokens[fgToken], tokens);
    const bg = resolve(tokens[bgToken], tokens);
    if (!fg || !bg) continue;
    const ratio = contrastRatio(fg, bg);
    if (ratio < min) {
      failures.push(`${theme} ${label} ${fgToken}/${bgToken}: ${ratio.toFixed(2)} < ${min}`);
    }
  }
}

if (failures.length) {
  console.error(`[foundation_contrast] ${failures.length} contrast failure(s)`);
  for (const failure of failures) console.error(`[foundation_contrast] ${failure}`);
  process.exit(1);
}

console.log("[foundation_contrast] semantic role contrast checks passed");
