# Local Demo: See the Admin UI Without Wiring Stripe

You want to *see* the billing admin UI your operators get — the customers,
subscriptions, invoices, webhook ingest, and audit history — without first
standing up a Stripe account or writing a line of integration code. The checked-in
`examples/accrue_host` Phoenix app gives you exactly that: a realistic, seeded host
backed by `Accrue.Processor.Fake`, so the whole story runs credential-free.

## TL;DR

```bash
git clone https://github.com/szTheory/accrue
cd accrue/examples/accrue_host
make proxy      # once per machine — starts the shared local proxy
make up         # boots and prints a launch banner
```

Open **http://accrue.localhost/admin**, sign in as `healthy@example.com` with password
`accrue-demo-password`. That's the operator surface.

## 1. Start it

From the repo, `cd examples/accrue_host`, run `make proxy` once (it starts a small
shared reverse proxy), then `make up`. The demo comes up at a **stable URL** —
`http://accrue.localhost` — that never changes and never collides with your other
running lib demos (each gets its own `*.localhost` name). `make open` jumps straight
there once it's up.

## 2. Read the banner

`make up` prints a copy-pasteable launch banner: the stable
`http://accrue.localhost/admin` URL (with a `http://127.0.0.1:<port>` fallback for
when the proxy is off), the real mounted routes, and every seeded demo login with its
password. You never have to guess a port or hunt for credentials — the banner is the
single source of truth for this run.

## 3. Sign in

All five seeded accounts share the password **`accrue-demo-password`**. Each one is
shaped to show a different billing state, so you can explore the admin UI against
real lifecycle variety:

| Login | What you'll see |
|-------|-----------------|
| `healthy@example.com` | Clean, subscribed — no dunning banner |
| `past-due@example.com` | `past_due` with an active dunning campaign banner |
| `canceled@example.com` | A canceled subscription |
| `enterprise@example.com` | Premium plan with a JPY invoice showcase |
| `trialing@example.com` | A trialing subscription |

Sign in at `/users/log-in`.

## 4. Walk `/admin`

`/admin` is the mounted Accrue Admin UI. From there you can review **customers**,
their **subscriptions** and **invoices**, inspect **webhook** ingest and **replay**
events, and read the persisted **audit** history that billing changes leave behind.
The mounted billing portal lives at `/billing`, and the host's own billing screens
sit under `/app/billing` and `/app/reports/advanced` (entitlement-gated).

## 5. What you'll see

Everything here is **Fake-backed** — `Accrue.Processor.Fake` stands in for Stripe, so
no live keys are required and the seeded states are deterministic. Sent emails (like
dunning notices) are captured locally and previewable at `/dev/mailbox`. This is the
admin experience your operators get, end to end, before you connect a real processor.

## Where to go next

- The full command reference (caching model, `make` targets, troubleshooting) lives
  in the example app README:
  [`../../examples/accrue_host/README.md`](../../examples/accrue_host/README.md).
- To install Accrue into your *own* Phoenix app, follow the package install story in
  [`../../accrue/guides/first_hour.md`](../../accrue/guides/first_hour.md).
- For host wiring of the admin UI itself (router mount, branding, auth), see
  [`admin_ui.md`](admin_ui.md).
