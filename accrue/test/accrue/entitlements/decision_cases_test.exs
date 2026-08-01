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

    assert length(vectors) == length(Enum.uniq_by(vectors, & &1.case_id))

    Enum.each(vectors, fn vector ->
      case_data = Map.fetch!(canonical, vector.case_id)
      assert vector.contract_version == case_data.contract_version
      assert vector.expected_disposition == Atom.to_string(case_data.expected.disposition)
    end)
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
