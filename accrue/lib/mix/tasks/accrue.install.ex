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
    * `--check`
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
      cond do
        opts.check ->
          run_check(project, opts)

        opts.dry_run or opts.manual or project.manual? ->
          report("manual: review generated snippets before applying")
          print_manual_snippets(project, opts)
          []

        true ->
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

    report("flags: --check --dry-run --yes --non-interactive --manual --force --write-conflicts")

    report("billing_context: #{opts.billing_context}")
    report("webhook_path: #{opts.webhook_path}")
    report("admin_mount: #{opts.admin_mount}")

    if opts.dry_run do
      report("dry-run: no files changed")
    end

    if opts.check do
      report("check: installer preflight mode")
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

  defp run_check(project, opts) do
    findings = preflight_findings(project, opts)

    if findings == [] do
      report("check: passed")
      [{:check_ok, "shared diagnostic preflight passed"}]
    else
      Enum.map(findings, fn diagnostic ->
        report("check failed: #{diagnostic.code}")
        report(Accrue.SetupDiagnostic.format(diagnostic))
        {:diagnostic, diagnostic}
      end)
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
    if opts.check do
      issue_count =
        Enum.count(results, fn
          {:diagnostic, _diagnostic} -> true
          _ -> false
        end)

      passed_count =
        Enum.count(results, fn
          {:check_ok, _reason} -> true
          _ -> false
        end)

      report("check passed: #{passed_count}")
      report("check issues: #{issue_count}")
      report("check status: #{if(issue_count == 0, do: "passed", else: "failed")}")
    else
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

  defp preflight_findings(project, opts) do
    router = read_file(project.router_path)
    config = read_file(project.config_path)
    runtime_config = read_file(project.runtime_config_path)
    webhook_path = opts.webhook_path
    admin_mount = opts.admin_mount

    []
    |> maybe_add(not webhook_route_present?(router, webhook_path), fn ->
      Accrue.SetupDiagnostic.webhook_route_missing(
        details: ~s(expected accrue_webhook "#{webhook_path}", :stripe in #{project.router_path})
      )
    end)
    |> maybe_add(
      webhook_route_present?(router, webhook_path) and not raw_body_reader_present?(router),
      fn ->
        Accrue.SetupDiagnostic.webhook_raw_body(
          details:
            "missing body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []} in router"
        )
      end
    )
    |> maybe_add(
      webhook_route_present?(router, webhook_path) and webhook_pipeline_misused?(router),
      fn ->
        Accrue.SetupDiagnostic.webhook_pipeline(
          details:
            "webhook route appears to share browser/auth pipeline concerns like protect_from_forgery or require_authenticated_user"
        )
      end
    )
    |> maybe_add(
      project.has_accrue_admin? and not admin_mount_present?(router, admin_mount),
      fn ->
        Accrue.SetupDiagnostic.admin_mount_missing(
          details: ~s(expected accrue_admin "#{admin_mount}" in #{project.router_path})
        )
      end
    )
    |> maybe_add(
      project.has_accrue_admin? and default_or_missing_auth_adapter?(config),
      fn ->
        Accrue.SetupDiagnostic.auth_adapter(
          details: "config/config.exs is missing a host auth adapter or still uses Accrue.Auth.Default"
        )
      end
    )
    |> maybe_add(project.has_oban? and not oban_config_present?(config, runtime_config, project), fn ->
      Accrue.SetupDiagnostic.oban_not_configured(
        details:
          "No `config :#{project.app || :my_app}, Oban` or `config :accrue, Oban` block was found"
      )
    end)
  end

  defp maybe_add(findings, true, builder), do: findings ++ [builder.()]
  defp maybe_add(findings, false, _builder), do: findings

  defp read_file(nil), do: ""
  defp read_file(path), do: if(File.exists?(path), do: File.read!(path), else: "")

  defp webhook_route_present?(router, webhook_path) do
    {scope_path, endpoint_path} = webhook_scope(webhook_path)
    escaped_full = Regex.escape(webhook_path)
    escaped_scope = Regex.escape(scope_path)
    escaped_endpoint = Regex.escape(endpoint_path)

    Regex.match?(~r/accrue_webhook(?:\s+|\()\"#{escaped_full}\",\s*:stripe\)?/, router) or
      (Regex.match?(~r/scope\s+\"#{escaped_scope}\"/, router) and
         Regex.match?(~r/accrue_webhook(?:\s+|\()\"#{escaped_endpoint}\",\s*:stripe\)?/, router))
  end

  defp raw_body_reader_present?(router) do
    router =~ "body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}"
  end

  defp webhook_pipeline_misused?(router) do
    router
    |> webhook_route_contexts()
    |> Enum.any?(&webhook_context_misused?/1)
  end

  defp webhook_route_contexts(router) do
    scope_blocks =
      Regex.scan(~r/scope\b.*?\bdo\b.*?\bend\b/s, router, capture: :first)
      |> List.flatten()

    matched_scopes =
      Enum.filter(scope_blocks, fn scope_block ->
        String.contains?(scope_block, "accrue_webhook")
      end)

    case matched_scopes do
      [] ->
        standalone_webhook_contexts(router)

      scopes ->
        Enum.map(scopes, &scope_context/1)
    end
  end

  defp standalone_webhook_contexts(router) do
    router
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, index} ->
      if String.contains?(line, "accrue_webhook") do
        [%{scope: line, pipelines: preceding_pipe_throughs(router, index)}]
      else
        []
      end
    end)
  end

  defp scope_context(scope_block) do
    %{
      scope: scope_block,
      pipelines: Regex.scan(~r/pipe_through(?:\s+|\()(.*?)(?:\)|$)/, scope_block, capture: :all_but_first)
    }
  end

  defp preceding_pipe_throughs(router, index) do
    router
    |> String.split("\n")
    |> Enum.take(index)
    |> Enum.reverse()
    |> Enum.take_while(&(String.trim(&1) == "" or String.contains?(&1, "pipe_through")))
    |> Enum.filter(&String.contains?(&1, "pipe_through"))
    |> Enum.map(fn line ->
      case Regex.run(~r/pipe_through(?:\s+|\()(.*?)(?:\)|$)/, line, capture: :all_but_first) do
        [pipelines] -> pipelines
        _ -> line
      end
    end)
  end

  defp webhook_context_misused?(%{scope: scope, pipelines: pipelines}) do
    pipeline_text = Enum.join(List.flatten(pipelines), "\n")

    not String.contains?(pipeline_text, ":accrue_webhook_raw_body") and
      (pipeline_text =~ ":browser" or
         pipeline_text =~ "require_authenticated_user" or
         pipeline_text =~ "fetch_current_scope_for_user" or
         scope =~ ~r/pipe_through.*:browser/ or
         scope =~ ~r/pipe_through.*require_authenticated_user/ or
         scope =~ ~r/pipe_through.*fetch_current_scope_for_user/ or
         scope =~ "protect_from_forgery")
  end

  defp admin_mount_present?(router, admin_mount) do
    escaped_mount = Regex.escape(admin_mount)
    Regex.match?(~r/accrue_admin(?:\s+|\()\"#{escaped_mount}\"/, router)
  end

  defp default_or_missing_auth_adapter?(config) do
    not String.contains?(config, "config :accrue, :auth_adapter") or
      String.contains?(config, "config :accrue, :auth_adapter, Accrue.Auth.Default")
  end

  defp oban_config_present?(config, runtime_config, project) do
    app = project.app || :my_app
    marker = "config :#{app}, Oban"
    config =~ marker or runtime_config =~ marker or config =~ "config :accrue, Oban" or
      runtime_config =~ "config :accrue, Oban"
  end

  defp webhook_scope(path) do
    normalized = "/" <> String.trim_leading(path || "/webhooks/stripe", "/")
    parts = String.split(String.trim_leading(normalized, "/"), "/", trim: true)

    case parts do
      [] -> {"/webhooks", "/stripe"}
      [only] -> {"/webhooks", "/" <> only}
      _ -> {"/" <> Enum.join(Enum.drop(parts, -1), "/"), "/" <> List.last(parts)}
    end
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
