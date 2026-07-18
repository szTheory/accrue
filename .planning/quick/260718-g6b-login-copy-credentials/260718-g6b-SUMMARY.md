---
quick_id: 260718-g6b
title: Click-to-copy demo credentials on the host login page
status: complete
date: 2026-07-18
commit: b4407552
---

# Quick Task 260718-g6b — Summary

## What changed
- **NEW** `examples/accrue_host/assets/js/hooks/clipboard.js` — Clipboard LiveView hook (ported from accrue_admin): guarded `navigator.clipboard` copy, transient `data-copied` icon state, and an ephemeral toast cloned from `#copy-toast-template` into fixed `#copy-toast-root` with auto-dismiss.
- `examples/accrue_host/assets/js/app.js` — imported and registered `Clipboard` in the `LiveSocket` hooks map.
- `examples/accrue_host/lib/accrue_host_web/live/user_live/login.ex` — each persona card now shows the email and password as click-to-copy chips (password repeated per card), a muted "Tap any field to copy" hint replaces the single top password badge, and a fixed toast root + hidden template were added. Loop switched to `Enum.with_index` for unique hook ids.
- `examples/accrue_host/assets/css/app.css` — `.copy-chip` icon swap keyed on `data-copied`, copied outline via inset box-shadow (no reflow), and `.copy-toast` leave transition.

## Verification
Playwright driving the live page with clipboard permissions granted — **10/10 assertions PASS**:
- email copies to clipboard; password copies (`accrue-demo-password`)
- toast shows "Copied email address" and auto-dismisses
- chip `data-copied="true"` + check icon appear after copy
- **no reflow**: chip bounding box AND page height unchanged on copy
- Enter key copies (keyboard accessibility)

Supporting checks: server render shows 8 `phx-hook="Clipboard"` chips + toast root + template; the built JS bundle serves `showCopyToast` and the CSS bundle serves the `copy-chip` rules plus daisyUI `alert-success`/`toast-top` (emitted because they now appear in scanned HEEx).

## Notes
- Deliverable is copy-to-clipboard, not form-autofill (per the approved plan; the page also has a duplicate `#user_email` id across its two forms that makes reliable fill fiddly).
- `AccrueHost.DemoBrand` (`personas/0`, `demo_password/0`) unchanged — still the single source of truth.
- Host builds its own assets at dev time; no committed-bundle rebuild needed. Built artifacts under `priv/static/assets/` are gitignored.
- The ~10 pre-existing dirty/untracked working-tree files were left untouched; the code commit staged exactly the four source files.
