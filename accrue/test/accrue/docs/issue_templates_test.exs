defmodule Accrue.Docs.IssueTemplatesTest do
  use ExUnit.Case, async: true

  @issue_template_dir Path.expand("../../../../.github/ISSUE_TEMPLATE", __DIR__)
  @config_path Path.join(@issue_template_dir, "config.yml")
  @expected_forms %{
    "bug.yml" => "[Bug]: ",
    "integration-problem.yml" => "[Integration]: ",
    "documentation-gap.yml" => "[Docs]: ",
    "feature-request.yml" => "[Feature]: "
  }
  @warning_phrases [
    "Do not paste API keys",
    "webhook secrets",
    "production payloads",
    "customer data",
    "PII"
  ]
  @public_surfaces [
    "MyApp.Billing",
    "Accrue.Webhook.Handler",
    "Accrue.Auth",
    "First Hour",
    "Troubleshooting"
  ]
  @forbidden_surfaces [
    "Accrue.Billing.Customer",
    "Accrue.Webhook.WebhookEvent",
    "Accrue.Events.Event",
    "Reducer",
    "reducer modules",
    "accrue_webhook_events"
  ]

  test "chooser config disables blank issues and routes support correctly" do
    config = File.read!(@config_path)

    assert config =~ "blank_issues_enabled: false"
    assert config =~ "contact_links"
    assert config =~ "SECURITY.md"
    assert config =~ "CONTRIBUTING.md"
  end

  test "exactly four approved issue forms exist" do
    forms =
      @issue_template_dir
      |> Path.join("*.yml")
      |> Path.wildcard()
      |> Enum.reject(&(Path.basename(&1) == "config.yml"))
      |> Enum.map(&Path.basename/1)
      |> Enum.sort()

    assert forms == Enum.sort(Map.keys(@expected_forms))
  end

  test "all forms preserve no-secrets warnings and public-boundary wording" do
    Enum.each(@expected_forms, fn {file_name, expected_title} ->
      contents = file_name |> form_path() |> File.read!()

      assert contents =~ ~s|title: "#{expected_title}"|
      assert contents =~ "needs-triage"

      Enum.each(@warning_phrases, fn phrase ->
        assert contents =~ phrase
      end)

      warning_index = index_of(contents, "Do not paste API keys")
      textarea_index = index_of(contents, "type: textarea")

      assert warning_index
      assert textarea_index
      assert warning_index < textarea_index

      Enum.each(@forbidden_surfaces, fn surface ->
        refute contents =~ surface
      end)
    end)
  end

  test "forms cover the approved taxonomy and guide links" do
    bug = File.read!(form_path("bug.yml"))
    integration = File.read!(form_path("integration-problem.yml"))
    docs_gap = File.read!(form_path("documentation-gap.yml"))
    feature = File.read!(form_path("feature-request.yml"))

    assert bug =~ "bug"
    assert bug =~ "MyApp.Billing"
    assert bug =~ "/billing"
    assert bug =~ "Accrue.Webhook.Handler"
    assert bug =~ "Accrue.Auth"

    assert integration =~ "integration"
    assert integration =~ "accrue/guides/first_hour.md"
    assert integration =~ "accrue/guides/troubleshooting.md"
    assert integration =~ "/webhooks/stripe"
    assert integration =~ "/billing"

    assert docs_gap =~ "documentation"
    assert docs_gap =~ "Doc path or page"
    assert docs_gap =~ "accrue/guides/first_hour.md"
    assert docs_gap =~ "accrue/guides/troubleshooting.md"

    assert feature =~ "feature-request"
    assert feature =~ "User problem"
    assert feature =~ "Current workaround"
    assert feature =~ "Affected public API surface"
    assert feature =~ "Why does this belong in Accrue?"

    Enum.each(@public_surfaces, fn surface ->
      combined = Enum.join([bug, integration, docs_gap, feature], "\n")
      assert combined =~ surface
    end)
  end

  defp form_path(file_name), do: Path.join(@issue_template_dir, file_name)

  defp index_of(binary, pattern) do
    case :binary.match(binary, pattern) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
