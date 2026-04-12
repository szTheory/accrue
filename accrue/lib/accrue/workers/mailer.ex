defmodule Accrue.Workers.Mailer do
  @moduledoc """
  Oban worker that delivers a transactional email asynchronously.

  ## Flow

  1. `Accrue.Mailer.Default.deliver/2` enqueues a job with string-keyed
     `%{"type" => "...", "assigns" => %{...}}` args (Oban-safe scalars only).
  2. `perform/1` rehydrates the assigns (Phase 1: pass-through; Phase 2+
     loads Customer/Invoice from the DB by id), resolves the template
     module (honoring `:email_overrides`), builds a `%Swoosh.Email{}`, and
     delivers via `Accrue.Mailer.Swoosh`.

  ## Queue

  Host applications MUST configure an Oban queue named `:accrue_mailers`.
  Recommended concurrency: 20.
  """

  use Oban.Worker, queue: :accrue_mailers, max_attempts: 5, unique: [period: 60, fields: [:args, :worker]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type_str, "assigns" => assigns}}) do
    type = String.to_existing_atom(type_str)
    template_mod = resolve_template(type)
    enriched = enrich(type, assigns)
    # Phoenix.HTML.Engine (used by mjml_eex) fetches atom keys out of the
    # assigns, so we atomize before handing to the template module. Keys
    # came from Oban JSON round-trip as strings — we only atomize keys
    # that already exist as atoms in the VM (the template fields) to keep
    # this safe against untrusted input.
    atomized = atomize_known_keys(enriched)

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(atomized[:to] || enriched["to"])
      |> Swoosh.Email.from(
        {Application.get_env(:accrue, :from_name, "Accrue"),
         Application.get_env(:accrue, :from_email, "noreply@example.com")}
      )
      |> Swoosh.Email.subject(template_mod.subject(atomized))
      |> Swoosh.Email.html_body(template_mod.render(atomized))
      |> Swoosh.Email.text_body(template_mod.render_text(atomized))

    case Accrue.Mailer.Swoosh.deliver(email) do
      {:ok, _} = ok -> ok
      {:error, _} = err -> err
    end
  end

  @doc """
  Resolves the template module for an email type. Honors `:email_overrides`
  (D-23 rung 3) so hosts can swap one template module without replacing the
  entire mailer pipeline.
  """
  @spec resolve_template(atom()) :: module()
  def resolve_template(type) when is_atom(type) do
    overrides = Application.get_env(:accrue, :email_overrides, [])

    case Keyword.fetch(overrides, type) do
      {:ok, mod} when is_atom(mod) -> mod
      :error -> default_template(type)
    end
  end

  defp default_template(:payment_succeeded), do: Accrue.Emails.PaymentSucceeded

  defp default_template(type) do
    raise ArgumentError,
          "no default template for email type #{inspect(type)}; Phase 6 ships the full catalog. " <>
            "Set config :accrue, :email_overrides, [#{type}: YourModule]."
  end

  # Phase 1: pass-through. Phase 2+ rehydrates Customer/Invoice from the DB
  # by id so the worker always operates on the latest DB state.
  defp enrich(_type, assigns) when is_map(assigns), do: assigns

  # Converts string keys to atoms ONLY when the atom already exists in the
  # VM (via `String.to_existing_atom/1`). Unknown strings are dropped from
  # the atom-keyed view but preserved in the original map — safe against
  # atom-table exhaustion for untrusted input.
  defp atomize_known_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {k, v}, acc when is_atom(k) ->
        Map.put(acc, k, v)

      {k, v}, acc when is_binary(k) ->
        try do
          Map.put(acc, String.to_existing_atom(k), v)
        rescue
          ArgumentError -> acc
        end
    end)
  end
end
