const { test, expect } = require("@playwright/test");
const {
  BROWSER_RECONCILIATION_TITLE,
  createExpectedBrowserCellDefinitions,
  isOwnedPhase253Run,
  mergeRunResults,
  readPhase253Manifest,
  reconcileResults,
  selectionFor,
  writeResults,
} = require("./phase253-composition-helpers.js");

// Phase 254 D-13/D-14: the dependent `phase254-reconcile` project. Cells write one file
// each (phase254-result-ledger.js); this test merges them into the results file the
// aggregate reads and applies every Phase 253 reconciliation invariant: missing,
// duplicate and unexpected keys, non-passed rows, manifest and run identity, source and
// served-asset identity. Phase 254 D-11/D-14: the expected keys are the selected case ids
// from PHASE254_SELECTION (the full compiled universe when it is unset, so full mode still
// means every cell, 151 today), never a count read back from the files merged; a result row
// for an excluded case or a missing selected row fails.
// An unowned load (a dependency load from another lane's run) registers no tests; the
// aggregate's exact identity inventory fails a real run that is missing this one.
if (isOwnedPhase253Run()) {
  const identity = readPhase253Manifest();
  const definitions = createExpectedBrowserCellDefinitions(identity.manifest);
  const selection = selectionFor(identity.manifest);
  const selectedKeys = new Set(selection.selected_keys);
  const selectedDefinitions = definitions.filter((definition) => selectedKeys.has(definition.key));
  const expectedKeys = selectedDefinitions.map((definition) => definition.key);

  test.describe("Phase 254 composition result reconciliation", () => {
    test(BROWSER_RECONCILIATION_TITLE, () => {
      expect(new Set(expectedKeys).size).toBe(expectedKeys.length);
      expect(expectedKeys.length).toBe(selection.selected_keys.length);

      const { filePath, results: merged } = mergeRunResults(identity);
      expect(merged.run_id).toBe(identity.runId);
      expect(merged.manifest_sha256).toBe(identity.manifestDigest);
      expect(merged.selection).toEqual(selection.block);
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
      expect(reconcileResults(results, identity.manifest, identity.manifestDigest, selection)).toEqual([]);

      const controls = results.cases.find((row) => row.case_kind === "geometry_negative_controls");
      expect(controls?.negative_controls).toEqual({ hidden_essential_detected: true, page_overflow_detected: true });
      const countOf = (kind) => results.cases.filter((row) => row.case_kind === kind).length;
      const selectedCountOf = (kind) => selectedDefinitions.filter((definition) => definition.case_kind === kind).length;
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
        // The compiled universe is always the full 151; the rows are the selected subset of it.
        expect(definedCountOf(kind), `${kind} compiled definitions`).toBe(count);
        expect(countOf(kind), `${kind} rows`).toBe(selectedCountOf(kind));
        if (selection.mode === "full") expect(countOf(kind), `${kind} rows in full mode`).toBe(count);
      }
      if (selection.mode === "full") expect(results.cases).toHaveLength(definitions.length);

      // Only a fully reconciled run produces the bundle the aggregate validates.
      writeResults(filePath, results);
    });
  });
}
