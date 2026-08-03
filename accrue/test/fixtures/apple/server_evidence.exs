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
  @wrong_leaf "MIIBuDCCAV6gAwIBAgIUfOBx/8GkYn500f6U0MTyiOksnDIwCgYIKoZIzj0EAwIwIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3NTM1OFoXDTMxMDcwODE3NTM1OFowITEfMB0GA1UEAwwWQWNjcnVlIFRlc3QgV3JvbmcgTGVhZjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABFSJEwxB3B6vttHaC3tsUGbs28DCw7vrCqfBumECJEvVhpXxnSjNhp/XaT54z/5xb0MFLVX6hg3Xa1SIawQuJMajcjBwMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBAGCiqGSIb3Y2QGC2MEAgUAMB0GA1UdDgQWBBQrLjxsFV5Qa12NumsPHMMhRRo6CTAfBgNVHSMEGDAWgBQGMSviAsWVd2CX0nnruxkbsaZDTTAKBggqhkjOPQQDAgNIADBFAiEAk7I6HDIMealTVi0f8rBRkN5CogPoJJyCRNEfYmuVyNMCID9VLmhkxq3Fgnxs30LODhxt1ImhYfLX9rlprtLIYMmi"
  @missing_leaf "MIIBpzCCAU6gAwIBAgIUfOBx/8GkYn500f6U0MTyiOksnDMwCgYIKoZIzj0EAwIwIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3NTM1OFoXDTMxMDcwODE3NTM1OFowIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgTWlzc2luZyBMZWFmMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE0f643as9XKSNiBVR34NaLTxyxtDLuR6sv0nhgOBAu64WNXHkWvED/JnQ4DQikjRK+7eG+IobgAbErZxteuDhvKNgMF4wDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCB4AwHQYDVR0OBBYEFKQUHDjHpHzV03lLleHqD9RVVS7EMB8GA1UdIwQYMBaAFAYxK+ICxZV3YJfSeeu7GRuxpkNNMAoGCCqGSM49BAMCA0cAMEQCIFU6TtESjKefZTaI8bE/OangFWAqbpNy12iU9jBi5fIWAiAzcS0zOIwGKrAfRMCvSAymJTZQJ9tDBaubrMtYvu+a5A=="
  @ca_leaf "MIIBuTCCAV6gAwIBAgIUfOBx/8GkYn500f6U0MTyiOksnDQwCgYIKoZIzj0EAwIwIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3NTM1OFoXDTMxMDcwODE3NTM1OFowHjEcMBoGA1UEAwwTQWNjcnVlIFRlc3QgQ0EgTGVhZjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABB7skgfKju+JxJ1+2jrR5g3+LIdbOHaT11ML/bJqTMRcq0ZyPnRm1zQVRfmCbQ0+XFF7nyx6IrmaIrxo7iS0/H6jdTBzMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgKEMBAGCiqGSIb3Y2QGCwEEAgUAMB0GA1UdDgQWBBTB+n0RIfUNSh2TNeHyDQii3SF2LDAfBgNVHSMEGDAWgBQGMSviAsWVd2CX0nnruxkbsaZDTTAKBggqhkjOPQQDAgNJADBGAiEA28sa+t4fjmoTaKE5sF69maCY2r6b3dKoXkiUxqHRkx8CIQDDKQkKqVMNR3Y7RIgQOLbStQUoVuks+D22VZIevWmWhA=="
  @no_sign_leaf "MIIBuTCCAWCgAwIBAgIUfOBx/8GkYn500f6U0MTyiOksnDUwCgYIKoZIzj0EAwIwIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3NTM1OFoXDTMxMDcwODE3NTM1OFowIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgTm8gU2lnbiBMZWFmMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEElvuyItHm1sAubkkwh/coMjm5in+mrRrJQWstOLH2YuAA+A/aWm5eMIQAMPHpm7nbwEd8tWVyW9MFLTMVglbVqNyMHAwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCBSAwEAYKKoZIhvdjZAYLAQQCBQAwHQYDVR0OBBYEFFDZQAl17poX/H54HZ7dGvxiUiT9MB8GA1UdIwQYMBaAFAYxK+ICxZV3YJfSeeu7GRuxpkNNMAoGCCqGSM49BAMCA0cAMEQCICu/Ljav8HRxunCPYllmDT9sbv9lDyyFchbS8l2hmR8oAiAaTcvgUTBvcLt3xR/fR/lmxpWAnzwJcEuMkBJcKhktmg=="
  @ca_sign_leaf "MIIBujCCAWCgAwIBAgIUfOBx/8GkYn500f6U0MTyiOksnDYwCgYIKoZIzj0EAwIwIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3NTM1OFoXDTMxMDcwODE3NTM1OFowIzEhMB8GA1UEAwwYQWNjcnVlIFRlc3QgQ0EgU2lnbiBMZWFmMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEc670s4ukE+2dTyVffnTg/ol6D/DFhjjX28HI2hTBmJNfKeBwLv7BwhWQxSGhzyKeA9h3/XlM6UkqLIlxHsbN2qNyMHAwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCAgQwEAYKKoZIhvdjZAYLAQQCBQAwHQYDVR0OBBYEFKjwQYh4f7J+3zHzPRp33SRBnLneMB8GA1UdIwQYMBaAFAYxK+ICxZV3YJfSeeu7GRuxpkNNMAoGCCqGSM49BAMCA0gAMEUCIBsZQA7UlYsVKSBf+mZtbbCprgdp2mOEFreYhUnkPK4bAiEAm4H6AJwr2JOOT0S+RDNLQHXJ1iCL87x2eKr1Vml1Yks="
  @wrong_intermediate "MIIBuzCCAWGgAwIBAgIUOghDP0u6cCTiy8qkPaPiqpAKJeEwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQWNjcnVlIFRlc3QgUm9vdDAeFw0yNjA4MDMxNzUzNThaFw0zMzA2MDcxNzUzNThaMCkxJzAlBgNVBAMMHkFjY3J1ZSBUZXN0IFdyb25nIEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABJd5qLzOnQpnxQu6o0brCg9IYchiG/TDb3bFE2rMzmtogjcS/Z7My42lyrY3njR957MA+vo/8EO8np668Da+KKejdTBzMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAmMEAgUAMB0GA1UdDgQWBBRwFcsHfsS6IARLMYfKPZq8RZAZcjAfBgNVHSMEGDAWgBS8E8W6SugNGpTlRcqW7YN/lk7APjAKBggqhkjOPQQDAgNIADBFAiAfAlGuDbUE3LJ9r0mmFNGCvFW6BcC/p4VQ+ON7Np/2YgIhAOSG6BvRwZ9MiHqkO3SlvtapSVUZnwT1mjpn+aANwGAS"
  @valid_wrong_intermediate_leaf "MIIBvjCCAWSgAwIBAgIUU0oQqirM9nveDnuNxUXq7nCJGzUwCgYIKoZIzj0EAwIwKTEnMCUGA1UEAwweQWNjcnVlIFRlc3QgV3JvbmcgSW50ZXJtZWRpYXRlMB4XDTI2MDgwMzE3NTM1OFoXDTMxMDcwODE3NTM1OFowITEfMB0GA1UEAwwWQWNjcnVlIFRlc3QgVmFsaWQgTGVhZjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAlHbccaWNaLeEPnCB/r5kU6G/N8xvKt+dYK99KIiPCg8RSwgr2s7GYtwOzzUmOrOllQW6e3FsKGM8j60XbHLtqjcjBwMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBAGCiqGSIb3Y2QGCwEEAgUAMB0GA1UdDgQWBBSypUE4M6ABL8Mz0BZlcCEW5yOqkTAfBgNVHSMEGDAWgBRwFcsHfsS6IARLMYfKPZq8RZAZcjAKBggqhkjOPQQDAgNIADBFAiBuXl2+79VTLw42XyH498sgBJ0najSpYfYz5YMusoyjhwIhAMrUMZaqH8sZdEaE+ag7L6+pAusk8rWiUUtnn1jbopYj"
  @missing_intermediate "MIIBrDCCAVGgAwIBAgIUOghDP0u6cCTiy8qkPaPiqpAKJeIwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQWNjcnVlIFRlc3QgUm9vdDAeFw0yNjA4MDMxNzUzNThaFw0zMzA2MDcxNzUzNThaMCsxKTAnBgNVBAMMIEFjY3J1ZSBUZXN0IE1pc3NpbmcgSW50ZXJtZWRpYXRlMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEFAFf5STn8WiXBF3mNY/Zk3yribG4T/fdl14sKs9sA4EP66Q5XGUNbzpIZAgfHj93llIacRgv0d6yLL2FQf+0jKNjMGEwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFPGZWJX8oSq489RLJ9w+MFOqJ4lbMB8GA1UdIwQYMBaAFLwTxbpK6A0alOVFypbtg3+WTsA+MAoGCCqGSM49BAMCA0kAMEYCIQCcsyJJGnE8MrUZcSZXwKPiUBn9bwW5WhiT1O203IpgRQIhANoLszCnnjQBu0RoL10IzK2mkmsQ5GCAyvCHP7rGvj6X"
  @valid_missing_intermediate_leaf "MIIBvzCCAWagAwIBAgIUG1YM1QFLsUHMhiwHlIrDrt0gWC0wCgYIKoZIzj0EAwIwKzEpMCcGA1UEAwwgQWNjcnVlIFRlc3QgTWlzc2luZyBJbnRlcm1lZGlhdGUwHhcNMjYwODAzMTc1MzU4WhcNMzEwNzA4MTc1MzU4WjAhMR8wHQYDVQQDDBZBY2NydWUgVGVzdCBWYWxpZCBMZWFmMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEecH4oKESMVtr4IsL55OtIw4BTmyDCSazrOaSFzcvIW9bFpX69m73Y/a0ypV7kmSPT4kFXonuAUa09KvViCCqXaNyMHAwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCB4AwEAYKKoZIhvdjZAYLAQQCBQAwHQYDVR0OBBYEFIpsuvN0EvtdApMowteO22nBna4SMB8GA1UdIwQYMBaAFPGZWJX8oSq489RLJ9w+MFOqJ4lbMAoGCCqGSM49BAMCA0cAMEQCIEjU5fkJFAgazW14beMyxDIr1UWVaa983rCLxtsGpKPBAiA+6JxrURkMEzZ4erOMBv9Dr1xke52EAV5CZ3q3E1vhWQ=="
  @wrong_leaf_key "MHcCAQEEIMBL+Rqo+H+o3zMj6bQVq37q7InOqK/DuVAek774ogRhoAoGCCqGSM49AwEHoUQDQgAEVIkTDEHcHq+20doLe2xQZuzbwMLDu+sKp8G6YQIkS9WGlfGdKM2Gn9dpPnjP/nFvQwUtVfqGDddrVIhrBC4kxg=="
  @missing_leaf_key "MHcCAQEEIPzK237NTvzdpVOzv/Z5O/2MWhpchRGf84NVMIbzhdJDoAoGCCqGSM49AwEHoUQDQgAE0f643as9XKSNiBVR34NaLTxyxtDLuR6sv0nhgOBAu64WNXHkWvED/JnQ4DQikjRK+7eG+IobgAbErZxteuDhvA=="
  @ca_leaf_key "MHcCAQEEIFFbwPDRb2K2d+9vpP7E6hwYgkaogHs5otOTgbxerZVyoAoGCCqGSM49AwEHoUQDQgAEHuySB8qO74nEnX7aOtHmDf4sh1s4dpPXUwv9smpMxFyrRnI+dGbXNBVF+YJtDT5cUXufLHoiuZoivGjuJLT8fg=="
  @no_sign_leaf_key "MHcCAQEEICf+qzhA6J0/3gVvPEG5cD3iLhP0W+o0cEbWBijYljBnoAoGCCqGSM49AwEHoUQDQgAEElvuyItHm1sAubkkwh/coMjm5in+mrRrJQWstOLH2YuAA+A/aWm5eMIQAMPHpm7nbwEd8tWVyW9MFLTMVglbVg=="
  @ca_sign_leaf_key "MHcCAQEEIHRHmORqZT0aqbsHkHJFEhqQSO7+Q1+4wtkiGiWcqSrxoAoGCCqGSM49AwEHoUQDQgAEc670s4ukE+2dTyVffnTg/ol6D/DFhjjX28HI2hTBmJNfKeBwLv7BwhWQxSGhzyKeA9h3/XlM6UkqLIlxHsbN2g=="
  @valid_wrong_intermediate_leaf_key "MHcCAQEEIHJn1OuNB1fFO72WFT8PzpexVMD2UhDAbfchaJ6baS7xoAoGCCqGSM49AwEHoUQDQgAECUdtxxpY1ot4Q+cIH+vmRTob83zG8q351gr30oiI8KDxFLCCvazsZi3A7PNSY6s6WVBbp7cWwoYzyPrRdscu2g=="
  @valid_missing_intermediate_leaf_key "MHcCAQEEIO61eG1ABTXdyhurJnXDbOQPRClZ8Hr5bm3jU1f3xgOHoAoGCCqGSM49AwEHoUQDQgAEecH4oKESMVtr4IsL55OtIw4BTmyDCSazrOaSFzcvIW9bFpX69m73Y/a0ypV7kmSPT4kFXonuAUa09KvViCCqXQ=="

  def production_root, do: Base.decode64!(@root)
  def unrelated_root, do: Base.decode64!(@leaf)

  def production_transaction(overrides \\ %{}) do
    transaction(variant(:valid), overrides)
  end

  def production_notification(overrides \\ %{}) do
    transaction = Map.get(overrides, :transaction, production_transaction())
    renewal = Map.get(overrides, :renewal, production_transaction())

    data =
      Map.merge(
        %{
          "bundleId" => "com.accrue.test",
          "environment" => "Production",
          "appAppleId" => 42,
          "signedTransactionInfo" => transaction,
          "signedRenewalInfo" => renewal
        },
        Map.get(overrides, :data, %{})
      )

    %{"notificationUUID" => "notification-production-1", "data" => data}
    |> Map.merge(Map.get(overrides, :outer, %{}))
    |> signed(variant(:valid))
  end

  def hostile_transaction(kind, overrides \\ %{})
      when kind in [
             :wrong_leaf_purpose,
             :missing_leaf_purpose,
             :ca_leaf,
             :missing_digital_signature,
             :ca_signing_only,
             :wrong_intermediate_purpose,
             :missing_intermediate_purpose
           ] do
    transaction(variant(kind), overrides)
  end

  defp transaction({leaf, intermediate, key}, overrides) do
    valid_claims(overrides) |> signed({leaf, intermediate, key})
  end

  defp signed(payload, {leaf, intermediate, key}) do
    header = %{"alg" => "ES256", "x5c" => [leaf, intermediate, @root]}
    protected = encode_json(header)
    payload = encode_json(payload)
    signing_input = protected <> "." <> payload

    signature =
      signing_input |> :public_key.sign(:sha256, decode_leaf_key(key)) |> der_to_raw_es256()

    signing_input <> "." <> Base.url_encode64(signature, padding: false)
  end

  defp variant(:valid), do: {@leaf, @intermediate, @leaf_key}
  defp variant(:wrong_leaf_purpose), do: {@wrong_leaf, @intermediate, @wrong_leaf_key}
  defp variant(:missing_leaf_purpose), do: {@missing_leaf, @intermediate, @missing_leaf_key}
  defp variant(:ca_leaf), do: {@ca_leaf, @intermediate, @ca_leaf_key}
  defp variant(:missing_digital_signature), do: {@no_sign_leaf, @intermediate, @no_sign_leaf_key}
  defp variant(:ca_signing_only), do: {@ca_sign_leaf, @intermediate, @ca_sign_leaf_key}

  defp variant(:wrong_intermediate_purpose),
    do: {@valid_wrong_intermediate_leaf, @wrong_intermediate, @valid_wrong_intermediate_leaf_key}

  defp variant(:missing_intermediate_purpose),
    do:
      {@valid_missing_intermediate_leaf, @missing_intermediate,
       @valid_missing_intermediate_leaf_key}

  defp decode_leaf_key(key) do
    key
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
