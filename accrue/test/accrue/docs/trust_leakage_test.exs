defmodule Accrue.Docs.TrustLeakageTest do
  use ExUnit.Case, async: true

  @security_path Path.expand("../../../../SECURITY.md", __DIR__)
  @contributing_path Path.expand("../../../../CONTRIBUTING.md", __DIR__)
  @releasing_path Path.expand("../../../../RELEASING.md", __DIR__)
  @live_stripe_path Path.expand("../../../../guides/testing-live-stripe.md", __DIR__)
  @playwright_config_path Path.expand(
                            "../../../../examples/accrue_host/playwright.config.js",
                            __DIR__
                          )

  test "public docs keep explicit no-secrets guidance" do
    for path <- [@security_path, @contributing_path, @releasing_path, @live_stripe_path] do
      content = File.read!(path)

      assert content =~ "secrets"
      assert content =~ "customer data"
      assert content =~ "PII"
    end
  end

  test "secret names appear only as env vars or GitHub secrets names" do
    docs =
      [@security_path, @contributing_path, @releasing_path, @live_stripe_path]
      |> Enum.map(&File.read!/1)
      |> Enum.join("\n")

    assert docs =~ "STRIPE_TEST_SECRET_KEY"
    assert docs =~ "HEX_API_KEY"
    assert docs =~ "RELEASE_PLEASE_TOKEN"

    refute docs =~ "sk_test_123"
    refute docs =~ "sk_live_123"
    refute docs =~ "whsec_live_123"
  end

  test "retained artifact policy stays failure-only" do
    playwright_config = File.read!(@playwright_config_path)

    assert playwright_config =~ ~s(trace: "retain-on-failure")
    assert playwright_config =~ ~s(screenshot: "only-on-failure")
    refute playwright_config =~ ~s(trace: "on")
    refute playwright_config =~ ~s(screenshot: "on")
  end
end
