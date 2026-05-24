---
phase: 127
slug: optional-stripe-native-sync-isolated-off-by-default
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-24
---

# Phase 127 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

This phase adds an **optional, off-by-default** Stripe-native entitlement-summary sync that writes an *advisory* local cache (`accrue_entitlement_summaries`). The core security promise is **ISOLATION**: the advisory cache must be provably unreachable from the always-on entitlement gate path (`entitled?/2`, `has_active_plan?/2`, the Resolver, and LocalMap). That promise was verified below with live grep + script execution, not documentation.

Register origin: `register_authored_at_plan_time: true` — all 4 PLAN files carried parseable `<threat_model>` blocks. The auditor verified mitigation-presence (it did not scan for new threats).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Stripe → webhook reducer | Untrusted full-snapshot summary payload (untyped raw map); signature verified upstream and non-bypassable. | Entitlement summary JSON (customer id, entitlements list, `has_more`) |
| Webhook reducer → cache table | Monotonic write boundary; out-of-order / replay must not regress newer state. | `accrue_entitlement_summaries` row (advisory cache) |
| Read seam → gate path | The seam MUST NOT be reachable from `entitled?/2`/`has_active_plan?/2` (observational-only). | (intentionally none — enforced as zero) |
| Config (host) → boot | Host-supplied `stripe_native_sync` value validated at boot. | `:disabled` / `:advisory` atom |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-127-01 | Tampering | `accrue_entitlement_summaries` writes | mitigate | `entitlement_summary.ex:61` `lock_version` + `:85` `optimistic_lock(:lock_version)`; watermark cols `:62-63` (`last_stripe_event_ts`/`_id`); `:86-87` `unique_constraint(:customer_id)` + `foreign_key_constraint`. Migration `:26` FK `on_delete: :delete_all`, `:42` `unique_index([:customer_id])`, `:44` partial truncated index. | closed |
| T-127-02 | Tampering | malformed config value | mitigate | `config.ex:433` `type: {:in, [:disabled, :advisory]}` — NimbleOptions rejects any other value at boot (ASVS V5). | closed |
| T-127-03 | Elevation of Privilege | cache reachable from gate path | mitigate | `config.ex:434` `default: :disabled`; `:806` `stripe_native_sync?/0` false when disabled. `default_handler.ex:300-306` off-lane returns `{:ok, :ignored}` BEFORE any `Repo` call. Gate-path scan: 0 cache refs. | closed |
| T-127-04 | Tampering | out-of-order / replayed summary clobber | mitigate | `default_handler.ex:514` reuses `check_stale/2`; `:1346-1350` strict `:lt -> :stale`; `:514-522` emits `[:accrue, :webhooks, :stale_event]` + `{:ok, :stale}` (no write). WR-02: `stamp_summary_watermark/4` `:660-670` refuses nil-clobber of a non-nil watermark. Monotonic property test present (ASVS V4). | closed |
| T-127-05 | Tampering | cache poisoning via malformed payload | mitigate | `default_handler.ex:490-492` defensive dual `get/2`; `:495-501` `customer` must be binary + `entitlements.data` a list, else `{:ok, :ignored}` (no write). `:537-547` orphan → `{:ok, :deferred}`, never raises (ASVS V5). Handler rescue-wrapped (`safe_handle/2`) as defense-in-depth. | closed |
| T-127-06 | Elevation of Privilege | stale/partial cache influencing authz | mitigate | Live scan of 4 gate-path files (`entitlements.ex`, `resolver.ex`, `resolver/local_map.ex`, `live/entitlements.ex`) → **0** refs to cache/seam. `stripe_sync.ex` seam is read-only one-way. `truncated` recorded (`:570`) but never gates. | closed |
| T-127-07 | Information Disclosure | raw payload leaking to logs/telemetry/ledger | mitigate | Telemetry metadata = IDs/counts only (`:519,544,576,583`); ledger `data` = `%{source, stripe_event_id}` only. Raw payload only in cache `data` JSONB (`:572`). No `Logger`/`IO` in reducer block. OTel `@allowed_attributes` not widened (ASVS V7). | closed |
| T-127-08 | Repudiation | sync state change leaves no audit trail | mitigate | `maybe_record_summary_event/3` `:607-615` writes `accrue_events` row `"entitlements.summary.synced"`, idempotency-keyed, ONLY on material change (`summary_material_change?/3` `:620-625`); byte-identical re-delivery → `result: :unchanged`, no row. | closed |
| T-127-09 | Elevation of Privilege | future refactor wiring cache into gate path | mitigate | `scripts/ci/verify_entitlement_sync_isolation.sh` scoped to 3 gate-path files, comment-anchored, alternation includes `stripe_native_sync` (WR-03 fix `:47`), `exit 1` on hit. **Live-proven**: fails on injected leak, passes clean. Wired merge-blocking in `ci.yml:53` (ASVS V4). | closed |
| T-127-10 | Tampering / Repudiation | support-matrix drift | mitigate | 3-way SSOT: `capabilities.ex:62,120-123` honest labels (`stripe: native (advisory)`); `processor-support-matrix.md:60` sibling row; `local_mapping` convergence row byte-unchanged. `verify_processor_support_matrix.sh` passes; **live regression proof**: flipping a `local_mapping` cell to `native` → exit 1, revert → exit 0. | closed |
| T-127-11 | Information Disclosure / Repudiation | operator misreads `:advisory` as gating | mitigate | `guides/entitlements.md:244` disclaimer "`:advisory` does NOT change `entitled?` …" pinned by `verify_package_docs.sh:134` needle (+ `:132-133,135`). Docs gate passes (exit 0). | closed |
| T-127-12 | Repudiation | sync telemetry undocumented | mitigate | `guides/telemetry.md:74-78,107,455` catalogs `[:accrue, :entitlements, :sync]`, `:summary_synced` (`result`), reused `stale_event`/`orphan_entitlement_summary`, and `[:accrue, :ops, :entitlement_summary_truncated]` (only when `has_more`). | closed |
| T-127-SC | Tampering | npm/pip/cargo installs | accept | Zero new dependencies this phase (all 4 plans). See Accepted Risks Log. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Isolation Claim (the phase's core security promise) — VERIFIED

The advisory cache is provably unreachable from the gate path:

1. **Static source scan (live):** the 4 gate-path files contain **0** references to `EntitlementSummary`, `StripeSync`, `accrue_entitlement_summaries`, or `stripe_native_sync` (raw scan, not just comment-anchored).
2. **Only 3 modules in `accrue/lib` touch the cache:** the schema (`billing/entitlement_summary.ex`), the read-only one-way seam (`entitlements/stripe_sync.ex`), and the webhook reducer (`webhook/default_handler.ex`). None is on the gate-decision path.
3. **Merge-blocking enforcement is real:** `verify_entitlement_sync_isolation.sh` was executed and genuinely fails (exit 1) on an injected gate-path leak and passes (exit 0) clean. It is wired into the `docs-contracts-shift-left` CI job (`ci.yml:53`), merge-blocking on pull_request.
4. **Off lane is DB-free:** with `stripe_native_sync: :disabled` (default), the dispatch clause returns `{:ok, :ignored}` before any `Repo` call.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| T-127-SC | Supply-chain (new dep installs) | Zero new dependencies introduced this phase across all 4 plans. git log over the phase commit range shows no `mix.exs`/`mix.lock` changes; all SUMMARYs declare `tech-stack.added: []`. No package-install attack surface. | gsd-security-auditor | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Unregistered Flags

None. All four plan SUMMARYs report "Threat Flags: None" (plans 02 and 04 carry an explicit `## Threat Flags` section; plans 01/03 introduce no new attack surface beyond the register). No new network endpoints, auth paths, file-access patterns, or trust-boundary schema changes appeared during implementation beyond the registered threats.

---

## Deferred (non-blocking, tracked outside this audit)

The code review (`127-REVIEW.md`) deferred WR-05 (concurrent same-customer delivery can raise `Ecto.StaleEntryError`, self-healing via Oban retry) and IN-01..04 (cosmetic/fidelity). None affect a declared threat disposition or the isolation invariant; they are availability/fidelity follow-ups, not authorization or data-leak gaps. Tracked in `.planning/todos/pending/`.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 13 | 13 | 0 | gsd-security-auditor (ASVS L2; mitigation-presence verification + live script/grep execution) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24

_Audit method: mitigation-presence verification with file:line evidence + live script/grep execution. Implementation files were not modified (read-only audit)._
