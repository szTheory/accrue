%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/", ~r"/priv/plts/"]
      },
      plugins: [],
      # The custom check module is compiled as part of the accrue app, so
      # we don't need to `requires:` the source file — that would redefine
      # the already-loaded BEAM module and emit a warning.
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [
          # Custom Accrue checks — enforce BILL-05 at lint time (Plan 03-01).
          {Accrue.Credo.NoRawStatusAccess, []}
        ]
      }
    }
  ]
}
