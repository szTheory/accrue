---
created: 2026-06-20T00:00:00Z
title: Clean up rendro (JSV/YamlElixir) + mailglass_admin (OptionalDeps) compile warnings on Docker host boot
area: deps / build-hygiene
priority: low
files:
  - examples/accrue_host/deps/rendro/mix.exs
  - examples/accrue_host/deps/rendro/lib/rendro/public_api/validator.ex
  - examples/accrue_host/deps/rendro/lib/rendro/viewer_evidence/validator.ex
  - examples/accrue_host/deps/rendro/lib/rendro/viewer_evidence/frontmatter.ex
  - examples/accrue_host/deps/mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - examples/accrue_host/deps/mailglass_admin/lib/mailglass_admin/operator/shell.ex
---

## Problem

Booting the Docker host demo (`cd examples/accrue_host && make up`) prints two
clusters of compile warnings, both from **sibling dependencies**, not Accrue's
own code. Cosmetic only — no runtime impact in the demo — but noisy.

### Cluster 1 — `rendro`: JSV / YamlElixir undefined

```
warning: YamlElixir.read_from_string/1 is undefined ...
  └─ lib/rendro/viewer_evidence/frontmatter.ex:8:25
warning: JSV.build!/1 is undefined ...
  └─ lib/rendro/public_api/validator.ex:8:68
warning: JSV.validate/2 is undefined ...        (validator.ex:10, viewer_evidence/validator.ex:29)
warning: JSV.normalize_error/1 is undefined ... (validator.ex:18, viewer_evidence/validator.ex:393)
warning: JSV.build!/1 is undefined ...          (viewer_evidence/validator.ex:384)
```

**Root cause (upstream in rendro):** `rendro/mix.exs` declares both deps as
test-only with no runtime:

```elixir
{:jsv, "~> 0.18", only: [:dev, :test], runtime: false},
{:yaml_elixir, "~> 2.12", only: [:dev, :test], runtime: false},
```

But `Rendro.PublicApi.Validator`, `Rendro.ViewerEvidence.Validator`, and
`Rendro.ViewerEvidence.Frontmatter` call `JSV.*` / `YamlElixir.*` directly. When
rendro compiles as a host dependency (prod-ish env, test-only deps absent), the
modules aren't available → undefined warnings. This is effectively a rendro-side
config bug: either those modules should be guarded behind
`Code.ensure_loaded?/1`, or `:jsv`/`:yaml_elixir` shouldn't be `runtime: false`
test-only if real codepaths use them.

### Cluster 2 — `mailglass_admin`: OptionalDeps.MailglassInbound undefined

```
warning: MailglassAdmin.OptionalDeps.MailglassInbound.available?/0 is undefined ...
  └─ lib/mailglass_admin/inbound_live.ex:552:48
  └─ lib/mailglass_admin/operator/shell.ex:41:52
```

**Root cause:** mailglass_admin's optional-dep guard
(`Code.ensure_loaded?(@gateway) and @gateway.available?()`) references the
`mailglass_inbound` integration module, which we don't pull into the host demo.
The runtime guard is correct; the warning is just the static compiler resolving
the module ref. Upstream could silence it with the standard
`Code.ensure_loaded?` + `function_exported?` two-step, or a module attribute
indirection.

## Follow Up

These live in sibling repos, so options are:

1. **Upstream fixes (preferred, real fix):**
   - rendro: guard the JSV/YamlElixir callsites behind `Code.ensure_loaded?/1`,
     OR promote `:jsv`/`:yaml_elixir` out of `only: [:dev, :test]` if those
     validators run in prod.
   - mailglass_admin: use `function_exported?/3` after `ensure_loaded?` so the
     optional gateway ref doesn't warn when the integration isn't present.
2. **Accept as known upstream warts** and note them in the docker-dx footguns
   list so they don't read as Accrue regressions.
3. If we ever gate the host demo build on warnings-as-errors, scope these deps
   out explicitly.

Out-of-band cleanup — not blocking anything. Surfaced in `examples/accrue_host`
Docker boot logs on 2026-06-20. Companion to the premailex Meeseeks.Error todo
([2026-06-20-premailex-meeseeks-compile-warning.md]).
