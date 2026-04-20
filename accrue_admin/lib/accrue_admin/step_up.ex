defmodule AccrueAdmin.StepUp do
  @moduledoc """
  Shared admin step-up workflow for destructive LiveView actions.

  The service keeps a per-LiveView grace window in assigns, delegates the
  actual challenge/verification work to `Accrue.Auth`, and records
  `admin.step_up.*` audit rows through the core event ledger.

  Escape and explicit cancel dismissals (`dismiss_challenge/1`) clear a pending
  challenge without running the deferred continuation and **without** emitting
  new `Events.record/1` rows — only successful or denied verification outcomes
  are audited.
  """

  import Phoenix.Component, only: [assign: 3]

  alias Accrue.{Auth, Events}

  @default_grace_seconds 300

  @type continuation :: (Phoenix.LiveView.Socket.t() -> Phoenix.LiveView.Socket.t())

  @spec require_fresh(Phoenix.LiveView.Socket.t(), map(), continuation(), keyword()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
          | {:challenge, Phoenix.LiveView.Socket.t()}
          | {:error, term(), Phoenix.LiveView.Socket.t()}
  def require_fresh(socket, action, continuation, opts \\ [])
      when is_map(action) and is_function(continuation, 1) and is_list(opts) do
    user = socket.assigns[:current_admin]

    cond do
      is_nil(user) ->
        {:error, :missing_current_admin, socket}

      fresh?(socket, opts) ->
        {:ok, continuation.(socket)}

      true ->
        challenge = Auth.step_up_challenge(user, action)

        case challenge do
          %{kind: :auto} = challenge ->
            with {:ok, socket} <- record_result(socket, user, :ok, action, challenge, opts) do
              {:ok, continuation.(socket)}
            end

          challenge when is_map(challenge) ->
            {:challenge,
             socket
             |> assign(:step_up_pending, true)
             |> assign(:step_up_action, action)
             |> assign(:step_up_challenge, challenge)
             |> assign(:step_up_error, nil)
             |> assign(:step_up_continuation, continuation)}
        end
    end
  rescue
    err in Accrue.Auth.StepUpUnconfigured ->
      {:error, err, socket}
  end

  @spec verify(Phoenix.LiveView.Socket.t(), map(), keyword()) ::
          {:ok, Phoenix.LiveView.Socket.t()} | {:error, term(), Phoenix.LiveView.Socket.t()}
  def verify(socket, params, opts \\ []) when is_map(params) and is_list(opts) do
    user = socket.assigns[:current_admin]
    action = socket.assigns[:step_up_action] || %{}
    challenge = socket.assigns[:step_up_challenge] || %{}
    continuation = socket.assigns[:step_up_continuation] || (& &1)

    case Auth.verify_step_up(user, params, action) do
      :ok ->
        with {:ok, socket} <- record_result(socket, user, :ok, action, challenge, opts) do
          {:ok, continuation.(socket)}
        end

      {:error, reason} ->
        _ = record_result(socket, user, :denied, action, challenge, opts)

        {:error, reason,
         socket
         |> assign(:step_up_error, humanize_error(reason))
         |> assign(:step_up_pending, true)}
    end
  end

  @doc """
  Clears a pending step-up without invoking the stored continuation and without
  writing audit events. Used for operator cancel / Escape flows.
  """
  @spec dismiss_challenge(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def dismiss_challenge(socket) do
    if socket.assigns[:step_up_pending] do
      clear_pending(socket)
    else
      socket
    end
  end

  @spec fresh?(Phoenix.LiveView.Socket.t(), keyword()) :: boolean()
  def fresh?(socket, opts \\ []) do
    grace_seconds = Keyword.get(opts, :grace_seconds, grace_seconds())

    case socket.assigns[:step_up_verified_at] do
      verified_at when is_integer(verified_at) ->
        System.system_time(:second) - verified_at < grace_seconds

      _ ->
        false
    end
  end

  defp record_result(socket, user, outcome, action, challenge, _opts) do
    event_type = "admin.step_up.#{outcome}"

    with {:ok, _event} <-
           Events.record(%{
             type: event_type,
             subject_type: "AdminUser",
             subject_id: Auth.actor_id(user) || "unknown",
             actor_type: "admin",
             actor_id: Auth.actor_id(user),
             caused_by_event_id: Map.get(action, :caused_by_event_id),
             caused_by_webhook_event_id: Map.get(action, :caused_by_webhook_event_id),
             data: audit_data(action, challenge)
           }) do
      :ok =
        Auth.log_audit(user, %{
          type: event_type,
          action: Map.get(action, :type),
          source: :accrue_admin
        })

      socket =
        case outcome do
          :ok -> assign(socket, :step_up_verified_at, System.system_time(:second))
          _ -> socket
        end

      {:ok, clear_pending(socket)}
    end
  end

  defp clear_pending(socket) do
    socket
    |> assign(:step_up_pending, false)
    |> assign(:step_up_action, nil)
    |> assign(:step_up_challenge, nil)
    |> assign(:step_up_error, nil)
    |> assign(:step_up_continuation, nil)
  end

  defp audit_data(action, challenge) do
    %{
      "action_type" => Map.get(action, :type),
      "subject_type" => Map.get(action, :subject_type),
      "subject_id" => Map.get(action, :subject_id),
      "challenge_kind" => challenge_kind(challenge)
    }
  end

  defp challenge_kind(%{kind: kind}) when is_atom(kind), do: Atom.to_string(kind)
  defp challenge_kind(%{"kind" => kind}) when is_binary(kind), do: kind
  defp challenge_kind(_), do: "unknown"

  defp humanize_error(reason) when is_binary(reason), do: reason
  defp humanize_error(reason), do: "Step-up verification failed: #{inspect(reason)}"

  defp grace_seconds do
    Application.get_env(:accrue_admin, :step_up_grace_seconds, @default_grace_seconds)
  end
end
