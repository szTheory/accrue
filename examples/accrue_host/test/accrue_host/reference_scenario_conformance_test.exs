defmodule AccrueHost.ReferenceScenarioConformanceTest do
  use AccrueHost.DataCase, async: false

  alias Accrue.Entitlements.{Account, ReferenceScenarios}

  @tag :tracer
  test "the host drives Apple-to-web through its configured Repo" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")
    account = account!("host-apple-web")

    operation =
      scenario.actions |> Enum.find(&Map.has_key?(&1, :operation)) |> Map.fetch!(:operation)

    assert {:ok, _} =
             Accrue.Entitlements.observe_apple_evidence(
               account,
               Jason.encode!(%{
                 "originalTransactionId" => operation.provider_lineage_id,
                 "appAccountToken" => account.id,
                 "transactionId" => operation.provider_transaction_id,
                 "productId" => operation.provider_product_id,
                 "signedDate" => 1_754_000_000_000,
                 "expiresDate" => 1_800_000_000_000
               })
             )
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(AccrueHost.Repo, "reference_host", owner_id) |> elem(1)
end
