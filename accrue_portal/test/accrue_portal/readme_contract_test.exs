defmodule AccruePortal.ReadmeContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../README.md", __DIR__)
  @readme File.read!(@readme_path)
  @context_source Path.expand("../../lib/accrue_portal/context.ex", __DIR__)

  test "documented mount options and adapter callbacks match the public router and behavior" do
    snippets = elixir_snippets(@readme)
    mount_snippet = Enum.find(snippets, &String.contains?(&1, "context_adapter:"))

    adapter_snippet =
      Enum.find(snippets, &String.contains?(&1, "@behaviour Accrue.Portal.Context"))

    assert is_binary(mount_snippet)
    assert is_binary(adapter_snippet)

    assert {:ok, mount_ast} = Code.string_to_quoted(mount_snippet)
    assert {:ok, adapter_ast} = Code.string_to_quoted(adapter_snippet)

    mount_args =
      mount_ast
      |> calls(:accrue_portal)
      |> Enum.find(fn
        [_path, opts] when is_list(opts) -> Keyword.has_key?(opts, :context_adapter)
        _ -> false
      end)

    assert [_path, opts] = mount_args
    assert Keyword.keys(opts) |> Enum.sort() == [:context_adapter, :login_path, :session_keys]
    assert Keyword.has_key?(opts, :context_adapter)

    documented_callbacks = definitions(adapter_ast)
    public_callbacks = Accrue.Portal.Context.behaviour_info(:callbacks)
    assert Enum.all?(public_callbacks, &(&1 in documented_callbacks))
    assert {:resolve, 2} in documented_callbacks
    assert {:authorize, 4} in documented_callbacks
  end

  test "every named Context action appears in adopter documentation" do
    source = File.read!(@context_source)

    assert [action_definition] =
             Regex.run(~r/@type action ::([\s\S]*?)@type t ::/m, source, capture: :all_but_first)

    actions =
      Regex.scan(~r/:([a-z_]+)/, action_definition, capture: :all_but_first)
      |> List.flatten()
      |> Enum.uniq()

    assert length(actions) == 11
    Enum.each(actions, fn action -> assert @readme =~ ":#{action}" end)
  end

  defp elixir_snippets(markdown) do
    Regex.scan(~r/```elixir\s*\n(.*?)\n```/s, markdown, capture: :all_but_first)
    |> List.flatten()
  end

  defp calls(ast, name) do
    {_ast, found} =
      Macro.prewalk(ast, [], fn
        {^name, _metadata, args} = node, found when is_list(args) -> {node, [args | found]}
        node, found -> {node, found}
      end)

    Enum.reverse(found)
  end

  defp definitions(ast) do
    {_ast, found} =
      Macro.prewalk(ast, [], fn
        {:def, _metadata, [{name, _call_metadata, args}, _body]} = node, found
        when is_atom(name) and is_list(args) ->
          {node, [{name, length(args)} | found]}

        node, found ->
          {node, found}
      end)

    Enum.reverse(found)
  end
end
