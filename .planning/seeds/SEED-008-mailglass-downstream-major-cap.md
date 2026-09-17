---
id: SEED-008
status: dormant
planted: 2026-09-15
planted_during: v1.62 Release Integration & Repository Hygiene — Phase 230 (reviewable history integration)
trigger_when: A downstream adopter needs mailglass 2.x behavior, OR Accrue's own email work reopens, OR a maintainer decides to publish the cap as a documented constraint
target_version: "mailglass 2.x (2.5.0 published 2026-08-20)"
scope: small-to-medium
source: cross-project request from the GetFluent session, 2026-09-15
---

# SEED-008: `mailglass ~> 1.0` caps every downstream consumer at 1.x

## Status: DORMANT

Not a defect, not blocking Accrue. This is a **door that is closed**, recorded so it is
not rediscovered by accident a third time.

## The Fact

`accrue/mix.exs:68` declares `{:mailglass, "~> 1.0"}`. Hex has **mailglass 2.5.0**
(published 2026-08-20). Because Accrue is the only edge in a consuming app's dependency
tree that mentions mailglass, **no host depending on Accrue can reach 2.x** — whether or
not that host uses mailglass itself.

Verified 2026-09-15 on `origin/main` (`d30fc25d`), the v1.62 milestone branch, and
`integration/v1.62-candidate`. The constraint is identical on all three.

## Why This Is Not A One-Line Constraint Bump

**Accrue uses mailglass deeply — 118 call sites** across `accrue/lib` and
`accrue_admin/lib`, including:

- `use Mailglass.Mailable, stream: :transactional`
- `Mailglass.Message` / `Mailglass.Message.put_function/2`
- `Mailglass.Renderer.render/1`

The email + invoice render spine runs through it (see PROJECT.md v1.29, Phases 88–90,
where `mjml_eex` + `phoenix_swoosh` were replaced by Mailglass). Relaxing to
`~> 1.0 or ~> 2.0` therefore requires a real compatibility assessment against 2.5.0's API
surface, not an edit to `mix.exs`.

**The three things to test, if this is ever picked up:**

1. what 2.x changed in the **mailable behaviour** (`use Mailglass.Mailable`)
2. what 2.x changed in the **message struct** (`Mailglass.Message`, `put_function/2`)
3. what 2.x changed in the **renderer contract** (`Mailglass.Renderer.render/1`)

## "Stays Capped" Is A Legitimate Outcome

If 2.x genuinely broke something Accrue relies on, the right answer is to **keep the cap
and document it**, not to force the bump. What is not acceptable is leaving it
undiscoverable: a transitive pin that silently caps an unrelated library's major version
is near-impossible to find from downstream. The requesting team found it only via
`mix deps.tree` and a guess.

**Therefore: whichever way the constraint lands, add a line to Accrue's README** naming
the mailglass major-version floor/ceiling and why. That half is worth doing independently
of the compatibility work.

## When to Surface

**Trigger:** dormant until one of —
- a downstream adopter needs mailglass 2.x behavior, or
- Accrue's own email/mailer work reopens for other reasons, or
- a maintainer simply wants the constraint documented (the README half is cheap and
  standalone — it does not require the compatibility assessment first).

Surface at the next `/gsd-new-milestone` scan, or run the README half as a quick task
at any time.

## Scope Estimate

**Small** for the README documentation half alone (quick task).
**Medium** if the 2.x compatibility assessment is undertaken — 118 call sites across two
packages, three API surfaces to diff, and the email regression suite to re-green.

## Origin

Raised 2026-09-15 by the GetFluent session as request AC-REQ-A, while Accrue was
mid-execution on v1.62 Phase 230. Their writeup lives outside this repo at
`~/getfluent/getfluent-app/lib-requests/2026-09-15-accrue.md`.

Their motivating incident is context, not a requirement on Accrue: they sent zero email
for twelve days behind a From address on a domain they did not own, which the provider
accepted with a 200 and a message id and then never delivered. CI and every deploy signal
stayed green throughout; the only disconfirming evidence was an empty inbox. Their actual
ask of mailglass is **submitted-vs-delivered as distinct, queryable states** — a version
bump only matters if 2.x ships that. They have put that question to the mailglass
maintainers directly rather than assuming.

They explicitly amended AC-REQ-A to state it should **not** be read as asking for a
constraint bump.

## Related, Already Resolved — Do Not Re-Raise

The same request originally paired this with `{:decimal, "~> 2.0"}`. **That one is already
fixed on `origin/main`**, which declares `{:decimal, "~> 3.0"}` and locks decimal 3.1.1.
Any downstream `override: true` for decimal is stale once the consumer's Accrue pin moves
past `d30fc25d`. No Accrue-side action needed.
