defmodule Accrue.Entitlements.OfflineGoldenVectorVerifier do
  @moduledoc false

  alias Accrue.Entitlements.DecisionCases
  alias Accrue.Entitlements.Offline

  @fixture Path.expand("../../../priv/entitlements/v1.59-offline-golden-vectors.json", __DIR__)
  @top_level_keys MapSet.new([
                    "schema_version",
                    "protocol_version",
                    "purpose",
                    "public_jwks",
                    "vectors"
                  ])

  def verify_fixture! do
    corpus = @fixture |> File.read!() |> Jason.decode!()

    with {:ok, vectors} <- validate_corpus(corpus) do
      {:ok, vectors, Enum.map(vectors, &observe/1)}
    end
  end

  # This test-only boundary validates fixture identity and then delegates every
  # security decision to the public production Offline facade. It contains no
  # crypto, parser, reducer, or ordering implementation of its own.
  def validate_corpus(
        %{
          "schema_version" => "v1.59",
          "protocol_version" => "v1.59",
          "public_jwks" => %{"keys" => keys},
          "vectors" => vectors
        } = corpus
      )
      when is_list(keys) and is_list(vectors) do
    canonical = Map.new(DecisionCases.all(), &{&1.id, &1})

    with :ok <- exact_top_level(corpus_keys(corpus)),
         :ok <- unique_ids(vectors),
         :ok <-
           Enum.reduce_while(vectors, :ok, fn vector, :ok ->
             case validate_vector(vector, :ok, canonical, keys) do
               :ok -> {:cont, :ok}
               error -> {:halt, error}
             end
           end) do
      {:ok, Enum.sort_by(vectors, & &1["id"])}
    end
  end

  def validate_corpus(_), do: {:error, "offline corpus: schema"}

  defp corpus_keys(corpus), do: Map.keys(corpus) |> MapSet.new()
  defp exact_top_level(keys) when keys == @top_level_keys, do: :ok
  defp exact_top_level(_), do: {:error, "offline corpus: top-level keys"}

  defp unique_ids(vectors) do
    ids = Enum.map(vectors, &Map.get(&1, "id"))

    if length(ids) == length(Enum.uniq(ids)) and Enum.all?(ids, &is_binary/1),
      do: :ok,
      else: {:error, "offline corpus: duplicate id"}
  end

  defp validate_vector(vector, :ok, canonical, _keys) do
    expected_keys =
      MapSet.new(
        [
          "id",
          "case_id",
          "contract_version",
          "expected_disposition",
          "compact_jws",
          "expected_claims",
          "verification_context",
          "expected_state",
          "expected_reason",
          "expected_next_action",
          "expected_cache_disposition"
        ] ++ if(Map.has_key?(vector, "fault_point"), do: ["fault_point"], else: [])
      )

    id = Map.get(vector, "id", "unknown")

    with true <- is_map(vector) and MapSet.new(Map.keys(vector)) == expected_keys,
         {:ok, case_data} <- Map.fetch(canonical, Map.get(vector, "case_id")),
         true <- vector["contract_version"] == case_data.contract_version,
         true <- vector["expected_disposition"] == Atom.to_string(case_data.expected.disposition),
         true <- is_map(vector["verification_context"]) and is_map(vector["expected_claims"]),
         true <- is_binary(vector["compact_jws"]),
         true <- vector["expected_state"] in ["fresh", "stale_offline", "denied", "invalid"],
         true <-
           is_binary(vector["expected_reason"]) and is_binary(vector["expected_next_action"]),
         true <- vector["expected_cache_disposition"] in ["allow", "deny"] do
      :ok
    else
      :error -> {:error, "offline corpus: vector #{id} case_id"}
      false -> {:error, "offline corpus: vector #{id} binding"}
      _ -> {:error, "offline corpus: vector #{id} schema"}
    end
  end

  defp observe(vector) do
    context = Map.put(vector["verification_context"], :public_keys, public_keys())

    context =
      if Map.has_key?(vector["verification_context"], "public_keys"),
        do: Map.put(context, :public_keys, vector["verification_context"]["public_keys"]),
        else: context

    context = atomize_context(context)
    {:ok, decision} = Offline.verify(vector["compact_jws"], context)
    policy = Offline.action_policy(decision, :read_downloaded_lesson)

    %{
      id: vector["id"],
      state: decision.state,
      reason: decision.reason,
      next_action: decision.next_action,
      cache: cache_after(vector, decision),
      claims: claims_map(decision.claims),
      policy: policy
    }
  end

  defp public_keys do
    @fixture |> File.read!() |> Jason.decode!() |> get_in(["public_jwks", "keys"])
  end

  defp atomize_context(context) do
    for {key, value} <- context, into: %{} do
      atom =
        if is_atom(key) do
          key
        else
          %{
            "issuer" => :issuer,
            "audience" => :audience,
            "account_subject" => :account_subject,
            "installation_id" => :installation_id,
            "device_thumbprint" => :device_thumbprint,
            "now" => :now,
            "clock_high_water" => :clock_high_water,
            "accepted_revision" => :accepted_revision,
            "accepted_disposition" => :accepted_disposition,
            "accepted_iat" => :accepted_iat,
            "accepted_fresh_until" => :accepted_fresh_until,
            "public_keys" => :public_keys
          }[key]
        end

      value =
        cond do
          atom == :accepted_disposition and is_binary(value) ->
            String.to_existing_atom(value)

          atom == :clock_high_water and is_map(value) ->
            Map.new(value, fn {nested_key, nested_value} ->
              {String.to_existing_atom(nested_key), nested_value}
            end)

          true ->
            value
        end

      {atom, value}
    end
  end

  # Model the durable compare-and-replace boundary from D-20 rather than copying
  # the vector's expected cache label. A before-rename fault retains the explicit
  # authenticated prior proof; a completed signed denial replaces it.
  defp cache_after(%{"fault_point" => "before_rename"} = vector, _decision),
    do: prior_cache(vector)

  defp cache_after(_vector, %{state: :denied}), do: :deny
  defp cache_after(vector, %{state: :invalid}), do: prior_cache(vector)
  defp cache_after(_vector, _decision), do: :allow

  defp prior_cache(%{"verification_context" => %{"accepted_disposition" => "deny"}}), do: :deny
  defp prior_cache(_), do: :allow

  defp claims_map(nil), do: %{}
  defp claims_map(claims), do: Map.from_struct(claims)
end
