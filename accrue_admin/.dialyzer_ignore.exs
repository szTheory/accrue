# Dialyzer + Ecto fixture seeds: `Subscription.changeset/2` and `insert!/1` chains
# produce spurious no_return / unused_fun / call warnings in MIX_ENV=test only.
# This file is the default Dialyxir ignore list when :ignore_warnings is omitted.
[
  ~r{^test/support/e2e_fixtures\.ex},
  # Phase 252 whole-page scenario support (dev/test Storybook only): dialyzer attributes the
  # compiler-generated boolean checks of the attribution `cond` to line 1 and reports a
  # statically constant branch. The cond is the fail-closed input validation and is covered by
  # the Phase 253 page-slice lane; it is not production code.
  {"storybook/_support/subscription_page_scenarios.ex", :pattern_match, 1},
  # PhoenixStorybook.Story.PageBehaviour declares render/1 as a %Rendered{}; the whole-page
  # story deliberately returns the production renderer's already-rendered static markup as
  # Phoenix.HTML.raw/1 ({:safe, iodata}), which Storybook embeds unchanged. The Phase 253
  # page-slice lane asserts that exact return shape.
  ~r{storybook/pages/subscription\.story\.exs.*callback_type_mismatch}
]
