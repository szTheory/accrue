---
phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po
audited: 2026-05-27
audit_mode: initial
asvs_level: 2
threats_total: 10
threats_closed: 10
threats_open: 0
unregistered_flags: 0
block_on: high
status: SECURED
---

# Phase 144 — Security Audit (Initial)

**Scope:** Verifies every declared threat mitigation from the four PLAN.md `<threat_model>` blocks against the implemented code. Implementation files were treated as read-only.

**Result:** 10/10 threats CLOSED. No `OPEN_THREATS`. No `unregistered_flag` warnings — no SUMMARY declared a `## Threat Flags` section.

## Threat Verification Table

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-144-01 | Denial of Service | mitigate | CLOSED | `accrue/lib/accrue/analytics/dunning.ex:52` — `fragment("CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END", e.data, e.data)`. Bare-cast absence verified: `grep -nE 'fragment\("\(\?->>'"'"'mrr_value_cents'"'"'\)::integer"' dunning.ex` returns nothing. Regression test at `accrue/test/accrue/analytics/dunning_test.exs:50` ("does not crash when a malformed string-typed mrr_value_cents row is present (DAN-08)"). |
| T-144-02 | Tampering (reporting integrity) | mitigate | CLOSED | `accrue/lib/accrue/analytics/dunning.ex:121–128` — `group_by: [e.subject_id, fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", e.data)]` with inner `bool_or(? = 'dunning.recovered')` / `bool_or(? = 'dunning.exhausted')` aggregations. Outer query at `:134–139` uses mutually-exclusive `count() filter` predicates. Property test at `accrue/test/property/dunning_funnel_property_test.exs:69` — `assert result.recovered + result.exhausted + result.active <= result.entered` over 100 StreamData runs. |
| T-144-03 | Tampering (SQL injection) | accept | CLOSED (accepted) | `accrue/lib/accrue/analytics/dunning.ex:152,157` — `apply_window/2` binds parameters via Ecto's `^since` / `^until` pin syntax (parameterised SQL, no string interpolation). `'__legacy__'` at `:123` is a hard-coded literal inside `fragment/1`, never derived from user input. Risk accepted: parameterised-binding posture inherited from Phase 143 T-143-01. |
| T-144-04 | Tampering (write-path reporting integrity) | mitigate | CLOSED | `accrue/lib/accrue/webhook/default_handler.ex:828` (exhausted edge — inside `Events.record/1` data map) and `:915` (recovered edge — inside `Events.record_multi/3` data map inside `Ecto.Multi`). Both inject `campaign_anchor: iso_anchor`. Recovered edge atomicity preserved: `Events.record_multi` shares the multi with `:clear_anchor` (`:889–892`). `grep -c "campaign_anchor: iso_anchor" default_handler.ex` → 2. Emission-boundary tests at `dunning_exhaustion_test.exs:343` (`is_binary` ledger assertion) and `dunning_campaign_keying_test.exs:377` (`ledger.data["campaign_anchor"] == DateTime.to_iso8601(anchor)`). |
| T-144-05 | Denial of Service (nil.year KeyError) | mitigate | CLOSED | `accrue/lib/accrue/webhook/default_handler.ex:794–798` — defensive `case row.dunning_campaign_started_at do %DateTime{} = dt -> DateTime.to_iso8601(dt); _ -> nil end`. Nil-anchor regression test at `accrue/test/accrue/webhook/dunning_exhaustion_test.exs:348` ("records campaign_anchor: nil when no anchor was set (Stripe-native path; DAN-02)") with assertion `is_nil(ledger.data["campaign_anchor"])` at `:366`. |
| T-144-06 | Cross-Site Scripting (SVG/HTML interpolation) | accept | CLOSED (accepted) | `accrue_admin/lib/accrue_admin/components/funnel_chart.ex:32–35` — four `attr(:_, :integer, required: true)` declarations (`:entered`, `:recovered`, `:exhausted`, `:active`); Phoenix.Component runtime rejects non-integers. `:36` adds `attr(:class, :string, default: nil)`. All HEEx interpolations use `<%= @assign %>` form (default-escaping). `grep -nE "raw\(|Phoenix\.HTML\.raw" funnel_chart.ex` returns nothing. Static literals only in SVG attributes. Risk accepted on integer-typed + HEEx-default-escape posture. |
| T-144-07 | Denial of Service (component args) | mitigate | CLOSED | `accrue_admin/lib/accrue_admin/components/funnel_chart.ex:104` — `defp pct(_n, 0), do: 0`. Division-by-zero guard. Regression test at `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs:39` ("guards against division-by-zero when entered: 0") with `refute html =~ "NaN"` at `:49`. |
| T-144-08 | Information Disclosure (non-admin route access) | accept | CLOSED (accepted) | `accrue_admin/lib/accrue_admin/router.ex:52–77` — `live_session :accrue_admin` with `on_mount: on_mount` where `@default_on_mount [{AccrueAdmin.AuthHook, :ensure_admin}]` at `:9`. `live("/recovery", RecoveryLive, :index)` at `:76` is nested inside this gated `live_session` (scope `/analytics` at `:75`). Plan 04 added no new routes. Risk accepted on inherited Phase 143 gating. |
| T-144-09 | Configuration leak (currency baked into release artifact) | mitigate | CLOSED | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:19–20` — `currency = Accrue.Config.get!(:default_currency)` + `locale = Accrue.Config.default_locale()`. Both are runtime accessors. `grep -nE "Application\.compile_env" recovery_live.ex` returns nothing — compile-time read absent. JPY regression test at `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:128` (`Application.put_env(:accrue, :default_currency, :jpy)`) with delete-if-nil `on_exit` restore at `:132–134`. |
| T-144-10 | Cross-Site Scripting (currency/locale interpolation) | accept | CLOSED (accepted) | `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:54,63` — KPI value attrs receive `@recovered_str` / `@exhausted_str`, which are `Accrue.Invoices.Render.format_money/3` outputs (CLDR-formatted strings, never raw HTML; double-fallback to `"N currency"` literal). `grep -nE "raw\(|Phoenix\.HTML\.raw" recovery_live.ex` returns nothing. HEEx escapes `<%= ... %>` interpolations by default. Risk accepted on CLDR-output + HEEx-default-escape posture. |

## Unregistered Flags

None. The four SUMMARY.md files (`144-01-SUMMARY.md` through `144-04-SUMMARY.md`) declare no `## Threat Flags` section — no executor-flagged new attack surface during implementation.

## Threats Considered, Out of Scope

The PLAN threat models also enumerated threats with `Threats considered, none applicable:` blocks (Spoofing, Repudiation, Information Disclosure of ledger payloads, Elevation of Privilege). These are inherited postures from prior phases (T-128-01 webhook signature gate, T-129-01 no-PII ledger payloads, append-only ledger immutability trigger SQLSTATE 45A01) and are not new threats introduced by Phase 144. No audit action required.

## Verification Methodology

For each `mitigate` threat: grep'd the cited file at the cited line range for the exact mitigation pattern declared in the PLAN. For each `accept` threat: confirmed the documented rationale holds by grepping for the asserted absence (`Application.compile_env`, `raw/1`) and confirming the asserted presence (integer attrs, parameterised SQL bindings, gated `live_session`). Corroborating regression tests were also located for every `mitigate` threat.

No implementation file was modified.

---

_Auditor: gsd-security-auditor_
_Phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po_
_ASVS Level: 2_
_Block-on policy: high_
_Audited: 2026-05-27_
