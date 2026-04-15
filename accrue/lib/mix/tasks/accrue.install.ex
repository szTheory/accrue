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
    validate_planned_config!(project)

    print_intro(opts)
    print_orchestration(project)
    report("config docs: #{String.split(config_docs(), "\n") |> hd()}")
    print_auth_guidance(project)
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

  defp print_orchestration(project) do
    report("Project: #{inspect(project.__struct__)}")
    report("Templates: #{inspect(Accrue.Install.Templates)}")
    report("Fingerprints: #{inspect(Accrue.Install.Fingerprints)}")
    report("Patches: #{inspect(Accrue.Install.Patches)}")

    report(
      "Stripe test-mode readiness uses STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET with " <>
        "sk_test_ / sk_live_ / whsec_ redaction"
    )

    if project.manual? do
      report("manual: project shape requires snippet review")
    end
  end

  defp print_auth_guidance(%{has_sigra?: true}) do
    report("Sigra detected: config :accrue, :auth_adapter, Accrue.Integrations.Sigra")
    report("Fallback/community path: Accrue.Auth.Default or a community auth adapter")
  end

  defp print_auth_guidance(_project) do
    report("Auth fallback: Accrue.Auth.Default with prod-safety warning")
    report("Community auth adapters can implement Accrue.Auth")
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

  defp validate_planned_config!(project) do
    Accrue.Config.validate!(
      repo: project.repo || Module.concat([project.app_module, Repo]),
      processor: Accrue.Processor.Stripe,
      auth_adapter:
        if(project.has_sigra?, do: Accrue.Integrations.Sigra, else: Accrue.Auth.Default),
      stripe_secret_key: "sk_test_install_validation",
      branding: [
        from_email: "billing@example.com",
        support_email: "support@example.com"
      ]
    )
  end

  defp config_docs do
    NimbleOptions.docs(Accrue.Config.schema())
  end

  defp redact(message) do
    message
    |> to_string()
    |> String.replace(~r/sk_(test|live)_[A-Za-z0-9_=-]+/, "sk_\\1_[REDACTED]")
    |> String.replace(~r/whsec_[A-Za-z0-9_=-]+/, "whsec_[REDACTED]")
    |> String.replace(~r/([A-Z0-9_]*(?:SECRET|KEY)[A-Z0-9_]*=)[^\s,}]+/, "\\1[REDACTED]")
  end

  defp report(message), do: IO.puts(redact(message))
end
