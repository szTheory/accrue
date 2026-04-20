defmodule AccrueAdmin.StepUpTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.StepUp

  import Ecto.Query

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(session), do: Map.get(session, "current_admin")

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]

    @impl Accrue.Auth
    def step_up_challenge(_user, %{type: "admin.auto"}) do
      %{kind: :auto, message: "Auto-approved"}
    end

    def step_up_challenge(_user, _action) do
      %{kind: :totp, message: "Enter your verification code"}
    end

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, _action), do: :ok
    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  defmodule TestLive do
    use Phoenix.LiveView

    alias AccrueAdmin.Components.StepUpAuthModal
    alias AccrueAdmin.StepUp

    @impl true
    def mount(_params, session, socket) do
      {:ok,
       socket
       |> Phoenix.Component.assign(:current_admin, session["current_admin"])
       |> Phoenix.Component.assign(:action_type, session["action_type"])
       |> Phoenix.Component.assign(:source_event_id, session["source_event_id"])
       |> Phoenix.Component.assign(:source_webhook_event_id, session["source_webhook_event_id"])
       |> Phoenix.Component.assign(:step_up_pending, false)
       |> Phoenix.Component.assign(:step_up_challenge, nil)
       |> Phoenix.Component.assign(:step_up_error, nil)
       |> Phoenix.Component.assign(:step_up_verified_at, nil)
       |> Phoenix.Component.assign(:executed, 0)}
    end

    @impl true
    def handle_event("danger", _params, socket) do
      action = %{
        type: socket.assigns.action_type,
        subject_type: "Refund",
        subject_id: "re_123",
        caused_by_event_id: socket.assigns.source_event_id,
        caused_by_webhook_event_id: socket.assigns.source_webhook_event_id
      }

      continuation = fn updated_socket ->
        Phoenix.Component.assign(updated_socket, :executed, updated_socket.assigns.executed + 1)
      end

      case StepUp.require_fresh(socket, action, continuation) do
        {:ok, socket} ->
          {:noreply, socket}

        {:challenge, socket} ->
          {:noreply, socket}

        {:error, reason, socket} ->
          {:noreply, Phoenix.Component.assign(socket, :step_up_error, inspect(reason))}
      end
    end

    def handle_event("step_up_submit", params, socket) do
      case StepUp.verify(socket, params) do
        {:ok, socket} -> {:noreply, socket}
        {:error, _reason, socket} -> {:noreply, socket}
      end
    end

    def handle_event("step_up_dismiss", _params, socket) do
      {:noreply, StepUp.dismiss_challenge(socket)}
    end

    def handle_event("step_up_escape", _params, socket) do
      {:noreply, StepUp.dismiss_challenge(socket)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <button phx-click="danger">Do dangerous thing</button>
        <p data-role="executed"><%= @executed %></p>
        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />
      </div>
      """
    end
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    {:ok, source_event} =
      Accrue.Events.record(%{
        type: "invoice.finalized",
        subject_type: "Invoice",
        subject_id: "in_123",
        actor_type: "system"
      })

    webhook =
      WebhookEvent.ingest_changeset(%{
        processor: "stripe",
        processor_event_id: "evt_step_up",
        type: "invoice.finalized",
        data: %{"id" => "evt_step_up"}
      })
      |> AccrueAdmin.TestRepo.insert!()

    {:ok, source_event: source_event, webhook: webhook}
  end

  test "auto challenges approve immediately and write audit linkage", %{
    conn: conn,
    source_event: source_event,
    webhook: webhook
  } do
    {:ok, view, _html} =
      live_isolated(conn, TestLive,
        session: %{
          "current_admin" => %{id: "admin_1", role: :admin},
          "action_type" => "admin.auto",
          "source_event_id" => source_event.id,
          "source_webhook_event_id" => webhook.id
        }
      )

    html = render_click(element(view, "button"))
    assert html =~ ~s(data-role="executed">1<)

    event =
      AccrueAdmin.TestRepo.get_by!(Event,
        type: "admin.step_up.ok",
        caused_by_event_id: source_event.id
      )

    assert event.caused_by_webhook_event_id == webhook.id
  end

  test "challenge flow verifies and grants a grace window", %{
    conn: conn,
    source_event: source_event,
    webhook: webhook
  } do
    {:ok, view, _html} =
      live_isolated(conn, TestLive,
        session: %{
          "current_admin" => %{id: "admin_1", role: :admin},
          "action_type" => "refund.issue",
          "source_event_id" => source_event.id,
          "source_webhook_event_id" => webhook.id
        }
      )

    assert render_click(element(view, "button")) =~ "Step-up required"

    assert render_submit(element(view, "form"), %{"code" => "123456"}) =~
             ~s(data-role="executed">1<)

    assert render_click(element(view, "button")) =~ ~s(data-role="executed">2<)

    events =
      AccrueAdmin.TestRepo.all(
        from(e in Event,
          where: e.type == "admin.step_up.ok" and e.caused_by_event_id == ^source_event.id
        )
      )

    assert length(events) == 1
  end

  test "challenge failures keep the modal open and write denied audit", %{
    conn: conn,
    source_event: source_event,
    webhook: webhook
  } do
    {:ok, view, _html} =
      live_isolated(conn, TestLive,
        session: %{
          "current_admin" => %{id: "admin_1", role: :admin},
          "action_type" => "refund.issue",
          "source_event_id" => source_event.id,
          "source_webhook_event_id" => webhook.id
        }
      )

    assert render_click(element(view, "button")) =~ "Step-up required"
    html = render_submit(element(view, "form"), %{"code" => "000000"})

    assert html =~ "invalid_code"
    assert html =~ "Step-up required"

    denied =
      AccrueAdmin.TestRepo.get_by!(Event,
        type: "admin.step_up.denied",
        caused_by_event_id: source_event.id
      )

    assert denied.caused_by_webhook_event_id == webhook.id
  end

  test "dismiss_challenge clears pending step-up without running continuation", %{
    conn: conn,
    source_event: source_event,
    webhook: webhook
  } do
    {:ok, view, _html} =
      live_isolated(conn, TestLive,
        session: %{
          "current_admin" => %{id: "admin_1", role: :admin},
          "action_type" => "refund.issue",
          "source_event_id" => source_event.id,
          "source_webhook_event_id" => webhook.id
        }
      )

    assert render_click(element(view, "button")) =~ "Step-up required"
    assert render_click(element(view, "button[phx-click='step_up_dismiss']")) =~
             ~s(data-role="executed">0<)

    refute render(view) =~ "Step-up required"
  end
end
