defmodule Accrue.Entitlements.GuardTelemetryTest do
  @moduledoc """
  Proves the `surface: :plug | :live` dimension that
  `Accrue.Entitlements.Guard.check/3` threads onto the gate call provably
  reaches the inherited Phase 123 `[:accrue, :entitlements, :check]` span for
  BOTH enforcement surfaces (D-18) — no new guard event, one span.

  The Guard reads only `container.assigns`, so the `:live` leg passes a bare
  `%{assigns: %{...}}` map as the container (a full LiveView socket would be
  heavy and unnecessary — documented here so the lightweight container choice
  is explicit). The `:plug` leg passes a real `%Plug.Conn{}` via `Plug.Test`.

  Mutates `:accrue, :entitlements` (sets the `:plans` catalog), so
  `async: false` with an `on_exit` restore.
  """

  use Accrue.BillingCase, async: false

  import Plug.Test

  alias Accrue.Entitlements.Guard
  alias Accrue.Test.Factory

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  @plans [
    p1: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_p1"]]
  ]

  @entitlements [plans: @plans, unmapped_action: :deny]

  setup do
    prev = Application.get_env(:accrue, :entitlements)
    Application.put_env(:accrue, :entitlements, @entitlements)

    test_pid = self()
    ref = make_ref()
    handler_id = {__MODULE__, ref}

    :telemetry.attach(
      handler_id,
      [:accrue, :entitlements, :check, :stop],
      fn name, measurements, metadata, _ ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)

      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    :ok
  end

  defp billable_for(owner_id), do: %TestUser{id: owner_id}

  defp entitled_billable do
    oid = Ecto.UUID.generate()
    Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})
    billable_for(oid)
  end

  test "Guard.check(:plug, conn, ...) lands surface: :plug on the :check span" do
    b = entitled_billable()
    conn = conn(:get, "/")

    assert {:allow, _conn} =
             Guard.check(:plug, conn, feature: :reports, billable: fn _ -> b end)

    assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, meta}
    assert meta.surface == :plug
  end

  test "Guard.check(:live, %{assigns: ...}, ...) lands surface: :live on the :check span" do
    b = entitled_billable()
    # Lightweight live container: the Guard reads only container.assigns, so a
    # bare map stands in for a full LiveView socket.
    container = %{assigns: %{}}

    assert {:allow, _container} =
             Guard.check(:live, container, feature: :reports, billable: fn _ -> b end)

    assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, meta}
    assert meta.surface == :live
  end

  test "a denied check still carries the surface dimension (:live)" do
    container = %{assigns: %{}}

    assert {:deny, _form, _ctx} =
             Guard.check(:live, container, feature: :reports, billable: fn _ -> nil end)

    assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, meta}
    assert meta.surface == :live
  end
end
