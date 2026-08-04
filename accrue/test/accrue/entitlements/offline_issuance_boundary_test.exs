defmodule Accrue.Entitlements.OfflineIssuanceBoundaryTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Offline
  alias Accrue.Entitlements.Offline.Issuer

  test "direct issuance cannot mint an allow or deny compact without reconnect admission" do
    handler = "offline-direct-issuance-#{System.unique_integer([:positive])}"
    test_pid = self()

    :ok =
      :telemetry.attach_many(
        handler,
        [
          [:accrue, :entitlements, :offline, :issue, :start],
          [:accrue, :entitlements, :offline, :issue, :stop]
        ],
        fn event, _measurements, metadata, _ ->
          send(test_pid, {:issuance_telemetry, event, metadata})
        end,
        nil
      )

    try do
      account = %Account{id: "account-direct-issuance"}

      request = %Issuer.Request{
        account_id: account.id,
        device_id: "device-direct-issuance",
        now: ~U[2026-08-04 01:00:00Z]
      }

      assert {:error, :unauthorized} =
               Offline.issue(account, request,
                 authorize: fn _, _ -> true end,
                 key_provider: __MODULE__
               )

      assert_receive {:issuance_telemetry, event, metadata}

      assert event in [
               [:accrue, :entitlements, :offline, :issue, :start],
               [:accrue, :entitlements, :offline, :issue, :stop]
             ]

      assert %{action: :offline_issue, disposition: :rejected, reason: :unauthorized} = metadata

      assert_receive {:issuance_telemetry, event, metadata}

      assert event in [
               [:accrue, :entitlements, :offline, :issue, :start],
               [:accrue, :entitlements, :offline, :issue, :stop]
             ]

      assert %{action: :offline_issue, disposition: :rejected, reason: :unauthorized} = metadata

      refute Map.has_key?(metadata, :account_id)
      refute Map.has_key?(metadata, :installation_id)
      refute Map.has_key?(metadata, :compact)
      refute inspect(metadata) =~ account.id
      refute inspect(metadata) =~ request.device_id
    after
      :telemetry.detach(handler)
    end
  end

  test "the issuer's legacy direct entry point also cannot mint a compact" do
    account = %Account{id: "account-direct-issuer"}

    request = %Issuer.Request{
      account_id: account.id,
      device_id: "device-direct-issuer",
      now: ~U[2026-08-04 01:00:00Z]
    }

    assert {:error, :unauthorized} = Issuer.issue(account, request, [])
  end
end
