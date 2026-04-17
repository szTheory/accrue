defmodule Accrue.Docs.TrustReviewTest do
  use ExUnit.Case, async: true

  @trust_review_path Path.expand(
                       "../../../../.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md",
                       __DIR__
                     )

  test "checked-in trust review exists and covers required boundaries" do
    review = File.read!(@trust_review_path)

    assert review =~ "## Trust Boundaries"
    assert review =~ "webhook request -> raw-body verification"
    assert review =~ "host auth/session -> /billing mount"
    assert review =~ "admin operator -> replay action"
    assert review =~ "generated installer output -> host-owned code"
    assert review =~ "retained browser artifacts -> repo/CI storage"
    assert review =~ "public docs/issues -> maintainer intake"
    assert review =~ "public errors/logs -> diagnostic readers"
  end

  test "trust review links concrete repo evidence and host-owned assumptions" do
    review = File.read!(@trust_review_path)

    assert review =~ "examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs"
    assert review =~ "examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs"
    assert review =~ ".github/ISSUE_TEMPLATE/bug.yml"
    assert review =~ ".github/ISSUE_TEMPLATE/integration-problem.yml"
    assert review =~ "scripts/ci/accrue_host_uat.sh"
    assert review =~ ".github/workflows/ci.yml"
    assert review =~ "accrue/test/accrue/webhook/plug_test.exs"
    assert review =~ "accrue/test/accrue/errors_test.exs"
    assert review =~ "accrue/test/accrue/telemetry/otel_test.exs"

    assert review =~ "host-owned"
    assert review =~ "advisory"
    assert review =~ "environment-specific"
    assert review =~ "TRUST-01"
    assert review =~ "TRUST-05"
    assert review =~ "TRUST-06"
  end

  test "trust review encodes severity, ASVS, and release-blocking policy" do
    review = File.read!(@trust_review_path)

    assert review =~ "### Threat Verification"
    assert review =~ "severity"
    assert review =~ "ASVS"
    assert review =~ "high-severity findings are release-blocking"
    assert review =~ "cannot be accepted in Phase 15"
    assert review =~ "low or medium"
    assert review =~ "concrete rationale"
  end
end
