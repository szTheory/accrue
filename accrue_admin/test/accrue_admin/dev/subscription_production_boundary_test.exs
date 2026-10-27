defmodule AccrueAdmin.Test.Phase252ProductionBoundaryTapFormatter do
  use GenServer

  def init(_opts), do: {:ok, []}

  def handle_cast({:test_finished, test}, results), do: {:noreply, [test | results]}

  def handle_cast({:suite_finished, _times}, results) do
    tests = Enum.reverse(results)
    IO.puts("TAP version 13")

    tests
    |> Enum.with_index(1)
    |> Enum.each(fn {test, index} ->
      name = "#{inspect(test.module)}::#{test.name}" |> String.replace(~r/[\r\n]+/u, " ")

      case test.state do
        nil ->
          IO.puts("ok #{index} - #{name}")

        {:skipped, _reason} ->
          IO.puts("ok #{index} - #{name} # SKIP")

        {:failed, failures} ->
          IO.puts("not ok #{index} - #{name}")

          Enum.each(failures, fn failure ->
            detail = failure_message(failure) |> String.replace(~r{/Users/[^/\s]+}, "<home>")
            IO.puts("# #{detail}")
          end)

        _ ->
          IO.puts("not ok #{index} - #{name}")
      end
    end)

    IO.puts("1..#{length(tests)}")
    {:noreply, []}
  end

  def handle_cast(_event, results), do: {:noreply, results}

  defp failure_message({exception, _stacktrace}) when is_exception(exception),
    do: Exception.message(exception)

  defp failure_message(exception) when is_exception(exception), do: Exception.message(exception)
  defp failure_message(%{message: message}) when is_binary(message), do: message

  defp failure_message(failure),
    do: inspect(failure, limit: 10, printable_limit: 400, pretty: false)
end

ExUnit.start(formatters: [AccrueAdmin.Test.Phase252ProductionBoundaryTapFormatter])

