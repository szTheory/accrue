defmodule Accrue.Test.AppleServerEvidence do
  @moduledoc false

  # Deliberately non-sensitive deterministic hostile corpus. Production golden
  # captures are supplied by the host's protected test fixture process.
  def malformed, do: "not-a-jws"

  def jws(header, payload, signature \\ <<0::512>>) do
    [header, payload]
    |> Enum.map(&encode_json/1)
    |> Kernel.++([Base.url_encode64(signature, padding: false)])
    |> Enum.join(".")
  end

  def valid_claims(overrides \\ %{}) do
    Map.merge(
      %{
        "bundleId" => "com.accrue.test",
        "environment" => "Production",
        "appAppleId" => 42,
        "originalTransactionId" => "opaque-lineage",
        "transactionId" => "opaque-transaction",
        "productId" => "product_pro"
      },
      overrides
    )
  end

  defp encode_json(value), do: value |> Jason.encode!() |> Base.url_encode64(padding: false)
end
