---
quick_id: 260620-lie
slug: fix-stale-active-org-login
date: 2026-06-20
---

# Quick Task: Fix login 500 from stale active_organization_id

## Problem

`POST /users/log-in` 500s with
`Ecto.ConstraintError ... "user_sessions_active_organization_id_fkey"`.

On login, `create_or_extend_session/3`
(`examples/accrue_host/lib/accrue_host_web/user_auth.ex`) read
`active_organization_id` straight from the browser session cookie and threaded
it into the new `user_sessions` INSERT with **no validation**. Sigra's Ecto
session store inserts via a raw struct (no changeset / `foreign_key_constraint`),
so when the cookie carried a dead org id — a reseed re-UUID'd the org, the org
was soft-deleted, or a cross-user cookie carried a foreign org — the FK violation
**raised** instead of degrading gracefully.

## Fix (single source file + test)

`examples/accrue_host/lib/accrue_host_web/user_auth.ex`:
- Replace the raw `get_session(conn, :active_organization_id)` read at the
  session-creation call site with `validated_active_organization_id(conn, user)`.
- Add that private helper: returns the session's org id only if the user is a
  current member of an existing (not soft-deleted) org, else `nil`. Mirrors the
  membership query already in `assign_default_organization_scope/2` and reuses the
  already-aliased `Organization`, `OrganizationMembership`, `Repo`, and
  `import Ecto.Query` (`from`).

`nil` is safe because `maybe_assign_default_organization_scope/2` re-derives the
active org from the user's live memberships immediately after.

## Tests

`examples/accrue_host/test/accrue_host_web/user_auth_test.exs` — two regression
tests in the `log_in_user/3` block:
- stale/foreign `active_organization_id` → login succeeds, persisted session row
  has `active_organization_id = nil` (would FK-crash before the fix);
- member's valid `active_organization_id` → preserved onto the session row.

## Out of scope
- Patching the upstream `sigra` session store (changeset-less insert) — we don't
  vendor-patch deps; preventing the bad value upstream of it is the correct fix.
- Deterministic seed org UUIDs — papers over the general case (orgs can be
  deleted in normal use).

## Verification
`cd examples/accrue_host && mix test test/accrue_host_web/user_auth_test.exs`
→ 29 tests, 0 failures.
