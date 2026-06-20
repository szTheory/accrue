---
created: 2026-06-20T00:00:00Z
title: Clean up premailex Meeseeks.Error compile warning on Docker host boot
area: deps / build-hygiene
priority: low
files:
  - examples/accrue_host/config/config.exs
  - accrue/deps/premailex/lib/premailex/html_parser/meeseeks.ex
---

## Problem

Booting the Docker host demo (`cd examples/accrue_host && make up`) prints a
compile warning while building the `premailex` dependency:

```
==> premailex
Compiling 10 files (.ex)
    warning: struct Meeseeks.Error is undefined (module Meeseeks.Error is not
    available or is yet to be defined)
     33 │     e in Meeseeks.Error ->
        │       ~
     └─ lib/premailex/html_parser/meeseeks.ex:33:7: Premailex.HTMLParser.Meeseeks.all/2
```

`premailex` ships parser adapters for both Floki and Meeseeks and compiles both
modules unconditionally. We use the Floki adapter (Floki IS in deps; `:meeseeks`
is NOT), so the `rescue e in Meeseeks.Error` clause in the unused Meeseeks
adapter references a struct from a module that was never loaded — hence the
warning. **Cosmetic only: no runtime impact**, the Meeseeks code path is never
executed.

## Follow Up

Pick the least-invasive option:

1. **Confirm/pin the Floki parser explicitly** so intent is documented:
   `config :premailex, html_parser: Premailex.HTMLParser.Floki`. NOTE: this does
   NOT stop premailex from *compiling* its Meeseeks module, so the warning likely
   persists — verify before relying on it.
2. **Suppress at the dep boundary** if premailex stays noisy — e.g. scope it out
   of the warnings-as-errors / strict-compile gate for that one dep, or accept it
   as a known upstream wart and document it in the docker-dx footguns list.
3. **Upstream**: premailex could guard the Meeseeks adapter behind
   `Code.ensure_loaded?(Meeseeks)`; consider an issue/PR if it bothers us enough.

Out-of-band cleanup — not blocking anything. Surfaced in `examples/accrue_host`
Docker boot logs on 2026-06-20.
