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
        "productId" => "product_pro",
        "signedDate" => 1_754_000_000_000,
        "expiresDate" => 1_800_000_000_000
      },
      overrides
    )
  end

  # Test-only P-256 chain material. The leaf, intermediate, and configured
  # trust root intentionally model the Apple Server API purpose extensions.
  @root "MIIBmjCCAUGgAwIBAgIUc9cCqyq4oM+rZEDK6tsH9fR+50MwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQWNjcnVlIFRlc3QgUm9vdDAeFw0yNjA4MDMxNzM3MDdaFw0zNjA3MzExNzM3MDdaMBsxGTAXBgNVBAMMEEFjY3J1ZSBUZXN0IFJvb3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQ1JYZ01dqTp9fzmsymFhrJ1Oi6ooEPuGtw70/iTkcvc5OwrI1nOtmZUBlQIbI1mJe0po85WHdoCjR2Sa0mHh1mo2MwYTAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUvBPFukroDRqU5UXKlu2Df5ZOwD4wHwYDVR0jBBgwFoAUvBPFukroDRqU5UXKlu2Df5ZOwD4wCgYIKoZIzj0EAwIDRwAwRAIgDpuZVMv5dDzqTVwqr5PzS02wVFXmzPq6wkIQR9RBeBcCID5Pn1zQRAFxLzE81WU1Rm/mwsimkorSOfOYvyAAcpji"
  @intermediate "MIIBtTCCAVugAwIBAgIUOghDP0u6cCTiy8qkPaPiqpAKJeAwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQWNjcnVlIFRlc3QgUm9vdDAeFw0yNjA4MDMxNzM3MDdaFw0zNDEwMjAxNzM3MDdaMCMxITAfBgNVBAMMGEFjY3J1ZSBUZXN0IEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABH1TDLYwFIb0t5lCjzlOQQg2BT/vXID+Pz611zaeYSgYVXS4g2dBTyHO++78q+LFk0VNposj74eiMCstAwMU/lWjdTBzMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgEEAgUAMB0GA1UdDgQWBBQGMSviAsWVd2CX0nnruxkbsaZDTTAfBgNVHSMEGDAWgBS8E8W6SugNGpTlRcqW7YN/lk7APjAKBggqhkjOPQQDAgNIADBFAiBJTSHwor6QSIHglSHZ4wTD42xHkHTPEpSHLkQ0lnyp1QIhAIOJLbYaQgtNI25lirc00BFPKjL3HLdbtncTID7JvthL"
  @leaf "MIIBsjCCAVigAwIBAgIUfOBx/8GkYn500f6U0MTyiOksnDEwCgYIKoZIzj0EAwIwIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3MzcwN1oXDTMyMDEyNDE3MzcwN1owGzEZMBcGA1UEAwwQQWNjcnVlIFRlc3QgTGVhZjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAoWe9oxMtQb+5pgTyD+KOLXDpI79DgssKQ4+lBNjxliJG3bfniaPKEZZrfGpYfsExHuWsFQrrkxTzdISfi+tnyjcjBwMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBAGCiqGSIb3Y2QGCwEEAgUAMB0GA1UdDgQWBBR8nMQPdVWtBkN0mqXhCQ/L2gpUcDAfBgNVHSMEGDAWgBQGMSviAsWVd2CX0nnruxkbsaZDTTAKBggqhkjOPQQDAgNIADBFAiAjE/44XeTyDVb5jv5thfyMcllT29ZrtwG7nLyacf7U3AIhAI3PfcKbi8WfY2IwF+2NUng7lC2kacziduUZrY2RhT7p"
  @leaf_key "MHcCAQEEICU1GCtEXt1UfPKuTW9vueMICuxowTxVEyZHjWdiwk+CoAoGCCqGSM49AwEHoUQDQgAEChZ72jEy1Bv7mmBPIP4o4tcOkjv0OCywpDj6UE2PGWIkbdt+eJo8oRlmt8alh+wTEe5awVCuuTFPN0hJ+L62fA=="

  def production_root, do: Base.decode64!(@root)

  def production_transaction(overrides \\ %{}) do
    header = %{"alg" => "ES256", "x5c" => [@leaf, @intermediate, @root]}
    protected = encode_json(header)
    payload = valid_claims(overrides) |> encode_json()
    signing_input = protected <> "." <> payload
    signature = signing_input |> :public_key.sign(:sha256, leaf_key()) |> der_to_raw_es256()
    signing_input <> "." <> Base.url_encode64(signature, padding: false)
  end

  defp leaf_key do
    @leaf_key
    |> Base.decode64!()
    |> then(&:public_key.pem_entry_decode({:ECPrivateKey, &1, :not_encrypted}))
  end

  defp der_to_raw_es256(
         <<0x30, _length, 0x02, r_length, r::binary-size(r_length), 0x02, s_length,
           s::binary-size(s_length)>>
       ) do
    <<r |> :binary.decode_unsigned()::unsigned-big-integer-size(256),
      s |> :binary.decode_unsigned()::unsigned-big-integer-size(256)>>
  end

  defp encode_json(value), do: value |> Jason.encode!() |> Base.url_encode64(padding: false)
end
