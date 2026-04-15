defmodule Accrue.Install.Patches do
  @moduledoc """
  Safe host-file patch builders and manual snippets for Accrue installs.

  The router snippet intentionally creates a route-scoped raw-body parser
  pipeline for Accrue webhooks. It never generates a global `Plug.Parsers`
  body reader and never hand-writes raw admin LiveView routes.

      pipeline :accrue_webhook_raw_body do
        plug Plug.Parsers,
          parsers: [:json],
          pass: ["*/*"],
          json_decoder: Jason,
          body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
          length: 1_000_000
      end

      scope "/webhooks" do
        pipe_through :accrue_webhook_raw_body
        accrue_webhook "/stripe", :stripe
      end
  """

  @doc """
  Returns structured patch plans for host router, auth config, test support,
  and Oban wiring.
  """
  @spec build(Accrue.Install.Project.t(), Accrue.Install.Options.t()) :: [map()]
  def build(project, opts) do
    [
      %{
        name: "Patches.router_webhook",
        path: project.router_path,
        snippet: router_snippet(opts),
        apply: &patch_router/3
      },
      %{
        name: "Patches.auth",
        path: project.config_path,
        snippet: auth_snippet(project),
        apply: &patch_auth_config/3
      },
      %{
        name: "Patches.test_support",
        path: Path.join(project.root, "test/support/accrue_case.ex"),
        snippet: test_support_snippet(),
        apply: &patch_test_support/3
      },
      %{
        name: "Patches.oban",
        path: nil,
        snippet: oban_snippet(),
        apply: &manual_only/3
      }
    ] ++ admin_patch(project, opts)
  end

  @doc """
  Exact manual snippets for `--manual`, `--dry-run`, and ambiguous projects.
  """
  def manual_snippets(project, opts) do
    build(project, opts)
    |> Enum.map(fn patch -> {patch.name, patch.snippet} end)
  end

  @doc """
  Applies safe patches and returns changed/skipped/manual result tuples.
  """
  def apply(project, opts) do
    project
    |> build(opts)
    |> Enum.map(fn patch -> patch.apply.(project, opts, patch) end)
  end

  def router_snippet(opts) do
    {scope_path, endpoint_path} = webhook_scope(opts.webhook_path)

    """
      import Accrue.Router

      pipeline :accrue_webhook_raw_body do
        plug Plug.Parsers,
          parsers: [:json],
          pass: ["*/*"],
          json_decoder: Jason,
          body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
          length: 1_000_000
      end

      scope "#{scope_path}" do
        pipe_through :accrue_webhook_raw_body
        accrue_webhook "#{endpoint_path}", :stripe
      end
    """
  end

  def admin_snippet(opts) do
    """
      import AccrueAdmin.Router

      # Protect this mount with AccrueAdmin.AuthHook via accrue_admin/2.
      # Hosts with custom routers may also pipe through Accrue.Auth.require_admin_plug().
      accrue_admin "#{opts.admin_mount}"
    """
  end

  def auth_snippet(%{has_sigra?: true}) do
    """
    config :accrue, :auth_adapter, Accrue.Integrations.Sigra
    """
  end

  def auth_snippet(_project) do
    """
    # prod-safety: Accrue.Auth.Default is dev/test friendly and fails closed in prod.
    # Replace with a host or community auth adapter before production.
    config :accrue, :auth_adapter, Accrue.Auth.Default
    """
  end

  def test_support_snippet do
    """
    defmodule AccrueCase do
      use ExUnit.CaseTemplate

      using do
        quote do
          use Accrue.Test
        end
      end
    end

    # Add to config/test.exs:
    #   config :accrue, :processor, Accrue.Processor.Fake
    #   config :accrue, :mailer, Accrue.Mailer.Test
    #   config :accrue, :pdf_adapter, Accrue.PDF.Test
    """
  end

  def oban_snippet do
    """
    # Add Accrue queues to your host Oban config:
    config :my_app, Oban,
      queues: [
        accrue_webhooks: 10,
        accrue_mailers: 20,
        accrue_pdf: 5
      ]
    """
  end

  defp admin_patch(%{has_accrue_admin?: true} = project, opts) do
    [
      %{
        name: "Patches.admin",
        path: project.router_path,
        snippet: admin_snippet(opts),
        apply: &patch_admin/3
      }
    ]
  end

  defp admin_patch(_project, _opts), do: []

  defp patch_router(_project, _opts, %{path: nil, snippet: snippet}) do
    {:manual, nil, "router missing", snippet}
  end

  defp patch_router(_project, opts, %{path: path, snippet: snippet}) do
    content = File.read!(path)
    {_scope_path, endpoint_path} = webhook_scope(opts.webhook_path)

    cond do
      content =~ ~s(accrue_webhook "#{endpoint_path}", :stripe) ->
        {:skipped, path, "webhook route already configured"}

      true ->
        patched =
          content
          |> ensure_import("Accrue.Router")
          |> insert_before_final_end(snippet)

        File.write!(path, patched)
        {:changed, path, "route-scoped webhook pipeline"}
    end
  end

  defp patch_admin(_project, _opts, %{path: nil, snippet: snippet}) do
    {:manual, nil, "router missing", snippet}
  end

  defp patch_admin(_project, opts, %{path: path, snippet: snippet}) do
    content = File.read!(path)

    cond do
      content =~ ~s(accrue_admin "#{opts.admin_mount}") ->
        {:skipped, path, "admin mount already configured"}

      true ->
        patched =
          content
          |> ensure_import("AccrueAdmin.Router")
          |> insert_before_final_end(snippet)

        File.write!(path, patched)
        {:changed, path, "protected accrue_admin mount"}
    end
  end

  defp patch_auth_config(_project, _opts, %{path: path, snippet: snippet}) do
    content = if File.exists?(path), do: File.read!(path), else: "import Config\n"

    if content =~ "config :accrue, :auth_adapter" do
      {:skipped, path, "auth adapter already configured"}
    else
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content <> "\n" <> snippet)
      {:changed, path, "auth adapter"}
    end
  end

  defp patch_test_support(_project, _opts, %{path: path, snippet: snippet}) do
    cond do
      File.exists?(path) and File.read!(path) =~ "use Accrue.Test" ->
        {:skipped, path, "test support already configured"}

      File.exists?(path) ->
        {:manual, path, "test support exists", snippet}

      true ->
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, snippet)
        {:changed, path, "Accrue test support"}
    end
  end

  defp manual_only(_project, _opts, %{snippet: snippet}) do
    {:manual, nil, "Oban queue wiring", snippet}
  end

  defp ensure_import(content, module) do
    import_line = "  import #{module}\n"

    cond do
      content =~ "import #{module}" ->
        content

      Regex.match?(~r/^\s*use\s+[^,\n]+,\s*:router\s*$/m, content) ->
        Regex.replace(~r/^(\s*use\s+[^,\n]+,\s*:router\s*)$/m, content, "\\1\n#{import_line}",
          global: false
        )

      true ->
        content
    end
  end

  defp insert_before_final_end(content, snippet) do
    replacement = "\n" <> String.trim_trailing(snippet) <> "\nend"
    Regex.replace(~r/\nend\s*$/s, content, replacement, global: false)
  end

  defp webhook_scope(path) do
    normalized = "/" <> (path || "/webhooks/stripe" |> String.trim_leading("/"))
    parts = normalized |> String.trim_leading("/") |> String.split("/", trim: true)

    case parts do
      [] -> {"/webhooks", "/stripe"}
      [only] -> {"/webhooks", "/" <> only}
      _ -> {"/" <> Enum.join(Enum.drop(parts, -1), "/"), "/" <> List.last(parts)}
    end
  end
end
