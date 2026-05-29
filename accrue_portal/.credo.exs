%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "test/",
          "web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/", ~r"/priv/plts/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        disabled: [
          {Credo.Check.Design.AliasUsage, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.WithSingleClause, []},
          {Credo.Check.Refactor.Apply, []},
          {Credo.Check.Refactor.CyclomaticComplexity, []},
          {Credo.Check.Refactor.MapJoin, []},
          {Credo.Check.Refactor.Nesting, []},
          {Credo.Check.Refactor.RejectReject, []}
        ]
      }
    }
  ]
}
