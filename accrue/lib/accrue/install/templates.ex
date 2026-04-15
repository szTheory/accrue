defmodule Accrue.Install.Templates do
  @moduledoc """
  Renders host-owned installer templates.
  """

  require EEx

  @template_root Path.expand("../../../priv/accrue/templates/install", __DIR__)
  @migration_root Path.expand("../../../priv/repo/migrations", __DIR__)

  @doc """
  Renders all generated files for the discovered host project.
  """
  @spec render_all(Accrue.Install.Project.t(), Accrue.Install.Options.t()) :: [
          {Path.t(), String.t()}
        ]
  def render_all(project, opts) do
    assigns = assigns(project, opts)

    [
      {context_path(project.root, opts.billing_context), render("billing.ex.eex", assigns)},
      {context_path(project.root, "#{opts.billing_context}Handler"),
       render("billing_handler.ex.eex", assigns)},
      {project.runtime_config_path, render("runtime_config.exs.eex", assigns)}
    ] ++ migration_templates(project, assigns)
  end

  @doc """
  Runtime config snippet for manual installs.
  """
  def runtime_config_snippet(project, opts),
    do: render("runtime_config.exs.eex", assigns(project, opts))

  @doc """
  Config docs generated from the Accrue NimbleOptions schema.
  """
  def config_docs do
    NimbleOptions.docs(Accrue.Config.schema())
  end

  @doc """
  Validates planned installer config against `Accrue.Config`.
  """
  def validate_planned_config!(project) do
    Accrue.Config.validate!(
      repo: project.repo || Module.concat([project.app_module, Repo]),
      processor: Accrue.Processor.Stripe,
      auth_adapter: auth_adapter(project),
      stripe_secret_key: "sk_test_install_validation",
      branding: [
        from_email: "billing@example.com",
        support_email: "support@example.com"
      ]
    )
  end

  @doc """
  Returns a redacted Stripe test-mode readiness report.
  """
  def stripe_test_mode_readiness(env \\ System.get_env()) do
    secret = Map.get(env, "STRIPE_SECRET_KEY")
    webhook_secret = Map.get(env, "STRIPE_WEBHOOK_SECRET")

    status =
      cond do
        is_nil(secret) or secret == "" -> "missing STRIPE_SECRET_KEY"
        String.starts_with?(secret, "sk_test_") -> "ready for Stripe test-mode with sk_test_ key"
        String.starts_with?(secret, "sk_live_") -> "live key detected; use sk_test_ for test-mode"
        true -> "invalid STRIPE_SECRET_KEY prefix for Stripe test-mode"
      end

    webhook_status =
      if is_binary(webhook_secret) and webhook_secret != "" do
        "STRIPE_WEBHOOK_SECRET configured (optional)"
      else
        "STRIPE_WEBHOOK_SECRET missing (optional)"
      end

    Accrue.Install.Fingerprints.redact("""
    Stripe test-mode readiness:
      STRIPE_SECRET_KEY: #{status} value=#{secret}
      STRIPE_WEBHOOK_SECRET: #{webhook_status} value=#{webhook_secret}
    """)
  end

  defp render(name, assigns) do
    @template_root
    |> Path.join(name)
    |> EEx.eval_file(assigns: assigns)
  end

  defp assigns(project, opts) do
    [
      app_module: project.app_module,
      repo: project.repo || Module.concat([project.app_module, Repo]),
      billing_context: opts.billing_context,
      billing_handler: "#{opts.billing_context}Handler",
      webhook_path: opts.webhook_path,
      admin_mount: opts.admin_mount,
      billable: project.billable || opts.billable || "#{project.app_module}.Accounts.User",
      auth_adapter: auth_adapter(project)
    ]
  end

  defp auth_adapter(%{has_sigra?: true}), do: Accrue.Integrations.Sigra
  defp auth_adapter(_project), do: Accrue.Auth.Default

  defp context_path(root, module) do
    filename =
      module
      |> module_parts()
      |> Enum.map(&Macro.underscore/1)
      |> Path.join()

    Path.join([root, "lib", "#{filename}.ex"])
  end

  defp module_parts(module) when is_atom(module), do: Module.split(module)
  defp module_parts(module) when is_binary(module), do: String.split(module, ".")

  defp migration_templates(project, assigns) do
    File.mkdir_p!(project.migrations_path)

    copied =
      @migration_root
      |> Path.join("*.exs")
      |> Path.wildcard()
      |> Enum.map(fn path ->
        {Path.join(project.migrations_path, Path.basename(path)), File.read!(path)}
      end)

    copied ++
      [
        {Path.join(project.migrations_path, "99999999999999_revoke_accrue_events_writes.exs"),
         render("revoke_accrue_events_writes.exs.eex", assigns)}
      ]
  end
end
