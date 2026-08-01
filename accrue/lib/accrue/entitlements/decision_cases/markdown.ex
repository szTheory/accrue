defmodule Accrue.Entitlements.DecisionCases.Markdown do
  @moduledoc false

  alias Accrue.Entitlements.DecisionCases

  def render(cases) do
    rows =
      cases
      |> Enum.sort_by(& &1.id)
      |> Enum.map(fn case_data ->
        expected = case_data.expected

        "| `#{case_data.id}` | #{case_data.evidence.rail}/#{case_data.evidence.environment} | #{expected.disposition} | #{expected.eligibility} | #{expected.lease} | `#{expected.reason}` |"
      end)

    [
      "# v1.59 Entitlement Decision Contract",
      "",
      "This is a derived non-runtime contract. It formats the canonical data-only Elixir corpus; it is not a reducer or public entitlement API.",
      "",
      "Contract version: `#{DecisionCases.version()}`",
      "",
      "| Case ID | Qualified evidence | Source disposition | Purchase eligibility | Continuity | Support reason |",
      "| --- | --- | --- | --- | --- | --- |",
      rows,
      ""
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end
end

defmodule Accrue.Entitlements.DecisionCases.Export do
  @moduledoc false

  alias Accrue.Entitlements.DecisionCases
  alias Accrue.Entitlements.DecisionCases.Markdown

  @markdown_relative ".planning/research/v1.59-DECISION-TABLE.md"
  @json_relative "accrue/priv/entitlements/v1.59-decision-cases.json"
  @offline_relative "accrue/priv/entitlements/v1.59-offline-golden-vectors.json"

  def write(root), do: write_files(root, generated())

  def check(root) do
    generated()
    |> Enum.reduce([], fn {relative, contents}, drifted ->
      path = Path.join(root, relative)
      if File.read(path) == {:ok, contents}, do: drifted, else: [path | drifted]
    end)
    |> case do
      [] -> :ok
      paths -> {:error, Enum.reverse(paths)}
    end
  end

  def json(cases) do
    %{
      contract_version: DecisionCases.version(),
      cases: Enum.map(Enum.sort_by(cases, & &1.id), &to_map/1)
    }
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
  end

  def offline_vectors do
    canonical = Map.new(DecisionCases.all(), &{&1.id, &1})

    offline_specs()
    |> Enum.map(fn spec ->
      case_data = Map.fetch!(canonical, spec.case_id)

      %{
        id: spec.id,
        case_id: case_data.id,
        contract_version: case_data.contract_version,
        expected_disposition: Atom.to_string(case_data.expected.disposition),
        compact_jws: spec.compact_jws,
        expected_verification: spec.expected_verification,
        expected_reason: spec.expected_reason,
        expected_cache_disposition: spec.expected_cache_disposition,
        fault_point: spec[:fault_point]
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
  end

  defp generated do
    cases = DecisionCases.all()

    [
      {@markdown_relative, Markdown.render(cases)},
      {@json_relative, json(cases)},
      {@offline_relative, offline_json()}
    ]
  end

  defp offline_json do
    %{
      schema_version: "v1.59",
      purpose: "TEST-ONLY signed offline entitlement verification corpus; never configure this key for issuance.",
      vectors: offline_vectors()
    }
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
  end

  defp offline_specs do
    allow = "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6ImFsbG93In0.JFnJfG7Tsj8imq2WkdKKRSAX3EdENW6FeFUkgwMpFT0Atgb3B0S9zrcRRf-UjmjfF1WMu8eBdZ1hs2GzC0kZmw"
    denial = "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6ImRlbnkifQ.IzhX4g4ftHpPUVHnjBGA47f0QX7IuOCUva9P-jvVH0Wv2lL1KNoCmaunfA4-BIWtQJ4F3uU3_F5xYDgWS1NVaA"

    [
      %{id: "valid_allow", case_id: "reconnect_positive_replacement", compact_jws: allow, expected_verification: "accept", expected_reason: "ok", expected_cache_disposition: "allow"},
      %{id: "valid_signed_denial", case_id: "reconnect_denied_tombstone", compact_jws: denial, expected_verification: "accept", expected_reason: "ok", expected_cache_disposition: "deny"},
      %{id: "wrong_signature", case_id: "invalid_apple_evidence", compact_jws: allow <> "x", expected_verification: "reject", expected_reason: "signature", expected_cache_disposition: "allow"},
      %{id: "wrong_key", case_id: "apple_token_mismatch", compact_jws: allow, expected_verification: "reject", expected_reason: "key", expected_cache_disposition: "allow"},
      %{id: "wrong_device", case_id: "unmapped_verified_product", compact_jws: allow, expected_verification: "reject", expected_reason: "device", expected_cache_disposition: "allow"},
      %{id: "rollback", case_id: "out_of_order_positive_after_revoke", compact_jws: allow, expected_verification: "reject", expected_reason: "rollback", expected_cache_disposition: "deny"},
      %{id: "older_iat", case_id: "duplicate_provider_event", compact_jws: allow, expected_verification: "reject", expected_reason: "iat", expected_cache_disposition: "deny"},
      %{id: "stale_freshness", case_id: "stale_offline_continuity", compact_jws: allow, expected_verification: "reject", expected_reason: "freshness", expected_cache_disposition: "allow"},
      %{id: "deny_precedence", case_id: "all_grants_revoked", compact_jws: denial, expected_verification: "accept", expected_reason: "ok", expected_cache_disposition: "deny"},
      %{id: "fault_before_replace", case_id: "atomic_transaction_boundary", compact_jws: allow, expected_verification: "accept", expected_reason: "fault_before_replace", expected_cache_disposition: "allow", fault_point: "before_rename"},
      %{id: "fault_after_replace", case_id: "stripe_revoked_apple_survives", compact_jws: denial, expected_verification: "accept", expected_reason: "fault_after_replace", expected_cache_disposition: "deny", fault_point: "after_rename"}
    ]
  end

  defp write_files(root, files) do
    Enum.each(files, fn {relative, contents} ->
      path = Path.join(root, relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
    end)

    :ok
  end

  defp to_map(case_data) do
    %{
      id: case_data.id,
      contract_version: case_data.contract_version,
      evidence: Map.from_struct(case_data.evidence),
      prior: Map.from_struct(case_data.prior),
      ordering: Map.from_struct(case_data.ordering),
      expected: Map.from_struct(case_data.expected)
    }
  end
end
