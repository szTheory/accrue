# Accrue Admin / Operator UI — Full Journey, IA, Screen, and Interaction Blueprint

**Use case:** reference document + LLM context for designing the ideal Accrue admin/operator UI from first principles.

**Product context assumed:** the Accrue library summary supplied in the prompt. If the codebase or product is currently named Scoria in another context, treat this document's “Accrue” naming as a replaceable product label, but keep the domain language unless the product intentionally renames the domain.

**Goal:** map the admin/operator experience in breadth and depth: personas, jobs-to-be-done, information architecture, visual hierarchy, screen inventory, page-level layouts, component patterns, interaction flows, modals, confirmations, responsive behavior, accessibility, and the storyboards for the high-value operator journeys.

---

## 1. Design thesis

Accrue Admin is not a generic CRUD interface. It is an **operator control plane over billing state**.

The UI should answer three questions faster than anything else:

1. **What needs attention?**
   - Failed or dead webhooks.
   - Past-due subscriptions.
   - Open invoices that need work.
   - Failed usage reports.
   - Fee reconciliation mismatches.
   - Expiring cards.
   - Connect account capability or payout issues.

2. **What is the customer's true billing state?**
   - Processor state.
   - Local projection state.
   - Application entitlement state.
   - Audit/event causality.

3. **What safe action can the operator take now?**
   - The UI should expose allowed verbs, hide or demote impossible verbs, and explain blocked actions in precise language.
   - Every state-changing action should leave a clear audit trail.
   - Every destructive or money-moving action should use a more guarded interaction pattern.

The desired feel is **calm, exact, dense, and durable**: a maintainer-grade operations console, not a fintech dashboard.

---

## 2. External UX anchors to preserve in the design process

Use these as method anchors, not style anchors.

1. **Journey maps should be goal-based.** They should describe what a person does over time to accomplish a goal, including steps, touchpoints, pain points, and opportunities. Source: Nielsen Norman Group, “Journey Mapping 101” and “User Journeys vs. User Flows.”
2. **Separate journeys from flows.** A journey is the broader goal narrative; a flow is the precise interaction path through UI states. Source: Nielsen Norman Group, “User Journeys vs. User Flows.”
3. **Use service-blueprint thinking where Accrue has backstage systems.** Webhooks, processor state, local projections, Oban jobs, emails, and ledger entries are backstage processes that should be visible enough for operators to reason about failures. Source: Nielsen Norman Group, “Service Blueprints: Definition.”
4. **Build interaction patterns to WCAG 2.2 AA expectations.** Treat keyboard access, focus order, error recovery, target size, contrast, status messages, and reduced motion as design requirements, not implementation cleanup. Source: W3C WCAG 2.2.
5. **Use WAI-ARIA Authoring Practices for modal dialogs, disclosure/accordion sections, tabs where unavoidable, and other advanced widgets.** Source: W3C WAI-ARIA Authoring Practices Guide.
6. **Use summary-list style thinking for detail headers.** Key facts should be readable as label/value pairs, with action affordances nearby only where the action changes that specific fact. Source: GOV.UK Design System Summary List.
7. **Use explicit error summaries and field-level error messages for forms.** State what went wrong and how to fix it; preserve user-entered data after validation errors. Source: GOV.UK Design System Error Summary / Error Message / Validation guidance.

---

## 3. Product mental model to make visible in the UI

The admin UI should constantly, subtly reinforce Accrue's operating model:

### 3.1 Three worlds

1. **Processor**
   - Stripe or Braintree is canonical for actual payment state.
   - Fake processor is available for local/dev/test workflows.

2. **Application**
   - The host app owns the user/org, auth boundary, and entitlements.
   - Accrue stores billing projections associated with the app's owner records.

3. **Operations**
   - The admin UI serves support, finance, developer, recovery, and audit workflows.
   - It must show causality, not just values.

### 3.2 Local projections

Many records are read-optimized projections of processor state. The UI should represent this without making the UI feel academic:

- Use subtle source labels such as **Processor**, **Local projection**, **Application**, and **Audit**.
- On detail pages, use a small “Source” column or chip where ambiguity matters.
- In raw/debug sections, show `processor`, `processor_id`, local UUID, `last_stripe_event_ts`, `last_stripe_event_id`, and `lock_version`.
- Avoid saying “source of truth” everywhere. Use it only in tooltips or debug panels.

### 3.3 Two write paths

Operator actions and webhook-applied changes are different:

- **Operator path:** validates allowed state transitions.
- **Webhook path:** accepts canonical processor state and records causality.

UI implication:

- Operator action menus should present only valid actions.
- Event timeline items should clearly mark actor type: **Admin**, **Webhook**, **System**, **Oban**, **User**.
- When the processor changed something asynchronously, say: **Updated by webhook `invoice.paid`** rather than **System updated invoice**.

---

## 4. User-facing domain language

The UI should be consistent enough that backend naming can eventually move toward it.

### 4.1 Primary nouns

Use these labels in navigation, page titles, filters, and empty states:

| Backend/domain concept | User-facing label | Notes |
|---|---|---|
| Customer | Customer | Owner details visible inside summary. |
| Owner | App owner | Use only where ambiguity matters: “App owner: org_123”. |
| PaymentMethod | Payment method | Do not expose raw card/payment PII. |
| Subscription | Subscription | State-heavy entity. |
| SubscriptionItem | Subscription item | Use “Plan item” only if product catalog UX demands it later. |
| SubscriptionSchedule | Schedule | In subscription context: “Schedule.” In global context: “Subscription schedule.” |
| Invoice | Invoice | Legal state machine. |
| InvoiceItem | Invoice line item | UI label: “Line item.” |
| Charge | Payment | In most operator contexts, “Payment” is more human. Keep “Charge” in raw/debug. |
| Refund | Refund | A child of a payment. |
| Coupon | Coupon | Internal discount definition. |
| PromotionCode | Promotion code | Customer-entered code. |
| MeterEvent | Usage report | “Meter event” in dev/debug. |
| MeterDefinition | Meter definition | Use “Meter” in most UI. |
| MeteredRenewal | Metered renewal | Billing-ops context. |
| CheckoutSession | Checkout session | Acquisition/debug context. |
| Connect Account | Connected account | Avoid “Connect” as noun except nav group. |
| EntitlementSummary | Entitlements | Always label advisory/cache state. |
| WebhookEvent | Webhook event | Incident/debug context. |
| Event ledger | Event log / Audit log | Nav can say “Event log”; detail language can say “audit ledger.” |

### 4.2 Action verbs

Use concrete verbs that match the engine:

- Subscriptions: **Subscribe**, **Cancel now**, **Cancel at period end**, **Resume**, **Pause collection**, **Unpause**, **Swap plan**, **Update quantity**, **Comp subscription**, **Add item**, **Remove item**, **Preview invoice**.
- Invoices: **Finalize**, **Send**, **Pay**, **Void**, **Mark uncollectible**, **Add line item**, **Remove line item**, **Open PDF**, **Open hosted invoice**.
- Payments: **Refund**, **Create payment**, **Create setup intent**, **Sync payment method**.
- Discounts: **Create coupon**, **Create promotion code**, **Apply promotion code**, **Deactivate**.
- Usage: **Report usage**, **Retry report**, **Mark reviewed** if a local operator-only review flag is added.
- Webhooks: **Replay**, **Bulk replay**, **Mark dead**, **Prune**.
- Connect: **Create account**, **Create account link**, **Create login link**, **Reject account**, **Sync account**.

Avoid vague verbs like **Manage**, **Handle**, **Fix**, **Resolve** unless paired with a precise object and outcome.

### 4.3 State labels

The UI should use exact backend statuses as chips, with a short explanation available on hover/focus.

**Subscription states:** `trialing`, `active`, `past_due`, `canceled`, `unpaid`, `incomplete`, `incomplete_expired`, `paused`.

**Invoice states:** `draft`, `open`, `paid`, `uncollectible`, `void`.

**Webhook states:** `received`, `processing`, `succeeded`, `failed`, `dead`, `replayed`.

**Refund states:** `pending`, `requires_action`, `succeeded`, `failed`, `canceled`.

**Schedule states:** `not_started`, `active`, `completed`, `released`, `canceled`.

**Usage report states:** `pending`, `reported`, `failed`.

Do not invent friendlier synonyms that obscure the legal or processor meaning. Add helper text instead.

---

## 5. Personas and operating altitudes

### 5.1 Persona 1 — Operator / Founder

**Question:** Is billing healthy right now?

**Altitude:** glance.

**Primary entry:** Home.

**UI needs:**

- Exceptions first.
- Few KPIs, not a metric wall.
- Obvious entry to the most urgent queue.
- Confidence that no critical issue is hidden.

### 5.2 Persona 2 — Customer Support

**Question:** This customer has a billing issue; what is the full story?

**Altitude:** single-customer investigation.

**Primary entry:** global search → customer 360.

**UI needs:**

- Fast search by email, name, owner ID, customer ID, subscription ID, invoice number, processor ID.
- One page that connects subscription, invoice, payment, payment method, entitlement, processor, and event state.
- Clear explanation of why a customer is blocked.
- Safe actions: send invoice, retry payment if available, open hosted invoice, update payment method, apply promotion code, sync.

### 5.3 Persona 3 — Finance / Billing Ops

**Question:** What invoice/payment work needs to be cleared today?

**Altitude:** queue processing.

**Primary entry:** Invoices worklist.

**UI needs:**

- Dense table with open/past-due/default filters.
- Sort by due date, amount remaining, status age, customer.
- Inline triage affordances.
- Detail panels for line items, discounts, tax, PDF, hosted link, events.
- Bulk actions only where safe and auditable.

### 5.4 Persona 4 — Recovery / Growth Ops

**Question:** What revenue is at risk, and where is each customer in dunning?

**Altitude:** funnel + at-risk queue.

**Primary entry:** Recovery.

**UI needs:**

- Dunning funnel by campaign step.
- Past-due age and amount at risk.
- Card expiration and payment-method health.
- Per-subscription recovery timeline.
- Entry to support/customer 360 for individual cases.

### 5.5 Persona 5 — Developer / Integration

**Question:** Why did this webhook or usage report fail, and what caused downstream state?

**Altitude:** incident/debug.

**Primary entry:** Webhooks / Event log / Usage failures.

**UI needs:**

- DLQ default lens.
- Raw request body and parsed payload.
- Processor event ID, timestamps, replay status, error traces.
- Causal chain from webhook → event ledger → affected objects.
- Replay action with guardrails and result feedback.

### 5.6 Persona 6 — Compliance / Audit

**Question:** Who did what, when, and what caused it?

**Altitude:** forensic.

**Primary entry:** Event log saved lens.

**UI needs:**

- Actor filters.
- Subject filters.
- Immutable event detail.
- Export/copy affordances if supported.
- State-as-of reconstruction where available.
- Causality links with no ambiguity.

