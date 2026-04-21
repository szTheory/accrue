# Phase 37 — Technical Research

**Question:** What do we need to know to plan the non-Sigra org billing doc spine and phx.gen.auth recipe well?

## RESEARCH COMPLETE

### ExDoc and guide registration

- `accrue/mix.exs` `docs/0` uses `extras: ["README.md" | Path.wildcard("guides/*.md")]` and `groups_for_extras: [Guides: Path.wildcard("guides/*.md")]`.
- **Implication:** Adding `accrue/guides/organization_billing.md` (or the chosen filename) automatically includes it in HexDocs; no `mix.exs` change is required unless we want a non-`guides/` path (CONTEXT D-01 allows planner to pick filename under `guides/`).

### Edit surfaces (non-spine)

| Artifact | Current shape | Required change (CONTEXT) |
|----------|---------------|----------------------------|
| `guides/auth_adapters.md` | Opens with contract + PhxGenAuth | Compact **“Choosing an adapter / without Sigra”** block immediately after opening framing (D-05); link to new spine + keep PhxGenAuth section as SSOT for adapter code |
| `guides/sigra_integration.md` | Jumps into deps after intro | **“Not using Sigra?”** callout **before** `## Add the dependency` (D-06); link `auth_adapters.md`; no full PhxGenAuth paste |
| `lib/mix/tasks/accrue.install.ex` | `print_auth_guidance/1` non-Sigra branch is two lines | Add **one stable pointer** to repo-relative or ExDoc path for `guides/auth_adapters.md` and new spine (D-07) |

### Reference host (`examples/accrue_host`)

- `AccrueHost.Accounts.User` and `AccrueHost.Accounts.Organization` both `use Accrue.Billable` — use as **annex** ground truth (D-16, D-17).
- `AccrueHost.Billing` is the generated facade pattern for `customer_for/1`, `subscribe/3`, etc.

### ORG-03 in-doc treatment

- Full ORG-03 text lives in `.planning/milestones/v1.3-REQUIREMENTS.md`; spine carries **checklist table** + short normative paragraph + link (D-13–D-15).

### Verification patterns already in repo

- `accrue/test/accrue/docs/community_auth_test.exs` reads `guides/auth_adapters.md` and asserts stable strings — **same pattern** can lock ORG-05/06 anchors for the new guide and post-edit auth/Sigra guides.

### Risks / footguns to document (D-21)

- Stale `active_organization_id` after membership revoke.
- IDOR on org routes without membership check.
- “First org in DB” defaults in admin.
- Webhook/replay using global queries.
- Treating `Accrue.Auth.Default` as production-safe for non-Sigra apps.

---

## Validation Architecture

This phase is **documentation-first**; automated feedback must prove (1) guides build under ExDoc, (2) locked acceptance strings exist in the right files, (3) auth installer messaging still reaches non-Sigra users.

### Dimension 8 — Doc and contract sampling

| Dimension | Signal | Instrument |
|-----------|--------|--------------|
| Doc build | No new ExDoc warnings on edited guides | `cd accrue && MIX_ENV=test mix docs` |
| ORG-05 spine | Spine file exists and contains required section markers | ExUnit reads `guides/organization_billing.md` (exact path chosen in Plan 01) |
| ORG-06 | phx.gen.auth + `Accrue.Auth` + `Accrue.Billable` + facade checklist literals | Same contract test + grep-verifiable headings in spine |
| Cross-guide | Sigra escape hatch + auth adapter choice strings | Extend or add tests over `auth_adapters.md` / `sigra_integration.md` |
| Installer | Non-Sigra branch mentions canonical paths | `rg` on `accrue.install.ex` |

### Manual-only (acceptable for v1.8 doc slice)

- Editorial readability and tutorial flow — covered by human review during execute-phase SUMMARY.

---

*Phase 37 — research synthesized 2026-04-21 for `/gsd-plan-phase 37`.*
