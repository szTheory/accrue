---
status: partial
phase: 175-b-persona-driven-ia-spine
source: [175-VERIFICATION.md]
started: 2026-06-04T09:23:07Z
updated: 2026-06-04T09:23:07Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Sidebar collapse/expand + localStorage persistence
expected: Recovery/Developer/Catalog groups collapse/expand via chevron; state persists across reload via localStorage (key `ax-sidebar-{mountPath}-{group}`); Billing zone is always-expanded; chevron CSS rotates.
result: [pending]

### 2. Attention-count badge tone & conditional appearance
expected: Recovery badge renders amber (`ax-badge-warning`) when at-risk/past-due > 0; Developer badge renders red (`ax-badge-danger`) when dead-letter webhooks > 0; both hidden when count is 0; collapsible group auto-expands when its badge > 0. Requires seeded DB data.
result: [pending]

### 3. Home launcher → work-queue persona path (≤2 clicks)
expected: From Home, "Clear the invoice queue" lands on /invoices pre-filtered to open+uncollectible with a cobalt-active Queue chip and a slate "All" escape chip one click away.
result: [pending]

### 4. Customer-360 "More ▾" overflow toggle
expected: Primary tabs (Subscriptions, Invoices, Payments) always visible; "More ▾" reveals Payment methods/Entitlements/Events/Metadata; menu closes on Escape and resets on tab navigation.
result: [pending]

### 5. Webhook→Event→entity three-screen thread
expected: From a dead-lettered webhook detail, a Related card links to the derived Event(s); /events/:id renders and links onward to the affected entity (Customer/Subscription/Invoice/Payment) — no dead ends. Requires seeded webhook data.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
