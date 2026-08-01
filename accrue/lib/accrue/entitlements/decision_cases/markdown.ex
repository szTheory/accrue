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

      case File.read(path) do
        {:ok, ^contents} ->
          drifted

        {:ok, actual} when relative == @offline_relative ->
          offline_drift(path, actual, contents) ++ drifted

        _ ->
          [path | drifted]
      end
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
    |> ordered_json()
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
    |> ordered_json()
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
  end

  defp offline_drift(path, actual, expected) do
    with {:ok, %{"vectors" => actual_vectors}} <- Jason.decode(actual),
         {:ok, %{"vectors" => expected_vectors}} <- Jason.decode(expected) do
      expected_by_id = Map.new(expected_vectors, &{&1["id"], &1})

      missing_ids =
        expected_vectors
        |> Enum.map(& &1["id"])
        |> MapSet.new()
        |> MapSet.difference(MapSet.new(Enum.map(actual_vectors, & &1["id"])))
        |> Enum.map(fn id -> "#{path}: missing vector #{id}" end)

      missing_paths = if missing_ids == [], do: [], else: [path]

      actual_vectors
      |> Enum.flat_map(fn vector ->
        case Map.fetch(expected_by_id, vector["id"]) do
          {:ok, expected_vector} ->
            for field <- ["expected_verification", "expected_reason", "expected_cache_disposition"],
                vector[field] != expected_vector[field],
                do: "#{path}: vector #{vector["id"]} #{field}"

          :error ->
            ["#{path}: unknown vector #{vector["id"]}"]
        end
      end)
      |> Kernel.++(missing_paths ++ missing_ids)
      |> case do
        [] -> []
        diagnostics -> diagnostics
      end
    else
      _ -> [path]
    end
  end

  defp offline_specs do
    allow = "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6ImFsbG93In0.JFnJfG7Tsj8imq2WkdKKRSAX3EdENW6FeFUkgwMpFT0Atgb3B0S9zrcRRf-UjmjfF1WMu8eBdZ1hs2GzC0kZmw"
    denial = "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6ImRlbnkifQ.IzhX4g4ftHpPUVHnjBGA47f0QX7IuOCUva9P-jvVH0Wv2lL1KNoCmaunfA4-BIWtQJ4F3uU3_F5xYDgWS1NVaA"

    [
      %{id: "valid_allow", case_id: "reconnect_positive_replacement", compact_jws: allow, expected_verification: "accept", expected_reason: "ok", expected_cache_disposition: "allow"},
      %{id: "valid_signed_denial", case_id: "reconnect_denied_tombstone", compact_jws: denial, expected_verification: "accept", expected_reason: "ok", expected_cache_disposition: "deny"},
      %{id: "wrong_signature", case_id: "invalid_apple_evidence", compact_jws: String.replace_suffix(allow, "Zmw", "Ymw"), expected_verification: "reject", expected_reason: "signature", expected_cache_disposition: "allow"},
      %{id: "wrong_key", case_id: "apple_token_mismatch", compact_jws: allow, expected_verification: "reject", expected_reason: "key", expected_cache_disposition: "allow"},
      %{id: "wrong_device", case_id: "unmapped_verified_product", compact_jws: allow, expected_verification: "reject", expected_reason: "device", expected_cache_disposition: "allow"},
      %{id: "rollback", case_id: "out_of_order_positive_after_revoke", compact_jws: allow, expected_verification: "reject", expected_reason: "rollback", expected_cache_disposition: "deny"},
      %{id: "older_iat", case_id: "duplicate_provider_event", compact_jws: allow, expected_verification: "reject", expected_reason: "iat", expected_cache_disposition: "deny"},
      %{id: "stale_freshness", case_id: "stale_offline_continuity", compact_jws: allow, expected_verification: "reject", expected_reason: "freshness", expected_cache_disposition: "allow"},
      %{id: "deny_precedence", case_id: "all_grants_revoked", compact_jws: denial, expected_verification: "accept", expected_reason: "ok", expected_cache_disposition: "deny"},
      %{id: "fault_before_replace", case_id: "atomic_transaction_boundary", compact_jws: allow, expected_verification: "accept", expected_reason: "fault_before_replace", expected_cache_disposition: "deny", fault_point: "before_rename"},
      %{id: "fault_after_replace", case_id: "stripe_revoked_apple_survives", compact_jws: denial, expected_verification: "accept", expected_reason: "fault_after_replace", expected_cache_disposition: "deny", fault_point: "after_rename"},
      %{id: "wrong_account", case_id: "apple_token_mismatch", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJhY2NvdW50X2lkIjoiYWNjb3VudC05OTkiLCJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOiJ0ZXN0LXRodW1icHJpbnQiLCJkZXZpY2VfaWQiOiJkZXZpY2UtMTIzIiwiZGlzcG9zaXRpb24iOiJhbGxvdyIsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJyZXZpc2lvbiI6NSwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50In0.43qdmSN-I2l2HZdFom_fQonTndBVyteuUa2LO0F_QwojXrVR9ZrvtBZXmnABBwSSzdyM7iBPdgoTqFnA8b-YBg", expected_verification: "reject", expected_reason: "account", expected_cache_disposition: "allow"},
      %{id: "wrong_audience", case_id: "invalid_apple_evidence", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJhY2NvdW50X2lkIjoiYWNjb3VudC0xMjMiLCJhdWQiOiJ3cm9uZy1hdWRpZW5jZSIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsImRldmljZV9pZCI6ImRldmljZS0xMjMiLCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZnJlc2hfdW50aWwiOjE3MDAwMDM2MDAsImlhdCI6MTcwMDAwMDAwMCwiaXNzIjoiYWNjcnVlLnRlc3Qub2ZmbGluZSIsInJldmlzaW9uIjo1LCJ0eXAiOiJhY2NydWUtZW50aXRsZW1lbnQifQ.6v1LxZrviSLxPXSgMaV1elIYkrBChMSHyiN8vrdsf0WvocJkMul69NnWaBVdWc7GpriznSVEfSiz_gSpQEUbnA", expected_verification: "reject", expected_reason: "audience", expected_cache_disposition: "allow"},
      %{id: "wrong_type", case_id: "unmapped_verified_product", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoid3JvbmctdHlwZSIsImFjY291bnRfaWQiOiJhY2NvdW50LTEyMyIsImRldmljZV9pZCI6ImRldmljZS0xMjMiLCJjbmYiOiJ0ZXN0LXRodW1icHJpbnQiLCJyZXZpc2lvbiI6NSwiaWF0IjoxNzAwMDAwMDAwLCJmcmVzaF91bnRpbCI6MTcwMDAwMzYwMCwiZGlzcG9zaXRpb24iOiJhbGxvdyJ9.BaZWg4FGrXhFJUh-doqyd41kMl6VhCbKlJcyxkWDhbqvc6bg3dKwGT1U6eRAXrGMgu1IKWa8ZVTEHjd31QK3LQ", expected_verification: "reject", expected_reason: "type", expected_cache_disposition: "allow"},
      %{id: "wrong_algorithm", case_id: "invalid_apple_evidence", compact_jws: "eyJhbGciOiJIUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJhY2NvdW50X2lkIjoiYWNjb3VudC0xMjMiLCJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOiJ0ZXN0LXRodW1icHJpbnQiLCJkZXZpY2VfaWQiOiJkZXZpY2UtMTIzIiwiZGlzcG9zaXRpb24iOiJhbGxvdyIsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3VlLnRlc3Qub2ZmbGluZSIsInJldmlzaW9uIjo1LCJ0eXAiOiJhY2NydWUtZW50aXRsZW1lbnQifQ.P1Qfjf00tfTI9dvtJojQpY_QjeOkGXygt-nQJhuyILMFrtNTspKdbfk8H1yTep10t6jUl-WH2w6ECIbrOSnpTQ", expected_verification: "reject", expected_reason: "algorithm", expected_cache_disposition: "allow"},
      %{id: "malformed_compact", case_id: "invalid_apple_evidence", compact_jws: "not-a-jws", expected_verification: "reject", expected_reason: "malformed", expected_cache_disposition: "allow"},
      %{id: "malformed_revision", case_id: "out_of_order_positive_after_revoke", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjoiZml2ZSIsImlhdCI6MTcwMDAwMDAwMCwiZnJlc2hfdW50aWwiOjE3MDAwMDM2MDAsImRpc3Bvc2l0aW9uIjoiYWxsb3cifQ.3XNemG0CWFPnLLNZDsxVvq6DhnOX-5_9e7jHsFJkI5G0En3WhazkYS_JAuxwoaLlM4OvlpjuQLk65foUU27qlA", expected_verification: "reject", expected_reason: "revision", expected_cache_disposition: "allow"},
      %{id: "malformed_iat", case_id: "duplicate_provider_event", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOiJub3ciLCJmcmVzaF91bnRpbCI6MTcwMDAwMzYwMCwiZGlzcG9zaXRpb24iOiJhbGxvdyJ9.Sy1U_J0PAO1zeYDn4Tp55OJo7qqdDZVjyMijy-oFSlP5lPFoVXf0NqKHA8E-IVMd1UQkel1h9NCnAuyE6spvNw", expected_verification: "reject", expected_reason: "iat", expected_cache_disposition: "allow"},
      %{id: "malformed_freshness", case_id: "stale_offline_continuity", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoibGF0ZXIiLCJkaXNwb3NpdGlvbiI6ImFsbG93In0.8Lz7r30EHYUzzgBcHmmlZUTb4kkUN3C0us9DIVZZul6LaV0CBUNGlREw37pgp2RDOcPB6Y1paGhdMlLbdSmFkg", expected_verification: "reject", expected_reason: "freshness", expected_cache_disposition: "allow"},
      %{id: "unknown_disposition", case_id: "reconnect_positive_replacement", compact_jws: "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6Im1heWJlIn0.IITy6KiR_eQ-OxZ5CdsQ_byEefEfWaEdI2-AFiMygkqHufz6w4lbxtO3sHSBleOIbnRgybpSUKotJgw4MFhY6Q", expected_verification: "reject", expected_reason: "disposition", expected_cache_disposition: "allow"}
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

  # Fixture bytes are versioned contract material, so map traversal must not leak
  # the VM's map ordering into checked-in JSON.
  defp ordered_json(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, ordered_json(value)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Jason.OrderedObject.new()
  end

  defp ordered_json(list) when is_list(list), do: Enum.map(list, &ordered_json/1)
  defp ordered_json(value), do: value

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