---

## 6. Information architecture

### 6.1 Primary navigation

Recommended left navigation groups:

1. **Home**
   - Overview and exception launchpad.

2. **Billing**
   - Customers
   - Subscriptions
   - Invoices
   - Payments

3. **Recovery**
   - At-risk subscriptions
   - Dunning campaigns
   - Expiring cards

4. **Usage**
   - Usage reports
   - Meters
   - Metered renewals

5. **Catalog**
   - Coupons
   - Promotion codes

6. **Connect**
   - Connected accounts

7. **Developer**
   - Webhooks
   - Event log
   - Checkout sessions
   - Dev tools, only in Fake/dev/test mode

8. **Settings**
   - Processor status/config readout
   - Branding overrides if exposed
   - Email templates/previews if not kept under Developer
   - Theme/accessibility preferences

### 6.2 Navigation badge rules

Badges should represent work, not counts for their own sake.

- **Home:** no badge; it is the dashboard.
- **Invoices:** count of actionable open invoices, not all open invoices if the current lens is scoped.
- **Recovery:** count of at-risk subscriptions currently in dunning or past due.
- **Usage:** failed usage reports.
- **Connect:** accounts with outstanding requirements or disabled payouts/charges.
- **Developer → Webhooks:** failed/dead webhook count.
- **Event log:** no badge unless there is an audit review queue feature.

Badge colors must not be the only signal. Use label text: **3 dead**, **18 at risk**, **7 failed**.

### 6.3 Tenant/org scope

The selected org scope is global chrome, not a filter hidden inside pages.

Desktop:

- Place org selector in the top-left header area above or beside nav.
- Show current scope label and compact owner ID in mono.
- Changing org opens a searchable popover.
- All generated URLs preserve `?org=`.
- If no org is scoped, show **All organizations** with a warning/help tooltip if actions are restricted.

Mobile:

- Org scope appears at top of the nav drawer and in page headers as a small chip.

### 6.4 Environment and processor visibility

Show environment/processor status in persistent chrome:

- **Live / Test / Fake** environment pill.
- Processor selector/readout where multi-processor data can appear.
- If Fake processor is active, use a clear but calm banner: **Fake processor active. Actions update local test state only.**
- If webhook processing is degraded, show a global status strip with link to Webhooks.

---

## 7. Global shell and layout

### 7.1 Desktop shell

**Structure:**

- Left sidebar, fixed width around 240–280px.
- Main content max width should not overly constrain tables; detail pages can use a readable max width for text-heavy panels.
- Top utility row inside main area:
  - Breadcrumbs.
  - Global search / command entry.
  - Org scope chip.
  - Environment chip.
  - Theme/user menu.

**Visual hierarchy:**

1. Current page title.
2. State/action row.
3. Exception/worklist content.
4. Drilldown content.
5. Raw/debug content.

### 7.2 Tablet shell

- Sidebar collapses to icon rail or drawer.
- Page title and action buttons remain visible.
- Tables reduce visible columns and support row expansion.
- Search remains accessible as a top button/input.

### 7.3 Mobile shell at 360px

- Bottom or top menu button opens nav drawer.
- Search is a full-width control near top of Home and list screens.
- Tables become stacked record cards.
- Detail summary lists stack label above value.
- Primary actions become sticky bottom action bar only when the action is safe/frequent. Destructive actions stay in overflow.
- Modals become full-screen sheets with clear close/back behavior.

### 7.4 Keyboard model

Core shortcuts:

- `/` or `⌘K` / `Ctrl+K`: global search/command.
- `g h`: Home.
- `g c`: Customers.
- `g s`: Subscriptions.
- `g i`: Invoices.
- `g w`: Webhooks.
- `?`: shortcuts overlay.
- `Esc`: close popover/modal if safe.

Do not make keyboard shortcuts the only way to perform actions.

---

## 8. Reusable screen grammar

The UI should have repeatable grammar, but not force every surface into identical layouts.

### 8.1 Overview grammar

Used for Home and Recovery.

Order:

1. **Attention rail** — exceptions requiring action.
2. **Task launchers** — verb-led shortcuts.
3. **Search** — visible and primary for support workflows.
4. **KPI strip** — demoted, clickable context.
5. **Recent activity** — short, audit-backed feed.

### 8.2 Worklist grammar

Used for Invoices, Webhooks DLQ, Usage failures, Connect requirements.

Order:

1. Breadcrumbs.
2. Title and default lens label.
3. Stat strip for the queue.
4. Saved views / filters.
5. Filter chips with clear-all.
6. Dense table or mobile cards.
7. Pagination.
8. Optional side preview panel for power-user triage.

Default view should be actionable work, not “all records.” Provide **All** one click away.

### 8.3 Index/list grammar

Used for Customers, Subscriptions, Payments, Coupons, Promotion Codes, Connected Accounts.

Order:

1. Header.
2. Search/filter row.
3. Stat strip where meaningful.
4. Table/cards.
5. Pagination.

### 8.4 Detail grammar

Used for single records.

Order:

1. Breadcrumbs.
2. Title row with identity, status, and primary actions.
3. Always-on summary list.
4. Diagnosis / “why this state?” card when applicable.
5. Contextual action panel.
6. Related records strip.
7. Drill sections.
8. Activity timeline.
9. Raw JSON / debug payload.

Tabs are allowed only for peer record sets, not for hiding primary state. Prefer anchored sections and collapsible drilldowns.

### 8.5 Incident/debug grammar

Used for Webhook detail, Event detail, Usage report failure, Checkout session detail.

Order:

1. Incident summary: state, last error, affected object, time.
2. Causality graph/timeline.
3. Replay/retry action panel.
4. Raw payload and headers.
5. Processing attempts.
6. Related records.

### 8.6 Action wizard grammar

Used for sensitive or multi-step actions:

1. Intent screen: what will happen.
2. Inputs screen: fields, constraints, validation.
3. Preview screen: state/money/timeline impact.
4. Step-up authentication if required.
5. Final confirmation.
6. Result screen/toast with event link.

For simple non-sensitive actions, a single modal may be enough, but it still needs preview and error recovery when money or legal state changes.

---

## 9. Design system component inventory

### 9.1 App shell

**Purpose:** persistent operator frame.

**Contains:** product/host logo, org scope, nav groups, badges, environment chip, global search, user menu.

**Variants:** desktop sidebar, tablet rail, mobile drawer.

**Rules:**

- Navigation labels use domain nouns.
- Badges show actionable queues only.
- Live/test/fake mode visible at all times.

### 9.2 Page header

**Contains:** breadcrumbs, title, subtitle, status chip, processor chip, primary actions, overflow actions.

**Rules:**

- Maximum two visible primary/secondary actions.
- Destructive actions go in overflow unless the page is specifically a destructive confirmation screen.
- Subtitles should clarify identity: email, invoice number, subscription ID, processor ID.

### 9.3 Summary list

**Purpose:** always-readable key facts.

**Rows:** label, value, optional source, optional action.

**Use for:** customer identity, invoice money rollups, subscription state, payment method, connected account capabilities.

**Rules:**

- Use tabular numerals for money and dates.
- Prefer labels like **Amount due**, **Current period**, **Default payment method**.
- Add per-row action only when changing that row is a common task.

### 9.4 Status badge

**Purpose:** exact state display.

**Variants:** success, warning, danger, neutral, info, terminal, draft.

**Rules:**

- Include text and optional icon.
- Do not rely on color alone.
- Tooltip explains state and allowed next actions.
- Use mono for raw enum only if the UI deliberately exposes the enum.

### 9.5 Attention item

**Purpose:** exception rail entry.

**Contains:** severity marker, noun, count, short fact, primary link, age.

**Example:**

- **Dead webhooks** — 3 events stopped processing. Oldest 42m ago. **Review**
- **Past-due subscriptions** — 18 subscriptions in dunning. **Open recovery**

### 9.6 Dense table

**Purpose:** operator worklists.

**Features:**

- Server pagination.
- Saved views.
- Filters.
- Sort.
- Column density controls if needed.
- Row click opens detail.
- Row action menu.
- Bulk selection only where safe.

**Column priority:** identity → state → money → time → next action → processor/debug.

**Mobile:** record cards with the same priority order.

### 9.7 Filter chips and saved views

**Saved view row:** All, Action required, Past due, Failed, Dead, Needs review, Mine if assignment exists.

**Filter chip row:** status, processor, date range, amount range, owner/org, currency, dunning step, actor type.

**Rules:**

- Show result count after filtering.
- Clear-all always available.
- Filter state encoded in URL.

### 9.8 Timeline

**Purpose:** audit and causality.

**Item structure:**

- Timestamp.
- Actor chip.
- Verb.
- Subject.
- State delta summary.
- Causality links.
- Expand for payload diff.

**Example:**

`Webhook invoice.paid applied → Invoice marked paid → Subscription active → Entitlements synced`

### 9.9 Causality graph

**Purpose:** make upstream/downstream event chains legible.

**Use for:** webhook detail, event detail, support diagnosis.

**Layout:** left-to-right chain on desktop; vertical stack on mobile.

**Nodes:** processor event, webhook event, ledger event, object state change, email sent, entitlement sync.

### 9.10 Raw JSON viewer

**Purpose:** debug without leaving admin.

**Features:**

- Collapsible tree.
- Copy full JSON.
- Copy path.
- Search within payload.
- Redaction marker for sensitive fields.
- Monospace with line wrapping toggle.

### 9.11 Action menu

**Purpose:** valid verbs for current object state.

**Rules:**

- Show unavailable actions only if explaining them prevents confusion. Otherwise hide.
- Group actions: Normal, Processor links, Dangerous.
- Dangerous actions use danger styling and confirmation.
- Menu item labels are verbs: **Void invoice**, not **Void** if ambiguity exists.

### 9.12 Modal dialog

**Purpose:** focused interruption for contained tasks.

**Rules:**

- Use for short tasks with known scope.
- Trap focus.
- Return focus to invoking control after close.
- Background inert.
- Use clear title: **Refund payment**, **Void invoice**, **Replay webhook**.
- Primary action label repeats the verb.
- Destructive primary button uses danger treatment and exact label.

### 9.13 Full-screen sheet

**Purpose:** mobile replacement for large modals and multi-step actions.

**Rules:**

- Header with title and close/back.
- Sticky footer with primary/secondary actions.
- Preserve form state when validation fails.

### 9.14 Step-up authentication panel

**Purpose:** guarded confirmation for sensitive actions.

**Triggers:** refunds, voiding/marking uncollectible if policy requires, payment method detachment if risky, Connect account rejection, bulk replay if high risk.

**Contents:**

- Action summary.
- Impact summary.
- Auth input.
- Confirmation phrase only for rare destructive actions, not routine refunds.
- Link to policy/help if available.

### 9.15 Toast / flash

**Purpose:** non-blocking result feedback.

**Rules:**

