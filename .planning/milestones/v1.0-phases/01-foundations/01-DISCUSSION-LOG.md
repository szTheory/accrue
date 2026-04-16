# Phase 1: Foundations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 01-foundations
**Areas discussed:** Money type strategy, Error return style, Event ledger immutability, Events.record + Multi ergonomics, Telemetry naming, Fake Processor test-clock, Mailer + PDF behaviour shapes, Auth.Default + monorepo release

---

## Money type strategy

### Q1: Accrue.Money strategy?

| Option | Description | Selected |
|---|---|---|
| Thin wrapper over :ex_money | Accrue.Money public type, delegates math/currency/CLDR to :ex_money | ✓ |
| Roll our own on :decimal | Zero extra deps, we own every edge case | |
| Expose :ex_money directly | No wrapper, leaks dep into user code | |

### Q2: Ecto representation?

| Option | Description | Selected |
|---|---|---|
| Two columns: amount_minor + currency | Stripe-style pattern, indexable, analytics-friendly | ✓ |
| Single jsonb column | Flexible but awkward for SQL aggregation | |
| Composite Postgres type | Clean but unportable + Ecto-awkward | |

### Q3: Constructor shape?

| Option | Description | Selected |
|---|---|---|
| Minor units only: Money.new(1000, :usd) | Matches Stripe API 1:1; Decimal/float raises | ✓ |
| Decimal primary, integer rejected | Forces explicit conversion; mismatches Stripe | |
| Both, disambiguated by helper | new/2 for minor, from_decimal/2 for Decimal | |

### Q4: Cross-currency arithmetic?

| Option | Description | Selected |
|---|---|---|
| Raise MismatchedCurrencyError | Matches success criterion #1; loud + early | ✓ |
| Return {:error, :mismatched_currency} | Ignorable, contradicts criterion | |
| Require explicit exchange rate | Out of scope for Phase 1 | |

---

## Error return style

### Q5: Public API error-return style?

| Option | Description | Selected |
|---|---|---|
| Ecto-style dual API | Tuple primary + raise! variants; matches Ecto/Phoenix | ✓ |
| Tuple-only | Single API, no bang variants | |
| Raise-heavy (Pay/Bling style) | Noisy for common card-decline case | |

### Q6: Error struct shape?

| Option | Description | Selected |
|---|---|---|
| Rich: code, message, decline_code, param, processor_error, request_id, http_status | Mirrors Stripe 1:1; pattern-matchable | ✓ |
| Minimal: code + message + processor_error | Forces dig into untyped map | |
| Flat atom + metadata map | Not pattern-matchable, not Exception | |

### Q7: Where does Stripe-error-to-Accrue.Error mapping happen?

| Option | Description | Selected |
|---|---|---|
| In Accrue.Processor.Stripe adapter | Only place that knows lattice_stripe; clean boundary | ✓ |
| In Accrue.Billing context | Couples context to Stripe shapes | |
| Dual: adapter normalizes, context enriches | More info but more complexity | |

### Q8: SignatureError — raise or tuple?

| Option | Description | Selected |
|---|---|---|
| Raise | Config error or attack signal, not recoverable | ✓ |
| Tuple | Boilerplate everywhere | |

---

## Event ledger immutability mechanism

### Q9: DB-level enforcement?

| Option | Description | Selected |
|---|---|---|
| Both: trigger + REVOKE grants | Defense in depth | ✓ |
| Trigger only | Disable-able by superuser | |
| REVOKE grants only | Requires two-role setup | |

### Q10: Role management?

| Option | Description | Selected |
|---|---|---|
| Host-managed + runtime check | Accrue doesn't create roles; boot check + docs | ✓ |
| Accrue owns the role | Conflicts with RDS/Supabase | |
| No role enforcement (trigger only) | Gives up defense in depth | |

### Q11: Events read-side schema?

| Option | Description | Selected |
|---|---|---|
| Full Ecto schema, no update/delete helpers exposed | Typed reads, no mutation surface | ✓ |
| Write-only raw SQL + separate query module | Maximum separation, more code | |

### Q12: Trigger error format?

| Option | Description | Selected |
|---|---|---|
| Custom SQLSTATE '45A01' + clear message | Pattern-matchable via Postgrex.Error | ✓ |
| Default SQLSTATE | Requires fragile message parsing | |

---

## Events.record + Ecto.Multi ergonomics

### Q13: Events.record API shape?

| Option | Description | Selected |
|---|---|---|
| Both: record_multi/3 + record/1 | Dual surface mirrors Ecto Multi/Repo | ✓ |
| Multi-only: record_multi/3 | Forces all callers into Ecto.Multi | |
| Macro-based: with_event do ... end | Hides transaction boundary; debuggability cost | |

### Q14: idempotency_key ownership?

| Option | Description | Selected |
|---|---|---|
| Optional caller-provided + unique index | Webhook id from upstream, internal can be nil | ✓ |
| Always required | Noisy for internal recordings | |
| Always auto-generated UUID | Defeats the purpose | |

### Q15: Actor context mechanism?

| Option | Description | Selected |
|---|---|---|
| Process dict via Accrue.Actor.put_current + override keyword | Plug + Oban middleware set it; matches OTel/Logger.metadata | ✓ |
| Explicit on every call | Verbose boilerplate | |
| Global Config.actor_resolver MFA | Surprising, requires docs-dive | |

