# Phase 240 Edge Coverage

The installed spec-less probe classified 32 applicable edges for the eight Phase 240 requirements. Each row below is resolved with an explicit acceptance predicate grounded in the approved context, UI contract and existing owners. This record supplements `240-EDGE-PROBE.json`, whose initial machine report remains the raw candidate inventory. No edge is dismissed or silently dropped. The plan `must_haves.truths` carry these requirement/category identities, and each named plan adds a recurring owner assertion or evidence record. These are planned checks, not execution results.

| Requirement | Category | Verification | Explicit acceptance predicate | Plan |
|---|---|---|---|---|
| DSN-01 | adjacency | explicit | Identity/scope, fact group and next-action group remain visually distinct when adjacent at current mounted geometry; 2px data and 1px rules remain intentional. | 01, 06 |
| DSN-01 | empty | explicit | Empty first-run, queue and filtered collection states remain distinct, while missing optional detail facts state unavailable. | 03 |
| DSN-01 | encoding | explicit | Long Unicode names and IDs remain readable/wrapped without byte truncation or loss of exact identity. | 03 |
| DSN-01 | ordering | explicit | Equal-status invoice rows keep the existing deterministic order and associated action/identity; no UI-only reorder implies priority. | 03 |
| DSN-02 | boundary | explicit | At 320, 600, 768 and 1024 CSS px and on either side of the existing breakpoint, identity, money, state and action remain reachable. | 03 |
| DSN-02 | empty | explicit | Absent long-content fields do not become zero money or blank task identity; explicit fallback stays visible under narrow/enlarged layout. | 03 |
| DSN-02 | encoding | explicit | Grapheme-rich long names/identifiers wrap or disclose at 200% text and spacing overrides without clipping. | 03 |
| DSN-02 | precision | explicit | Canonical currency/minor-unit amount survives formatter, reflow and zoom without rounding or ambiguous omission. | 01, 03 |
| DSN-03 | idempotency | explicit | Selecting the same Light/Dark/System preference twice leaves one stored selection and the same effective style. | 04 |
| DSN-03 | concurrency | explicit | OS light→dark→light changes while System is selected and intervening LiveView patch/reload preserve stored System and latest effective style; host force wins. | 04 |
| DSN-04 | empty | explicit | Absent staged action remains disabled/unavailable and does not turn into a usable action during reconnect. | 05 |
| DSN-04 | encoding | explicit | Busy/result labels and target identity survive DOM replacement with readable text and matching accessible names. | 05 |
| DSN-04 | idempotency | explicit | Repeated patch/reconnect does not replay the action; authoritative fixture dispatch/audit count stays one. | 05 |
| DSN-04 | concurrency | explicit | During held work, online event and repeated patches cannot enable a control before LiveView readiness and fresh server eligibility. | 05 |
| DSN-05 | empty | explicit | Removed opening trigger returns focus to the nearest logical surviving control, not body or a hidden node. | 04 |
| DSN-05 | encoding | explicit | Long/Unicode labels, associated error and status messages keep accessible names and visible focus without clipping. | 04 |
| DSN-05 | idempotency | explicit | Repeated open/dismiss and rapid teardown do not leave duplicate traps or inert overlay hit targets. | 04 |
| DSN-05 | concurrency | explicit | Validation, correction, submit and concurrent LiveView replacement retain Tab/Shift+Tab containment and logical focus return. | 04 |
| UXC-02 | empty | explicit | First-run empty, queue empty, filtered no-match and unavailable records remain separate, with no inferred health. | 03 |
| UXC-02 | encoding | explicit | Exact provider diagnostic terms and locked legal/audit strings remain intact while surrounding routine labels stay readable. | 03 |
| UXC-02 | idempotency | explicit | Repeated render of accepted/pending/failed/unknown states does not promote them to completed or introduce blind mutation retry. | 03, 05 |
| UXC-02 | concurrency | explicit | A late or unknown result is shown only from fresh authoritative state; stale result cannot overwrite a newer material state. | 03, 05 |
| EVR-01 | adjacency | explicit | Source, fixture, built, compiled, served, rendered and exercised entries remain separately labeled even when they refer to the same route/asset. | 06 |
| EVR-01 | empty | explicit | Unobserved browser/remote evidence is labeled unavailable/unobserved rather than counted as exercised. | 06 |
| EVR-01 | encoding | explicit | Paths/digests/route identities retain exact bytes in the provenance record; human-readable labels cannot substitute for asset hashes. | 06 |
| EVR-01 | ordering | explicit | Current route/owner ledger uses stable compiled-route order, while registry and source-module counts keep separate meanings. | 06 |
| EVR-01 | concurrency | explicit | Rebuild/host compilation and served-response capture belong to the same identified source revision; a stale digest fails. | 06 |
| EVR-02 | adjacency | explicit | Snapshot expected-set preflight is immediately followed by the existing blocking pixel command in the same CI owner. | 02 |
| EVR-02 | empty | explicit | All eight absent and any one absent both exit nonzero; zero browser tests or absent evidence cannot count as a pass. | 02, 06 |
| EVR-02 | ordering | explicit | Expected set is validated before pixels and new guard negatives are proved before claiming the changed owner green. | 02, 06 |
| EVR-02 | idempotency | explicit | Repeating the complete-set preflight over unchanged eight files gives the same pass; repeated build/verify does not mint baselines. | 02 |
| EVR-02 | concurrency | explicit | Missing baseline and stale-asset checks remain blocking even when CI shards or other checks run in parallel. | 02, 06 |

## Prohibition recall

The adversarial recall considered silent weakening of billing authorization, preview-data mutation, misleading completion language, hidden evidence, and softened visual gates. Existing locked D-08–D-13, the Phase 239 safety contracts and the plan threat models already prohibit these; they are not minted as new normative product prohibitions. Canonical security cases (foreign-scope action and duplicate dispatch) remain STRIDE mitigations with server-owner checks. No additional descriptor-less values/safety prohibition survives precision filtering beyond those approved constraints; no policy or fabricated check descriptor is added.
