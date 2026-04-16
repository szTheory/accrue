defmodule Mix.Tasks.Accrue.Gen.Handler do
  @shortdoc "Generate an Accrue webhook handler"
  @moduledoc """
  Generates a host-owned Accrue webhook handler scaffold.
  Generated files are stamped with `# accrue:generated` by
  `Accrue.Install.Fingerprints`.

  ## Flags

    * `--module MyApp.BillingHandler`
    * `--path lib/my_app/billing_handler.ex`
    * `--dry-run`
    * `--yes`
    * `--non-interactive`
    * `--force`
    * `--manual`

  For Phoenix-generator familiarity, a single positional module argument is
  also accepted:

      mix accrue.gen.handler MyApp.BillingHandler
  """

  use Mix.Task

  require EEx

  @switches [
    module: :string,
    path: :string,
    dry_run: :boolean,
    yes: :boolean,
    non_interactive: :boolean,
    force: :boolean,
    manual: :boolean
  ]

  @template Path.expand("../../../priv/accrue/templates/install/billing_handler.ex.eex", __DIR__)

  @impl Mix.Task
  def run(argv) do
    loadpaths()

    {opts, args, invalid} = OptionParser.parse(argv, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown accrue.gen.handler option(s): #{inspect(invalid)}")
    end

    module = module_name!(opts, args)
    path = Keyword.get(opts, :path) || module_path(module)
    content = render(module)

    cond do
      opts[:manual] || opts[:dry_run] ->
        report("manual: #{path}")
        report(content)

      File.exists?(path) and Accrue.Install.Fingerprints.user_edited?(path, content) ->
        report("skipped: never overwrite user-edited handler #{path}")

      File.exists?(path) and not Accrue.Install.Fingerprints.pristine?(path, content) ->
        report("skipped: never overwrite user-edited handler #{path}")

      true ->
        {status, reason} =
          Accrue.Install.Fingerprints.write(path, content,
            force: opts[:force] || false,
            dry_run: opts[:dry_run] || false
          )

        report("#{status}: #{path} #{reason}")
    end
  end

  defp loadpaths do
    Mix.Task.run("loadpaths")
  rescue
    e in Mix.Error ->
      if Exception.message(e) =~ "errors on dependencies" do
        report("loadpaths: continuing with available paths; run mix deps.get if deps are missing")
      else
        reraise e, __STACKTRACE__
      end
  end

  defp module_name!(opts, args) do
    case {Keyword.get(opts, :module), args} do
      {nil, []} -> "MyApp.BillingHandler"
      {module, []} when is_binary(module) -> module
      {nil, [module]} -> module
      {_module, [_arg | _]} -> Mix.raise("Use --module or a positional module, not both")
      {_module, []} -> Mix.raise("Invalid handler module")
    end
  end

  defp module_path(module) do
    filename =
      module
      |> String.split(".")
      |> Enum.map(&Macro.underscore/1)
      |> Path.join()

    Path.join(["lib", "#{filename}.ex"])
  end

  defp render(module) do
    EEx.eval_file(@template, assigns: [billing_handler: module])
  end

  defp report(message), do: IO.puts(message)
end
