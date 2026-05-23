defmodule Accrue.Entitlements.GuardTest do
  @moduledoc """
  Unit coverage for the shared `Accrue.Entitlements.Guard` decision engine:

    * billable-resolution precedence (per-guard opt → config global → default
      `current_scope.user`/`current_user` probe),
    * resolve-once (the billable fn runs exactly once per conn; the stash holds
      the billable TERM only — never the boolean decision, D-17 / Pitfall 3),
    * fail-closed legs (nil billable / raising `billable:` fn / unmapped
      billable all deny, `ctx.surface == :plug`),
    * opaque content-negotiated plug deny (D-10).

  Mutates `:accrue, :entitlements` (it sets the `:plans` catalog + global
  `billable`), so `async: false` with an `on_exit` restore — mirrors the
  fail-closed property test scaffolding.
  """

  use Accrue.BillingCase, async: false

  import Plug.Test
  import Plug.Conn, only: [put_req_header: 3, get_resp_header: 2]

  alias Accrue.Entitlements.Guard
  alias Accrue.Test.Factory

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  # Two mapped plans (clone of the property test catalog). :enterprise is NOT
  # mapped — the unmapped-billable sentinel for the fail-closed legs.
  @plans [
    p1: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_p1"]],
    p2: [features: [:export, :api], limits: [api_calls: 100], price_ids: ["price_p2"]]
  ]

  @entitlements [plans: @plans, unmapped_action: :deny]

  setup do
    prev = Application.get_env(:accrue, :entitlements)
    Application.put_env(:accrue, :entitlements, @entitlements)

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    :ok
  end

  defp billable_for(owner_id), do: %TestUser{id: owner_id}

  # An entitled billable: a real customer + active sub on the mapped :p1 plan
  # whose feature set contains :reports.
  defp entitled_billable do
    oid = Ecto.UUID.generate()
    Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})
    billable_for(oid)
  end

  defp put_env(key, value) do
    Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, key, value))
  end

  # --------------------------------------------------------------------------
  # billable-resolution precedence
  # --------------------------------------------------------------------------
  describe "billable resolution precedence" do
    test "per-guard :billable opt resolves the expected billable (allow)" do
      b = entitled_billable()
      conn = conn(:get, "/")

      assert {:allow, _conn} =
               Guard.check(:plug, conn, feature: :reports, billable: fn _ -> b end)
    end

    test "per-guard :billable opt WINS over the config global" do
      good = entitled_billable()
      # Config global resolves a no-data billable (would deny); the per-guard
      # opt must take precedence and allow.
      put_env(:billable, fn _ -> billable_for(Ecto.UUID.generate()) end)
      conn = conn(:get, "/")

      assert {:allow, _conn} =
               Guard.check(:plug, conn, feature: :reports, billable: fn _ -> good end)
    end

    test "config global :billable WINS over the default probe" do
      good = entitled_billable()
      put_env(:billable, fn _ -> good end)
      # The default probe would find a no-data current_user, but the config
      # global resolves the entitled billable.
      conn = %{conn(:get, "/") | assigns: %{current_user: billable_for(Ecto.UUID.generate())}}

      assert {:allow, _conn} = Guard.check(:plug, conn, feature: :reports)
    end

    test "default probe uses current_scope.user first" do
      b = entitled_billable()
      conn = %{conn(:get, "/") | assigns: %{current_scope: %{user: b}}}

      assert {:allow, _conn} = Guard.check(:plug, conn, feature: :reports)
    end

    test "default probe falls back to current_user when current_scope is absent" do
      b = entitled_billable()
      conn = %{conn(:get, "/") | assigns: %{current_user: b}}

      assert {:allow, _conn} = Guard.check(:plug, conn, feature: :reports)
    end
  end

  # --------------------------------------------------------------------------
  # resolve-once (billable-only stash, D-17 / Pitfall 3)
  # --------------------------------------------------------------------------
  describe "resolve-once" do
    test "the :billable fn runs exactly once across two checks on the same conn" do
      b = entitled_billable()
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      counting_fn = fn _container ->
        Agent.update(agent, &(&1 + 1))
        b
      end

      conn = conn(:get, "/")

      assert {:allow, conn} = Guard.check(:plug, conn, feature: :reports, billable: counting_fn)
      # A SECOND check on the same conn reads the stash, does not re-run the fn.
      assert {:allow, conn} = Guard.check(:plug, conn, feature: :export, billable: counting_fn)

      assert Agent.get(agent, & &1) == 1

      # The stash holds the billable TERM, never the boolean decision.
      assert Map.has_key?(conn.assigns, :accrue_billable)
      assert conn.assigns[:accrue_billable] == b
      refute Map.has_key?(conn.assigns, :accrue_entitled)
    end
  end

  # --------------------------------------------------------------------------
  # fail-closed legs
  # --------------------------------------------------------------------------
  describe "fail-closed legs" do
    test "nil billable denies, ctx.surface == :plug" do
      conn = conn(:get, "/")

      assert {:deny, _form, ctx} =
               Guard.check(:plug, conn, feature: :reports, billable: fn _ -> nil end)

      assert ctx.surface == :plug
      assert ctx.guard == :feature
      assert ctx.required == :reports
    end

    test "a raising :billable fn denies (fail-closed), ctx.surface == :plug" do
      conn = conn(:get, "/")

      assert {:deny, _form, ctx} =
               Guard.check(:plug, conn, feature: :reports, billable: fn _ -> raise "boom" end)

      assert ctx.surface == :plug
    end

    test "an unmapped (no-data) billable denies, ctx.surface == :plug" do
      conn = conn(:get, "/")
      no_data = billable_for(Ecto.UUID.generate())

      assert {:deny, _form, ctx} =
               Guard.check(:plug, conn, feature: :reports, billable: fn _ -> no_data end)

      assert ctx.surface == :plug
    end
  end

  # --------------------------------------------------------------------------
  # deny_plug content negotiation (opacity, D-10)
  # --------------------------------------------------------------------------
  describe "deny_plug/4 content negotiation" do
    test "JSON accept header yields an opaque 403 JSON body, halted" do
      conn =
        conn(:get, "/")
        |> put_req_header("accept", "application/json")

      {:deny, form, ctx} =
        Guard.check(:plug, conn, feature: :reports, billable: fn _ -> nil end)

      conn = Guard.deny_plug(conn, form, ctx)

      assert conn.status == 403
      assert conn.halted == true
      assert conn.resp_body == ~s({"error":"forbidden"})
      # Opacity: the gated feature name is NEVER in the wire body.
      refute conn.resp_body =~ "reports"
    end

    test "no JSON accept header yields plain-text Forbidden, halted" do
      conn = conn(:get, "/")

      {:deny, form, ctx} =
        Guard.check(:plug, conn, feature: :reports, billable: fn _ -> nil end)

      conn = Guard.deny_plug(conn, form, ctx)

      assert conn.status == 403
      assert conn.halted == true
      assert conn.resp_body == "Forbidden"
      refute conn.resp_body =~ "reports"
    end

    test ":status opt overrides the default 403" do
      conn =
        conn(:get, "/")
        |> put_req_header("accept", "application/json")

      {:deny, form, ctx} =
        Guard.check(:plug, conn, feature: :reports, billable: fn _ -> nil end)

      conn = Guard.deny_plug(conn, form, ctx, status: 402)

      assert conn.status == 402
      assert conn.resp_body == ~s({"error":"forbidden"})
    end

    test "{:redirect, path} deny form (per-guard on_deny) sends a 302 with a location header, halted" do
      conn = conn(:get, "/")

      # The per-guard on_deny override resolves the {:redirect, _} deny form.
      assert {:deny, {:redirect, "/p"}, ctx} =
               Guard.check(:plug, conn,
                 feature: :reports,
                 billable: fn _ -> nil end,
                 on_deny: {:redirect, "/p"}
               )

      conn = Guard.deny_plug(conn, {:redirect, "/p"}, ctx)

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/p"]
      assert conn.halted == true
    end
  end
end