### Q16: OTel trace_id capture?

| Option | Description | Selected |
|---|---|---|
| Auto-capture from OTel context (conditional) | Zero boilerplate, graceful no-op | ✓ |
| Caller-provided only | Boilerplate everywhere | |

---

## Telemetry

### Q17: Event naming depth?

| Option | Description | Selected |
|---|---|---|
| 4-level: [:accrue, :billing, :subscription, :create] | Matches Ecto/Phoenix depth; domain-level attach | ✓ |
| 3-level | Flatter, loses domain grouping | |
| Per-module macro | Users can't glob patterns | |

### Q18: Ship Telemetry.Metrics helper?

| Option | Description | Selected |
|---|---|---|
| Yes — Accrue.Telemetry.Metrics with defaults | Optional dep; users get counters/distributions free | ✓ |
| No — users define their own | Every user writes same counter defs | |

---

## Fake Processor test-clock

### Q19: Test clock mechanism?

| Option | Description | Selected |
|---|---|---|
| Explicit test clock + advance/2 helper | Matches Stripe test-clock; tests read like prod | ✓ |
| Mox-based time injection | Friction in async concurrent tests | |
| Mutable Agent holding clock | Verbose per-test wiring | |

### Q20: Deterministic IDs shape?

| Option | Description | Selected |
|---|---|---|
| Prefixed counter: cus_fake_00001 | Matches Stripe prefix convention; readable | ✓ |
| Random with seeded RNG | Hard to grep in test output | |
| Hash of inputs | Collides on reused inputs | |

---

## Mailer + PDF behaviour shapes

> This area was reframed after research: four parallel agents investigated Phoenix 1.8 Swoosh conventions, Pow's precedent for wrapping Swoosh, Pay + Laravel Cashier email/PDF patterns, and ChromicPDF + HEEx usage in real Elixir projects. Findings stored as research context in the conversation; decisions below reflect synthesis.

### Q21: Accrue.Mailer behaviour shape?

| Option | Description | Selected |
|---|---|---|
| Semantic + graduated overrides (Pay-style, Pow-compatible) | deliver(type, assigns); 4-rung override ladder; Oban-safe IDs only | ✓ |
| Semantic, one callback per email type | ~15 callbacks; type-safe but bloats behaviour surface | |
| Accept %Swoosh.Email{} directly | Leaks Swoosh, breaks Oban serialization | |

### Q22: Accrue.PDF behaviour shape?

| Option | Description | Selected |
|---|---|---|
| Shape B: render(html_binary, opts) | Matches ChromicPDF's own API; core stays LiveView-free; every real-world example | ✓ |
| Shape A: render(template_module, assigns, opts) | Forces phoenix_live_view into core; zero precedent | |
| Both: B contract, A convenience in core | Same constraint violation as pure Shape A | |

### Q23: Stripe-hosted PDF passthrough?

| Option | Description | Selected |
|---|---|---|
| Yes — source: :auto / :stripe / :local | Cashier-avoidance; zero-config path for Chrome-hostile hosts | ✓ |
| Local only | Users discover lattice_stripe path alone | |

### Q24: Auto-attach invoice PDF to receipt email?

| Option | Description | Selected |
|---|---|---|
| Auto-attach by default, config-disable | Pay's default; PDFs never live in Oban args | ✓ |
| Independent — users opt in | Every serious SaaS rediscovers the flag | |

---

## Auth.Default + monorepo release

### Q25: Accrue.Auth.Default fallback behavior?

| Option | Description | Selected |
|---|---|---|
| Dev-permissive, prod-refuses-to-boot | Loud, early failure; sigra auto-wire preempts | ✓ |
| Always permissive, warn loudly | Dangerously close to shipping unauthed admin | |
| Always refuses | Hurts mix accrue.install demo-ability | |

### Q26: Monorepo version strategy?

| Option | Description | Selected |
|---|---|---|
| Lockstep majors, independent minors/patches | accrue_admin pins {:accrue, "~> 1.0"}; coordinated 1.0 day one | ✓ |
| Strict version lockstep | Can't ship admin-only bugfix | |
| Fully independent | Max user confusion | |

---

## Claude's Discretion

Areas explicitly left to Phase 1 planner/executor (see D-46 block in CONTEXT.md):

- Internal module organization (`lib/accrue/` layout)
- `Accrue.Config` NimbleOptions schema field-by-field details
- Test organization and fixture strategy
- Exact migration filenames/order
- `Accrue.Application.start/2` body (child list if any)
- Internal naming of workers, plugs, middlewares
- Whether `Accrue.Mailer.Default` is its own file or inlined
- Exact count and scope of `Accrue.Emails.*` modules shipped in Phase 1

## Deferred Ideas

Noted for future phases (see `<deferred>` in CONTEXT.md):

- `Accrue.Billing.invoice_pdf` Stripe passthrough — depends on Phase 2 Invoice schema
- Auto-attach invoice PDF default — depends on Phase 2 Invoice + Customer
- Full ~15-template email catalog — lands alongside triggering domain events in Phase 2+
- `Accrue.Integrations.Sigra` concrete callbacks beyond conditional-compile scaffold
- Customer Portal / Checkout Session helpers — Phase 2+
- Stripe Connect — later phase
