---
status: partial
phase: 102-coupon-discount-mapping
source: [102-VERIFICATION.md]
started: 2026-05-02T18:51:00Z
updated: 2026-05-02T18:51:00Z
---

## Current Test

awaiting human testing

## Tests

### 1. Real Hosted Fields sandbox checkout with a mapped promo code
expected: preview shows provisional savings, submit succeeds, created subscription carries the mapped Braintree discount id
result: pending

### 2. Keyboard and screen-reader review of promo preview, invalid, and drift states
expected: `aria-live` announcements are clear and do not imply preview is final confirmation
result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