- Include object and outcome.
- Include link to event detail for state-changing actions.
- Use status-live announcements for assistive technology.

Example: **Refund created. View event.**

### 9.16 Inline validation and error summary

**Purpose:** fast recovery.

**Rules:**

- Top error summary on submit.
- Field-level message directly below field.
- Preserve all entered values.
- State both the fact and next action.

Example: **Amount must be less than or equal to $48.00 remaining.**

### 9.17 Empty state

**Purpose:** explain absence without cheerleading.

**Structure:** noun, condition, next appearance/action.

Examples:

- **No failed webhooks.** Failed or dead webhook events appear here when processing stops.
- **No open invoices.** Invoices appear here after they are finalized and still have amount remaining.

---

## 10. Screen inventory

This inventory is intentionally broad. Some teams may ship a smaller v1, but the design language should anticipate the full surface.

| Area | Screen | Default lens | Primary persona | Notes |
|---|---|---|---|---|
| Home | Overview | Exceptions | Founder/operator | Daily glance. |
| Billing | Customers list | Recent / search-first | Support | Search is dominant. |
| Billing | Customer 360 | State summary | Support | The most important detail screen. |
| Billing | Subscriptions list | Actionable / active | Support + recovery | Status-heavy. |
| Billing | Subscription detail | Current state | Support | Actions and timeline. |
| Billing | Subscription schedule detail | Current/next phase | Billing ops | Can be nested under subscription. |
| Billing | Invoices list | Open/actionable | Finance | Worklist. |
| Billing | Invoice detail | Legal/money summary | Finance/support | State machine visible. |
| Billing | Payments list | Recent payments/refunds | Finance/support | Money movement ledger. |
| Billing | Payment detail | Payment + refunds | Finance/support | Refund entry. |
| Billing | Refund detail | Refund state | Finance/support | May be nested under payment. |
| Recovery | Recovery dashboard | At-risk | Recovery ops | Funnel and queue. |
| Recovery | Dunning subscription detail | Campaign timeline | Recovery ops | Can be section on subscription. |
| Recovery | Expiring cards | Upcoming expirations | Recovery/support | Optional separate lens. |
| Usage | Usage reports | Failed/pending | Developer/billing ops | DLQ-like worklist. |
| Usage | Usage report detail | Processing state | Developer | Raw payload + retry. |
| Usage | Meters list | Active meters | Developer/billing ops | Definitions. |
| Usage | Meter detail | Usage history | Developer/billing ops | Linked subscription items. |
| Usage | Metered renewals | Actionable | Billing ops | State machine. |
| Catalog | Coupons list | Active | Billing ops | Internal discount definitions. |
| Catalog | Coupon detail | Redemption summary | Billing ops | Related promotion codes. |
| Catalog | Promotion codes list | Active | Billing/support | Customer-facing codes. |
| Catalog | Promotion code detail | Redemption summary | Billing/support | Apply/deactivate. |
| Connect | Connected accounts list | Requirements/actionable | Platform ops | Marketplace/platform. |
| Connect | Connected account detail | Capabilities + requirements | Platform ops | Account links, login links. |
| Developer | Webhooks list | Failed/dead | Developer | Incident queue. |
| Developer | Webhook detail | Error + causality | Developer | Replay. |
| Developer | Event log | Recent / filtered | Audit/developer | Saved compliance lens. |
| Developer | Event detail | Immutable event | Audit/developer | Causality and payload. |
| Developer | Checkout sessions list | Recent / incomplete | Support/developer | Acquisition debugging. |
| Developer | Checkout session detail | Status/payment status | Support/developer | Related customer/subscription. |
| Developer | Email previews | Template list | Developer | Fake/dev only or Settings. |
| Developer | Webhook fixtures | Fixture library | Developer | Fake/dev only. |
| Developer | Time travel clock | Current fake time | Developer | Fake only. |
| Developer | Component gallery | Components | Developer/designer | Dev only. |
| Settings | Processor status | Config readout | Admin/developer | Read-only where possible. |
| Settings | Theme/preferences | User prefs | All | Theme, density, reduced motion. |

---

## 11. Home overview screen

### 11.1 Purpose

Answer: **Is billing healthy right now, and what should I inspect first?**

### 11.2 Desktop layout thumbnail

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Breadcrumbs / org scope / environment / search                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ Home                                      [⌘K Search customers/invoices…]   │
│ Billing state, modeled clearly.                                             │
├───────────────────────────────────────┬─────────────────────────────────────┤
│ Attention                             │ Task launchers                      │
│ ┌ Dead webhooks        3 Review ┐     │ [Find customer] [Work invoices]     │
│ ├ Past-due subs       18 Open   ┤     │ [Review dunning] [Replay webhooks]  │
│ ├ Failed usage         7 Retry  ┤     │ [Create coupon] [Open event log]    │
│ └ Connect requirements 4 Open   ┘     │                                     │
├───────────────────────────────────────┴─────────────────────────────────────┤
│ KPI strip: open amount · MRR-ish if available · recovered · failed fees     │
├─────────────────────────────────────────────────────────────────────────────┤
│ Recent activity                                                             │
│ 10:42 webhook invoice.paid → invoice paid → subscription active             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 11.3 Content hierarchy

1. Attention rail.
2. Global search.
3. Task launchers.
4. KPIs.
5. Recent activity.

### 11.4 Attention rail item details

Each item has:

- Severity.
- Count.
- Oldest age or newest event.
- Short explanation.
- Primary action.

Example:

**Dead webhooks** 3  
Oldest stopped 42m ago. Events will not update local projections until replayed.  
**Review webhooks**

### 11.5 Home interactions

- Clicking an attention item routes to the corresponding worklist with filters pre-applied.
- Hover/focus on a KPI shows definition.
- Clicking a KPI routes to a list filtered to the metric's underlying records.
- Search opens the command palette, with focus inside the input.
- Recent activity items open event detail or the affected record.
- Live updates can insert a new attention item or increment a count with subtle motion; no distracting animation.

### 11.6 Empty state

When no exceptions exist:

- Show a calm “No action required” panel.
- Keep task launchers and search visible.
- Show recent activity so the page does not feel dead.

Microcopy:

**No action required.**  
Failed webhooks, past-due subscriptions, failed usage reports, and Connect account requirements appear here when they need review.

### 11.7 Mobile layout

Order:

1. Header.
2. Search.
3. Attention cards.
4. Task launcher grid, two columns or single column at 360px.
5. KPI scroll row.
6. Recent activity.

---

## 12. Global search and command palette

### 12.1 Purpose

Support's fastest route to customer 360 and operators' fastest route to objects/actions.

### 12.2 Entry points

- Header search input.
- `⌘K` / `Ctrl+K`.
- `/` when not typing in a form.
- Home search field.

### 12.3 Searchable objects

- Customer name/email.
- App owner ID.
- Customer UUID.
- Processor customer ID.
- Subscription UUID / processor ID.
- Invoice number / UUID / processor ID.
- Payment/charge UUID / processor ID.
- Promotion code string.
- Webhook event ID.
- Event ledger ID.
- Checkout session ID.

### 12.4 Palette layout

```
┌───────────────────────────────────────────────┐
│ Search Accrue…                            Esc │
├───────────────────────────────────────────────┤
│ Customers                                    │
│  jane@example.com      Customer · active      │
│  Jane Co               Owner org_123          │
├───────────────────────────────────────────────┤
│ Invoices                                     │
│  INV-0042              open · $48.00 due      │
├───────────────────────────────────────────────┤
│ Actions                                      │
│  Work open invoices                           │
│  Review dead webhooks                         │
└───────────────────────────────────────────────┘
```

### 12.5 Result behavior

- Arrow keys move through results.
- Enter opens selected result.
- Result groups show count if more are available.
- Recent objects show before typing.
- When query exactly matches an ID, put exact match first.
- “No results” state should suggest searchable IDs.

### 12.6 Actions in command palette

Allowed actions:

- Navigate to queues.
- Open create screens.
- Open settings/dev tools.

Avoid destructive actions directly in the palette. The palette can open the relevant detail/action modal but should not execute destructive work.

---

## 13. Customers list

### 13.1 Purpose

Find a customer or inspect customer population.

### 13.2 Default behavior

Search-first. The list can show recent customers, but the search input is primary.

### 13.3 Desktop layout

Header:

- Breadcrumb: Billing / Customers.
- Title: Customers.
- Subtitle: Customer projections across processors.
- Action: optional **Sync customer** if supported.

Filters:

- Processor.
- Has active subscription.
- Has open invoice.
- Payment method status.
- Entitlement status.
- Created date.
- Org scope.

Table columns:

1. Customer: name/email.
2. App owner: owner type + owner ID.
3. Status summary: active/past_due/open invoice/blocked if derivable.
4. Default payment method.
5. Open amount.
6. Processor.
7. Updated.

### 13.4 Row interactions

- Row click opens customer 360.
- Hover/focus reveals copy buttons for email and IDs.
- Row action menu:
  - View customer.
  - View invoices.
  - View subscriptions.
  - Open processor customer if URL available.

### 13.5 Mobile card

Card order:

1. Name/email.
2. Status chips.
3. Owner.
4. Open amount.
5. Default payment method.
6. Last updated.
7. Actions.

---

## 14. Customer 360 detail

### 14.1 Purpose

Answer support's central question: **What is this customer's complete billing story?**

### 14.2 Page header

Title: customer name or email.  
Subtitle: app owner + processor customer ID.  
Status chips: active subscription, open invoice, payment method present, entitlements synced, processor.

Primary actions:

- **Open billing portal** if available.
- **Create invoice** or **Create payment** only if engine supports safe operator initiation.
- Overflow: sync customer, apply promotion code, attach payment method, set default method, open processor.

### 14.3 Always-on summary list

Rows:

- Customer.
- Email.
- App owner.
- Processor.
- Processor customer ID.
- Default payment method.
- Preferred locale.
- Preferred timezone.
- Entitlements synced at.
- Open amount.
- Active subscriptions.

Each row can include source label where useful.

### 14.4 “Why blocked?” diagnosis card

This should be the signature support component.

It synthesizes:

- Entitlement state.
- Subscription status.
- Invoice status.
- Payment status.
- Webhook lag/failure.
- Payment method state.

Possible output patterns:

**Customer appears blocked because the active entitlement cache has not synced after payment.**  
Invoice INV-0042 is paid. Subscription sub_123 is active. Last entitlement sync was before the `invoice.paid` webhook.  
Actions: **View webhook**, **Sync entitlements** if supported, **Open event chain**.

**Customer appears blocked because the subscription is `past_due`.**  
Invoice INV-0042 has $48.00 remaining and the default payment method failed.  
Actions: **Send hosted invoice**, **Open payment method**, **View dunning timeline**.

If the UI cannot determine blocked status, say:

**No local blocking reason detected.**  
Review application-level authorization outside Accrue if the customer remains blocked.

