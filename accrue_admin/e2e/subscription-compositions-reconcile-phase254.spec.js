const { test, expect } = require("@playwright/test");
const {
  BROWSER_RECONCILIATION_TITLE,
  createExpectedBrowserCellDefinitions,
  isOwnedPhase253Run,
  mergeRunResults,
  readPhase253Manifest,
  reconcileResults,
  writeResults,
} = require("./phase253-composition-helpers.js");

// Phase 254 D-13/D-14: the dependent `phase254-reconcile` project. Cells write one file
// each (phase254-result-ledger.js); this test merges them into the results file the
// aggregate reads and applies every Phase 253 reconciliation invariant: missing,
// duplicate and unexpected keys, non-passed rows, manifest and run identity, source and
// served-asset identity. Expected keys are the full compiled cell universe, so full mode
// still means every cell (151 today) and never a count read back from the files merged.
// An unowned load (a dependency load from another lane's run) registers no tests; the
// aggregate's exact identity inventory fails a real run that is missing this one.
if (isOwnedPhase253Run()) {
  const identity = readPhase253Manifest();
  const definitions = createExpectedBrowserCellDefinitions(identity.manifest);
  const expectedKeys = definitions.map((definition) => definition.key);

  test.describe("Phase 254 composition result reconciliation", () => {
    test(BROWSER_RECONCILIATION_TITLE, () => {
      expect(new Set(expectedKeys).size).toBe(expectedKeys.length);

      const { filePath, results: merged } = mergeRunResults(identity);
      expect(merged.run_id).toBe(identity.runId);
      expect(merged.manifest_sha256).toBe(identity.manifestDigest);
      expect(merged.human_judgment).toBe(false);
      expect(merged.proof_lane).toBe("actual direct browser presentation; no mounted-effect claims");
      for (const asset of [
        "accrue_admin/assets/css/app.css",
        "accrue_admin/priv/static/accrue_admin.css",
        "accrue_admin/priv/static/storybook.css",
      ]) {
        expect(merged.source_and_asset_sha256[asset]).toMatch(/^[a-f0-9]{64}$/);
      }

      // The header the cells spec declared must be the same universe the manifest compiles.
      expect([...merged.expected_case_keys].sort()).toEqual([...expectedKeys].sort());
      const results = { ...merged, expected_case_keys: expectedKeys };

      expect(results.cases).toHaveLength(expectedKeys.length);
      expect(reconcileResults(results, identity.manifest, identity.manifestDigest)).toEqual([]);

      const controls = results.cases.find((row) => row.case_kind === "geometry_negative_controls");
      expect(controls?.negative_controls).toEqual({ hidden_essential_detected: true, page_overflow_detected: true });
      const countOf = (kind) => results.cases.filter((row) => row.case_kind === kind).length;
      const definedCountOf = (kind) => definitions.filter((definition) => definition.case_kind === kind).length;
      for (const [kind, count] of [
        ["viewport", 40],
        ["breakpoint", 8],
        ["container", 4],
        ["synthetic_text_stress", 2],
        ["page_composition", 90],
        ["page_synthetic_text_stress", 6],
        ["geometry_negative_controls", 1],
      ]) {
        expect(countOf(kind), `${kind} rows`).toBe(count);
        expect(definedCountOf(kind), `${kind} compiled definitions`).toBe(count);
      }

      // Only a fully reconciled run produces the bundle the aggregate validates.
      writeResults(filePath, results);
    });
  });
}