defmodule AccrueAdmin.Dev.SubscriptionProductionBoundaryTest do
  use ExUnit.Case, async: false

  defmodule ProdLikeRouter do
    use Phoenix.Router

    import AccrueAdmin.Router

    accrue_admin("/ops", session_keys: [:admin_token], allow_live_reload: false)
  end

  @production_tooling_paths [
    "/dev/clock",
    "/dev/email-preview",
    "/dev/webhook-fixtures",
    "/dev/components",
    "/dev/fake-inspect",
    "/dev/mail",
    "/dev/storybook",
    "/__e2e__",
    "/test/reset",
    "/lab"
  ]

  test "real dev routes keep Storybook, its assets, and the independent kitchen visible" do
    paths = Enum.map(AccrueAdmin.TestRouter.__routes__(), & &1.path)

    assert "/billing/dev/components" in paths
    assert Enum.any?(paths, &String.contains?(&1, "/dev/storybook"))
    assert AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook") in paths
    assert AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook") in paths
    assert "/dev/storybook/assets/geist-sans-vf.woff2" in paths
    assert "/dev/storybook/assets/geist-mono-vf.woff2" in paths
    assert Enum.any?(paths, &String.starts_with?(&1, "/billing/dev/mail"))
  end

  test "prod-like route table omits Storybook, test, and lab routes while retaining product routes" do
    paths = Enum.map(ProdLikeRouter.__routes__(), & &1.path)

    assert "/ops" in paths
    assert "/ops/subscriptions" in paths
    assert "/ops/subscriptions/:id" in paths
    assert "/ops/assets/css-#{AccrueAdmin.Assets.css_hash()}" in paths

    for tooling_path <- @production_tooling_paths do
      refute Enum.any?(paths, &String.contains?(&1, tooling_path)),
             "unexpected production tooling route containing #{tooling_path}: #{inspect(paths)}"
    end

    refute Enum.any?(paths, &String.contains?(&1, "/dev/storybook/assets/"))
    refute Enum.any?(paths, &String.contains?(&1, "/dev/storybook"))
  end

  test "production Mix project metadata excludes facts and story adapters from compile and package roots" do
    root = repo_root()

    projects = [
      {"accrue", "accrue/mix.exs"},
      {"accrue_admin", "accrue_admin/mix.exs"},
      {"accrue_portal", "accrue_portal/mix.exs"}
    ]

    configs =
      Enum.map(projects, fn {app, project_file} ->
        config = production_project_config(root, project_file)
        assert config.app == app
        assert config.elixirc_paths == "lib"

        package_files = String.split(config.package_files, "|", trim: true)
        assert "lib" in package_files
        refute Enum.any?(package_files, &(&1 in ["storybook", "test", "test/support"]))

        {app, config}
      end)

    {_app, admin} = Enum.find(configs, fn {app, _config} -> app == "accrue_admin" end)
    assert admin.storybook_scope == "dev,test"
    assert admin.storybook_runtime == "true"
  end

  test "story facts, adapters, manifests, runners, and browser support stay outside production sources" do
    root = repo_root()

    fixture_roots = [
      "dev_support/ui_scenarios/cadence_subscriptions.exs",
      "accrue_admin/storybook/_support/subscription_scenarios.ex",
      "storybook/components/subscription_detail.story.exs",
      "storybook/phase252-manifest.json",
      "scripts/dev/phase252_lab.mjs",
      "accrue_admin/e2e/phase252-story-helpers.js",
      "accrue_admin/e2e/subscription-stories-phase252.spec.js"
    ]

    for fixture <- fixture_roots do
      assert File.regular?(Path.join(root, fixture)),
             "expected positive fixture control: #{fixture}"

      refute Path.expand(fixture, root)
             |> String.starts_with?(Path.join(root, "accrue_admin/lib/"))

      refute Path.expand(fixture, root) |> String.starts_with?(Path.join(root, "accrue/lib/"))

      refute Path.expand(fixture, root)
             |> String.starts_with?(Path.join(root, "accrue_portal/lib/"))
    end

    production_sources =
      for app <- ["accrue", "accrue_admin", "accrue_portal"],
          path <- Path.wildcard(Path.join(root, "#{app}/lib/**/*.{ex,exs}")),
          do: {path, File.read!(path)}

    for {path, source} <- production_sources do
      refute source =~ "CadenceSubscriptionFacts", "scenario facts imported in #{path}"

      refute source =~ "AccrueAdmin.Storybook.SubscriptionScenarios",
             "story adapter imported in #{path}"

      refute source =~ "AccrueAdmin.Storybook.SubscriptionManifest",
             "story manifest imported in #{path}"
    end
  end

  test "canonical example host mount remains dev-disabled and has no Phase 252 lab forward" do
    router =
      File.read!(Path.join(repo_root(), "examples/accrue_host/lib/accrue_host_web/router.ex"))

    assert router =~
             "accrue_admin(\"/admin\", session_keys: [:user_token], allow_live_reload: false)"

    refute router =~ "forward(\"/__e2e__\""
    refute router =~ "phase252_lab"
  end

  defp repo_root, do: Path.expand("../../../../", __DIR__)

  defp production_project_config(root, project_file) do
    source_path = Path.join(root, project_file)

    code = ~S"""
    Mix.start()
    Mix.env(:prod)
    [{module, _bytecode}] = Code.compile_file(System.argv() |> hd())
    config = apply(module, :project, [])
    IO.puts("app=#{config[:app]}")
    IO.puts("elixirc_paths=#{Enum.join(config[:elixirc_paths], "|")}")
    IO.puts("package_files=#{Enum.join(config[:package][:files], "|")}")
    storybook = Enum.find(config[:deps], fn dep -> elem(dep, 0) == :phoenix_storybook end)
    {scope, runtime} = case storybook do
      nil -> {"absent", "absent"}
      {_, _, opts} ->
        {opts |> Keyword.get(:only, []) |> Enum.map_join(",", &to_string/1),
         opts |> Keyword.get(:runtime, true) |> to_string()}
    end
    IO.puts("storybook_scope=#{scope}")
    IO.puts("storybook_runtime=#{runtime}")
    """

    {output, 0} = System.cmd("elixir", ["-e", code, "--", source_path], cd: root)

    output
    |> String.split("\n", trim: true)
    |> Map.new(fn line ->
      [key, value] = String.split(line, "=", parts: 2)
      {String.to_atom(key), value}
    end)
  end
end
