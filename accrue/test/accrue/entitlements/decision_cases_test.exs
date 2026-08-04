defmodule Accrue.Entitlements.DecisionCasesTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.DecisionCases
  alias Accrue.Entitlements.DecisionCases.Markdown

  test "the canonical corpus has sorted unique stable IDs and one version" do
    cases = DecisionCases.all()
    ids = Enum.map(cases, & &1.id)

    assert length(cases) > 0
    assert ids == Enum.sort(ids)
    assert length(ids) == length(Enum.uniq(ids))
    assert Enum.all?(cases, &(&1.contract_version == DecisionCases.version()))
  end

  test "every case has the closed D-07 schema and a bounded privacy-safe reason" do
    assert Enum.all?(DecisionCases.all(), &DecisionCases.valid?/1)

    assert Enum.all?(DecisionCases.all(), fn case_data ->
             case_data.expected.reason =~ ~r/^entitlement_[a-z0-9_]{3,80}$/
           end)
  end

  test "the corpus covers required rail, ordering, survivor, and continuity cases" do
    ids = DecisionCases.all() |> Enum.map(& &1.id) |> MapSet.new()

    for id <- [
          "apple_token_mismatch",
          "duplicate_provider_event",
          "out_of_order_positive_after_revoke",
          "stripe_revoked_apple_survives",
          "all_grants_revoked",
          "purchase_eligibility_ambiguous",
          "stale_offline_continuity",
          "reconnect_positive_replacement",
          "reconnect_denied_tombstone",
          "atomic_transaction_boundary"
        ] do
      assert MapSet.member?(ids, id), "missing #{id}"
    end
  end

  test "projector-visible Phase-215 cases carry closed revision and reason outcomes" do
    projector_cases =
      DecisionCases.all()
      |> Enum.filter(
        &(&1.id in [
            "all_grants_revoked",
            "atomic_transaction_boundary",
            "duplicate_provider_event",
            "out_of_order_positive_after_revoke",
            "stripe_revoked_apple_survives"
          ])
      )

    assert Enum.map(projector_cases, & &1.id) == [
             "all_grants_revoked",
             "atomic_transaction_boundary",
             "duplicate_provider_event",
             "out_of_order_positive_after_revoke",
             "stripe_revoked_apple_survives"
           ]

    Enum.each(projector_cases, fn case_data ->
      assert case_data.expected.atomic
      assert is_integer(case_data.expected.revision_delta)
      assert case_data.expected.reason == "entitlement_#{case_data.id}"
    end)
  end

  test "malformed closed values fail validation" do
    [first | _] = DecisionCases.all()

    refute DecisionCases.valid?(put_in(first.evidence.rail, :google))
    refute DecisionCases.valid?(put_in(first.evidence.environment, :staging))
    refute DecisionCases.valid?(put_in(first.ordering.relation, :future))
    refute DecisionCases.valid?(put_in(first.expected.disposition, :maybe))
  end

  test "D-07 bindings and closed evidence outcomes fail validation when mutated" do
    [first | _] = DecisionCases.all()

    refute DecisionCases.valid?(put_in(first.evidence.account_binding, :unknown_account))
    refute DecisionCases.valid?(put_in(first.evidence.device_binding, :unknown_device))
    refute DecisionCases.valid?(put_in(first.evidence.kind, :unverified_payload))
    refute DecisionCases.valid?(put_in(first.expected.continuity, :maybe_continuous))
    refute DecisionCases.valid?(put_in(first.expected.repair, :maybe_repair))
  end

  test "D-07 revision deltas are non-negative" do
    [first | _] = DecisionCases.all()

    refute DecisionCases.valid?(put_in(first.expected.revision_delta, -1))
    assert DecisionCases.valid?(put_in(first.expected.revision_delta, 0))

    assert Enum.all?(DecisionCases.all(), fn case_data ->
             case_data.expected.revision_delta >= 0 and DecisionCases.valid?(case_data)
           end)
  end

  test "D-07 prior state, ordering, atomicity, and reason shapes fail closed" do
    [first | _] = DecisionCases.all()

    refute DecisionCases.valid?(put_in(first.prior.sources, [:stripe, :unknown_rail]))
    refute DecisionCases.valid?(put_in(first.prior.sources, [:stripe, :stripe]))
    refute DecisionCases.valid?(put_in(first.prior.snapshot, %{unknown: "shape"}))
    refute DecisionCases.valid?(put_in(first.ordering.provider_cursor, ""))
    refute DecisionCases.valid?(put_in(first.ordering.observed_at, -1))
    refute DecisionCases.valid?(put_in(first.ordering.relation, :future))
    refute DecisionCases.valid?(put_in(first.expected.atomic, nil))
    refute DecisionCases.valid?(put_in(first.expected.reason, "unbounded reason"))
  end

  test "derived markdown and JSON have the same stable case IDs and version" do
    markdown = Markdown.render(DecisionCases.all())
    json = Accrue.Entitlements.DecisionCases.Export.json(DecisionCases.all())

    assert markdown =~ "derived non-runtime contract"
    assert Jason.decode!(json)["contract_version"] == DecisionCases.version()

    json_ids = json |> Jason.decode!() |> Map.fetch!("cases") |> Enum.map(& &1["id"])
    assert json_ids == Enum.map(DecisionCases.all(), & &1.id)
    assert markdown == Markdown.render(DecisionCases.all())
    assert json == Accrue.Entitlements.DecisionCases.Export.json(DecisionCases.all())
  end

  test "markdown renders lease and continuity as distinct canonical columns" do
    case_data = Enum.find(DecisionCases.all(), &(&1.id == "stale_offline_continuity"))
    markdown = Markdown.render([case_data])

    assert markdown =~ "| Lease | Continuity |"

    assert markdown =~
             "| `stale_offline_continuity` | stripe/offline | preserve | not_applicable | stale_offline | downloaded_only |"
  end

  test "export check detects generated view drift" do
    root = Path.join(System.tmp_dir!(), "decision-cases-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(root) end)

    assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    assert :ok = Accrue.Entitlements.DecisionCases.Export.check(root)

    markdown_path = Path.join(root, ".planning/research/v1.59-DECISION-TABLE.md")
    File.write!(markdown_path, "drift\n")
    assert {:error, [^markdown_path]} = Accrue.Entitlements.DecisionCases.Export.check(root)
  end

  test "offline vectors are derived from unique canonical case bindings" do
    vectors = Accrue.Entitlements.DecisionCases.Export.offline_vectors()
    canonical = Map.new(DecisionCases.all(), &{&1.id, &1})

    assert length(vectors) == length(Enum.uniq_by(vectors, & &1.id))

    Enum.each(vectors, fn vector ->
      case_data = Map.fetch!(canonical, vector.case_id)
      assert vector.contract_version == case_data.contract_version
      assert vector.expected_disposition == Atom.to_string(case_data.expected.disposition)
    end)
  end

  test "offline corpus preserves the authenticated prior cache when replacement faults before rename" do
    vector =
      Accrue.Entitlements.DecisionCases.Export.offline_vectors()
      |> Enum.find(&(&1.id == "fault_before_replace"))

    assert vector.expected_cache_disposition == "allow"
    assert vector.verification_context.accepted_disposition == :allow
  end

  test "offline corpus declares every required fail-closed verifier case" do
    ids =
      Accrue.Entitlements.DecisionCases.Export.offline_vectors()
      |> Enum.map(& &1.id)
      |> MapSet.new()

    for id <- [
          "wrong_account",
          "wrong_audience",
          "wrong_type",
          "wrong_algorithm",
          "malformed_compact",
          "malformed_revision",
          "malformed_iat",
          "malformed_freshness",
          "unknown_disposition"
        ] do
      assert MapSet.member?(ids, id), "missing #{id}"
    end
  end

  test "offline export check fails closed with named diagnostics for case drift" do
    root = Path.join(System.tmp_dir!(), "offline-vectors-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(root) end)

    assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    assert :ok = Accrue.Entitlements.DecisionCases.Export.check(root)

    vector_path = Path.join(root, "accrue/priv/entitlements/v1.59-offline-golden-vectors.json")
    File.write!(vector_path, "{\"vectors\": []}\n")

    assert {:error, paths} = Accrue.Entitlements.DecisionCases.Export.check(root)
    assert vector_path in paths
  end

  test "offline export check names every mutated expectation field and vector" do
    root =
      Path.join(System.tmp_dir!(), "offline-expectations-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(root) end)

    assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    vector_path = Path.join(root, "accrue/priv/entitlements/v1.59-offline-golden-vectors.json")

    for field <- ["expected_verification", "expected_reason", "expected_cache_disposition"] do
      fixture = Jason.decode!(File.read!(vector_path))
      [first | rest] = fixture["vectors"]
      mutated = put_in(first[field], "mutated")

      File.write!(
        vector_path,
        Jason.encode!(%{fixture | "vectors" => [mutated | rest]}, pretty: true) <> "\n"
      )

      assert {:error, diagnostics} = Accrue.Entitlements.DecisionCases.Export.check(root)
      assert "#{vector_path}: vector #{first["id"]} #{field}" in diagnostics
      assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    end
  end

  test "offline export check rejects every corpus binding, schema, key, and identity drift" do
    root = Path.join(System.tmp_dir!(), "offline-contract-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(root) end)

    assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    vector_path = Path.join(root, "accrue/priv/entitlements/v1.59-offline-golden-vectors.json")

    for field <- [
          "id",
          "case_id",
          "contract_version",
          "expected_disposition",
          "compact_jws",
          "expected_verification",
          "expected_reason",
          "expected_cache_disposition"
        ] do
      fixture = Jason.decode!(File.read!(vector_path))
      [first | rest] = fixture["vectors"]

      File.write!(
        vector_path,
        Jason.encode!(%{fixture | "vectors" => [Map.put(first, field, "mutated") | rest]},
          pretty: true
        ) <> "\n"
      )

      assert {:error, diagnostics} = Accrue.Entitlements.DecisionCases.Export.check(root)
      assert "#{vector_path}: vector #{first["id"]} #{field}" in diagnostics
      assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    end

    for field <- ["schema_version", "purpose"] do
      fixture = Jason.decode!(File.read!(vector_path))

      File.write!(
        vector_path,
        Jason.encode!(Map.put(fixture, field, "mutated"), pretty: true) <> "\n"
      )

      assert {:error, diagnostics} = Accrue.Entitlements.DecisionCases.Export.check(root)
      assert "#{vector_path}: #{field}" in diagnostics
      assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    end

    for corpus <- [
          Map.delete(Jason.decode!(File.read!(vector_path)), "purpose"),
          Map.put(Jason.decode!(File.read!(vector_path)), "unexpected", "value")
        ] do
      File.write!(vector_path, Jason.encode!(corpus, pretty: true) <> "\n")
      assert {:error, diagnostics} = Accrue.Entitlements.DecisionCases.Export.check(root)
      assert Enum.any?(diagnostics, &String.contains?(&1, " key "))
      assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    end

    fixture = Jason.decode!(File.read!(vector_path))
    [first | rest] = fixture["vectors"]

    for {vectors, diagnostic} <- [
          {[first, first | rest], "#{vector_path}: duplicate vector #{first["id"]}"},
          {rest, "#{vector_path}: missing vector #{first["id"]}"},
          {[Map.put(first, "id", "extra_vector") | fixture["vectors"]],
           "#{vector_path}: unexpected vector extra_vector"},
          {[Map.delete(first, "compact_jws") | rest],
           "#{vector_path}: vector #{first["id"]} missing key compact_jws"},
          {[Map.put(first, "unexpected", "value") | rest],
           "#{vector_path}: vector #{first["id"]} unexpected key unexpected"}
        ] do
      File.write!(
        vector_path,
        Jason.encode!(%{fixture | "vectors" => vectors}, pretty: true) <> "\n"
      )

      assert {:error, diagnostics} = Accrue.Entitlements.DecisionCases.Export.check(root)
      assert diagnostic in diagnostics
      assert :ok = Accrue.Entitlements.DecisionCases.Export.write(root)
    end

    fixture = Jason.decode!(File.read!(vector_path))
    fault_index = Enum.find_index(fixture["vectors"], &Map.has_key?(&1, "fault_point"))
    fault_vector = Enum.at(fixture["vectors"], fault_index)

    vectors =
      List.replace_at(
        fixture["vectors"],
        fault_index,
        Map.put(fault_vector, "fault_point", "mutated")
      )

    File.write!(
      vector_path,
      Jason.encode!(%{fixture | "vectors" => vectors}, pretty: true) <> "\n"
    )

    assert {:error, diagnostics} = Accrue.Entitlements.DecisionCases.Export.check(root)
    assert "#{vector_path}: vector #{fault_vector["id"]} fault_point" in diagnostics
  end

  test "offline fixture key is unmistakably test-only and private material stays out of application code" do
    root = Path.expand("../../..", __DIR__)
    key_path = Path.join(root, "priv/entitlements/v1.59-offline-test-key.jwk.json")
    key = Jason.decode!(File.read!(key_path))

    assert key["use"] == "test-only"
    assert key["warning"] =~ "MUST NEVER"

    private_material = Map.fetch!(key, "d")

    root
    |> Path.join("lib/**/*.ex")
    |> Path.wildcard()
    |> Enum.each(fn path -> refute File.read!(path) =~ private_material end)
  end
end
