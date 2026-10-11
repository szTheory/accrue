Code.eval_file("seeds/helpers.exs", __DIR__)

# Use eval_file (not require_file) so the sub-seeds re-run every time seeds.exs is
# evaluated. require_file memoizes globally per BEAM node, which silently skips the
# sub-seeds on the 2nd+ eval — breaking the host-integration tests that each
# `Code.eval_file("priv/repo/seeds.exs")` in the same `mix test` run (they'd see 0
# rows). The sub-seeds are idempotent (ensure_*/on_conflict: :nothing), so re-eval
# is safe in production single-run too.
Code.eval_file("seeds/hero_accounts.exs", __DIR__)
Code.eval_file("seeds/background_data.exs", __DIR__)
Code.eval_file("seeds/showcase.exs", __DIR__)
Code.eval_file("seeds/edge_states.exs", __DIR__)
Code.eval_file("seeds/phase191_flow_states.exs", __DIR__)
