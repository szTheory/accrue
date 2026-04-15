defmodule Accrue.Connect.ChargesTest do
  @moduledoc """
  Phase 5 Plan 05 — `Accrue.Connect.destination_charge/2` and
  `Accrue.Connect.separate_charge_and_transfer/2`. Covers
  VALIDATION.md rows 11, 12, 13.
  """
  use Accrue.ConnectCase, async: false

  alias Accrue.Billing.{Charge, Customer}
  alias Accrue.Connect
  alias Accrue.Processor.Fake

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_conn_05",
        email: "conn-charge@example.com"
      })
      |> Repo.insert()

    {:ok, acct} = Connect.create_account(%{type: :standard, country: "US"})

    %{customer: customer, account: acct}
  end

  # -------------------------------------------------------------------------
  # destination_charge/2
  # -------------------------------------------------------------------------

  describe "destination_charge/2 (CONN-04)" do
    test "builds stripe params with transfer_data and application_fee_amount",
         %{customer: customer, account: acct} do
      {:ok, %Charge{}} =
        Connect.destination_charge(%{
          amount: Money.new(10_000, :usd),
          destination: acct,
          customer: customer,
          application_fee_amount: Money.new(320, :usd)
        })

      [fake_charge | _] =
        Fake.charges_on(:platform)
        |> Enum.sort_by(& &1[:id], :desc)

      assert fake_charge[:transfer_data] == %{destination: acct.stripe_account_id}
      assert fake_charge[:application_fee_amount] == 320
      assert fake_charge[:amount] == 10_000
      assert fake_charge[:currency] == "usd"
    end

    test "forces platform scope even inside with_account/2",
         %{customer: customer, account: acct} do
      Connect.with_account("acct_override_scope", fn ->
        {:ok, %Charge{}} =
          Connect.destination_charge(%{
            amount: Money.new(5_000, :usd),
            destination: acct,
            customer: customer
          })
      end)

      # The new charge must be tagged :platform scope, NOT
      # "acct_override_scope" — Pitfall 2 guard (T-05-05-01).
      platform_charges = Fake.charges_on(:platform)
      scoped_charges = Fake.charges_on("acct_override_scope")

      assert length(platform_charges) >= 1
      assert Enum.empty?(scoped_charges)
    end

    test "returns a persisted %Accrue.Billing.Charge{} projection",
         %{customer: customer, account: acct} do
      assert {:ok, %Charge{} = charge} =
               Connect.destination_charge(%{
                 amount: Money.new(2_500, :usd),
                 destination: acct,
                 customer: customer
               })

      assert charge.customer_id == customer.id
      assert charge.amount_cents == 2_500
      assert charge.currency == "usd"
      assert charge.processor == "fake"
      assert is_binary(charge.processor_id)
      assert Repo.get(Charge, charge.id)
    end

    test "emits telemetry :start and :stop events with destination metadata",
         %{customer: customer, account: acct} do
      parent = self()
      handler_id = "test-destination-charge-#{System.unique_integer([:positive])}"

      :telemetry.attach_many(
        handler_id,
        [
          [:accrue, :connect, :destination_charge, :start],
          [:accrue, :connect, :destination_charge, :stop]
        ],
        fn event, measurements, metadata, _ ->
          send(parent, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      try do
        {:ok, %Charge{}} =
          Connect.destination_charge(%{
            amount: Money.new(1_000, :usd),
            destination: acct,
            customer: customer
          })
      after
        :telemetry.detach(handler_id)
      end

      assert_received {:telemetry, [:accrue, :connect, :destination_charge, :start], _, meta_start}
      assert meta_start.destination == acct.stripe_account_id

      assert_received {:telemetry, [:accrue, :connect, :destination_charge, :stop], measurements_stop, _}
      assert is_integer(measurements_stop.duration)
    end

    test "rejects missing destination with ConfigError",
         %{customer: customer} do
      assert {:error, %Accrue.ConfigError{}} =
               Connect.destination_charge(%{
                 amount: Money.new(100, :usd),
                 destination: 12_345,
                 customer: customer
               })
    end

    test "destination_charge!/2 raises on error",
         %{customer: customer} do
      assert_raise Accrue.ConfigError, fn ->
        Connect.destination_charge!(%{
          amount: Money.new(100, :usd),
          destination: :bogus,
          customer: customer
        })
      end
    end
  end

  # -------------------------------------------------------------------------
  # separate_charge_and_transfer/2
  # -------------------------------------------------------------------------

  describe "separate_charge_and_transfer/2 (CONN-05)" do
    test "issues TWO distinct API calls (one charge + one transfer)",
         %{customer: customer, account: acct} do
      before_charge_count = Fake.call_count(:create_charge)
      before_transfer_count = Fake.call_count(:create_transfer)

      {:ok, %{charge: %Charge{}, transfer: transfer}} =
        Connect.separate_charge_and_transfer(%{
          amount: Money.new(10_000, :usd),
          customer: customer,
          destination: acct,
          transfer_amount: Money.new(9_700, :usd)
        })

      assert Fake.call_count(:create_charge) == before_charge_count + 1
      assert Fake.call_count(:create_transfer) == before_transfer_count + 1

      assert transfer[:amount] == 9_700
      assert transfer[:destination] == acct.stripe_account_id
      assert transfer[:source_transaction] |> is_binary()
    end

    test "returns {:ok, %{charge: ..., transfer: ...}} on success",
         %{customer: customer, account: acct} do
      assert {:ok, %{charge: %Charge{}, transfer: transfer}} =
               Connect.separate_charge_and_transfer(%{
                 amount: Money.new(2_000, :usd),
                 customer: customer,
                 destination: acct,
                 transfer_amount: Money.new(1_940, :usd)
               })

      assert transfer[:object] == "transfer"
    end

    test "returns {:error, {:transfer_failed, charge, err}} when the transfer step fails",
         %{customer: customer, account: acct} do
      Fake.scripted_response(
        :create_transfer,
        {:error, %Accrue.APIError{code: "fake_transfer_decline", http_status: 402}}
      )

      assert {:error, {:transfer_failed, %Charge{} = charge, %Accrue.APIError{}}} =
               Connect.separate_charge_and_transfer(%{
                 amount: Money.new(1_000, :usd),
                 customer: customer,
                 destination: acct,
                 transfer_amount: Money.new(900, :usd)
               })

      # Charge row is persisted even though the transfer failed, so the
      # caller can reconcile. (T-05-05-03 mitigation.)
      assert Repo.get(Charge, charge.id)
    end

    test "forces platform scope on the charge step",
         %{customer: customer, account: acct} do
      Connect.with_account("acct_separate_scope", fn ->
        {:ok, _} =
          Connect.separate_charge_and_transfer(%{
            amount: Money.new(1_000, :usd),
            customer: customer,
            destination: acct,
            transfer_amount: Money.new(970, :usd)
          })
      end)

      assert Enum.empty?(Fake.charges_on("acct_separate_scope"))
    end
  end
end
