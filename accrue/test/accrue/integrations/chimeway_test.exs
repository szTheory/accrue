defmodule Accrue.Integrations.ChimewayTest do
  @moduledoc """
  Phase 131 Plan 01 Task 2: Verify the Chimeway conditional-compile scaffold (DUN-03, D-04).

  Contract:
    * When :chimeway is NOT loaded, Accrue.Integrations.Chimeway is NEVER
      defined — Code.ensure_loaded/1 returns {:error, :nofile}.
    * When :chimeway IS loaded, the module is defined and implements
      Accrue.Dunning.Engine with both callbacks exported.
    * In BOTH matrices, mix compile --warnings-as-errors passes.

  This test accepts either outcome — the sanity check is that asking for the
  module does not raise, and when it IS loaded the behaviour surface is correct.

  Test 2 ("source uses the 4-pattern conditional compile") is RED until
  lib/accrue/integrations/chimeway.ex exists (Plan 04).
  """

  use ExUnit.Case, async: false

  describe "conditional compile" do
    test "Accrue.Integrations.Chimeway is either loaded OR :nofile — never a crash" do
      case Code.ensure_loaded(Accrue.Integrations.Chimeway) do
        {:module, Accrue.Integrations.Chimeway} ->
          # Chimeway-present matrix — assert behaviour surface
          assert function_exported?(Accrue.Integrations.Chimeway, :start_campaign, 3)
          assert function_exported?(Accrue.Integrations.Chimeway, :cancel_campaign, 3)

          behaviours =
            Accrue.Integrations.Chimeway.module_info(:attributes)
            |> Keyword.get_values(:behaviour)
            |> List.flatten()

          assert Accrue.Dunning.Engine in behaviours

        {:error, :nofile} ->
          # Chimeway-absent matrix (the current default) — module must not
          # exist, and merely asking for it must not raise.
          refute Code.ensure_loaded?(Chimeway)
      end
    end

    test "source file exists and uses the 4-pattern conditional compile" do
      source = File.read!("lib/accrue/integrations/chimeway.ex")

      # Pattern 1 — Code.ensure_loaded? gate around the defmodule.
      assert source =~ "Code.ensure_loaded?(Chimeway)"

      # Pattern 2 — @compile {:no_warn_undefined, ...} inside the defmodule
      # so warnings-as-errors passes when Chimeway.* references resolve at
      # runtime instead of compile time.
      assert source =~ "@compile {:no_warn_undefined"

      # Pattern 3 — behaviour declaration.
      assert source =~ "@behaviour Accrue.Dunning.Engine"
    end
  end

  describe "cancel_campaign/3 Outcome Signal (ECOS-06)" do
    @describetag :requires_chimeway
    setup tags do
      case Code.ensure_loaded(Accrue.Integrations.Chimeway) do
        {:module, _} ->
          Accrue.ChimewayTestSupport.ensure_repo_started!()

          accrue_owner =
            Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])

          chimeway_owner =
            Ecto.Adapters.SQL.Sandbox.start_owner!(Chimeway.Repo, shared: not tags[:async])

          prev_dunning = Application.get_env(:accrue, :dunning)

          Application.put_env(:accrue, :dunning,
            engine: Accrue.Integrations.Chimeway,
            campaign: [enabled: true]
          )

          on_exit(fn ->
            # Restore the :dunning config — leaving engine: Chimeway / a stepless
            # enabled campaign in the global app env pollutes later tests
            # (ApplicationTest boot validation, DunningExhaustion/Keying ownership).
            if prev_dunning do
              Application.put_env(:accrue, :dunning, prev_dunning)
            else
              Application.delete_env(:accrue, :dunning)
            end

            Ecto.Adapters.SQL.Sandbox.stop_owner(chimeway_owner)
            Ecto.Adapters.SQL.Sandbox.stop_owner(accrue_owner)
          end)

          customer =
            %Accrue.Billing.Customer{}
            |> Accrue.Billing.Customer.changeset(%{
              owner_type: "User",
              owner_id: Ecto.UUID.generate(),
              processor: "fake",
              processor_id:
                "cus_chimeway_" <> Integer.to_string(System.unique_integer([:positive])),
              email: "cancel-signal@example.com",
              name: "Cancel Signal Customer"
            })
            |> Accrue.TestRepo.insert!()

          subscription =
            %Accrue.Billing.Subscription{customer_id: customer.id, processor: "fake"}
            |> Accrue.Billing.Subscription.force_status_changeset(%{
              processor_id:
                "sub_chimeway_" <> Integer.to_string(System.unique_integer([:positive])),
              status: :past_due,
              past_due_since: DateTime.utc_now() |> DateTime.truncate(:second)
            })
            |> Accrue.TestRepo.insert!()

          %{customer: customer, subscription: subscription}

        {:error, :nofile} ->
          :ok
      end
    end

    @tag :requires_chimeway
    test "uses one capability-matched identity for trigger and invoice.paid recovery", %{
      customer: customer,
      subscription: subscription
    } do
      anchor = DateTime.utc_now()
      iso_anchor = DateTime.to_iso8601(anchor)
      atom_params = %{subscription_id: subscription.id}
      string_params = %{"subscription_id" => subscription.id}

      assert {:ok, [atom_recipient]} =
               Accrue.Integrations.Chimeway.DunningNotifier.recipients(atom_params)

      assert {:ok, [string_recipient]} =
               Accrue.Integrations.Chimeway.DunningNotifier.recipients(string_params)

      privacy_safe? = Accrue.Integrations.Chimeway.privacy_safe_recipient_refs?()

      if privacy_safe? do
        assert atom_recipient.recipient_ref == string_recipient.recipient_ref
        assert String.starts_with?(atom_recipient.recipient_ref, "cw_accrue_customer_")
        refute String.contains?(atom_recipient.recipient_ref, customer.email)
        assert atom_recipient.recipient_identity == "user:" <> customer.email
      else
        refute Map.has_key?(atom_recipient, :recipient_ref)
        refute Map.has_key?(string_recipient, :recipient_ref)
        assert atom_recipient.recipient_identity == customer.email
        assert string_recipient.recipient_identity == customer.email
      end

      assert :ok =
               Accrue.Integrations.Chimeway.start_campaign(
                 subscription,
                 anchor,
                 []
               )

      assert :ok =
               Accrue.Integrations.Chimeway.cancel_campaign(subscription, iso_anchor, [])

      import Ecto.Query

      notification =
        Chimeway.Repo.one!(
          from(n in Chimeway.Notifications.Notification,
            order_by: [desc: n.inserted_at],
            limit: 1
          )
        )

      signals =
        Chimeway.Repo.all(
          from(s in Chimeway.Signals.Signal,
            where: s.tenant_id == ^subscription.customer_id
          )
        )

      assert length(signals) == 1

      [signal] = signals

      expected_actor =
        if privacy_safe?,
          do: atom_recipient.recipient_ref,
          else: atom_recipient.recipient_identity

      assert notification.recipient_identity == expected_actor
      assert notification.recipient_identity == signal.actor_id
      assert signal.tenant_id == subscription.customer_id
      assert signal.actor_id == expected_actor
      assert signal.event_name == "invoice.paid"

      if privacy_safe? do
        assert Map.fetch!(notification, :tenant_id) == subscription.customer_id
        refute String.contains?(notification.recipient_identity, customer.email)
      else
        assert signal.actor_id == customer.email
      end

      assert signal.payload[:subscription_id] == subscription.id or
               signal.payload["subscription_id"] == subscription.id

      refute signal.event_name == "payment_recovered"
      refute signal.actor_id == "accrue.dunning"
    end
  end

  describe "DunningNotifier workflow contract" do
    @tag :requires_chimeway
    test "exports workflow/2 and rendering/2 when Chimeway is loaded" do
      case Code.ensure_loaded(Accrue.Integrations.Chimeway) do
        {:module, _} ->
          notifier = Accrue.Integrations.Chimeway.DunningNotifier

          assert {:workflow, 2} in notifier.__info__(:functions)
          assert {:rendering, 2} in notifier.__info__(:functions)

          assert {:ok, declaration} = notifier.workflow(%{}, %{})

          assert {:ok, normalized} =
                   Chimeway.Notifier.normalize_workflow_declaration(declaration)

          assert normalized.workflow_key == "accrue.dunning"

          [initial_step | _] = normalized.steps
          assert initial_step.step_key == "initial_email"

          # Chimeway 1.0.0 wait_until rules carry only kind/anchor/delay_seconds/to_step;
          # cancellation is driven at runtime by an invoice.paid Signal (cancel_campaign/3),
          # not a declared cancel_signals key (which normalize rejects as :mixed_rule_shape).
          [wait_rule | _] = get_in(initial_step.config, ["progress"])
          assert wait_rule["kind"] == "wait_until"
          assert wait_rule["to_step"] == "escalation_email"
          refute Map.has_key?(wait_rule, "cancel_signals")

          assert {:ok, rendering} = notifier.rendering(%{subscription_id: "sub_123"}, %{})

          assert get_in(rendering, [:channels, :email, :render_key]) ==
                   "accrue.dunning.initial_email"

        {:error, :nofile} ->
          :ok
      end
    end
  end
end
