defmodule Accrue.Live.EntitlementsTest do
  @moduledoc """
  Coverage for the cond-compiled LiveView enforcement surface
  `Accrue.Live.Entitlements` (ENT-07):

    * **cond-compile 4-pattern (source assertion, SC#3)** — the file uses the
      Sigra wrapper (`Code.ensure_loaded?(Phoenix.LiveView)` +
      `@compile {:no_warn_undefined`) and exposes `def on_mount`.
    * **module-always-loaded** — UNLIKE Sigra (which may be `:nofile`),
      `:phoenix_live_view` is a HARD core dep, so the module is ALWAYS defined
      and exports `on_mount/4` (RESEARCH L447 divergence).
    * **on_mount cont/halt** — an entitled billable yields `{:cont, socket}`
      with the billable-only `:accrue_billable` stash (no boolean); an
      unentitled/nil billable yields `{:halt, socket}` with the socket
      redirected (fail-closed, T-124-11).
    * **deny surface-translation (D-21)** — `{:redirect, "/pricing"}` redirects
      to `/pricing`; `:forbidden` redirects to `deny_path` (default `"/"`) and
      sets a GENERIC flash that never names the feature/plan (D-10, T-124-12).

  Mutates `:accrue, :entitlements` (sets the `:plans` catalog and, for the deny
  legs, the global `on_deny`), so `async: false` with an `on_exit` restore —
  mirrors the fail-closed property test scaffolding.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Live.Entitlements, as: LiveGuard
  alias Accrue.Test.Factory
  alias Phoenix.LiveView.Socket

  defmodule TestUser do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  # Two mapped plans (clone of the property/guard test catalog). :enterprise is
  # NOT mapped — the unmapped sentinel. :p1 carries feature :reports.
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

  # A stub socket (A3 — prefer this over a full live mount). The default-probe
  # billable lives under :current_user; :flash + the default :__changed__ /
  # private.live_temp make put_flash/redirect work on the bare struct.
  defp socket_with_billable(billable) do
    %Socket{assigns: %{__changed__: %{}, flash: %{}, current_user: billable}}
  end

  defp put_env(key, value) do
    Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, key, value))
  end

  # --------------------------------------------------------------------------
  # cond-compile 4-pattern (source assertion, SC#3)
  # --------------------------------------------------------------------------
  describe "cond-compile 4-pattern (source assertion)" do
    test "the file uses the Code.ensure_loaded?/@compile/on_mount 4-pattern" do
      source = File.read!("lib/accrue/live/entitlements.ex")

      assert source =~ "Code.ensure_loaded?(Phoenix.LiveView)"
      assert source =~ "@compile {:no_warn_undefined"
      assert source =~ "def on_mount"
    end

    test "the source delegates to Accrue.Entitlements.Guard (no own decision logic)" do
      source = File.read!("lib/accrue/live/entitlements.ex")

      assert source =~ "Accrue.Entitlements.Guard.check"
    end
  end

  # --------------------------------------------------------------------------
  # module-always-loaded (HARD-dep divergence from Sigra)
  # --------------------------------------------------------------------------
  describe "module is always loaded (hard dep)" do
    test "Accrue.Live.Entitlements is defined and exports on_mount/4" do
      assert {:module, Accrue.Live.Entitlements} = Code.ensure_loaded(LiveGuard)
      assert function_exported?(LiveGuard, :on_mount, 4)
    end
  end

  # --------------------------------------------------------------------------
  # on_mount cont (entitled) / halt (unentitled)
  # --------------------------------------------------------------------------
  describe "on_mount allow leg ({:cont, socket})" do
    test "{:require_feature, :reports} with an entitled billable -> {:cont, _}, billable stashed" do
      socket = socket_with_billable(entitled_billable())

      assert {:cont, socket2} = LiveGuard.on_mount({:require_feature, :reports}, %{}, %{}, socket)

      # The billable-only stash is present; the boolean decision is NOT stashed.
      assert Map.has_key?(socket2.assigns, :accrue_billable)
      refute Map.has_key?(socket2.assigns, :accrue_entitled)
      # Allowed mounts are never redirected.
      assert socket2.redirected == nil
    end

    test "{:require_plan, :p1} with an entitled billable -> {:cont, _}" do
      socket = socket_with_billable(entitled_billable())

      assert {:cont, socket2} = LiveGuard.on_mount({:require_plan, :p1}, %{}, %{}, socket)
      assert socket2.redirected == nil
    end
  end

  describe "on_mount deny leg ({:halt, socket})" do
    test "an entitled-but-wrong-feature mount halts and redirects" do
      # Billable is entitled to :reports/:export on :p1 but NOT :api.
      socket = socket_with_billable(entitled_billable())

      assert {:halt, socket2} = LiveGuard.on_mount({:require_feature, :api}, %{}, %{}, socket)
      assert match?({:redirect, %{to: _}}, socket2.redirected)
    end

    test "a nil billable (unentitled) halts and redirects (fail-closed)" do
      socket = socket_with_billable(nil)

      assert {:halt, socket2} = LiveGuard.on_mount({:require_plan, :pro}, %{}, %{}, socket)
      assert match?({:redirect, %{to: _}}, socket2.redirected)
    end
  end

  # --------------------------------------------------------------------------
  # deny surface-translation (D-21) + flash opacity (D-10)
  # --------------------------------------------------------------------------
  describe "deny surface-translation" do
    test "{:redirect, \"/pricing\"} on_deny halts and redirects to /pricing" do
      put_env(:on_deny, {:redirect, "/pricing"})
      socket = socket_with_billable(nil)

      assert {:halt, socket2} = LiveGuard.on_mount({:require_feature, :reports}, %{}, %{}, socket)
      assert {:redirect, %{to: "/pricing"}} = socket2.redirected
    end

    test ":forbidden halts, redirects to deny_path default \"/\", and sets a generic opaque flash" do
      # :forbidden is the built-in default on_deny (no put_env needed).
      socket = socket_with_billable(nil)

      assert {:halt, socket2} = LiveGuard.on_mount({:require_feature, :reports}, %{}, %{}, socket)
      assert {:redirect, %{to: "/"}} = socket2.redirected

      flash = socket2.assigns.flash
      assert Map.has_key?(flash, "error")
      # Opacity (D-10): the flash never names the gated feature/plan.
      refute flash["error"] =~ "reports"
      refute flash["error"] =~ "p1"
    end

    test "a {status, body} global on_deny degrades to the :forbidden flash+redirect path (D-21)" do
      put_env(:on_deny, {403, "nope"})
      socket = socket_with_billable(nil)

      assert {:halt, socket2} = LiveGuard.on_mount({:require_feature, :reports}, %{}, %{}, socket)
      # On a socket the raw {status, body} is meaningless -> degrades to deny_path.
      assert {:redirect, %{to: "/"}} = socket2.redirected
      assert Map.has_key?(socket2.assigns.flash, "error")
    end
  end
end
