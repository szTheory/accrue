defmodule AccrueHost.Demo.CommandManifestTest do
  use ExUnit.Case, async: true

  Code.require_file("../../demo/command_manifest.exs", __DIR__)

  alias AccrueHost.Demo.CommandManifest

  test "exports the canonical first-run and seeded-history modes" do
    manifest = CommandManifest.manifest()

    assert manifest.first_run.label == "First run"
    assert manifest.seeded_history.label == "Seeded history"

    assert [
             "cd examples/accrue_host",
             "mix setup",
             "mix phx.server",
             "Create a Fake-backed subscription through AccrueHost.Billing",
             "POST one signed /webhooks/stripe event",
             "Inspect /billing",
             "mix verify"
           ] == manifest.first_run.commands

    assert [
             "cd examples/accrue_host",
             "mix setup",
             "mix verify.full",
             "Seed deterministic replay/history state for browser smoke"
           ] == manifest.seeded_history.commands
  end

  test "exports the locked command labels" do
    labels = CommandManifest.command_labels()

    assert "mix setup" in labels
    assert "mix verify" in labels
    assert "mix verify.full" in labels
    assert "bash scripts/ci/accrue_host_uat.sh" in labels
  end

  test "distinguishes public first-run commands from seeded-only evaluation paths" do
    manifest = CommandManifest.manifest()

    assert manifest.first_run.boundary == :public
    assert manifest.seeded_history.boundary == :seeded
    assert "customer.subscription.created" in manifest.story_artifacts
    assert "/billing" in manifest.story_artifacts
    assert "/webhooks/stripe" in manifest.story_artifacts

    refute Enum.any?(manifest.first_run.commands, &String.contains?(&1, "Seed"))
  end
end
