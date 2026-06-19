import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");

const LEDGER_PATH =
  process.env.PHASE191_DEFECTS_PATH ||
  path.join(REPO_ROOT, ".planning/phases/187-audit-baseline/defects.ndjson");
const SPEC_PATH =
  process.env.PHASE191_SPEC_PATH ||
  path.join(REPO_ROOT, "accrue_admin/e2e/admin-page-flow-phase191.spec.js");
const HELPER_PATH =
  process.env.PHASE191_HELPER_PATH ||
  path.join(REPO_ROOT, "accrue_admin/e2e/phase191-page-flow-helpers.js");
const HANDOFF_PATH =
  process.env.PHASE191_HANDOFF_PATH ||
  path.join(
    REPO_ROOT,
    ".planning/phases/190-navigation-data-display-meta-component-cohesion/190-PHASE-191-HANDOFF.md"
  );

const TAG_ALIASES = new Map([
  ["liveview-patch-focus", "live-focus"],
  ["live-patch-focus", "live-focus"],
  ["copy", "microcopy"],
]);

const D30_CATEGORIES = [
  { category: "focus trap", markers: ["focus-trap"] },
  { category: "focus restore", markers: ["focus-restore"] },
  { category: "Escape", markers: ["escape"] },
  { category: "click outside", markers: ["click-outside"] },
  { category: "scroll reachability", markers: ["scroll-reachability"] },
  { category: "overlay position", markers: ["overlay-position", "layer-z-index"] },
  { category: "LiveView patch focus", markers: ["liveview-patch-focus", "live-focus"] },
  { category: "fixture gaps", markers: ["fixture-gaps", "AX187-442", "AX187-443", "AX187-444", "AX187-445"] },
  { category: "microcopy", markers: ["microcopy", "copy-recovery", "copy-specificity"] },
];

function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    throw new Error(`Unable to read ${filePath}: ${error.message}`);
  }
}

function readNdjson(filePath) {
  return readFile(filePath)
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${filePath}:${index + 1}: ${error.message}`);
      }
    });
}

function normalizeTag(value) {
  if (!value) return null;

  const normalized = String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

  return TAG_ALIASES.get(normalized) || normalized || null;
}

function defectTags(defect) {
  return Array.from(
    new Set([...(defect.overlay_tags || []), ...(defect.tags || [])].map(normalizeTag).filter(Boolean))
  );
}

function idsIn(source) {
  return new Set(source.match(/AX187-\d{3}/g) || []);
}

function normalizedSource(source) {
  return source
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function normalizedText(value) {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function sourceHasMarker(source, marker) {
  if (/^AX187-\d{3}$/.test(marker)) return idsIn(source).has(marker);

  const normalized = normalizeTag(marker);
  return normalizedSource(source).includes(normalized);
}

function formatDefect(defect) {
  const tags = defectTags(defect);
  const tagText = tags.length > 0 ? ` tags=${tags.join(",")}` : " tags=(none)";
  return `${defect.id} ${defect.severity} ${defect.surface} ${defect.rubric_dimension}${tagText}`;
}

function failWithReport(sections) {
  console.error("Phase 191 AX187 coverage audit failed.");
  for (const section of sections) {
    if (section.items.length === 0) continue;
    console.error(`\n${section.title}:`);
    for (const item of section.items.slice(0, 40)) console.error(`- ${item}`);
    if (section.items.length > 40) console.error(`- ...and ${section.items.length - 40} more`);
  }
  process.exit(1);
}

const specSource = readFile(SPEC_PATH);
const helperSource = readFile(HELPER_PATH);
const combinedSource = `${specSource}\n${helperSource}`;
const handoffSource = readFile(HANDOFF_PATH);

const owner191 = readNdjson(LEDGER_PATH).filter((row) => String(row.owner_phase) === "191");
const high = owner191.filter((row) => row.severity === "high");
const medium = owner191.filter((row) => row.severity === "medium");

const specIds = idsIn(specSource);
const combinedIds = idsIn(combinedSource);

const missingHighDirectIds = high.filter((defect) => !specIds.has(defect.id)).map(formatDefect);
const missingMediumCoverage = medium
  .filter((defect) => {
    if (combinedIds.has(defect.id)) return false;

    const tags = defectTags(defect);
    return tags.length === 0 || !tags.some((tag) => sourceHasMarker(combinedSource, tag));
  })
  .map(formatDefect);

const missingD30InHandoff = D30_CATEGORIES.filter(({ category }) => {
  return !normalizedSource(handoffSource).includes(normalizedText(category));
}).map(({ category }) => category);

const missingD30Coverage = D30_CATEGORIES.filter(({ markers }) => {
  return !markers.some((marker) => sourceHasMarker(combinedSource, marker));
}).map(({ category, markers }) => `${category} (${markers.join(" or ")})`);

const severityCounts = owner191.reduce((acc, defect) => {
  acc[defect.severity] = (acc[defect.severity] || 0) + 1;
  return acc;
}, {});

const tagCounts = owner191.reduce((acc, defect) => {
  for (const tag of defectTags(defect)) acc[tag] = (acc[tag] || 0) + 1;
  return acc;
}, {});

console.log(`Phase 191 AX187 owner count: ${owner191.length}`);
console.log(`Severity split: high=${severityCounts.high || 0}, medium=${severityCounts.medium || 0}`);
console.log(`Direct high-severity coverage: ${high.length - missingHighDirectIds.length}/${high.length}`);
console.log(`Medium ID/tag coverage: ${medium.length - missingMediumCoverage.length}/${medium.length}`);
console.log(`Normalized overlay tags: ${JSON.stringify(tagCounts)}`);

if (
  owner191.length !== 178 ||
  high.length !== 70 ||
  medium.length !== 108 ||
  missingHighDirectIds.length > 0 ||
  missingMediumCoverage.length > 0 ||
  missingD30InHandoff.length > 0 ||
  missingD30Coverage.length > 0
) {
  failWithReport([
    {
      title: "Unexpected ledger counts",
      items:
        owner191.length === 178 && high.length === 70 && medium.length === 108
          ? []
          : [`owner=${owner191.length}, high=${high.length}, medium=${medium.length}`],
    },
    { title: "High-severity rows missing direct spec AX187 IDs", items: missingHighDirectIds },
    { title: "Medium rows missing AX187 ID or normalized overlay-tag coverage", items: missingMediumCoverage },
    { title: "D-30 categories missing from handoff source", items: missingD30InHandoff },
    { title: "D-30 categories missing from Phase 191 spec/helper markers", items: missingD30Coverage },
  ]);
}

console.log("Phase 191 AX187 coverage audit passed.");
