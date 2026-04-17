defmodule Accrue.Docs.ReleaseGuidanceTest do
  use ExUnit.Case, async: true

  @releasing_path Path.expand("../../../../RELEASING.md", __DIR__)
  @guide_path Path.expand("../../../../guides/testing-live-stripe.md", __DIR__)
  @contributing_path Path.expand("../../../../CONTRIBUTING.md", __DIR__)

  test "release guidance separates deterministic, provider-parity, and advisory lanes" do
    releasing = File.read!(@releasing_path)

    assert releasing =~ "Canonical local demo: Fake"
    assert releasing =~ "required deterministic gate"
    assert releasing =~ "security/trust artifact"
    assert releasing =~ "seeded performance smoke"
    assert releasing =~ "compatibility floor/target checks"
    assert releasing =~ "browser accessibility/responsive checks"
    assert releasing =~ "Provider parity: Stripe test mode"
    assert releasing =~ "provider-parity checks"
    assert releasing =~ "release-gate"
    assert releasing =~ "Advisory/manual: live Stripe"
    assert releasing =~ "advisory/manual before shipping your app"
    assert releasing =~ "guides/testing-live-stripe.md"
    assert releasing =~ "signed webhook verification and runtime secrets remain required"

    refute releasing =~ "Phase 9 release gate"
    refute releasing =~ "live Stripe is required for clone-to-evaluate"
    refute releasing =~ "live Stripe is required for standard releases"
    refute releasing =~ "Stripe test mode is required for every release"
  end

  test "provider parity guide stays explicit about test mode and advisory status" do
    guide = File.read!(@guide_path)

    assert guide =~ "provider-parity checks"
    assert guide =~ "Stripe test mode"
    assert guide =~ "STRIPE_TEST_SECRET_KEY"
    assert guide =~ "continue-on-error: true"
    assert guide =~ "advisory"
    assert guide =~ "does not replace Fake"
    assert guide =~ "release-gate"
    assert guide =~ "host-integration"
    assert guide =~ "signed webhook verification and runtime secrets still remain required"

    refute guide =~ "primary `test` job"
  end

  test "contributing routes contributors to the provider parity guide safely" do
    contributing = File.read!(@contributing_path)

    assert contributing =~ "guides/testing-live-stripe.md"
    assert contributing =~ "provider-parity"
    assert contributing =~ "required deterministic release gate"
    assert contributing =~ "keep real credentials out of shell history and logs"
    assert contributing =~ "Node.js for browser UAT in `examples/accrue_host`"

    refute contributing =~ "Node.js for browser UAT in `accrue_admin`"
  end
end
