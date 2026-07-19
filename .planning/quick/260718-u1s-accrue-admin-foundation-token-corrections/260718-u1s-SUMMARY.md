---
quick_id: 260718-u1s
title: accrue_admin foundation token corrections (light contrast, de-hardcode cobalt, single-source dark)
status: complete
date: 2026-07-19
mode: quick
---

# Summary — accrue_admin foundation token corrections

Three deterministic, root-cause CSS-token corrections in `accrue_admin` plus a bundle
rebuild — Phase 1 of the approved admin re-skin gameplan. Cobalt `#5D79F6` kept as the sole
interaction accent; no palette change, no greening, no component restyle. All four verify
gates pass.

## Commits (atomic, one per task)

| Task | Commit | Message |
| ---- | ------ | ------- |
| 1 — Light-mode contrast pass | `2c6da192` | `style(260718-u1s): light-mode contrast pass on admin tokens` |
| 2 — De-hardcode cobalt literals | `89410264` | `fix(260718-u1s): derive accent-readable/focus/sidebar-active from --ax-accent` |
| 3 — Single-source dark set | `42e2be0b` | `refactor(260718-u1s): single-source admin dark --ax-* set` |
| 4 — Rebuild CSS bundle | `8dbad259` | `chore(260718-u1s): rebuild accrue_admin CSS bundle` |

## What changed

**Task 1 — Light-mode contrast (`theme.css`, light block only):**
- `--ax-border` `rgba(36,48,59,0.12)` → `0.20` — a visible-but-quiet 1px card edge on
  `--ax-elevated` (`#fff`) and `--ax-base` (`#FAFBFC`).
- `--ax-border-strong` `0.24` → `0.32` — kept clearly stronger than the new border.
- Surface layering achieved via the now-visible edge (plan permits relying on the border
  rather than darkening `--ax-base`). Muted text `#5d6a73` (~4.9:1 on white) and all five
  status `-border`/`-bg` pairs were audited and left as-is — none were genuinely invisible.
- Dark blocks untouched; no new selectors.

**Task 2 — De-hardcode stray cobalt literals (`theme.css` + `app.css`):**
- Light `--ax-accent-readable: #174ea6` → `color-mix(in srgb, var(--ax-accent) 62%, var(--accrue-ink))`.
- Dark (×2 copies) `--ax-accent-readable: #9bb5ff` → `color-mix(in srgb, var(--ax-accent) 65%, var(--accrue-paper))`.
- `--ax-focus-ring` (light + dark) → `var(--ax-accent-readable)` (derives from accent).
- `--ax-focus-shadow` (light `rgba(93,121,246,.24)` + dark `rgba(155,181,255,.24)`) →
  `0 0 0 4px color-mix(in srgb, var(--ax-accent) 24%, transparent)`.
- `app.css` sidebar dark + system@dark active pill: `background-color: #1f283d !important` →
  `color-mix(in srgb, var(--ax-accent) 12%, var(--ax-elevated)) !important`. The nav-label
  pins `color: #f4f7fa` (851/859) → `var(--ax-primary)`. `!important` and selectors kept.
- Out-of-scope `#f4f7fa`/`#1f283d` at lines 1020/1025/5121/5130 left untouched (later ratchet scope).
- Correctness check satisfied by construction: all four tokens now reference `var(--ax-accent)`
  (directly or via `--ax-accent-readable`), so a runtime accent swap propagates. No scratch
  change was made, so nothing needed reverting.

**Task 3 — Single-source dark `--ax-*` set (`theme.css`):**
- The two NON-media dark scopes (`html.accrue-admin[data-theme="dark"]` and the
  `html.accrue-admin [data-theme="dark"], .accrue-admin [data-theme="dark"]` sub-tree pair)
  merged into ONE combined selector-list rule — dark set authored once, was triplicated.
- The `@media (prefers-color-scheme: dark) html.accrue-admin[data-theme="system"]` rule kept
  as the 2nd authored copy (CSS cannot list a media-gated selector); system-dark stays
  media-gated, light-on-dark-OS behavior preserved.
- No bridging to core `--accrue-*` where values diverge (`--ax-primary #f4f7fa` vs
  `--accrue-ink #ECF1F5`; `--ax-elevated #171d24` vs `--accrue-surface #171B20`) — exact admin
  hexes kept, so rendered dark appearance is byte-identical. `#0f1318` occurrences 12 → 8.

**Task 4 — Rebuild bundle (`priv/static/accrue_admin.css`):**
- `mix accrue_admin.assets.build` regenerated the committed CSS bundle (source ships nothing
  until rebuilt — `assets.ex` embeds at compile time). JS bundle unchanged; only CSS staged.

## Verification results (all pass)

1. `mix accrue_admin.assets.build` — exit 0 (storybook `css_path`/`js_path` warnings are
   pre-existing and unrelated to tokens).
2. Post-commit `git diff --exit-code -- accrue_admin/priv/static/accrue_admin.css` — clean
   (exit 0), and idempotent (second rebuild re-diffs clean).
3. `mix compile --warnings-as-errors` — exit 0.
4. `npm run ratchet:ledger:self-test` — exit 0 (`verify_ratchet_ledger self-test passed.`).
5. `npm run ratchet:verify:self-test` — exit 0 (`ratchet-verify self-test passed.`).
6. Accent-derived tokens follow `--ax-accent` (confirmed by construction — all four resolve
   through `var(--ax-accent)`; bundle carries `62%`/`65%`/`24%`/`12%`/`48%` mixes and no
   `#174ea6`/`#9bb5ff`/`rgba(93,121,246)`/`rgba(155,181,255)`/`#1f283d` literals remain).

Dark appearance unchanged (pure refactor for all non-accent-derived tokens); the 4
accent-derived tokens land near — not exactly on — the old hand-picked hexes at cobalt
(expected tolerance): sidebar-active mix at 12% renders `#1f283d` exactly; accent-readable
mixes land near `#174ea6`/`#9bb5ff`. Light mode gains visible card borders + layered surfaces.

## Deviations from plan

- **Sidebar-active mix percentage: used 12%, not the plan's approximate "~18%".** The plan
  wrote `~18%` with a tilde and the explicit directive "tune the % so it renders `#1f283d`
  when accent==cobalt". Computed against the dark `--ax-elevated` (`#171d24`), 12% cobalt
  renders `#1f283d` exactly (18% renders ~`#242e4a`, a visibly lighter pill). 12% honors the
  tuning directive and best preserves the dark near-pixel-identical invariant.
- No other deviations. `mix accrue_admin.ui.round`/`ui.fix` and any `--verify-frozen` gate
  were NOT run (per guardrails — need a live key / baseline intentionally unfrozen).
  Pre-existing dirty working-tree files and `mix.lock` left untouched; only intentionally
  changed files staged per task.

## Self-Check: PASSED
- Commits `2c6da192`, `89410264`, `42e2be0b`, `8dbad259` all present in `git log`.
- Bundle diff clean post-commit; compile warnings-clean; both self-tests exit 0.
