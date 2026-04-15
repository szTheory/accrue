defmodule Accrue.Connect.TransferTest do
  @moduledoc """
  Phase 5 Plan 05 — standalone `Accrue.Connect.transfer/2`. Covers
  VALIDATION.md row 14.
  """
  use Accrue.ConnectCase, async: false

  alias Accrue.Connect
  alias Accrue.Events.Event
  alias Accrue.Processor.Fake

  setup do
    {:ok, acct} = Connect.create_account(%{type: :standard, country: "US"})
    %{account: acct}
  end

  test "transfer/2 round-trips through the Fake processor", %{account: acct} do
    assert {:ok, transfer} =
             Connect.transfer(%{
               amount: Money.new(5_000, :usd),
               destination: acct
             })

    assert transfer[:amount] == 5_000
    assert transfer[:destination] == acct.stripe_account_id
    assert String.starts_with?(transfer[:id], "tr_fake_")
  end

  test "transfer/2 records an events ledger row", %{account: acct} do
    before_count =
      Repo.aggregate(
        from(e in Event, where: e.type == "connect.transfer"),
        :count,
        :id
      )

    {:ok, _} =
      Connect.transfer(%{
        amount: Money.new(750, :usd),
        destination: acct
      })

    after_count =
      Repo.aggregate(
        from(e in Event, where: e.type == "connect.transfer"),
        :count,
        :id
      )

    assert after_count == before_count + 1
  end

  test "transfer/2 emits telemetry span events", %{account: acct} do
    parent = self()
    handler_id = "test-connect-transfer-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      handler_id,
      [
        [:accrue, :connect, :transfer, :start],
        [:accrue, :connect, :transfer, :stop]
      ],
      fn event, measurements, metadata, _ ->
        send(parent, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    try do
      {:ok, _} =
        Connect.transfer(%{
          amount: Money.new(200, :usd),
          destination: acct
        })
    after
      :telemetry.detach(handler_id)
    end

    assert_received {:telemetry, [:accrue, :connect, :transfer, :start], _, meta}
    assert meta.destination == acct.stripe_account_id
    assert meta.amount_minor == 200

    assert_received {:telemetry, [:accrue, :connect, :transfer, :stop], measurements, _}
    assert is_integer(measurements.duration)
  end

  test "transfer/2 forces platform scope regardless of with_account/2", %{account: acct} do
    Connect.with_account("acct_transfer_override", fn ->
      {:ok, _} =
        Connect.transfer(%{
          amount: Money.new(100, :usd),
          destination: acct
        })
    end)

    [transfer | _] = Fake.transfers_on(:platform)
    assert transfer[:destination] == acct.stripe_account_id
    assert Enum.empty?(Fake.transfers_on("acct_transfer_override"))
  end

  test "transfer!/2 raises on error", %{account: acct} do
    Fake.scripted_response(
      :create_transfer,
      {:error, %Accrue.APIError{code: "funds_unavailable", http_status: 402}}
    )

    assert_raise Accrue.APIError, fn ->
      Connect.transfer!(%{
        amount: Money.new(100, :usd),
        destination: acct
      })
    end
  end

  test "transfer/2 rejects missing destination" do
    assert {:error, %Accrue.ConfigError{}} =
             Connect.transfer(%{
               amount: Money.new(100, :usd),
               destination: 123
             })
  end
end
