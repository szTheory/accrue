defmodule Mix.Tasks.Accrue.Install do
  @shortdoc "Install Accrue into a Phoenix application"
  @moduledoc """
  Generates host-owned Accrue wiring.

  ## Flags

    * `--billable MyApp.Accounts.User`
    * `--billing-context MyApp.Billing`
    * `--webhook-path /webhooks/stripe`
    * `--admin-mount /billing`
    * `--admin` / `--no-admin`
    * `--sigra` / `--no-sigra`
    * `--dry-run`
    * `--yes`
    * `--non-interactive`
    * `--manual`
    * `--force`
    * `--write-conflicts`
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    loadpaths()

    opts = Accrue.Install.Options.parse!(argv)
    project = Accrue.Install.Project.discover!(opts)
    Accrue.Install.Templates.validate_planned_config!(project)

    print_intro(opts)
    report("config docs: #{String.split(Accrue.Install.Templates.config_docs(), "\n") |> hd()}")
    report(Accrue.Install.Templates.stripe_test_mode_readiness())

    results =
      if opts.dry_run or opts.manual or project.manual? do
        report("manual: review generated snippets before applying")
        print_manual_snippets(project, opts)
        []
      else
        install(project, opts)
      end

    print_summary(results, opts, project)
  end

  defp loadpaths do
    Mix.Task.run("loadpaths")
  rescue
    e in Mix.Error ->
      if Exception.message(e) =~ "errors on dependencies" do
        Mix.shell().info(
          "loadpaths: continuing with available paths; run mix deps.get if deps are missing"
        )
      else
        reraise e, __STACKTRACE__
      end
  end

  defp print_intro(%Accrue.Install.Options{} = opts) do
    report("Accrue installer")
    report("dependency: {:igniter, \"~> 0.7.9\", runtime: false}")

    report("flags: --dry-run --yes --non-interactive --manual --force --write-conflicts")

    report("billing_context: #{opts.billing_context}")
    report("webhook_path: #{opts.webhook_path}")
    report("admin_mount: #{opts.admin_mount}")

    if opts.dry_run do
      report("dry-run: no files changed")
    end
  end

  defp install(project, opts) do
    template_results =
      project
      |> Accrue.Install.Templates.render_all(opts)
      |> Enum.map(fn {path, content} ->
        {status, reason} =
          Accrue.Install.Fingerprints.write(path, content,
            force: opts.force,
            dry_run: opts.dry_run
          )

        report("#{status}: #{Path.relative_to_cwd(path)} #{reason}")
        {status, path, reason}
      end)

    patch_results =
      project
      |> Accrue.Install.Patches.apply(opts)
      |> Enum.map(&report_patch_result/1)

    template_results ++ patch_results
  end

  defp print_manual_snippets(project, opts) do
    for {name, snippet} <- Accrue.Install.Patches.manual_snippets(project, opts) do
      report("#{name}:")
      report(snippet)
    end
  end

  defp report_patch_result({status, path, reason}) when status in [:changed, :skipped] do
    report("#{status}: #{Path.relative_to_cwd(path)} #{reason}")
    {status, path, reason}
  end

  defp report_patch_result({:manual, nil, reason, snippet}) do
    report("manual: #{reason}")
    report(snippet)
    {:manual, nil, reason}
  end

  defp report_patch_result({:manual, path, reason, snippet}) do
    report("manual: #{Path.relative_to_cwd(path)} #{reason}")
    report(snippet)
    {:manual, path, reason}
  end

  defp print_summary(results, opts, project) do
    changed = Enum.count(results, &match?({:changed, _, _}, &1))
    skipped = Enum.count(results, &match?({:skipped, _, _}, &1))
    manual = if opts.manual or opts.dry_run or project.manual?, do: 1, else: 0

    report("changed: #{changed}")
    report("skipped: #{skipped}")
    report("manual: #{manual}")
  end

  defp report(message), do: IO.puts(message)
end
