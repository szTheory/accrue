import Config

# Runtime config is intentionally minimal at Wave 0.
#
# Per CLAUDE.md §Config Boundaries, runtime-only settings (Stripe secrets,
# webhook signing secrets, host-owned feature toggles) belong in this file.
# Plan 04's Stripe adapter reads its secrets via Application.get_env/3 at call
# time; adding the System.fetch_env!/1 calls to runtime.exs is explicitly
# deferred until Phase 2 when a live webhook test proves the shape.