### 14.5 Main content sections

1. **Current state**
   - Active subscriptions.
   - Open invoices.
   - Recent payments/refunds.
   - Entitlement summary.

2. **Subscriptions**
   - Compact table/cards.
   - Status, plan/items, period, cancel/pause status, dunning status.
   - Action: View subscription.

3. **Invoices**
   - Open first, then recent.
   - Invoice number, state, total, amount remaining, due date, PDF/hosted links.

4. **Payments and refunds**
   - Charges and refund children.
   - Fee settlement state.

5. **Payment methods**
   - Default first.
   - Brand/last4/expiration.
   - Expiring soon indicator.
   - Actions: set default, detach, sync.

6. **Entitlements**
   - Count, truncated flag, synced_at.
   - Explain advisory/cache nature.

7. **Checkout sessions**
   - Incomplete/recent sessions for acquisition debugging.

8. **Activity timeline**
   - Subject timeline across customer, subscriptions, invoices, payments.

9. **Raw data**
   - Local projection.
   - Processor payload.

### 14.6 Interaction details

- Summary cards link to the underlying object.
- Activity timeline can filter by object type.
- Copy buttons for IDs show a short toast: **Copied customer ID.**
- Applying a promotion code opens a modal with code entry, validation, preview of affected subscription/invoice, and confirmation.
- Attach payment method likely opens a processor-hosted/session-based flow; if so, the UI explains handoff and return state.
- Sync actions show progress and final event link.

### 14.7 Mobile behavior

- Header chips wrap.
- Summary list stacks.
- “Why blocked?” appears before any tabular data.
- Sections collapse by default after Current state.
- Sticky bottom action: **Open billing portal** if common; otherwise no sticky action.

---

## 15. Subscriptions list

### 15.1 Purpose

Find subscriptions and work subscription state exceptions.

### 15.2 Default saved views

- Action required: `past_due`, `unpaid`, `incomplete`, `paused` with risk flags.
- Active.
- Trialing.
- Canceling at period end.
- Canceled.
- All.

### 15.3 Filters

- Status.
- Processor.
- Plan/price.
- Dunning state.
- Trial ending date.
- Current period end.
- Cancel at period end.
- Has discount.
- Tax enabled.
- Org.

### 15.4 Table columns

1. Customer.
2. Subscription status.
3. Items/plan summary.
4. Quantity.
5. Period end.
6. Amount / latest invoice if available.
7. Dunning age / past-due since.
8. Processor.
9. Updated.

### 15.5 Row actions

- View subscription.
- View customer.
- Preview invoice.
- Pause/unpause if valid.
- Cancel at period end if valid.

Destructive actions should not execute inline; they open a modal/wizard.

---

## 16. Subscription detail

### 16.1 Purpose

Understand current subscription state and safely change it.

### 16.2 Header

Title: Subscription.  
Subtitle: customer + processor ID.  
Status chips: subscription state, dunning state, cancel-at-period-end, paused, processor.

Primary actions:

- **Preview invoice**.
- One context-sensitive primary state action:
  - Active/trialing: **Cancel at period end** or **Pause collection**, depending product policy.
  - Past due: **View recovery**.
  - Paused: **Unpause**.
  - Canceled: **Resume** only if engine supports.

Overflow:

- Cancel now.
- Swap plan.
- Update quantity.
- Add item.
- Remove item.
- Apply promotion code.
- Comp subscription.
- Open processor subscription.

### 16.3 Summary list

Rows:

- Customer.
- Status.
- Current period.
- Trial period.
- Cancel at period end.
- Pause collection.
- Dunning campaign started.
- Past due since.
- Discount.
- Tax behavior.
- Processor ID.
- Last processor event.

### 16.4 State machine card

Show a compact lifecycle strip:

`trialing → active → past_due → unpaid/canceled` with current state highlighted.

For invoices, state machines are legal/strict; for subscriptions, use a more flexible lifecycle visualization with branches.

### 16.5 Sections

1. **Items**
   - Price ID, quantity, period, amount if known.
   - Actions: update quantity, remove item.

2. **Upcoming invoice preview**
   - Button generates preview.
   - Shows line items, proration flags, discount, tax, amount due.
   - Explicitly labels as preview from processor.

3. **Dunning / recovery**
   - Past-due overlay.
   - Campaign steps.
   - Next scheduled action.

4. **Invoices**
   - Related invoices.

5. **Payment methods**
   - Default method summary.

6. **Schedule**
   - Current phase index, next phase, phase count.

7. **Timeline**
   - Subscription events.

8. **Raw data**

### 16.6 Flow: preview upcoming invoice

1. Operator clicks **Preview invoice**.
2. Button enters loading state: **Previewing…**.
3. If successful, a side panel opens.
4. Panel shows:
   - Current subscription items.
   - Proposed changes if launched from another action.
   - Invoice line items.
   - Proration lines marked **Proration**.
   - Total / amount due.
   - Processor timestamp.
5. Operator can copy summary or proceed to a related change if this preview is part of a wizard.
6. If processor error occurs, show fact and next action:
   - **Processor preview failed. Retry or open the processor subscription.**

### 16.7 Flow: swap plan

1. Operator opens overflow → **Swap plan**.
2. Modal/sheet opens with current plan summary.
3. Operator selects new price ID/plan.
4. Operator chooses proration behavior if supported.
5. UI requests preview.
6. Preview shows next invoice impact.
7. Operator confirms.
8. If sensitive policy requires, step-up auth.
9. UI commits action.
10. Success toast: **Plan swap queued/applied. View event.**
11. Detail page updates via LiveView.

### 16.8 Flow: pause collection

1. Operator clicks **Pause collection**.
2. Modal explains effect:
   - Collection pauses; subscription state may remain active/paused depending processor behavior.
   - Entitlement impact if applicable.
3. Fields:
   - Pause behavior.
   - Resume date if supported.
   - Internal reason.
4. Preview shows affected invoices/payment collection.
5. Confirm.
6. Event appears in timeline.

### 16.9 Flow: cancel now / cancel at period end

Use separate labels, never one ambiguous **Cancel** action.

Cancel at period end modal:

- Title: **Cancel at period end**.
- Summary: current period end date and entitlement implications.
- Field: internal reason.
- Confirmation label: **Schedule cancellation**.

Cancel now modal:

- Title: **Cancel subscription now**.
- Danger styling.
- Summary: immediate state impact.
- Show related open invoices and whether they are affected.
- Field: reason.
- Optional confirmation phrase for policy.
- Confirmation label: **Cancel now**.

---

## 17. Invoices list / worklist

### 17.1 Purpose

Finance's default daily queue: **work open invoices to zero**.

### 17.2 Default lens

Open/actionable invoices, sorted by due date ascending and amount remaining descending as secondary.

### 17.3 Saved views

- Action required.
- Open.
- Past due.
- Draft.
- Paid.
- Uncollectible.
- Void.
- All.

### 17.4 Header stat strip

- Open amount.
- Past-due amount.
- Draft invoices.
- Paid today/period.
- Uncollectible amount.

### 17.5 Filters

- Status.
- Due date.
- Amount remaining.
- Currency.
- Collection method.
- Billing reason.
- Processor.
- Customer.
- Has PDF.
- Has proration.
- Org.

### 17.6 Table columns

1. Invoice number.
2. Customer.
3. State.
4. Amount due / remaining.
5. Due date or finalized date.
6. Collection method.
7. Billing reason.
8. Latest payment state.
9. Processor.
10. Updated.

### 17.7 Row interactions

- Row click opens invoice detail.
- PDF icon opens PDF in new tab if available.
- Hosted invoice link opens hosted URL.
- Row menu:
  - View invoice.
  - Send invoice.
  - Pay invoice if valid.
  - Mark uncollectible.
  - Void invoice.

### 17.8 Bulk actions

Use cautiously.

Allowed bulk candidates:

- Send selected open invoices.
- Export selected if export exists.
- Mark reviewed if local review status exists.

Avoid bulk void/pay unless a strong operational requirement and step-up auth exist.

---

## 18. Invoice detail

### 18.1 Purpose

Understand invoice legal/money state and perform valid invoice actions.

### 18.2 Header

Title: `INV-0042` or “Invoice.”  
Subtitle: customer + processor invoice ID.  
Status chips: invoice state, collection method, currency, processor.

Primary actions by state:

- `draft`: **Finalize**; overflow **Void**.
- `open`: **Send invoice** and **Pay** if valid; overflow **Mark uncollectible**, **Void**.
- `paid`: **Open PDF**; maybe **Refund payment** via payment detail.
- `uncollectible`: **Open PDF**; no normal mutation unless engine supports reversal.
- `void`: no mutation.

### 18.3 Summary list

Rows:

- Customer.
- State.
- Number.
- Currency.
- Subtotal.
- Tax.
- Discount.
- Total.
- Amount due.
- Amount paid.
- Amount remaining.
- Period.
- Due date.
- Finalized at.
- Paid at.
- Voided at.
- Billing reason.
- Collection method.
- Processor ID.

### 18.4 State machine card

Show strict invoice lifecycle:

```
draft ──finalize──> open ──pay────────────> paid
  │                  ├─mark uncollectible──> uncollectible
  └─void────────────>└─void────────────────> void
```

Highlight current state. Disable impossible transitions with a tooltip if shown.

### 18.5 Line items section

Columns:

- Description.
- Quantity.
- Period.
- Amount.
- Proration flag.

Actions:

- Add line item, only in draft if valid.
- Remove line item, only in draft if valid.

### 18.6 Discounts and coupons section

- Realized coupon redemptions.
- Amount off.
- Promotion code if known.
- Link to coupon/promotion detail.

### 18.7 Payment attempts section

- Charges/payments associated.
- Status.
- Amount.
- Failure reason.
- Fee settlement.
- Link to payment detail.

### 18.8 Document links section

- Hosted invoice URL.
- PDF URL.
- Copy link.
- Open in new tab.

### 18.9 Timeline and raw data

- Timeline shows invoice state transitions, payment events, emails sent, PDF generation, webhook causes.
- Raw data section exposes processor payload and local watermarks.

### 18.10 Flow: finalize draft invoice

1. Operator clicks **Finalize**.
2. Modal shows invoice summary and line items.
3. Warning: after finalization, line items may no longer be editable.
4. Confirmation button: **Finalize invoice**.
5. On submit, button loading: **Finalizing…**.
6. Success: invoice state becomes `open`, finalized_at appears, new event in timeline.
7. Toast: **Invoice finalized. View event.**
8. If validation fails, show top error and field-level/section-level errors.

### 18.11 Flow: send invoice

1. Operator clicks **Send invoice**.
2. Modal shows recipient email, locale/timezone, hosted invoice link if available.
3. Optional internal note if email template supports.
4. Confirmation: **Send invoice**.
5. Success toast: **Invoice sent to jane@example.com. View event.**
6. Timeline adds email/send event if tracked.

