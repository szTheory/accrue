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
      |> Enum.flat_map(fn {path, content} ->
        path
        |> Accrue.Install.Fingerprints.write(content,
          force: opts.force,
          dry_run: opts.dry_run,
          write_conflicts: opts.write_conflicts
        )
        |> report_template_result()
      end)

    patch_results =
      project
      |> Accrue.Install.Patches.apply(opts)
      |> Enum.flat_map(&report_patch_result/1)

    template_results ++ patch_results
  end

  defp print_manual_snippets(project, opts) do
    for {name, snippet} <- Accrue.Install.Patches.manual_snippets(project, opts) do
      report("#{name}:")
      report(snippet)
    end
  end

  defp report_template_result({status, path, reason}) when status in [:changed, :skipped] do
    label = template_label(status, reason)
    report("#{label}: #{Path.relative_to_cwd(path)}")
    [{status, path, reason}]
  end

  defp report_template_result({:skipped, path, reason, artifact_path}) do
    label = template_label(:skipped, reason)
    report("#{label}: #{Path.relative_to_cwd(path)}")
    report("conflict artifact: #{Path.relative_to_cwd(artifact_path)}")
    [{:skipped, path, reason}, {:conflict_artifact, artifact_path, reason}]
  end

  defp report_patch_result({status, path, reason}) when status in [:changed, :skipped] do
    label = patch_label(status, reason)
    report("#{label}: #{Path.relative_to_cwd(path)}")
    [{status, path, reason}]
  end

  defp report_patch_result({:manual, nil, reason, snippet}) do
    report("manual: #{reason}")
    report(snippet)
    [{:manual, nil, reason}]
  end

  defp report_patch_result({:manual, path, reason, snippet}) do
    report("manual: #{Path.relative_to_cwd(path)} #{reason}")
    report(snippet)
    [{:manual, path, reason}]
  end

  defp report_patch_result({:manual, path, reason, snippet, artifact_path}) do
    report("manual: #{Path.relative_to_cwd(path)} #{reason}")
    report("conflict artifact: #{Path.relative_to_cwd(artifact_path)}")
    report(snippet)
    [{:manual, path, reason}, {:conflict_artifact, artifact_path, reason}]
  end

  defp print_summary(results, opts, project) do
    summary =
      Enum.reduce(results, default_summary(opts, project), fn
        {:changed, _path, "created"}, acc ->
          Map.update!(acc, :created, &(&1 + 1))

        {:changed, _path, "updated pristine"}, acc ->
          Map.update!(acc, :updated_pristine, &(&1 + 1))

        {:skipped, _path, "user-edited"}, acc ->
          Map.update!(acc, :skipped_user_edited, &(&1 + 1))

        {:skipped, _path, "exists"}, acc ->
          Map.update!(acc, :skipped_exists, &(&1 + 1))

        {:manual, _path, _reason}, acc ->
          Map.update!(acc, :manual, &(&1 + 1))

        {:conflict_artifact, _path, _reason}, acc ->
          Map.update!(acc, :conflict_artifact, &(&1 + 1))

        _other, acc ->
          acc
      end)

    report("created: #{summary.created}")
    report("updated pristine: #{summary.updated_pristine}")
    report("skipped user-edited: #{summary.skipped_user_edited}")
    report("skipped exists: #{summary.skipped_exists}")
    report("manual: #{summary.manual}")
    report("conflict artifact: #{summary.conflict_artifact}")
  end

  defp default_summary(opts, project) do
    %{
      created: 0,
      updated_pristine: 0,
      skipped_user_edited: 0,
      skipped_exists: 0,
      manual: if(opts.manual or opts.dry_run or project.manual?, do: 1, else: 0),
      conflict_artifact: 0
    }
  end

  defp template_label(:changed, "created"), do: "created"
  defp template_label(:changed, "updated pristine"), do: "updated pristine"
  defp template_label(:changed, reason), do: "changed (#{reason})"
  defp template_label(:skipped, "user-edited"), do: "skipped user-edited"
  defp template_label(:skipped, "exists"), do: "skipped exists"
  defp template_label(:skipped, reason), do: "skipped (#{reason})"

  defp patch_label(:changed, _reason), do: "created"
  defp patch_label(:skipped, reason) when is_binary(reason), do: "skipped exists"

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
