---
phase: quick-260918-hnk
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/milestones/v1.62-MILESTONE-AUDIT.md
autonomous: true
requirements: [QT-260918-HNK]

estimate:
  tokens: 18000
  raw_tokens: 12000
  tasks: 2
  confidence: low

must_haves:
  truths:
    - "Item #2 of the v1.62 audit's Tech Debt section reads as RESOLVED, with the CI run id, head SHA, and the named parked non-blocking exception cited inline."
    - "The resolution note uses the same blockquote convention already established by item #1."
    - "Audit items #3, #4, and #5 are byte-identical to their pre-edit text."
    - "No file other than .planning/milestones/v1.62-MILESTONE-AUDIT.md is modified."
  artifacts:
    - .planning/milestones/v1.62-MILESTONE-AUDIT.md
  key_links:
    - "Item #2 heading suffix `— RESOLVED` mirrors item #1's heading suffix so any reader scanning headings sees both closures."
---

<objective>
Close tech-debt item #2 ("The candidate SHA is red on its own merge-blocking gates") in
`.planning/milestones/v1.62-MILESTONE-AUDIT.md` with an honest, evidence-cited inline
resolution note, matching the convention item #1 already uses.

Purpose: the audit is the permanent archived record of v1.62. Item #2 was the entire
distance between the milestone and an actual release; that distance is now closed
(PR #45 merged, 1.6.0 released, `main` green). Leaving the item reading as an open
release blocker archives a false claim, which is precisely the defect class item #1
was raised to catch.

Output: one edited markdown file. Documentation-only, no code, no scripts, no CI.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@.planning/milestones/v1.62-MILESTONE-AUDIT.md
@CLAUDE.md

Grounding facts (already established this session — do not re-derive):
- CI run `35366858523` at `main` / `48c1c167` completed `success`; 23 jobs, 22 green.
- The three lanes the audit recorded red on the candidate (`docs-contracts-shift-left`,
  `release-gate` all matrix cells, `phase18-tax-gate`) are green at that head.
- The single non-success job is `Admin UI ratchet guardrails [parked]`, which is
  `continue-on-error` / non-blocking per `.github/workflows/ci.yml:1243-1247`, belongs
  to the parked v1.56 milestone, and fails identically at the last previously-green
  run — not a regression, not a merge blocker.
- PR #45 is merged; tags `v1.62`, `accrue-v1.6.0`, `accrue_admin-v1.6.0`,
  `accrue_portal-v1.6.0` exist; 1.6.0 is released.
- The audit file is not in any `covered_files` array, so no `covered_digest` re-mint
  is required.

Scope guard: STATE.md is a `covered_files` entry of an archived verification and is
orchestrator-owned here — do not touch it. Do not touch ROADMAP.md, REQUIREMENTS.md,
any workflow, or any script.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write the item #2 resolution note in the established convention</name>
  <files>.planning/milestones/v1.62-MILESTONE-AUDIT.md</files>
  <precondition>The file contains a heading `### 2. The candidate SHA is red on its own merge-blocking gates` under `## Tech Debt Requiring a Decision`, and item #1's heading already ends in `— RESOLVED` followed by a `>` blockquote note.</precondition>
  <action>
Re-read the item #1 block (heading line plus its immediately following blockquote) and
reproduce its exact shape for item #2: an em-dash `— RESOLVED` suffix appended to the
existing `### 2.` heading, then a blank line, then a blockquote whose first sentence
is bolded and states the closure with its evidence, then a sentence noting the original
finding is retained below as the historical record, then a blank line, then the original
item #2 body left unchanged.

Do not rewrite, soften, or delete any sentence of the existing item #2 body — the
historical record of what was red at `c1397fe9` and why D-47 forbade fixing it in place
must survive verbatim, exactly as item #1's body did.

The blockquote must be specific, not a bare "resolved". It must name, in prose:
the closing date 2026-09-18; that the path forward the item itself prescribed was
executed (phase-close commits pushed, PR #45 merged, Release Please run, 1.6.0
released); CI run id `35366858523` at `main` / `48c1c167` completing `success` with
23 jobs and 22 green; that all three previously-red lanes named in the body
(`docs-contracts-shift-left`, `release-gate` across its matrix cells, `phase18-tax-gate`)
are green at that head; and that the one remaining non-success job,
`Admin UI ratchet guardrails [parked]`, is a known ruled-out exception — declared
`continue-on-error` at `.github/workflows/ci.yml:1243-1247`, owned by the parked v1.56
milestone, and failing identically at the last previously-green run, therefore neither
a regression nor a merge blocker.

Introduce no new occurrence of any token tracked by
`.planning/hygiene/sensitive-token-census.json` (this file already contributes 5
observed occurrences; the note must not raise that count). In particular do not name
adopter organizations, hosts, usernames, or absolute home paths.

Change nothing outside the item #2 heading line and the lines immediately following it
up to the start of `### 3.`. Items #3, #4, and #5 stay untouched.
  </action>
  <verify>
    <automated>git diff --name-only | sort > /tmp/hnk_files.txt &amp;&amp; [ "$(cat /tmp/hnk_files.txt)" = ".planning/milestones/v1.62-MILESTONE-AUDIT.md" ] &amp;&amp; grep -q '^### 2\..*— RESOLVED$' .planning/milestones/v1.62-MILESTONE-AUDIT.md &amp;&amp; for tok in 35366858523 48c1c167 'continue-on-error' 'ci.yml:1243-1247' 'PR #45'; do grep -F -q "$tok" .planning/milestones/v1.62-MILESTONE-AUDIT.md || { echo "MISSING: $tok"; exit 1; }; done &amp;&amp; echo OK</automated>
  </verify>
  <done>Item #2's heading ends in `— RESOLVED`; a blockquote immediately below it cites run `35366858523`, head `48c1c167`, PR #45, and the `continue-on-error` parked job with its `ci.yml` line range; the original item #2 prose is still present below the note; the only modified file is the audit.</done>
</task>

<task type="auto">
  <name>Task 2: Prove the edit was surgical and broke no repo contract</name>
  <files>.planning/milestones/v1.62-MILESTONE-AUDIT.md</files>
  <action>
Assert the blast radius is exactly what was intended, with positive controls so a
green result is real evidence rather than a checker that cannot fail.

1. Confirm the diff is additive-only within item #2: `git diff -U0` on the file must
   show zero removed lines other than the single original `### 2.` heading line it
   replaces. Any other deletion means body prose was lost — fix before proceeding.
2. Confirm items #3-#5 are unchanged by extracting the byte range from `### 3.` to the
   end of the `## Tech Debt Requiring a Decision` section in both `HEAD:` and the working
   tree and diffing them; the diff must be empty. Before trusting that empty result,
   run the same extraction against a deliberately mutated copy in the scratchpad and
   confirm it reports a difference — a comparison that cannot fail is not evidence.
3. Confirm the sensitive-token census still passes and that the audit file's observed
   count has not risen, by running the repo's own verifier rather than a hand-rolled
   grep: `node scripts/ci/verify_sensitive_token_census.mjs` (add `--self-test` if the
   script supports it — check `--help` first).
4. Re-confirm the file appears in no `covered_files` array, so no
   `verify_artifact_fixed_point.mjs` re-mint is owed. Use `-e` for the pattern, never a
   bare `--` before it (that makes git parse it as a pathspec and silently report zero).
  </action>
  <verify>
    <automated>node scripts/ci/verify_sensitive_token_census.mjs &amp;&amp; git diff -U0 -- .planning/milestones/v1.62-MILESTONE-AUDIT.md | grep -c '^-[^-]' | { read n; [ "$n" -le 1 ] || { echo "NON_SURGICAL: $n removed lines"; exit 1; }; } &amp;&amp; echo SURGICAL_OK</automated>
  </verify>
  <done>Census verifier exits 0 with the audit file's observed count unchanged; the diff removes at most the one original `### 2.` heading line; the `### 3.`-onward byte range is identical to `HEAD`, proven with a mutated-copy positive control; no `covered_files` entry names the audit file.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none | Documentation-only edit to an archived planning artifact. No input crosses a trust boundary; no code path, endpoint, dependency, or credential is touched. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-hnk-01 | Tampering | `.planning/milestones/v1.62-MILESTONE-AUDIT.md` historical record | low | mitigate | Resolution written as an additive blockquote; original finding prose retained verbatim. Task 2 asserts deletions ≤ 1 line. |
| T-hnk-02 | Information Disclosure | sensitive-token census counts | low | mitigate | Note forbidden from naming adopters, hosts, usernames, or home paths; `verify_sensitive_token_census.mjs` run as a gate. |
| T-hnk-03 | Repudiation | audit truth claim | low | mitigate | Claim is evidence-bound (run id + head SHA + workflow line range), not a bare "resolved", so a future reader can independently re-check it. |

No package-manager installs in this plan, so no package-legitimacy gate applies.
</threat_model>

<verification>
- `git diff --name-only` lists exactly one path: `.planning/milestones/v1.62-MILESTONE-AUDIT.md`.
- `node scripts/ci/verify_sensitive_token_census.mjs` exits 0.
- Item #2 heading carries `— RESOLVED`; its note cites `35366858523`, `48c1c167`, PR #45, and the `continue-on-error` parked job at `.github/workflows/ci.yml:1243-1247`.
- Items #3, #4, #5 byte-identical to `HEAD`.
</verification>

<success_criteria>
A reader opening the archived v1.62 audit sees item #2 marked RESOLVED with checkable
evidence and the original finding preserved beneath it, items #3-#5 still open, and no
other file in the repository changed.
</success_criteria>

<output>
Create `.planning/quick/260918-hnk-close-v1-62-audit-tech-debt-item-2-candi/260918-hnk-SUMMARY.md` when done
</output>