### 18.12 Flow: pay invoice

1. Operator clicks **Pay**.
2. Modal shows amount remaining and default payment method.
3. If no default method, show blocked state with action to update payment method or open hosted invoice.
4. If payment method exists, show confirmation and possible processor caveats.
5. Submit.
6. Processing state shows async status if payment intent requires action.
7. Result:
   - Success: state updates to paid.
   - Requires action: show exact requirement and next action.
   - Failure: show processor failure reason and next actions.

### 18.13 Flow: void invoice

1. Operator opens overflow → **Void invoice**.
2. Danger modal opens.
3. Modal states:
   - Current state.
   - Amount remaining.
   - Legal/operational effect.
   - Related subscription/customer.
4. Required field: reason.
5. Optional confirmation phrase if policy demands.
6. Step-up auth if configured.
7. Button: **Void invoice**.
8. Success: status `void`; event link.
9. Failure: exact message, no lost input.

### 18.14 Flow: mark uncollectible

Similar to void, but less destructive language:

- Title: **Mark invoice uncollectible**.
- Explain that the invoice remains part of billing history but will not be collected through the normal path.
- Required reason.
- Confirmation: **Mark uncollectible**.

---

## 19. Payments list

### 19.1 Purpose

Inspect money movement and fee/reconciliation exceptions.

### 19.2 Saved views

- Recent.
- Failed.
- Refunded.
- Partially refunded.
- Fee unsettled.
- Fee mismatch.
- All.

### 19.3 Filters

- Status.
- Processor.
- Amount.
- Currency.
- Date.
- Customer.
- Invoice.
- Fee settlement.
- Refund status.

### 19.4 Table columns

1. Payment/charge ID.
2. Customer.
3. Invoice.
4. Amount.
5. Status.
6. Refund state/amount.
7. Fees.
8. Processor.
9. Created.

### 19.5 Interactions

- Row opens payment detail.
- Fee mismatch chip opens reconciliation section.
- Refund action opens guarded refund flow.

---

## 20. Payment detail

### 20.1 Header

Title: Payment.  
Subtitle: amount + customer + processor charge ID.  
Status chips: payment status, refund status, fee status, processor.

Primary action:

- **Refund** if refundable amount remains.

Overflow:

- Open processor payment.
- Copy IDs.

### 20.2 Summary list

Rows:

- Customer.
- Invoice.
- Amount.
- Currency.
- Status.
- Amount refunded.
- Refundable amount.
- Processor fee.
- Fees settled at.
- Processor ID.

### 20.3 Refunds section

Columns:

- Refund ID.
- Amount.
- Status.
- Merchant loss.
- Fee refunded.
- Created.

### 20.4 Fee reconciliation section

Show:

- Charge amount.
- Processor fee.
- Net.
- Fee settlement status.
- Refund fee impact.
- Mismatch warning if present.

### 20.5 Flow: refund payment

1. Operator clicks **Refund**.
2. Modal opens with payment summary.
3. Choose amount:
   - Full remaining amount.
   - Partial amount.
4. Fields:
   - Amount.
   - Reason.
   - Optional metadata/internal note.
5. Preview:
   - Refund amount.
   - Remaining refundable amount after refund.
   - Fee impact if known.
   - Merchant loss if known.
   - Related invoice/customer.
6. Validation:
   - Amount must be greater than zero.
   - Amount cannot exceed refundable amount.
   - Currency fixed.
7. Step-up auth.
8. Final confirmation button: **Refund $48.00**.
9. Submit state: **Creating refund…**.
10. Success:
    - Modal closes.
    - Toast: **Refund created. View event.**
    - Refund appears in section with current status.
11. Requires action/failure:
    - Keep modal/page state.
    - Show exact status and next action.

---

## 21. Payment methods

Payment methods appear primarily inside customer detail, with optional standalone lens if volume demands.

### 21.1 Customer payment method section

Default method first.

Fields:

- Brand.
- Last 4.
- Expiration.
- Default marker.
- Fingerprint only hidden behind debug/expand.
- Processor payment method ID.

### 21.2 States

- Default.
- Expiring soon.
- Expired.
- Detached.
- Duplicate fingerprint if relevant.

### 21.3 Actions

- Set default.
- Detach.
- Sync.
- Open processor.

### 21.4 Flow: set default

1. Operator clicks row action **Set as default**.
2. Small confirmation modal shows method and customer.
3. Confirm.
4. Success updates default chip and timeline.

### 21.5 Flow: detach payment method

1. Operator clicks **Detach**.
2. Modal shows whether method is default and whether active subscriptions depend on it.
3. If it is the only method for active/past-due subscriptions, show a stronger warning.
4. Required reason if policy.
5. Confirm.
6. Step-up if configured.

---

## 22. Recovery dashboard

### 22.1 Purpose

Answer: **What revenue is at risk, and where is recovery work stuck?**

### 22.2 Desktop layout thumbnail

```
┌───────────────────────────────────────────────────────────────────────┐
│ Recovery                                                              │
│ Past-due and dunning state across subscriptions.                       │
├───────────────────────────────────────────────────────────────────────┤
│ At-risk summary: amount · subscriptions · oldest · recovered this week │
├─────────────────────────────┬─────────────────────────────────────────┤
│ Dunning funnel              │ At-risk queue                           │
│ Day 0 action required       │ customer · amount · age · step · action  │
│ Day 3 reminder              │                                         │
│ Day 7 final notice          │                                         │
│ Exhausted                   │                                         │
├─────────────────────────────┴─────────────────────────────────────────┤
│ Trends / recent recovery events                                       │
└───────────────────────────────────────────────────────────────────────┘
```

### 22.3 Components

- At-risk summary strip.
- Dunning funnel/stage cards.
- At-risk subscription table.
- Expiring cards panel.
- Recent dunning activity timeline.

### 22.4 At-risk table columns

1. Customer.
2. Subscription status.
3. Amount at risk.
4. Past due since.
5. Campaign step.
6. Last dunning email/action.
7. Default payment method.
8. Next action.

### 22.5 Interactions

- Click stage in funnel filters queue.
- Click row opens subscription recovery detail or customer 360.
- “Send reminder” only if engine supports manual send; otherwise show generated email history.
- “Open hosted invoice” from row if available.

### 22.6 Empty state

**No subscriptions in recovery.**  
Subscriptions appear here when they become past due and a dunning campaign starts.

---

## 23. Per-subscription dunning / recovery detail

This can be a dedicated page or a section on subscription detail with deep anchor.

### 23.1 Header

Title: Recovery timeline.  
Subtitle: customer + subscription.  
Status chips: past_due/unpaid, campaign step, amount at risk.

### 23.2 Timeline

Each step:

- Offset day.
- Scheduled date/time.
- Actual sent/attempted date.
- Email template.
- Outcome.
- Related invoice/payment.

### 23.3 Diagnosis card

Summarize:

- Why campaign started.
- Last payment failure reason if known.
- Default payment method health.
- Next scheduled step.
- Exhaustion risk.

### 23.4 Actions

- Open invoice.
- Send hosted invoice.
- Open customer.
- Pause/unpause/cancel if relevant.
- Mark internal note if notes exist.

---

## 24. Usage reports list

### 24.1 Purpose

Operate usage billing outbox/DLQ.

### 24.2 Default lens

Failed usage reports.

### 24.3 Saved views

- Failed.
- Pending.
- Reported.
- All.

### 24.4 Filters

- Status.
- Event name.
- Subscription item.
- Customer.
- Processor.
- Created date.
- Last attempt.

### 24.5 Table columns

1. Usage report ID.
2. Event name.
3. Customer/subscription.
4. Quantity/value.
5. Status.
6. Attempts.
7. Last error.
8. Created.

### 24.6 Row interactions

- View detail.
- Retry if failed.
- Copy idempotency key.

---

## 25. Usage report detail

### 25.1 Header

Title: Usage report.  
Subtitle: event name + idempotency key.  
Status chips: pending/reported/failed, processor.

Primary action:

- **Retry report** if failed.

### 25.2 Summary list

Rows:

- Event name.
- Aggregation mode if linked through meter.
- Customer.
- Subscription item.
- Quantity/value.
- Status.
- Attempts.
- Last error.
- Idempotency key.
- Processor event/status.

### 25.3 Sections

- Processing attempts.
- Related meter.
- Related subscription item.
- Raw payload.
- Timeline.

### 25.4 Flow: retry usage report

1. Operator clicks **Retry report**.
2. Modal shows event name, quantity, idempotency key, last error.
3. Confirmation: **Retry report**.
4. Success shows pending/reported state and event link.
5. Failure preserves modal and shows exact reason.

---

## 26. Meters and metered renewals

### 26.1 Meters list

Columns:

- Event name.
- Aggregation mode.
- Subscription item.
- Customer/subscription.
- Recent reports.
- Failed reports.
- Updated.

Actions:

- View meter.
- Report usage if manual reporting is exposed.

### 26.2 Meter detail

Sections:

- Definition summary.
- Linked subscription item.
- Recent usage reports.
- Aggregation behavior explanation.
- Raw data.

### 26.3 Metered renewals list

Default lens: action required.

States:

- `pending`.
- `retry_scheduled`.
- `awaiting_payment_method`.
- `paid`.
- `failed_exhausted`.

Columns:

- Customer/subscription.
- Renewal state.
- Amount.
- Next retry.
- Attempts.
- Payment method.
- Updated.

---

## 27. Catalog — coupons

### 27.1 Coupons list

Default lens: active/valid.

Filters:

- Valid.
- Duration.
- Amount off / percent off.
- Redeem by.
- Max redemptions.
- Processor.

Columns:

1. Coupon name/code/id.
2. Discount.
3. Duration.
4. Redemptions.
5. Redeem by.
6. Valid.
7. Processor.
8. Updated.

Actions:

- Create coupon.
- View coupon.
- Create promotion code from coupon.

### 27.2 Coupon detail

Summary list:

- Discount type.
- Duration.
- Max redemptions.
- Times redeemed.
- Redeem by.
- Valid.
- Processor ID.

Sections:

- Promotion codes.
- Recent invoice redemptions.
- Raw data.
- Timeline.

### 27.3 Flow: create coupon

1. Click **Create coupon**.
2. Form fields:
   - Name.
   - Discount type: amount or percent.
   - Amount/currency or percent.
   - Duration.
   - Repeating duration count if repeating.
   - Max redemptions.
   - Redeem by.
   - Metadata.
3. Inline validation.
4. Preview card explains how it will apply.
5. Submit: **Create coupon**.
6. Success opens coupon detail.

---

## 28. Catalog — promotion codes

### 28.1 Promotion codes list

Default lens: active.

Filters:

- Active.
- Coupon.
- Expires at.
- Redemption cap.
- Processor.

Columns:

1. Code.
2. Coupon.
3. Active.
4. Redemptions.
5. Expires.
6. Restrictions.
7. Processor.
8. Updated.

