defmodule Accrue.Entitlements.DecisionCases do
  @moduledoc false

  @version "v1.59"
  @rails [:stripe, :apple]
  @environments [:production, :sandbox, :offline]
  @evidence_kinds [:verified_event]
  @account_bindings [:authenticated]
  @device_bindings [:registered]
  @relations [:newer, :equal, :older]
  @dispositions [:grant, :no_grant, :retract, :noop, :preserve]
  @leases [:fresh, :stale_offline, :reconnect_required, :denied, :unchanged]
  @eligibility [:eligible, :warn, :block, :not_applicable]
  @continuities [:full_actions, :cached_only, :local_only, :downloaded_only]
  @repairs [
    :audit,
    :catalog,
    :duplicate,
    :high_water,
    :quarantine,
    :reconnect,
    :replace,
    :retry,
    :security,
    :stale_observation,
    :support,
    :survivor,
    :repair_lineage,
    :needs_repair
  ]

  defmodule Evidence do
    @enforce_keys [:rail, :environment, :qualified, :kind]
    defstruct [:rail, :environment, :qualified, :kind, :account_binding, :device_binding]
  end

  defmodule PriorState do
    @enforce_keys [:sources, :snapshot, :revision]
    defstruct [:sources, :snapshot, :revision]
  end

  defmodule Ordering do
    @enforce_keys [:provider_cursor, :observed_at, :relation]
    defstruct [:provider_cursor, :observed_at, :relation]
  end

  defmodule Expected do
    @enforce_keys [
      :disposition,
      :snapshot,
      :revision_delta,
      :eligibility,
      :lease,
      :continuity,
      :repair,
      :reason
    ]
    defstruct [
      :disposition,
      :snapshot,
      :revision_delta,
      :eligibility,
      :lease,
      :continuity,
      :repair,
      :reason,
      :atomic
    ]
  end

  defmodule DecisionCase do
    @enforce_keys [:id, :contract_version, :evidence, :prior, :ordering, :expected]
    defstruct [:id, :contract_version, :evidence, :prior, :ordering, :expected]
  end

  @spec version() :: String.t()
  def version, do: @version

  @spec all() :: [DecisionCase.t()]
  def all, do: cases() |> Enum.sort_by(& &1.id)

  @spec valid?(DecisionCase.t()) :: boolean()
  def valid?(%DecisionCase{} = value) do
    value.contract_version == @version and valid_id?(value.id) and
      valid_evidence?(value.evidence) and valid_prior?(value.prior) and
      valid_ordering?(value.ordering) and valid_expected?(value.expected)
  end

  def valid?(_), do: false

  defp valid_id?(id), do: is_binary(id) and id =~ ~r/^[a-z0-9_]{3,80}$/

  defp valid_evidence?(%Evidence{} = evidence) do
    evidence.rail in @rails and evidence.environment in @environments and
      is_boolean(evidence.qualified) and evidence.kind in @evidence_kinds and
      evidence.account_binding in @account_bindings and
      evidence.device_binding in @device_bindings
  end

  defp valid_evidence?(_), do: false

  defp valid_prior?(%PriorState{sources: sources, snapshot: snapshot, revision: revision}) do
    is_list(sources) and sources != [] and Enum.uniq(sources) == sources and
      Enum.all?(sources, &(&1 in @rails)) and valid_snapshot?(snapshot) and
      is_integer(revision) and revision >= 0
  end

  defp valid_prior?(_), do: false

  defp valid_ordering?(%Ordering{provider_cursor: cursor, observed_at: at, relation: relation}) do
    is_binary(cursor) and cursor =~ ~r/^[A-Za-z0-9_:-]{1,160}$/ and
      is_integer(at) and at >= 0 and relation in @relations
  end

  defp valid_ordering?(_), do: false

  defp valid_expected?(%Expected{} = expected) do
    expected.disposition in @dispositions and valid_snapshot?(expected.snapshot) and
      is_integer(expected.revision_delta) and expected.revision_delta >= 0 and
      expected.eligibility in @eligibility and expected.lease in @leases and
      expected.continuity in @continuities and expected.repair in @repairs and
      is_boolean(expected.atomic) and is_binary(expected.reason) and
      expected.reason =~ ~r/^entitlement_[a-z0-9_]{3,80}$/
  end

  defp valid_expected?(_), do: false

  defp valid_snapshot?(%{} = snapshot) when map_size(snapshot) == 0, do: true

  defp valid_snapshot?(%{plans: plans} = snapshot) do
    map_size(snapshot) == 1 and is_list(plans) and plans != [] and
      Enum.uniq(plans) == plans and
      Enum.all?(plans, &(is_binary(&1) and &1 =~ ~r/^[a-z0-9_:-]{1,80}$/))
  end

  defp valid_snapshot?(_), do: false

  defp case_data(id, opts) do
    evidence = %Evidence{
      rail: Keyword.get(opts, :rail, :stripe),
      environment: Keyword.get(opts, :environment, :production),
      qualified: Keyword.get(opts, :qualified, true),
      kind: Keyword.get(opts, :kind, :verified_event),
      account_binding: :authenticated,
      device_binding: :registered
    }

    prior = %PriorState{
      sources: Keyword.get(opts, :sources, [:stripe]),
      snapshot: %{plans: ["pro"]},
      revision: Keyword.get(opts, :revision, 4)
    }

    ordering = %Ordering{
      provider_cursor: "cursor_#{id}",
      observed_at: 1_700_000_000,
      relation: Keyword.get(opts, :relation, :newer)
    }

    expected = %Expected{
      disposition: Keyword.get(opts, :disposition, :grant),
      snapshot: Keyword.get(opts, :snapshot, %{plans: ["pro"]}),
      revision_delta: Keyword.get(opts, :revision_delta, 1),
      eligibility: Keyword.get(opts, :eligibility, :warn),
      lease: Keyword.get(opts, :lease, :fresh),
      continuity: Keyword.get(opts, :continuity, :full_actions),
      repair: Keyword.get(opts, :repair, :audit),
      reason: "entitlement_#{id}",
      atomic: Keyword.get(opts, :atomic, true)
    }

    %DecisionCase{
      id: id,
      contract_version: @version,
      evidence: evidence,
      prior: prior,
      ordering: ordering,
      expected: expected
    }
  end

  defp cases do
    [
      case_data("all_grants_revoked",
        disposition: :retract,
        snapshot: %{},
        eligibility: :eligible,
        lease: :denied,
        continuity: :local_only,
        repair: :support
      ),
      case_data("apple_token_mismatch",
        rail: :apple,
        qualified: false,
        disposition: :no_grant,
        revision_delta: 0,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :quarantine
      ),
      case_data("apple_verified_grant",
        rail: :apple,
        environment: :production,
        sources: [:stripe, :apple]
      ),
      case_data("apple_verified_unbound_repair",
        rail: :apple,
        qualified: false,
        disposition: :no_grant,
        revision_delta: 0,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :repair_lineage
      ),
      case_data("apple_family_sharing_deferred",
        rail: :apple,
        disposition: :preserve,
        revision_delta: 0,
        eligibility: :not_applicable,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :support
      ),
      case_data("apple_offer_authoring_deferred",
        rail: :apple,
        disposition: :preserve,
        revision_delta: 0,
        eligibility: :not_applicable,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :support
      ),
      case_data("apple_retry_exhausted",
        rail: :apple,
        qualified: false,
        disposition: :no_grant,
        revision_delta: 0,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :needs_repair
      ),
      case_data("atomic_transaction_boundary", disposition: :grant, repair: :audit, atomic: true),
      case_data("duplicate_provider_event",
        disposition: :noop,
        relation: :equal,
        revision_delta: 0,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :duplicate
      ),
      case_data("invalid_apple_evidence",
        rail: :apple,
        qualified: false,
        disposition: :no_grant,
        revision_delta: 0,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :security
      ),
      case_data("out_of_order_positive_after_revoke",
        disposition: :noop,
        relation: :older,
        revision_delta: 0,
        lease: :denied,
        continuity: :local_only,
        repair: :stale_observation
      ),
      case_data("purchase_eligibility_ambiguous",
        disposition: :preserve,
        revision_delta: 0,
        eligibility: :block,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :retry
      ),
      case_data("reconnect_denied_tombstone",
        disposition: :retract,
        snapshot: %{},
        eligibility: :block,
        lease: :denied,
        continuity: :local_only,
        repair: :support
      ),
      case_data("reconnect_positive_replacement",
        disposition: :grant,
        lease: :fresh,
        continuity: :full_actions,
        repair: :replace
      ),
      case_data("stale_offline_continuity",
        environment: :offline,
        disposition: :preserve,
        revision_delta: 0,
        eligibility: :not_applicable,
        lease: :stale_offline,
        continuity: :downloaded_only,
        repair: :reconnect
      ),
      case_data("stripe_revoked_apple_survives",
        rail: :stripe,
        sources: [:stripe, :apple],
        disposition: :retract,
        revision_delta: 0,
        lease: :fresh,
        continuity: :full_actions,
        repair: :survivor
      ),
      case_data("unmapped_verified_product",
        disposition: :no_grant,
        revision_delta: 0,
        eligibility: :block,
        lease: :unchanged,
        continuity: :cached_only,
        repair: :catalog
      ),
      case_data("valid_fresh_lease",
        environment: :offline,
        disposition: :preserve,
        revision_delta: 0,
        eligibility: :not_applicable,
        lease: :fresh,
        continuity: :full_actions,
        repair: :high_water
      )
    ]
  end
end
