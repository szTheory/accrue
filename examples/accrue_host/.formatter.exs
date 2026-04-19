[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  # Keep Accrue router macros in the space form expected by `mix accrue.install`
  # skip detection when compiling against published Hex `accrue` (host Hex smoke).
  locals_without_parens: [accrue_admin: 2, accrue_webhook: 2],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