### 28.2 Promotion code detail

Summary list:

- Code.
- Coupon.
- Active.
- Max redemptions.
- Times redeemed.
- Expires at.
- Processor ID.

Actions:

- Deactivate.
- Apply to customer/subscription if engine supports.

### 28.3 Flow: apply promotion code

Can start from customer, subscription, or promotion detail.

1. Operator chooses **Apply promotion code**.
2. Modal context shows customer/subscription target.
3. Enter/select promotion code.
4. Validate code:
   - active.
   - not expired.
   - redemption limits.
   - processor compatibility.
5. Preview effect.
6. Confirm.
7. Success updates target and timeline.

---

## 29. Connect accounts list

### 29.1 Purpose

Operate platform/marketplace connected accounts.

### 29.2 Default lens

Accounts with requirements or disabled charges/payouts.

### 29.3 Saved views

- Action required.
- Charges disabled.
- Payouts disabled.
- Requirements due.
- Deauthorized.
- All.

### 29.4 Table columns

1. Account.
2. Country.
3. Charges enabled.
4. Payouts enabled.
5. Details submitted.
6. Requirements count / due soon.
7. Capabilities summary.
8. Updated.

### 29.5 Actions

- View account.
- Create account link.
- Create login link.
- Sync.
- Reject/deauthorize if valid.

---

## 30. Connected account detail

### 30.1 Header

Title: Connected account.  
Subtitle: account ID + country.  
Status chips: charges, payouts, details, requirements, deauthorized.

Primary actions:

- **Create account link** if requirements exist.
- **Create login link** if account is active.

Overflow:

- Sync account.
- Reject account.
- Open processor account.

### 30.2 Summary list

Rows:

- Account ID.
- Country.
- Charges enabled.
- Payouts enabled.
- Details submitted.
- Requirements due.
- Deauthorized at.
- Platform fee config if visible.

### 30.3 Requirements panel

Show current requirements as a checklist/table:

- Requirement key.
- Due date if available.
- Blocking effect: charges/payouts.
- Status.

### 30.4 Capabilities matrix

Rows are capabilities. Columns:

- Requested.
- Status.
- Requirement link.

### 30.5 Flow: create account link

1. Operator clicks **Create account link**.
2. Modal shows target account and purpose.
3. Confirm.
4. Result displays generated link with copy/open actions and expiration if known.
5. Timeline records action if event exists.

### 30.6 Flow: reject account

1. Overflow → **Reject account**.
2. Danger modal shows effect on charges/payouts.
3. Required reason.
4. Step-up auth.
5. Confirm: **Reject account**.
6. Success updates state and timeline.

---

## 31. Webhooks list / incident queue

### 31.1 Purpose

Debug and replay failed/dead processor events.

### 31.2 Default lens

Failed/dead.

### 31.3 Saved views

- Failed/dead.
- Failed.
- Dead.
- Processing.
- Succeeded.
- Replayed.
- All.

### 31.4 Header stat strip

- Failed.
- Dead.
- Oldest failed age.
- Replayed today.
- Processing lag.

### 31.5 Filters

- State.
- Event type.
- Processor.
- Date received.
- Affected object type.
- Error class.
- Replay status.

### 31.6 Table columns

1. Event type.
2. State.
3. Processor event ID.
4. Affected object.
5. Received at.
6. Attempts.
7. Last error.
8. Last replayed.

### 31.7 Row interactions

- Row click opens webhook detail.
- Row action: replay if valid.
- Bulk selection: bulk replay for failed/dead only, with confirmation.

### 31.8 Bulk replay flow

1. Operator selects events.
2. Bulk bar appears: count, event type mix, oldest age.
3. Click **Replay selected**.
4. Confirmation modal shows:
   - number selected.
   - status breakdown.
   - warning about idempotency/watermarks.
   - dry-run option if supported.
5. Step-up if policy.
6. Confirm.
7. Progress panel shows queued/replayed/failed.
8. Results link to filtered list.

---

## 32. Webhook detail

### 32.1 Purpose

Answer: **What happened to this inbound processor event, and what can I do?**

### 32.2 Header

Title: webhook event type, e.g. `invoice.paid`.  
Subtitle: processor event ID.  
Status chips: state, processor, replayed/dead.

Primary action:

- **Replay webhook** if state allows.

Overflow:

- Copy raw body.
- Open related record.
- Mark dead if action exists.

### 32.3 Incident summary card

Fields:

- State.
- Received at.
- Processed at.
- Attempts.
- Last error.
- Affected object.
- Last local watermark.

### 32.4 Causality graph

Nodes:

1. Processor event.
2. Webhook receipt.
3. Processing attempt(s).
4. Ledger event(s).
5. Affected records.
6. Emails/entitlement sync if tracked.

Each node is clickable.

### 32.5 Raw request section

- Headers.
- Raw body.
- Parsed JSON.
- Signature verification status if available.
- Copy controls.

### 32.6 Replay flow

1. Operator clicks **Replay webhook**.
2. Modal shows event type, state, affected object, last error, idempotency note.
3. Confirmation button: **Replay webhook**.
4. Submit.
5. UI shows processing state.
6. Outcomes:
   - Succeeded: state updates, related events appear.
   - Failed: error panel shows exact failure and attempt details.
   - Skipped/stale: explain watermark/idempotency reason.
7. Toast includes event/result link.

---

## 33. Event log

### 33.1 Purpose

Audit and causality across Accrue.

### 33.2 Default lens

Recent events, with saved lenses:

- Admin actions.
- Webhook-applied changes.
- Refunds.
- Invoice state changes.
- Subscription state changes.
- Compliance review.
- By actor.

### 33.3 Filters

- Event type.
- Actor type.
- Actor ID.
- Subject type.
- Subject ID.
- Trace ID.
- Caused by webhook.
- Date range.
- Processor.

### 33.4 Table columns

1. Time.
2. Type.
3. Actor.
4. Subject.
5. Summary.
6. Caused by.
7. Trace ID.

### 33.5 Timeline-style list option

For audit users, a chronological event list may be easier than a table. Offer display mode toggle if useful.

### 33.6 Saved compliance lens

Not a separate nav destination.

Preset filter:

- Actor type = admin/user.
- Sensitive event types = refunds, voids, uncollectible, subscription cancels, payment method detachments, Connect rejections.
- Date range required for export if export exists.

---

## 34. Event detail

### 34.1 Header

Title: event type.  
Subtitle: event UUID.  
Status chip: immutable/audit.

Actions:

- Copy event ID.
- Copy trace ID.
- View subject.
- View causing webhook/event.

### 34.2 Summary list

Rows:

- Type.
- Time.
- Actor type.
- Actor ID.
- Subject type.
- Subject ID.
- Trace ID.
- Caused by event.
- Caused by webhook.

### 34.3 Payload sections

- Data summary.
- JSON payload.
- State diff if derivable.
- Causality graph.
- Related timeline for subject.

### 34.4 State-as-of interaction

If supported:

1. Click **View state at this time**.
2. Side panel opens.
3. Shows reconstructed subject state at event timestamp.
4. Diff toggle: before/after.
5. Copy/export if supported.

---

## 35. Checkout sessions

### 35.1 List purpose

Debug acquisition and incomplete self-service flows.

### 35.2 Saved views

- Incomplete.
- Completed.
- Payment failed.
- Setup mode.
- Subscription mode.
- All.

### 35.3 Table columns

1. Session ID.
2. Customer/email if known.
3. Mode.
4. UI mode.
5. Status.
6. Payment status.
7. Line items.
8. Created.

### 35.4 Detail sections

- Summary.
- Line items.
- URLs: success/cancel/return.
- Related customer/subscription/invoice/payment.
- Raw payload.
- Timeline.

### 35.5 Support flow

If customer says checkout failed:

1. Search email or checkout session ID.
2. Open session detail.
3. See status/payment status.
4. Link to related invoice/subscription or absence of one.
5. Open processor if needed.
6. Copy return/hosted link if valid.

---

## 36. Dev-only Fake processor tools

Only visible in Fake/dev/test environments.

### 36.1 Dev tools landing

Cards:

- Time travel clock.
- Email previews.
- Webhook fixtures.
- Fake inspect.
- Component gallery.

### 36.2 Time travel clock

Purpose: simulate billing lifecycle changes.

Interactions:

- Show current fake time.
- Advance by preset durations: 1 hour, 1 day, billing period.
- Custom date/time.
- Preview affected jobs if possible.
- Confirm.
- Timeline of time changes.

### 36.3 Email previews

Purpose: inspect transactional emails.

List templates:

- invoice finalized.
- invoice paid.
- payment failed.
- receipt.
- refund issued.
- trial ending.
- subscription paused/resumed/canceled.
- coupon applied.
- card expiring.
- dunning notices.

Preview controls:

- Locale.
- Timezone.
- Sample customer/invoice/subscription.
- Light/dark if email supports.
- Send test email if configured.

### 36.4 Webhook fixtures

Purpose: simulate processor events.

Interactions:

- Select event type.
- Select target object.
- Edit fixture JSON.
- Validate.
- Dispatch.
- Result links to webhook detail and event log.

### 36.5 Fake inspect

Purpose: inspect fake processor state.

Sections:

- Fake customers.
- Fake subscriptions.
- Fake invoices.
- Fake payments.
- Fake webhooks.

### 36.6 Component gallery

Purpose: maintain design system.

Show all components in light/dark, density modes, responsive widths, error states, loading states, empty states.

---

## 37. Settings / configuration surfaces

Keep settings sparse. Accrue admin is primarily operational.

### 37.1 Processor status

Show:

- Processor module.
- Mode: live/test/fake.
- Webhook endpoint status.
- Last webhook received.
- Last successful processing.
- Queue health if available.

Avoid exposing secrets.

### 37.2 UI preferences

- Theme: system/light/dark.
- Density: comfortable/dense.
- Time display: local/UTC if useful.
- Reduced motion follows OS; user override optional.

### 37.3 Branding readout

If host-derivable branding is configurable:

- Logo.
- Product/admin title.
- Accent tokens.
- Email/PDF branding links.

---

## 38. High-value storyboards

### 38.1 Journey A — Founder/operator daily health glance

**Goal:** determine whether billing needs attention.

**Entry:** Home.

**Storyboard:**

1. Operator opens admin.
2. Header shows org scope, live/test/fake mode, processor.
3. Attention rail loads first.
4. Operator sees **Dead webhooks: 3** with oldest age.
5. Operator clicks **Review webhooks**.
6. Webhooks list opens with failed/dead filter applied.
7. Operator opens oldest event.
8. Webhook detail shows error and affected invoice.
9. Operator clicks **Replay webhook**.
10. Replay succeeds.
11. Causality graph updates: webhook → invoice paid → subscription active.
12. Operator returns Home.
13. Attention count decreases.
14. KPI strip and recent activity provide confirmation.

