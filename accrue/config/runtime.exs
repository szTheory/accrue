import Config

# Runtime config is intentionally minimal at Wave 0.
#
# Per CLAUDE.md §Config Boundaries, runtime-only settings (Stripe secrets,
# webhook signing secrets, host-owned feature toggles) belong in this file.
# Plan 04's Stripe adapter reads its secrets via Application.get_env/3 at call
# time; adding the System.fetch_env!/1 calls to runtime.exs is explicitly
# deferred until Phase 2 when a live webhook test proves the shape.

# Live-Stripe test opt-in (quick task 260414-l9q).
#
# When running `mix test.live` (or the scheduled `live-stripe` CI job)
# with `STRIPE_TEST_SECRET_KEY` set in the environment, switch the
# default processor to `Accrue.Processor.Stripe` and wire the secret
# into `:lattice_stripe, :api_key` so live-stripe tests hit real Stripe
# test mode. Individual tests under `test/live_stripe/` also set these
# in their own `setup_all` as a defensive fallback.
#
# Default remains `Accrue.Processor.Fake` — any `mix test` run without
# the secret is untouched.
if config_env() == :test do
  if key = System.get_env("STRIPE_TEST_SECRET_KEY") do
    # The Stripe processor reads its secret via
    # `Application.get_env(:accrue, :stripe_secret_key)` (see
    # `lib/accrue/processor/stripe.ex:627`), not from the
    # `:lattice_stripe` app env. Set it here so live-stripe tests
    # picking up the processor swap automatically resolve their key.
    config :accrue,
      processor: Accrue.Processor.Stripe,
      stripe_secret_key: key
  end
end
