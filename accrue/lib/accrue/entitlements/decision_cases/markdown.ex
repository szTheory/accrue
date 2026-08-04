defmodule Accrue.Entitlements.DecisionCases.Markdown do
  @moduledoc false

  alias Accrue.Entitlements.DecisionCases

  def render(cases) do
    rows =
      cases
      |> Enum.sort_by(& &1.id)
      |> Enum.map(fn case_data ->
        expected = case_data.expected

        "| `#{case_data.id}` | #{case_data.evidence.rail}/#{case_data.evidence.environment} | #{expected.disposition} | #{expected.eligibility} | #{expected.lease} | #{expected.continuity} | `#{expected.reason}` |"
      end)

    [
      "# v1.59 Entitlement Decision Contract",
      "",
      "This is a derived non-runtime contract. It formats the canonical data-only Elixir corpus; it is not a reducer or public entitlement API.",
      "",
      "Contract version: `#{DecisionCases.version()}`",
      "",
      "| Case ID | Qualified evidence | Source disposition | Purchase eligibility | Lease | Continuity | Support reason |",
      "| --- | --- | --- | --- | --- | --- | --- |",
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

    # Keeps the retired fixture recipe available for historical corpus decoding
    # without making it part of the generated v1.59 public profile.
    if false, do: offline_specs()

    offline_specs_v159()
    |> Enum.map(fn spec ->
      case_data = Map.fetch!(canonical, spec.case_id)

      %{
        id: spec.id,
        case_id: case_data.id,
        contract_version: case_data.contract_version,
        expected_disposition: Atom.to_string(case_data.expected.disposition),
        compact_jws: spec.compact_jws,
        expected_claims: spec.expected_claims,
        verification_context: spec.verification_context,
        expected_state: spec.expected_state,
        expected_reason: spec.expected_reason,
        expected_next_action: spec.expected_next_action,
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
      protocol_version: "v1.59",
      purpose:
        "TEST-ONLY synthetic public-proof corpus; private signing material is confined to test support and never configured for issuance.",
      public_jwks: %{"keys" => [public_test_key()]},
      vectors: offline_vectors()
    }
    |> ordered_json()
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
  end

  @top_level_keys MapSet.new([
                    "schema_version",
                    "protocol_version",
                    "purpose",
                    "public_jwks",
                    "vectors"
                  ])
  @vector_fields [
    "id",
    "case_id",
    "contract_version",
    "expected_disposition",
    "compact_jws",
    "expected_verification",
    "expected_reason",
    "expected_cache_disposition",
    "fault_point"
  ]

  defp offline_drift(path, actual, expected) do
    with {:ok, actual_corpus} <- Jason.decode(actual),
         {:ok, expected_corpus} <- Jason.decode(expected),
         true <- is_map(actual_corpus) and is_map(expected_corpus),
         {:ok, actual_vectors} <- fetch_vectors(actual_corpus),
         {:ok, expected_vectors} <- fetch_vectors(expected_corpus) do
      diagnostics =
        top_level_drift(path, actual_corpus, expected_corpus) ++
          duplicate_id_drift(path, actual_vectors) ++
          vector_identity_drift(path, actual_vectors, expected_vectors) ++
          vector_content_drift(path, actual_vectors, expected_vectors)

      if diagnostics == [], do: [], else: [path | diagnostics]
    else
      _ -> [path]
    end
  end

  defp fetch_vectors(%{"vectors" => vectors}) when is_list(vectors), do: {:ok, vectors}
  defp fetch_vectors(_), do: :error

  defp top_level_drift(path, actual, expected) do
    keys = Map.keys(actual) |> MapSet.new()

    key_diagnostics(path, keys, @top_level_keys) ++
      for field <- ["schema_version", "protocol_version", "purpose", "public_jwks"],
          actual[field] != expected[field],
          do: "#{path}: #{field}"
  end

  defp duplicate_id_drift(path, vectors) do
    vectors
    |> Enum.map(&Map.get(&1, "id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.filter(fn {_id, count} -> count > 1 end)
    |> Enum.map(fn {id, _count} -> "#{path}: duplicate vector #{id}" end)
    |> Enum.sort()
  end

  defp vector_identity_drift(path, actual_vectors, expected_vectors) do
    actual_ids = MapSet.new(Enum.map(actual_vectors, &Map.get(&1, "id")))
    expected_ids = MapSet.new(Enum.map(expected_vectors, &Map.get(&1, "id")))

    missing =
      MapSet.difference(expected_ids, actual_ids)
      |> Enum.sort()
      |> Enum.map(&"#{path}: missing vector #{&1}")

    extra =
      MapSet.difference(actual_ids, expected_ids)
      |> Enum.sort()
      |> Enum.map(&"#{path}: unexpected vector #{&1}")

    missing ++ extra
  end

  defp vector_content_drift(path, actual_vectors, expected_vectors) do
    Enum.zip(actual_vectors, expected_vectors)
    |> Enum.flat_map(fn {actual, expected} ->
      vector_id = Map.get(expected, "id", "unknown")

      if is_map(actual) do
        actual_keys = Map.keys(actual) |> MapSet.new()
        expected_keys = Map.keys(expected) |> MapSet.new()

        key_diagnostics(path <> ": vector #{vector_id}", actual_keys, expected_keys) ++
          for field <- @vector_fields,
              Map.get(actual, field) != Map.get(expected, field),
              do: "#{path}: vector #{vector_id} #{field}"
      else
        ["#{path}: vector #{vector_id}"]
      end
    end)
  end

  defp key_diagnostics(path, actual_keys, expected_keys) do
    missing =
      MapSet.difference(expected_keys, actual_keys)
      |> Enum.sort()
      |> Enum.map(&"#{path} missing key #{&1}")

    extra =
      MapSet.difference(actual_keys, expected_keys)
      |> Enum.sort()
      |> Enum.map(&"#{path} unexpected key #{&1}")

    missing ++ extra
  end

  @compile {:nowarn_unused_function, [{:offline_specs, 0}]}
  defp offline_specs do
    allow =
      "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6ImFsbG93In0.JFnJfG7Tsj8imq2WkdKKRSAX3EdENW6FeFUkgwMpFT0Atgb3B0S9zrcRRf-UjmjfF1WMu8eBdZ1hs2GzC0kZmw"

    denial =
      "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6ImRlbnkifQ.IzhX4g4ftHpPUVHnjBGA47f0QX7IuOCUva9P-jvVH0Wv2lL1KNoCmaunfA4-BIWtQJ4F3uU3_F5xYDgWS1NVaA"

    [
      %{
        id: "valid_allow",
        case_id: "reconnect_positive_replacement",
        compact_jws: allow,
        expected_verification: "accept",
        expected_reason: "ok",
        expected_cache_disposition: "allow"
      },
      %{
        id: "valid_signed_denial",
        case_id: "reconnect_denied_tombstone",
        compact_jws: denial,
        expected_verification: "accept",
        expected_reason: "ok",
        expected_cache_disposition: "deny"
      },
      %{
        id: "wrong_signature",
        case_id: "invalid_apple_evidence",
        compact_jws: String.replace_suffix(allow, "Zmw", "Ymw"),
        expected_verification: "reject",
        expected_reason: "signature",
        expected_cache_disposition: "allow"
      },
      %{
        id: "wrong_key",
        case_id: "apple_token_mismatch",
        compact_jws: allow,
        expected_verification: "reject",
        expected_reason: "key",
        expected_cache_disposition: "allow"
      },
      %{
        id: "wrong_device",
        case_id: "unmapped_verified_product",
        compact_jws: allow,
        expected_verification: "reject",
        expected_reason: "device",
        expected_cache_disposition: "allow"
      },
      %{
        id: "rollback",
        case_id: "out_of_order_positive_after_revoke",
        compact_jws: allow,
        expected_verification: "reject",
        expected_reason: "rollback",
        expected_cache_disposition: "deny"
      },
      %{
        id: "older_iat",
        case_id: "duplicate_provider_event",
        compact_jws: allow,
        expected_verification: "reject",
        expected_reason: "iat",
        expected_cache_disposition: "deny"
      },
      %{
        id: "stale_freshness",
        case_id: "stale_offline_continuity",
        compact_jws: allow,
        expected_verification: "reject",
        expected_reason: "freshness",
        expected_cache_disposition: "allow"
      },
      %{
        id: "deny_precedence",
        case_id: "all_grants_revoked",
        compact_jws: denial,
        expected_verification: "accept",
        expected_reason: "ok",
        expected_cache_disposition: "deny"
      },
      %{
        id: "fault_before_replace",
        case_id: "atomic_transaction_boundary",
        compact_jws: allow,
        expected_verification: "accept",
        expected_reason: "fault_before_replace",
        expected_cache_disposition: "deny",
        fault_point: "before_rename"
      },
      %{
        id: "fault_after_replace",
        case_id: "stripe_revoked_apple_survives",
        compact_jws: denial,
        expected_verification: "accept",
        expected_reason: "fault_after_replace",
        expected_cache_disposition: "deny",
        fault_point: "after_rename"
      },
      %{
        id: "wrong_account",
        case_id: "apple_token_mismatch",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJhY2NvdW50X2lkIjoiYWNjb3VudC05OTkiLCJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOiJ0ZXN0LXRodW1icHJpbnQiLCJkZXZpY2VfaWQiOiJkZXZpY2UtMTIzIiwiZGlzcG9zaXRpb24iOiJhbGxvdyIsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJyZXZpc2lvbiI6NSwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50In0.43qdmSN-I2l2HZdFom_fQonTndBVyteuUa2LO0F_QwojXrVR9ZrvtBZXmnABBwSSzdyM7iBPdgoTqFnA8b-YBg",
        expected_verification: "reject",
        expected_reason: "account",
        expected_cache_disposition: "allow"
      },
      %{
        id: "wrong_audience",
        case_id: "invalid_apple_evidence",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJhY2NvdW50X2lkIjoiYWNjb3VudC0xMjMiLCJhdWQiOiJ3cm9uZy1hdWRpZW5jZSIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsImRldmljZV9pZCI6ImRldmljZS0xMjMiLCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZnJlc2hfdW50aWwiOjE3MDAwMDM2MDAsImlhdCI6MTcwMDAwMDAwMCwiaXNzIjoiYWNjcnVlLnRlc3Qub2ZmbGluZSIsInJldmlzaW9uIjo1LCJ0eXAiOiJhY2NydWUtZW50aXRsZW1lbnQifQ.6v1LxZrviSLxPXSgMaV1elIYkrBChMSHyiN8vrdsf0WvocJkMul69NnWaBVdWc7GpriznSVEfSiz_gSpQEUbnA",
        expected_verification: "reject",
        expected_reason: "audience",
        expected_cache_disposition: "allow"
      },
      %{
        id: "wrong_type",
        case_id: "unmapped_verified_product",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoid3JvbmctdHlwZSIsImFjY291bnRfaWQiOiJhY2NvdW50LTEyMyIsImRldmljZV9pZCI6ImRldmljZS0xMjMiLCJjbmYiOiJ0ZXN0LXRodW1icHJpbnQiLCJyZXZpc2lvbiI6NSwiaWF0IjoxNzAwMDAwMDAwLCJmcmVzaF91bnRpbCI6MTcwMDAwMzYwMCwiZGlzcG9zaXRpb24iOiJhbGxvdyJ9.BaZWg4FGrXhFJUh-doqyd41kMl6VhCbKlJcyxkWDhbqvc6bg3dKwGT1U6eRAXrGMgu1IKWa8ZVTEHjd31QK3LQ",
        expected_verification: "reject",
        expected_reason: "type",
        expected_cache_disposition: "allow"
      },
      %{
        id: "wrong_algorithm",
        case_id: "invalid_apple_evidence",
        compact_jws:
          "eyJhbGciOiJIUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJhY2NvdW50X2lkIjoiYWNjb3VudC0xMjMiLCJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOiJ0ZXN0LXRodW1icHJpbnQiLCJkZXZpY2VfaWQiOiJkZXZpY2UtMTIzIiwiZGlzcG9zaXRpb24iOiJhbGxvdyIsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3VlLnRlc3Qub2ZmbGluZSIsInJldmlzaW9uIjo1LCJ0eXAiOiJhY2NydWUtZW50aXRsZW1lbnQifQ.P1Qfjf00tfTI9dvtJojQpY_QjeOkGXygt-nQJhuyILMFrtNTspKdbfk8H1yTep10t6jUl-WH2w6ECIbrOSnpTQ",
        expected_verification: "reject",
        expected_reason: "algorithm",
        expected_cache_disposition: "allow"
      },
      %{
        id: "malformed_compact",
        case_id: "invalid_apple_evidence",
        compact_jws: "not-a-jws",
        expected_verification: "reject",
        expected_reason: "malformed",
        expected_cache_disposition: "allow"
      },
      %{
        id: "malformed_revision",
        case_id: "out_of_order_positive_after_revoke",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjoiZml2ZSIsImlhdCI6MTcwMDAwMDAwMCwiZnJlc2hfdW50aWwiOjE3MDAwMDM2MDAsImRpc3Bvc2l0aW9uIjoiYWxsb3cifQ.3XNemG0CWFPnLLNZDsxVvq6DhnOX-5_9e7jHsFJkI5G0En3WhazkYS_JAuxwoaLlM4OvlpjuQLk65foUU27qlA",
        expected_verification: "reject",
        expected_reason: "revision",
        expected_cache_disposition: "allow"
      },
      %{
        id: "malformed_iat",
        case_id: "duplicate_provider_event",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOiJub3ciLCJmcmVzaF91bnRpbCI6MTcwMDAwMzYwMCwiZGlzcG9zaXRpb24iOiJhbGxvdyJ9.Sy1U_J0PAO1zeYDn4Tp55OJo7qqdDZVjyMijy-oFSlP5lPFoVXf0NqKHA8E-IVMd1UQkel1h9NCnAuyE6spvNw",
        expected_verification: "reject",
        expected_reason: "iat",
        expected_cache_disposition: "allow"
      },
      %{
        id: "malformed_freshness",
        case_id: "stale_offline_continuity",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoibGF0ZXIiLCJkaXNwb3NpdGlvbiI6ImFsbG93In0.8Lz7r30EHYUzzgBcHmmlZUTb4kkUN3C0us9DIVZZul6LaV0CBUNGlREw37pgp2RDOcPB6Y1paGhdMlLbdSmFkg",
        expected_verification: "reject",
        expected_reason: "freshness",
        expected_cache_disposition: "allow"
      },
      %{
        id: "unknown_disposition",
        case_id: "reconnect_positive_replacement",
        compact_jws:
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSJ9.eyJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwiYXVkIjoiYWNjcnVlLW9mZmxpbmUtY2xpZW50IiwidHlwIjoiYWNjcnVlLWVudGl0bGVtZW50IiwiYWNjb3VudF9pZCI6ImFjY291bnQtMTIzIiwiZGV2aWNlX2lkIjoiZGV2aWNlLTEyMyIsImNuZiI6InRlc3QtdGh1bWJwcmludCIsInJldmlzaW9uIjo1LCJpYXQiOjE3MDAwMDAwMDAsImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJkaXNwb3NpdGlvbiI6Im1heWJlIn0.IITy6KiR_eQ-OxZ5CdsQ_byEefEfWaEdI2-AFiMygkqHufz6w4lbxtO3sHSBleOIbnRgybpSUKotJgw4MFhY6Q",
        expected_verification: "reject",
        expected_reason: "disposition",
        expected_cache_disposition: "allow"
      }
    ]
  end

  # These compact proofs are deterministic published test vectors generated from the
  # TEST-ONLY private fixture. The checked-in corpus contains only the public JWK.
  defp offline_specs_v159 do
    allow =
      "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJqdGkiOiJ0ZXN0LXByb29mLWFsbG93IiwibmJmIjoxNzAwMDAwMDAwLCJwbGFucyI6WyJwcm8iXSwicXVhbnRpdGllcyI6eyJkb3dubG9hZHMiOjN9LCJyZXZpc2lvbiI6NSwic3ViIjoic3ludGhldGljLWFjY291bnQiLCJ2ZXJzaW9uIjoidjEuNTkifQ.MiJ1s4A9RFTT7H45va6XapmgKrAfH483j1Qj425tCNsAi1k6YcHhagtqIc0f4CAH7kYIvxTNGIo3sRBoDoTAAw"

    deny =
      "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkZW5pYWxfcmVhc29uIjoiYWNjZXNzX3VuYXZhaWxhYmxlIiwiZGlzcG9zaXRpb24iOiJkZW55IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6W10sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJqdGkiOiJ0ZXN0LXByb29mLWRlbnkiLCJuYmYiOjE3MDAwMDAwMDAsInBsYW5zIjpbXSwicXVhbnRpdGllcyI6e30sInJldmlzaW9uIjo1LCJzdWIiOiJzeW50aGV0aWMtYWNjb3VudCIsInZlcnNpb24iOiJ2MS41OSJ9.QL9Fjm96nx4i-cJSWwGrZkV2aSGtbJdtkHDlUwOv93NRQOFRcErWDOzUjWQBm3jm4FSYd2z10res_q6XbV3l5g"

    base = %{
      issuer: "accrue.test.offline",
      audience: "accrue-offline-client",
      account_subject: "synthetic-account",
      installation_id: "synthetic-installation",
      device_thumbprint: "IVw958D_sxKYMg6iCHQs-vmxkOVIiRwwKlfeV6ykrCg",
      now: 1_700_000_001,
      clock_high_water: %{},
      accepted_revision: 0,
      accepted_disposition: nil,
      accepted_iat: 0,
      accepted_fresh_until: 0
    }

    allow_claims = claims_for(allow)
    deny_claims = claims_for(deny)

    spec = fn id, case_id, compact, context, state, reason, action, cache, claims ->
      %{
        id: id,
        case_id: case_id,
        compact_jws: compact,
        verification_context: context,
        expected_claims: claims,
        expected_state: state,
        expected_reason: reason,
        expected_next_action: action,
        expected_cache_disposition: cache
      }
    end

    # Every negative below has its own signed (or deliberately malformed) compact
    # input and its own context.  These are not labels for one shared bad token:
    # the corpus is the language-neutral proof that each D-09/D-12 branch is live.
    [
      spec.(
        "valid_allow",
        "reconnect_positive_replacement",
        allow,
        base,
        "fresh",
        "ok",
        "none",
        "allow",
        allow_claims
      ),
      spec.(
        "valid_signed_denial",
        "reconnect_denied_tombstone",
        deny,
        base,
        "denied",
        "signed_denial",
        "reconnect_required",
        "deny",
        deny_claims
      ),
      spec.(
        "stale_at_freshness",
        "stale_offline_continuity",
        allow,
        %{base | now: 1_700_003_600},
        "stale_offline",
        "revalidation_due",
        "reconnect_required",
        "allow",
        allow_claims
      ),
      spec.(
        "stale_beyond_72h",
        "stale_offline_continuity",
        allow,
        %{base | now: 1_700_262_800},
        "stale_offline",
        "revalidation_due",
        "reconnect_required",
        "allow",
        allow_claims
      ),
      spec.(
        "hard_expired",
        "invalid_apple_evidence",
        allow,
        %{base | now: 1_702_592_000},
        "invalid",
        "hard_expired",
        "reconnect_required",
        "allow",
        %{}
      ),
      spec.(
        "wrong_issuer",
        "invalid_apple_evidence",
        allow,
        %{base | issuer: "wrong"},
        "invalid",
        "wrong_issuer",
        "reconnect_required",
        "allow",
        %{}
      ),
      spec.(
        "wrong_audience",
        "invalid_apple_evidence",
        allow,
        %{base | audience: "wrong"},
        "invalid",
        "wrong_audience",
        "reconnect_required",
        "allow",
        %{}
      ),
      spec.(
        "wrong_device",
        "unmapped_verified_product",
        allow,
        %{base | account_subject: "other"},
        "invalid",
        "device_mismatch",
        "reconnect_required",
        "allow",
        %{}
      ),
      spec.(
        "unknown_kid",
        "apple_token_mismatch",
        allow,
        Map.put(base, :public_keys, []),
        "invalid",
        "unknown_key",
        "reconnect_required",
        "allow",
        %{}
      ),
      spec.(
        "rollback",
        "out_of_order_positive_after_revoke",
        allow,
        %{base | accepted_revision: 6, accepted_disposition: :deny},
        "invalid",
        "superseded",
        "reconnect_required",
        "deny",
        %{}
      ),
      spec.(
        "older_issuance",
        "duplicate_provider_event",
        allow,
        %{base | accepted_revision: 5, accepted_disposition: :deny, accepted_iat: 1_700_000_001},
        "invalid",
        "superseded",
        "reconnect_required",
        "deny",
        %{}
      ),
      spec.(
        "denial_precedence",
        "all_grants_revoked",
        allow,
        %{base | accepted_revision: 5, accepted_disposition: :deny},
        "invalid",
        "superseded",
        "reconnect_required",
        "deny",
        %{}
      ),
      spec.(
        "clock_rollback",
        "atomic_transaction_boundary",
        allow,
        %{base | clock_high_water: %{now: 1_700_000_002}},
        "invalid",
        "clock_rollback",
        "reconnect_required",
        "allow",
        %{}
      ),
      spec.(
        "before_replace_crash",
        "atomic_transaction_boundary",
        allow,
        %{base | accepted_disposition: :deny},
        "fresh",
        "ok",
        "none",
        "deny",
        allow_claims
      )
      |> Map.put(:fault_point, "before_rename"),
      spec.(
        "after_replace_crash",
        "stripe_revoked_apple_survives",
        deny,
        base,
        "denied",
        "signed_denial",
        "reconnect_required",
        "deny",
        deny_claims
      )
      |> Map.put(:fault_point, "after_directory_sync")
    ] ++
      [
        spec.(
          "fault_before_replace",
          "atomic_transaction_boundary",
          deny,
          %{base | accepted_disposition: :allow, accepted_revision: 5},
          "denied",
          "signed_denial",
          "reconnect_required",
          "allow",
          deny_claims
        )
        |> Map.put(:fault_point, "before_rename"),
        spec.(
          "wrong_account",
          "apple_token_mismatch",
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJqdGkiOiJ0ZXN0LXByb29mLWFsbG93IiwibmJmIjoxNzAwMDAwMDAwLCJwbGFucyI6WyJwcm8iXSwicXVhbnRpdGllcyI6eyJkb3dubG9hZHMiOjN9LCJyZXZpc2lvbiI6NSwic3ViIjoib3RoZXItYWNjb3VudCIsInZlcnNpb24iOiJ2MS41OSJ9.S5WocwDaOfrmdLIqrXDdA73hpyX9lpuxbH8gRbAQUBttkwIkHKwe_FZ02zG1q5JxLqcIoldHSNYyV8_c6ntxGQ",
          %{base | account_subject: "synthetic-account"},
          "invalid",
          "device_mismatch",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "wrong_type",
          "unmapped_verified_product",
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6Indyb25nLXR5cGUifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3VlLnRlc3Qub2ZmbGluZSIsImp0aSI6InRlc3QtcHJvb2YtYWxsb3ciLCJuYmYiOjE3MDAwMDAwMDAsInBsYW5zIjpbInBybyJdLCJxdWFudGl0aWVzIjp7ImRvd25sb2FkcyI6M30sInJldmlzaW9uIjo1LCJzdWIiOiJzeW50aGV0aWMtYWNjb3VudCIsInZlcnNpb24iOiJ2MS41OSJ9.qL97V9kcx2CtCAY7igO-m0Gvv3kCtOvD_uUVWshA2vtV1TlvMcYOeinDQ4NLYwXrG5kEhZRIatm_8HhCJDOHMA",
          %{base | now: 1_700_000_002},
          "invalid",
          "wrong_type",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "wrong_algorithm",
          "invalid_apple_evidence",
          "eyJhbGciOiJIUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3VlLnRlc3Qub2ZmbGluZSIsImp0aSI6InRlc3QtcHJvb2YtYWxsb3ciLCJuYmYiOjE3MDAwMDAwMDAsInBsYW5zIjpbInBybyJdLCJxdWFudGl0aWVzIjp7ImRvd25sb2FkcyI6M30sInJldmlzaW9uIjo1LCJzdWIiOiJzeW50aGV0aWMtYWNjb3VudCIsInZlcnNpb24iOiJ2MS41OSJ9.O7ju-BXSsqbT1OrzJhn95tZBczEEE-7BgSZJ0Hexpl3q6NRKr2K-5qFZ-HijRGpASfcU-RmEjG3DiIKmTu0BDw",
          %{base | accepted_iat: 1},
          "invalid",
          "wrong_algorithm",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "malformed_compact",
          "invalid_apple_evidence",
          "not-a-jws",
          %{base | installation_id: "malformed"},
          "invalid",
          "malformed",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "malformed_revision",
          "out_of_order_positive_after_revoke",
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJqdGkiOiJ0ZXN0LXByb29mLWFsbG93IiwibmJmIjoxNzAwMDAwMDAwLCJwbGFucyI6WyJwcm8iXSwicXVhbnRpdGllcyI6eyJkb3dubG9hZHMiOjN9LCJyZXZpc2lvbiI6ImZpdmUiLCJzdWIiOiJzeW50aGV0aWMtYWNjb3VudCIsInZlcnNpb24iOiJ2MS41OSJ9.jlWtv4AKsff3KJjTGQbvgOMF0GimbQCPd1ADt3KLsNYSY5YOVqNpb95W6vYQ-4LpB7HbJcYwckHu1-S4NmJy6A",
          %{base | accepted_revision: 1},
          "invalid",
          "malformed",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "malformed_iat",
          "duplicate_provider_event",
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOiJub3ciLCJpc3MiOiJhY2NydWUudGVzdC5vZmZsaW5lIiwianRpIjoidGVzdC1wcm9vZi1hbGxvdyIsIm5iZiI6MTcwMDAwMDAwMCwicGxhbnMiOlsicHJvIl0sInF1YW50aXRpZXMiOnsiZG93bmxvYWRzIjozfSwicmV2aXNpb24iOjUsInN1YiI6InN5bnRoZXRpYy1hY2NvdW50IiwidmVyc2lvbiI6InYxLjU5In0.SiANA7tFoVf07njkKxXECoZE-toAfukqhdsslVp6KJF-_EMLYVY8FJ5Fgt4gTtRF4lR9B4kJt_EPJqbaugozYQ",
          %{base | accepted_iat: 1},
          "invalid",
          "malformed",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "malformed_freshness",
          "stale_offline_continuity",
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6ImFsbG93IiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoibGF0ZXIiLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJqdGkiOiJ0ZXN0LXByb29mLWFsbG93IiwibmJmIjoxNzAwMDAwMDAwLCJwbGFucyI6WyJwcm8iXSwicXVhbnRpdGllcyI6eyJkb3dubG9hZHMiOjN9LCJyZXZpc2lvbiI6NSwic3ViIjoic3ludGhldGljLWFjY291bnQiLCJ2ZXJzaW9uIjoidjEuNTkifQ.44Xk-4mVg5olVSqLKze7MAdIM6-Kriye86MuzhccDP-baYlcZIkTcZJ3jp5hEzNV2iIWg1BgweMSCEMyR6JCJQ",
          %{base | accepted_fresh_until: 1},
          "invalid",
          "malformed",
          "reconnect_required",
          "allow",
          %{}
        ),
        spec.(
          "unknown_disposition",
          "reconnect_positive_replacement",
          "eyJhbGciOiJFUzI1NiIsImtpZCI6ImFjY3J1ZS12MS41OS1vZmZsaW5lLXRlc3Qtb25seSIsInR5cCI6ImFjY3J1ZS1lbnRpdGxlbWVudC1wcm9vZitqd3QifQ.eyJhdWQiOiJhY2NydWUtb2ZmbGluZS1jbGllbnQiLCJjbmYiOnsiamt0IjoiSVZ3OTU4RF9zeEtZTWc2aUNIUXMtdm14a09WSWlSd3dLbGZlVjZ5a3JDZyJ9LCJkaXNwb3NpdGlvbiI6Im1heWJlIiwiZXhwIjoxNzAyNTkyMDAwLCJmZWF0dXJlcyI6WyJvZmZsaW5lX3N0dWR5Il0sImZyZXNoX3VudGlsIjoxNzAwMDAzNjAwLCJpYXQiOjE3MDAwMDAwMDAsImlzcyI6ImFjY3J1ZS50ZXN0Lm9mZmxpbmUiLCJqdGkiOiJ0ZXN0LXByb29mLWFsbG93IiwibmJmIjoxNzAwMDAwMDAwLCJwbGFucyI6WyJwcm8iXSwicXVhbnRpdGllcyI6eyJkb3dubG9hZHMiOjN9LCJyZXZpc2lvbiI6NSwic3ViIjoic3ludGhldGljLWFjY291bnQiLCJ2ZXJzaW9uIjoidjEuNTkifQ.kc7cRWxUT1y2bR9rWeefB44e4LdBBpjtx1ew8cx6iNUFqJEX6vbYy77ScByxb8bvj6Kc_hQgTadJvU4nkH1bTg",
          %{base | accepted_disposition: :allow},
          "invalid",
          "malformed",
          "reconnect_required",
          "allow",
          %{}
        )
      ]
  end

  defp claims_for(compact) do
    [_header, payload, _signature] = String.split(compact, ".")
    payload |> Base.url_decode64!(padding: false) |> Jason.decode!()
  end

  defp public_test_key do
    %{
      "kty" => "EC",
      "crv" => "P-256",
      "kid" => "accrue-v1.59-offline-test-only",
      "use" => "sig",
      "alg" => "ES256",
      "x" => "ILy0daKycIXATH4kWl48vbUd4Sn9AqwHL-zPXonI8-M",
      "y" => "JdAT80VGTVn3qxGJkUZMZ9y85nUFr9TYaPkyzOpDMEc"
    }
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