**Success condition:** operator knows whether any attention queue remains.

**Design notes:**

- Home does not try to explain every metric.
- Attention rail drives action.
- Live updates reinforce trust without theatrics.

### 38.2 Journey B — Support: “Customer says they paid but is blocked”

**Goal:** explain and resolve access mismatch.

**Entry:** global search.

**Storyboard:**

1. Support presses `⌘K`.
2. Types customer's email.
3. Search result shows customer plus open invoice and subscription chips.
4. Presses Enter.
5. Customer 360 opens.
6. “Why blocked?” card appears above details.
7. UI identifies one of these stories:
   - Invoice paid but entitlement cache stale.
   - Invoice open/past due and subscription past_due.
   - Payment succeeded at processor but webhook failed/dead.
   - Subscription incomplete due to payment action required.
   - No billing-side block detected.
8. Support opens the linked invoice/payment/webhook from the diagnosis card.
9. If webhook failed, support/developer replays or escalates.
10. If invoice remains open, support sends hosted invoice link.
11. If payment method failed, support opens billing portal link.
12. Support copies a concise customer-facing explanation if a “copy summary” affordance exists.

**Success condition:** support can answer exactly why access differs from payment expectation.

**Key UI requirement:** customer 360 must connect processor, projection, entitlement, and event state in one place.

### 38.3 Journey C — Finance: work open invoices to zero

**Goal:** process invoice queue.

**Entry:** Invoices.

**Storyboard:**

1. Finance opens Invoices.
2. Default view is **Action required**.
3. Stat strip shows open amount and past-due amount.
4. Finance filters to due date before today.
5. Table sorts by amount remaining.
6. Opens first invoice.
7. Invoice detail shows state machine and amount remaining.
8. Finance reviews line items and payment attempts.
9. If payment method exists, clicks **Pay**.
10. If no method, clicks **Send invoice** or opens hosted invoice.
11. If collection is no longer expected, opens **Mark uncollectible**.
12. Each action produces event link and updates queue count.
13. Finance returns to list using “next invoice” control if provided.

**Success condition:** fewer actionable invoices, clear audit trail for each action.

**Power-user improvement:** support previous/next queue navigation from invoice detail.

### 38.4 Journey D — Recovery: monitor dunning funnel

**Goal:** reduce at-risk revenue and identify exhausted campaigns.

**Entry:** Recovery.

**Storyboard:**

1. Recovery opens dashboard.
2. At-risk summary shows amount, count, oldest past due.
3. Funnel shows stages: started, reminder, final notice, exhausted.
4. Recovery clicks **Exhausted**.
5. Queue filters to failed/exhausted dunning.
6. Opens subscription recovery timeline.
7. Diagnosis shows failed payment method and all emails sent.
8. Recovery opens customer 360 or invoice detail.
9. Sends hosted invoice or confirms cancellation/uncollectible path depending policy.
10. Timeline records action.

**Success condition:** at-risk queue becomes explainable and prioritized.

### 38.5 Journey E — Developer: debug failed webhook end-to-end

**Goal:** understand failure and replay safely.

**Entry:** Developer → Webhooks.

**Storyboard:**

1. Developer opens Webhooks.
2. Failed/dead lens is preselected.
3. Developer filters by event type `invoice.paid`.
4. Opens a failed event.
5. Incident summary shows last error.
6. Raw payload search finds invoice ID.
7. Causality graph shows processing stopped before ledger event.
8. Developer checks local watermark to avoid stale replay.
9. Clicks **Replay webhook**.
10. Confirmation explains idempotency.
11. Replay succeeds or fails.
12. If succeeds, event detail shows created ledger event and affected invoice/subscription.
13. If fails, attempt log captures new error.

**Success condition:** developer can see whether replay changed state and why.

### 38.6 Journey F — Compliance: investigate a refund

**Goal:** identify actor, reason, and causality for a sensitive action.

**Entry:** Event log saved compliance lens.

**Storyboard:**

1. Auditor opens Event log.
2. Applies saved lens **Sensitive admin actions**.
3. Filters event type to refund created.
4. Opens event detail.
5. Summary shows actor type/admin ID, subject payment/refund, timestamp, trace ID.
6. Payload shows amount and reason.
7. Causality graph links payment → refund → invoice/customer.
8. Auditor opens payment detail for money context.
9. Uses state-as-of to inspect payment before refund if available.
10. Copies event ID/trace ID for records.

**Success condition:** complete “who, what, when, why, caused by” story.

### 38.7 Journey G — Platform ops: connected account losing payouts

**Goal:** restore or explain account capability issue.

**Entry:** Connect nav badge.

**Storyboard:**

1. Operator sees Connect badge **4 requirements**.
2. Opens Connected accounts.
3. Default lens shows accounts with disabled payouts/requirements.
4. Opens account.
5. Requirements panel lists missing fields and due dates.
6. Capabilities matrix shows payouts disabled.
7. Operator creates account link.
8. Copies link or opens it.
9. Timeline records link creation if supported.
10. Account remains in queue until requirements clear.

**Success condition:** operator knows what the connected account must provide and has generated the correct handoff link.

### 38.8 Journey H — Developer/billing ops: failed usage report

**Goal:** retry or explain missing metered usage.

**Entry:** Usage nav badge.

**Storyboard:**

1. Operator opens Usage → Usage reports.
2. Failed lens is selected.
3. Opens failed usage report.
4. Summary shows event name, subscription item, idempotency key, last error.
5. Raw payload confirms quantity.
6. Operator clicks **Retry report**.
7. Confirmation shows idempotency key.
8. Retry succeeds; status changes to reported.
9. Related meter detail shows updated recent reports.

**Success condition:** usage reaches processor or failure has an exact reason for developer follow-up.

---

## 39. Cross-screen interaction patterns

### 39.1 List → detail → next item loop

For worklists, detail pages should support:

- Back to current filtered list.
- Previous/next item in queue.
- Queue position: **3 of 18 open invoices**.
- Preserve scroll/filter state.

### 39.2 Related-resource strip

On every detail page, include exactly one compact strip for primary related objects.

Example on invoice detail:

- Customer.
- Subscription.
- Payment.
- Webhook.
- Event timeline.

This prevents scattering links across every section.

### 39.3 Raw/debug reveal

Raw JSON is valuable but should not dominate support/finance screens.

Pattern:

- Collapsed by default.
- Label: **Raw processor payload** / **Local projection**.
- Show last updated and payload size.
- Search/copy inside expanded panel.

### 39.4 Processor links

Processor links should be clearly external:

- Icon plus label: **Open in Stripe** / **Open in Braintree**.
- Do not make processor links primary unless the local UI cannot complete the task.

### 39.5 Loading and LiveView updates

- Buttons show loading verb: **Replaying…**, **Finalizing…**, **Refunding…**.
- Disable duplicate submits.
- For background jobs, show pending state and a link to the job/event if available.
- Live updates should preserve focus and not reorder focused rows unexpectedly.

### 39.6 Optimistic-lock conflict

If `lock_version` conflict occurs:

Message:

**This record changed after the page loaded. Review the latest state before applying this action.**

Actions:

- Refresh state.
- Compare changes if available.
- Cancel.

### 39.7 Webhook freshness / stale projection

If local projection lags:

- Show a freshness chip: **Last processor event 14m ago**.
- If a failed webhook affects this record, show banner:
  **A failed webhook may be preventing this state from updating. Review webhook.**

---

## 40. Sensitive-action system

### 40.1 Sensitive action classes

**Class A — ordinary reversible-ish actions**

- Send invoice.
- Set default payment method.
- Preview invoice.
- Sync customer.

Pattern: simple modal or inline action.

**Class B — state-changing actions**

- Finalize invoice.
- Pause subscription.
- Swap plan.
- Apply promotion code.
- Replay webhook.

Pattern: preview + confirmation + audit event.

**Class C — destructive/money/legal actions**

- Refund.
- Void invoice.
- Mark uncollectible.
- Cancel subscription now.
- Detach only payment method.
- Reject connected account.
- Bulk replay.

Pattern: guarded modal/wizard + reason + step-up auth + explicit impact preview.

### 40.2 Confirmation content order

1. What object is affected.
2. Current state.
3. New state/effect.
4. Related money/access impact.
5. Required reason.
6. Authentication if required.
7. Exact action button.

### 40.3 Success result pattern

Toast:

**[Object] [verb completed]. View event.**

Examples:

- **Invoice voided. View event.**
- **Refund created. View event.**
- **Webhook replayed. View event.**

---

## 41. Content hierarchy rules

### 41.1 Every detail page answers in this order

1. What is this?
2. What state is it in?
3. Is anything wrong?
4. What can I do?
5. What related records matter?
6. What happened over time?
7. What raw payload proves it?

### 41.2 Every queue row answers in this order

1. Which object/customer?
2. What state?
3. How much/what impact?
4. How old/urgent?
5. What next action?

### 41.3 Every error message answers

1. What happened.
2. How to recover.
3. Where to inspect if recovery is not obvious.

Example:

**Webhook replay failed. The invoice transition is stale because a newer processor event has already been applied. Review the event timeline.**

### 41.4 Empty states

Use precise, non-celebratory empty states.

Format:

**No [objects].**  
[Objects] appear here when [condition].

---

## 42. Visual system guidance

### 42.1 Overall look

- Developer-tooling console.
- Quiet borders.
- Dense but breathable tables.
- Strong typography and alignment.
- Minimal decoration.
- No finance cliché illustrations.

### 42.2 Color use

Use supplied Accrue tokens:

- Ink for primary text/dark surfaces.
- Slate for secondary text/borders.
- Fog/Paper for neutral surfaces.
- Moss for success/active.
- Cobalt for links/focus.
- Amber for warning/pending/grace.
- Danger red for destructive/error.
- Info teal for neutral informational state.

Rules:

- Status is never color-only.
- Danger color reserved for destructive/error, not generic emphasis.
- Cobalt is for interaction/focus, not status.

### 42.3 Typography

- Geist Sans for headings and body.
- Geist Mono for IDs, enum chips, event names, trace IDs, code/JSON.
- Tabular numerals for money, counts, dates in tables.
- Medium-weight headings, not heavy marketing weights.

### 42.4 Density

- Use 4px spacing scale.
- Dense table rows may use 2px increments.
- Default desktop table should show at least 8 rows above the fold where practical.
- Detail pages should avoid both cramped accordion soup and oversized whitespace.

### 42.5 Motion

- Use motion to orient: drawer open, row expansion, live update insertion.
- No celebratory animations.
- Honor `prefers-reduced-motion`.

---

## 43. Responsive behavior

### 43.1 Table to card transformation

Desktop table columns collapse to mobile card fields in priority order.

Invoice mobile card example:

```
INV-0042              open
Jane Doe              $48.00 remaining
Due Jul 12            collection: charge automatically
Last payment failed   [View] [Send]
```

