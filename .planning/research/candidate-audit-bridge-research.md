# Milestone Next-Step Assessment: Audit Bridge (Threadline Integration)

## 1. Framing & Current State
The "Audit Bridge" candidate aims to sink Accrue's critical billing lifecycle events (e.g., plan upgraded, invoice paid, refund issued) into an external immutable audit platform called Threadline (`SEED-002 #2`).
**Current State:** Accrue already provides its own tamper-evident PostgreSQL audit ledger (`Accrue.Events`) via database triggers that reject `UPDATE` or `DELETE` commands. According to `JTBD-FRONTIER.md`, the library is currently "6 of 6 on the canonical SaaS loop" and operates in an **intake-gated maintenance mode**. The core is fully feature-complete for its scope.

## 2. Pros, Cons, and Tradeoffs
### Pros
* **Cross-Service Compliance:** For organizations standardizing on Threadline as their single-pane-of-glass for SOC2/HIPAA compliance, this bridge prevents billing events from being siloed in Accrue's local database.
* **Separation of Duties:** Sends compliance events to an environment where the application developers don't have database access, satisfying strict enterprise audit requirements.

### Cons
* **Marginal Value for Most Adopters:** Accrue's existing `Accrue.Events` ledger already provides strong immutability and temporal querying (`state_as_of/3`, `timeline_for/3`). This integration solves a problem only enterprise teams with multi-service compliance architectures face.
* **Dependency Surface:** Introduces a new integration adapter that requires maintenance alongside changes to Threadline's API.

### Concrete Example
An operator refunds a customer via `Accrue.Billing.refund/2`. This writes an `Accrue.Events.Schemas.RefundCreated` record to the local `accrue_events` table within an `Ecto.Multi` transaction. The Audit Bridge securely forwards this event—along with the `actor_id` and `trace_id`—to the Threadline API, ensuring the security team sees a non-repudiable log of who issued the refund.

## 3. Idiomatic Elixir / Phoenix Approach
The Elixir ecosystem strongly favors decoupling side-effects from critical business transactions to maintain fault-tolerance and low latency.

**The Anti-Pattern (Footgun):**
Making a synchronous HTTP call to the Threadline API directly inside the `Accrue.Events.record_multi/3` or `Repo.transact/1` boundary. If Threadline is slow or down, the billing transaction fails or blocks the database connection pool, taking down the SaaS application.

**The Idiomatic Approach (Transactional Outbox via Oban):**
* Accrue relies heavily on Oban for robust background jobs (already used for `DispatchWorker` and dunning sweepers).
* Instead of ephemeral `telemetry` hooks (which can drop events if the node crashes before the hook finishes), the bridge should use the **Outbox Pattern**.
* **Implementation:** Inside `Accrue.Events.record_multi/3`, Ecto's `Multi.run` or `Multi.merge` would look for a configured list of `audit_backends` (e.g., `config :accrue, audit_backends: [Accrue.Integrations.Threadline]`). If configured, it appends an `Oban.insert/1` call to the same database transaction.
* The `Accrue.Integrations.Threadline.Worker` processes the job asynchronously, securely passing the event payload and Accrue's `idempotency_key` (or `event.id`) to Threadline. If the network call fails, Oban's robust retry mechanics handle it without impacting the core billing flow.

## 4. Lessons Learned (Ecosystem Space)
* **Never Drop Compliance Data (Node.js/Rails lesson):** Many frameworks use fire-and-forget in-memory queues (like `EventEmitter` in Node or basic ActiveSupport::Notifications without background jobs) for audit logs. If the server OOMs before the network call completes, the audit trail drifts from the database reality. Relying on an ACID-compliant background queue like Oban is essential for financial/audit data.
* **Idempotency is Mandatory:** When syncing to an external system, retries will happen. Accrue events already auto-capture an `idempotency_key`; this must be mapped directly to the external system's deduplication key to prevent duplicate audit logs during network timeouts.
* **Zero Schema Pollution:** Good integrations don't force core schema changes. Avoid adding `synced_to_threadline_at` to the `accrue_events` table; rely on Oban's execution state or external system idempotency instead.

## 5. Developer Ergonomics (DX) & Least Surprise
For the Phoenix SaaS developer adopting this, the integration must feel invisible:
1. **Drop-in configuration:**
   ```elixir
   config :accrue, audit_backends: [Accrue.Integrations.Threadline]
   ```
2. **Zero code changes:** The developer should not need to modify any of their `Accrue.Billing.subscribe/3` or `refund/2` calls. The events are automatically routed.
3. **No boot crashes:** If the Threadline API keys are missing in development, the system should gracefully log a warning rather than crashing the supervision tree, or provide a `Threadline.Sandbox` backend for local dev.

## 6. One-Shot Recommendations & Blunt Maintainer Takeaway

**Maintainer Verdict: PARK THIS MILESTONE.**

As explicitly noted in `JTBD-FRONTIER.md` and the `MILESTONE-NEXT-STEP-ASSESSMENT.md` instructions: *If the honest answer is "nothing major, this is basically done for its scope," say that directly.*

**Recommendation 1: Defer Execution (Intake-Gated)**
Accrue has reached feature completion ("6 of 6 on the canonical SaaS loop"). Building the Threadline Audit Bridge right now is speculative, multi-file work that violates **Stop Rule S1** of the library's maintenance posture. Because Accrue already possesses a tamper-evident audit ledger, this bridge provides minimal marginal utility. **Do not build it unless a concrete adopter explicitly requests it.**

**Recommendation 2: Use Oban for the Outbox (If authorized later)**
If an adopter requires this, strictly avoid ephemeral `telemetry` for compliance data. Enqueue an `Oban` worker directly within the `Accrue.Events` `Ecto.Multi` transaction to guarantee delivery.

**Recommendation 3: Maintain Zero-Schema Isolation**
If built, the integration must exist entirely within `Accrue.Integrations.Threadline`, requiring no migrations or structural awareness from the core `Accrue.Events` ledger.

---
*(Bookkeeping applied: No feature code written. Validated that Accrue remains feature-complete. Reaffirmed intake-gated maintenance mode.)*