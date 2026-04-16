defmodule Accrue.Docs.TroubleshootingGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/troubleshooting.md"
  @diagnostic_codes [
    "ACCRUE-DX-REPO-CONFIG",
    "ACCRUE-DX-MIGRATIONS-PENDING",
    "ACCRUE-DX-OBAN-NOT-CONFIGURED",
    "ACCRUE-DX-OBAN-NOT-SUPERVISED",
    "ACCRUE-DX-WEBHOOK-SECRET-MISSING",
    "ACCRUE-DX-WEBHOOK-ROUTE-MISSING",
    "ACCRUE-DX-WEBHOOK-RAW-BODY",
    "ACCRUE-DX-WEBHOOK-PIPELINE",
    "ACCRUE-DX-AUTH-ADAPTER",
    "ACCRUE-DX-ADMIN-MOUNT-MISSING"
  ]
  @anchors [
    "accrue-dx-repo-config",
    "accrue-dx-migrations-pending",
    "accrue-dx-oban-not-configured",
    "accrue-dx-webhook-raw-body"
  ]
  @matrix_columns [
    "What happened",
    "Why Accrue cares",
    "Fix",
    "How to verify"
  ]
  @verification_commands [
    "mix ecto.migrate",
    "mix test test/accrue_host_web/webhook_ingest_test.exs",
    "mix test test/accrue_host_web/admin_mount_test.exs",
    "mix accrue.install --check"
  ]

  test "troubleshooting guide reserves stable codes, anchors, and verification surface" do
    guide = File.read!(@guide)

    Enum.each(@diagnostic_codes, fn code ->
      assert guide =~ code
    end)

    Enum.each(@anchors, fn anchor ->
      assert guide =~ anchor
    end)

    Enum.each(@matrix_columns, fn column ->
      assert guide =~ column
    end)

    Enum.each(@verification_commands, fn command ->
      assert guide =~ command
    end)
  end
end