### 43.2 Filter behavior on mobile

- Filters open in full-screen sheet.
- Applied filters show as horizontal chips.
- Saved views remain visible as segmented chips.
- Result count visible before applying if LiveView can update.

### 43.3 Detail pages on mobile

- Summary list first.
- Diagnosis card before sections.
- Sections collapsed after first two.
- Action menu in sticky footer only for common safe actions.
- Destructive actions stay inside overflow menu and modal flow.

### 43.4 Timelines on mobile

- Vertical timeline only.
- Causality graph stacks nodes.
- Raw JSON viewer uses full-screen view with copy/search.

---

## 44. Accessibility requirements

### 44.1 Standards

Target WCAG 2.2 AA.

### 44.2 Keyboard and focus

- Every interactive control reachable by keyboard.
- Visible focus ring using Cobalt or tokenized focus color.
- Modals trap focus and return focus to trigger.
- Disclosure controls toggle with Enter/Space.
- Escape closes overlays when closing is safe.

### 44.3 Semantics

- Tables use real table semantics on desktop.
- Mobile cards retain programmatic labels.
- Status updates use live regions where appropriate.
- Icons have text labels or accessible names.

### 44.4 Forms

- Label every field.
- Required/optional clear.
- Top error summary plus field-level errors.
- Preserve data after validation errors.
- Avoid relying solely on placeholder text.

### 44.5 Color and contrast

- All text meets contrast requirements.
- Status not color-only.
- Badge text remains readable in light and dark.

### 44.6 Reduced motion

- Respect OS reduced-motion preference.
- Do not animate critical state changes in a way that hides information.

---

## 45. Backend/domain alignment opportunities

The user-facing UI can guide future backend cleanup.

### 45.1 Prefer domain verbs over CRUD

Instead of generic update endpoints, expose verbs that match operator tasks:

- `void_invoice`.
- `mark_invoice_uncollectible`.
- `pause_subscription`.
- `replay_webhook`.
- `retry_usage_report`.
- `apply_promotion_code`.

### 45.2 Make diagnosis first-class

Consider backend support for customer diagnosis:

- `billing_state_for_customer(customer_id)`.
- `blocking_reason_for_owner(owner)`.
- `timeline_for_customer(customer_id)`.
- `causality_chain_for_event(event_id)`.

### 45.3 Saved lenses

Represent common operator lenses:

- open invoices.
- failed webhooks.
- past-due subscriptions.
- failed usage reports.
- sensitive admin actions.

### 45.4 Event types as UI contracts

Audit event names should read like durable product language, not implementation leakage.

Good:

- `invoice.finalized`.
- `invoice.voided`.
- `refund.created`.
- `subscription.paused`.
- `webhook.replayed`.

Avoid ambiguous names:

- `object.updated`.
- `billing.changed`.

---

## 46. Acceptance checklist

Use this checklist when reviewing the design.

### 46.1 Information architecture

- Can each persona enter through the natural path?
- Are specialist rooms visible only when useful?
- Does Compliance exist as an event-log lens, not a redundant destination?
- Are nav badges actionable counts?

### 46.2 Detail pages

- Does the page answer state before raw details?
- Are valid actions obvious?
- Are invalid actions hidden or explained?
- Is there exactly one clear related-resource strip?
- Is the timeline available without overwhelming primary content?

### 46.3 Worklists

- Is the default lens actionable?
- Are filters encoded in URL?
- Can a power user process items without losing place?
- Are rows dense enough for operator work?

### 46.4 Sensitive actions

- Is impact preview shown?
- Is reason captured where needed?
- Is step-up auth used for configured sensitive actions?
- Does success link to the audit event?

### 46.5 Support diagnosis

- Can the UI answer “paid but blocked” from customer 360?
- Does it connect invoice, subscription, payment, entitlement, webhook, and event state?
- Does it distinguish processor canonical state from local projection state?

### 46.6 Accessibility

- Keyboard-only path exists for every task.
- Modals/disclosures meet expected interaction patterns.
- Errors use summary + field messages.
- Status is not color-only.
- Mobile 360px layouts remain usable.

### 46.7 Brand/voice

- Does it feel like developer tooling rather than fintech marketing?
- Are words measured and exact?
- Are banned claim adjectives avoided?
- Are money metaphors/illustrations avoided?

---

## 47. Prompt to generate a downstream UI/UX spec from this document

Use this section when pasting into another LLM. Paste the Accrue library summary before this prompt, then paste this whole document, then ask the model to produce the requested design output.

```text
You are acting as a principal product designer, UX architect, interaction designer, design systems lead, and operator-tools specialist.

You are designing the ideal admin/operator UI for Accrue, an Elixir/Phoenix billing library. Treat the supplied Accrue domain summary and this UI blueprint as source context. Your job is not to make a generic dashboard. Your job is to design a safe, auditable billing operations control plane.

Design from first principles, but preserve the product's domain truths:
- Processor state is canonical.
- Local records are projections.
- Operator writes and webhook writes are different paths.
- The event ledger and webhook event log are the operational backbone.
- Operators mostly work exceptions, not healthy records.
- Support's central question is: “This customer says they paid — why are they blocked?”

Produce a comprehensive UI/UX spec with breadth and depth. Do not handwave. For each section, specify visual layout, content hierarchy, components, controls, interactions, states, responsive behavior, accessibility behavior, and microcopy.

Required output:

1. Design principles
   - 8–12 principles specific to Accrue Admin.
   - Explain how each principle changes screen design.

2. Information architecture
   - Primary nav, secondary nav, badges, org scoping, environment/processor visibility.
   - Explain why each destination exists and which persona uses it.

3. Domain language
   - User-facing nouns, verbs, states, and helper text.
   - Identify where backend terms should remain visible and where they should be translated.

4. Screen inventory
   - List every screen, route-style name, default lens, primary persona, primary action, and related objects.

5. Global shell
   - Desktop, tablet, and 360px mobile layouts.
   - Global search/command palette behavior.
   - Keyboard shortcuts.
   - Org scope behavior.
   - Environment/test/fake mode behavior.

6. Reusable components
   - Page header, summary list, dense table, filter chips, saved views, status badge, attention item, timeline, causality graph, raw JSON viewer, modal, drawer/sheet, step-up auth, toast, empty state, validation summary.
   - For each component: purpose, anatomy, variants, interaction behavior, accessibility requirements, and examples.

7. Screen-by-screen UX specs
   For every major screen, include:
   - Purpose.
   - Primary user question.
   - Desktop thumbnail in text/wireframe form.
   - Mobile ordering.
   - Header content.
   - Summary/stat content.
   - Table/card columns or sections.
   - Filters and saved views.
   - Primary/secondary/destructive actions.
   - Empty/loading/error states.
   - Live update behavior.
   - Links to related records.
   - Raw/debug placement.

8. Journey storyboards
   Produce detailed storyboard flows for at least:
   - Founder/operator daily health glance.
   - Support: customer says they paid but is blocked.
   - Finance: work open invoices to zero.
   - Recovery: dunning/at-risk revenue review.
   - Developer: failed webhook debug and replay.
   - Compliance: sensitive refund audit.
   - Platform ops: connected account requirements.
   - Developer/billing ops: failed usage report retry.

   For each journey include:
   - Trigger.
   - Entry screen.
   - User goal.
   - Step-by-step UI actions.
   - What the user sees at each step.
   - System response.
   - Error/edge states.
   - Exit condition.
   - Design rationale.

9. Action flows
   Fully specify these interaction flows:
   - Replay webhook.
   - Bulk replay webhooks.
   - Refund payment.
   - Finalize invoice.
   - Send invoice.
   - Pay invoice.
   - Void invoice.
   - Mark invoice uncollectible.
   - Preview upcoming invoice.
   - Swap plan.
   - Pause/unpause subscription.
   - Cancel now vs cancel at period end.
   - Apply promotion code.
   - Retry failed usage report.
   - Create Connect account link.
   - Reject connected account.

   Each action flow must include:
   - Preconditions.
   - Entry points.
   - Modal/sheet/wizard structure.
   - Field list.
   - Validation.
   - Preview/impact summary.
   - Step-up auth requirement if sensitive.
   - Success state.
   - Failure state.
   - Audit event link behavior.

10. State and status grammar
   - Visual treatment and helper text for subscription, invoice, webhook, refund, schedule, and usage states.
   - Allowed actions by state.
   - Status chip rules.

11. Accessibility and responsive spec
   - WCAG 2.2 AA expectations.
   - Keyboard flows.
   - Focus management.
   - Screen reader labels.
   - Mobile table-to-card transformations.
   - Reduced motion behavior.

12. Design system guidance
   - Token usage.
   - Typography.
   - Spacing/density.
   - Light/dark mode.
   - Motion.
   - Empty/error/loading content patterns.

13. Backend/domain alignment notes
   - Where UI language suggests backend refactors.
   - Useful view models or query endpoints.
   - Event naming and causality contracts.

Constraints:
- Be specific. Avoid generic “dashboard,” “manage,” or “simple” language.
- Do not overfit to Stripe's brand style.
- Do not hide operational complexity that users need for billing support.
- Do not make raw JSON primary on non-developer screens.
- Do not make destructive actions too easy.
- Do not rely on color alone.
- Keep density high enough for operator work.
- Use exact Accrue domain states and actions.
- Where you make assumptions, label them clearly and continue.

Write the final answer as a product/design spec that a designer and Phoenix LiveView engineer could build from.
```

---

## 48. Compact version for quick LLM prompting

```text
Design the ideal Accrue admin/operator UI from first principles. Accrue is a Phoenix billing library where processor state is canonical, local rows are projections, webhooks update state, operator actions are validated state transitions, and the append-only event ledger is the audit backbone.

Map the complete operator experience in breadth and depth: personas, IA, navigation, screen inventory, user-facing domain language, design system components, page layouts, content hierarchy, tables/cards, filters, modals, action flows, state machines, timeline/causality patterns, responsive behavior, accessibility, and microcopy.

Personas: founder/operator health glance; support customer 360; finance invoice queue; recovery dunning; developer webhook/usage debugging; compliance audit.

Core journeys to storyboard: billing health glance; “customer paid but blocked”; invoice queue to zero; dunning recovery; failed webhook replay; refund audit; Connect requirements; failed usage report retry.

For every screen, specify purpose, primary question, desktop and mobile layout, summary/header content, table columns or sections, saved views/filters, primary/secondary/destructive actions, empty/loading/error states, related links, timeline/raw JSON placement, and LiveView interaction behavior.

For every sensitive action, specify preconditions, modal/wizard steps, fields, validation, impact preview, step-up auth, success/failure states, and audit event link.

Style: calm, exact, dense, developer-tooling, not fintech. Use exact domain states and precise verbs. Exceptions first. Summary before drilldown. Timeline and raw payload last unless debugging. Do not rely on color alone. Design for WCAG 2.2 AA and 360px mobile.
```
