# Phase 28: Accessibility hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `28-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-20  
**Phase:** 28-accessibility-hardening  
**Areas discussed:** Step-up focus + keyboard; Table accessible name (A11Y-02); Axe CI gate (A11Y-04); Contrast evidence (A11Y-03)  
**Mode:** User selected **all** areas; research via parallel subagents; principal agent synthesized into single coherent architecture.

---

## 1. Step-up focus + keyboard (A11Y-01)

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView `JS.push_focus` / `JS.pop_focus` + `JS.focus_first` on open only | Patch-aware focus stack; idiomatic LV 1.1 | ✓ |
| `phx-hook` + minimal JS for tab trap + optional `inert` | Needed beyond stack alone; documented host registration | ✓ (paired with row above) |
| Native `<dialog>` + `showModal()` + `JS.ignore_attributes` | Strong browser semantics; defer unless easy | |
| Third-party focus-trap / Alpine / large a11y libs | Battle-tested but wrong dependency shape for mountable lib | |

**User's choice:** All areas explored; locked decision = **JS focus stack as default spine** + **small namespaced hook** for trap/inert + **Escape closes by default** with documented exceptions.  
**Notes:** Avoid focus calls on every patch; LiveViewTest for contracts, Playwright for mounted hook behavior.

---

## 2. Table accessible name (A11Y-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Visually hidden `<caption>` + Copy/assign alignment | Native table naming; low coupling to page `id`s | ✓ |
| `aria-labelledby` → page `<h1>` | DRY at DOM level; needs stable unique id | |
| `aria-label` on `<table>` | Simple but drift-prone | |

**User's choice:** **Optional `DataTable` assign** for caption text sourced from **`AccrueAdmin.Copy`** (same semantic source as page title); customers + webhooks only in this phase.

---

## 3. Axe CI gate (A11Y-04)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Single static URL | Fast but often not “mounted admin” realistic | |
| (b) Short journey login + navigate + `waitForLiveView` | Matches VERIFY-01; session-realistic | ✓ |
| (c) Many specs / routes | Higher flake and CI time | |

**Severity:** **Critical + serious** (not “serious” excluding critical).  
**Integration:** **Extend existing host Playwright** / VERIFY-01 invocation; **new spec file** acceptable; **no new CI job** by default.

**User's choice:** (b) + extend VERIFY-01 + desktop Chromium + attach axe output on failure.

---

## 4. Contrast evidence (A11Y-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Axe only | Computed colors; misses some gradients/states | Partial |
| Manual token checklist only | Cheap; misses composition | Partial |
| Axe on routes × light/dark + short gap checklist | Coherent with A11Y-04; targeted redundancy | ✓ |
| Stylelint WCAG plugins | Low ROI for `var()` + LV | Defer |

**User's choice:** **Same Playwright harness as axe gate** with **explicit light and dark** + **short gap checklist** in phase doc for axe-blind spots and exception registry.

---

## Claude's Discretion

- Hook module naming and whether webhooks gets a second axe test in the first PR.
- Extra stable wait selector beyond `waitForLiveView` if needed for flake reduction.

## Deferred Ideas

- Optional future migration to **native `<dialog>`** if it simplifies focus/Escape vs current `section` overlay.
