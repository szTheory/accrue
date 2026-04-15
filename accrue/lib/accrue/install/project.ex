defmodule Accrue.Install.Project do
  @moduledoc """
  Phoenix host project discovery for `mix accrue.install`.
  """

  defstruct root: ".",
            app: nil,
            app_module: nil,
            repo: nil,
            router_path: nil,
            config_path: nil,
            runtime_config_path: nil,
            mix_path: nil,
            migrations_path: nil,
            has_accrue_admin?: false,
            has_sigra?: false,
            has_oban?: false,
            billable: nil,
            manual?: false

  @type t :: %__MODULE__{}

  @doc """
  Discovers the host Phoenix project shape.

  If router/repo/app cannot be determined safely, discovery marks the project
  as manual so the installer can print snippets instead of mutating files.
  """
  @spec discover!(Accrue.Install.Options.t()) :: t()
  def discover!(%Accrue.Install.Options{} = opts) do
    root = File.cwd!()
    mix_path = Path.join(root, "mix.exs")
    mix = read(mix_path)
    app_module = discover_app_module(mix)
    app = discover_app(mix)
    router_path = discover_router(root, app_module)
    repo = discover_repo(root, app_module)
    config_path = Path.join(root, "config/config.exs")
    runtime_config_path = Path.join(root, "config/runtime.exs")
    migrations_path = Path.join(root, "priv/repo/migrations")

    manual? =
      opts.manual or is_nil(app_module) or is_nil(router_path) or is_nil(repo) or is_nil(app)

    %__MODULE__{
      root: root,
      app: app,
      app_module: app_module || "MyApp",
      repo: repo,
      router_path: router_path,
      config_path: config_path,
      runtime_config_path: runtime_config_path,
      mix_path: mix_path,
      migrations_path: migrations_path,
      has_accrue_admin?: enabled?(opts.admin, dependency?(mix, :accrue_admin)),
      has_sigra?: enabled?(opts.sigra, dependency?(mix, :sigra)),
      has_oban?: dependency?(mix, :oban),
      billable: opts.billable || detect_billable(root),
      manual?: manual?
    }
  end

  defp read(path) do
    if File.exists?(path), do: File.read!(path), else: ""
  end

  defp discover_app_module(mix) do
    case Regex.run(~r/defmodule\s+([A-Z][A-Za-z0-9_.]*)\.MixProject/, mix) do
      [_, module] -> module
      _ -> nil
    end
  end

  defp discover_app(mix) do
    case Regex.run(~r/app:\s*:([a-zA-Z0-9_]+)/, mix) do
      [_, app] -> String.to_atom(app)
      _ -> nil
    end
  end

  defp discover_router(root, app_module) when is_binary(app_module) do
    underscored = Macro.underscore(app_module)
    path = Path.join([root, "lib/#{underscored}_web/router.ex"])
    if File.exists?(path), do: path
  end

  defp discover_router(_root, _app_module), do: nil

  defp discover_repo(root, app_module) when is_binary(app_module) do
    expected = Module.concat([app_module, Repo])

    root
    |> Path.join("lib/**/*.ex")
    |> Path.wildcard()
    |> Enum.find_value(fn path ->
      content = File.read!(path)

      cond do
        content =~ "defmodule #{inspect(expected)}" -> expected
        content =~ "use Ecto.Repo" -> module_from_file(content)
        true -> nil
      end
    end) || expected
  end

  defp discover_repo(_root, _app_module), do: nil

  defp module_from_file(content) do
    case Regex.run(~r/defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do/, content) do
      [_, module] -> Module.concat([module])
      _ -> nil
    end
  end

  defp dependency?(mix, dep) when is_atom(dep) do
    mix =~ ":#{dep}" or mix =~ "{#{inspect(dep)},"
  end

  defp enabled?(true, _detected?), do: true
  defp enabled?(false, _detected?), do: false
  defp enabled?(:auto, detected?), do: detected?

  defp detect_billable(root) do
    root
    |> Path.join("lib/**/*.ex")
    |> Path.wildcard()
    |> Enum.find_value(fn path ->
      content = File.read!(path)

      if content =~ "use Accrue.Billable" do
        module_from_file(content)
      end
    end)
  end
end
