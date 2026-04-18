# Dialyzer + Ecto fixture seeds: `Subscription.changeset/2` and `insert!/1` chains
# produce spurious no_return / unused_fun / call warnings in MIX_ENV=test only.
# This file is the default Dialyxir ignore list when :ignore_warnings is omitted.
[
  ~r{^test/support/e2e_fixtures\.ex}
]
