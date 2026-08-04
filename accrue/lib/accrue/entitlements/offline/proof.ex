defmodule Accrue.Entitlements.Offline.Proof do
  @moduledoc false

  @version "v1.59"
  @proof_type "accrue-entitlement-proof+jwt"
  @max_string 256
  @max_collection 100
  @sensitive_claims ~w(version iss aud jti sub cnf revision iat nbf fresh_until exp disposition plans features quantities denial_reason)
  @allow_claims Enum.sort(List.delete(@sensitive_claims, "denial_reason"))
  # The signed denial reason is part of the public wire contract, not a free-form
  # provider diagnostic. Keep this list shared with issuance.
  @denial_reasons ~w(signed_denial superseded device_revoked)

  @spec denial_reason?(atom() | String.t()) :: boolean()
  def denial_reason?(reason) when is_atom(reason), do: denial_reason?(Atom.to_string(reason))
  def denial_reason?(reason) when is_binary(reason), do: reason in @denial_reasons
  def denial_reason?(_), do: false
  @deny_claims Enum.sort(@sensitive_claims)

  defmodule VerificationContext do
    @moduledoc false
    @enforce_keys [
      :issuer,
      :audience,
      :account_subject,
      :installation_id,
      :device_thumbprint,
      :now
    ]
    defstruct issuer: nil,
              audience: nil,
              account_subject: nil,
              installation_id: nil,
              device_thumbprint: nil,
              now: nil,
              clock_high_water: %{},
              accepted_revision: 0,
              accepted_disposition: nil,
              accepted_iat: 0,
              accepted_fresh_until: 0,
              public_keys: []

    @type t :: %__MODULE__{
            issuer: binary(),
            audience: binary(),
            account_subject: binary(),
            installation_id: binary(),
            device_thumbprint: binary(),
            now: integer(),
            clock_high_water: map(),
            accepted_revision: non_neg_integer(),
            accepted_disposition: :allow | :deny | nil,
            accepted_iat: non_neg_integer(),
            accepted_fresh_until: non_neg_integer(),
            public_keys: [map()]
          }

    def new(%__MODULE__{} = context), do: {:ok, context}

    def new(context) when is_map(context) do
      fields = Map.take(context, __struct__() |> Map.keys() |> List.delete(:__struct__))

      try do
        {:ok, struct!(__MODULE__, fields)}
      rescue
        KeyError -> :error
      end
    end

    def new(_), do: :error
  end

  defmodule Claims do
    @moduledoc false
    @enforce_keys [
      :version,
      :issuer,
      :audience,
      :token_id,
      :subject,
      :confirmation,
      :revision,
      :issued_at,
      :not_before,
      :fresh_until,
      :expires_at,
      :disposition,
      :plans,
      :features,
      :quantities
    ]
    defstruct [
      :version,
      :issuer,
      :audience,
      :token_id,
      :subject,
      :confirmation,
      :revision,
      :issued_at,
      :not_before,
      :fresh_until,
      :expires_at,
      :disposition,
      :plans,
      :features,
      :quantities,
      :denial_reason
    ]

    @type t :: %__MODULE__{}
  end

  defmodule Decision do
    @moduledoc false
    @enforce_keys [:state, :reason, :next_action, :claims]
    defstruct [:state, :reason, :next_action, :claims]

    @type t :: %__MODULE__{
            state: :fresh | :stale_offline | :denied | :invalid,
            reason: atom(),
            next_action: atom(),
            claims: Claims.t() | nil
          }
  end

  defmodule ActionPolicy do
    @moduledoc false
    @enforce_keys [:action, :allowed, :next_action, :guidance_key]
    defstruct [:action, :allowed, :next_action, :guidance_key]

    @type t :: %__MODULE__{
            action: atom(),
            allowed: boolean(),
            next_action: :none | :reconnect_required | :access_unavailable | :check_access,
            guidance_key: :fresh | :stale_offline | :denied | :invalid
          }
  end

  defmodule Guidance do
    @moduledoc false
    @enforce_keys [:key, :text, :action_label]
    defstruct [:key, :text, :action_label]

    @type t :: %__MODULE__{
            key: :fresh | :stale_offline | :denied | :invalid,
            text: binary(),
            action_label: binary()
          }
  end

  @actions [
    :read_downloaded_lesson,
    :read_local_progress,
    :write_local_progress,
    :download_premium,
    :enroll,
    :export,
    :purchase,
    :mutate_account,
    :mutate_rail,
    :other_value_expansion
  ]

  @spec action_policy(Decision.t(), atom()) :: ActionPolicy.t()
  def action_policy(%Decision{state: state, claims: claims}, action)
      when state in [:fresh, :stale_offline, :denied, :invalid] do
    cond do
      action not in @actions -> policy(action, false, :reconnect_required, state)
      state == :fresh -> fresh_policy(action, claims)
      state == :stale_offline -> stale_policy(action)
      state in [:denied, :invalid] -> unavailable_policy(action, state)
    end
  end

  def action_policy(_decision, action), do: policy(action, false, :reconnect_required, :invalid)

  @spec guidance(:fresh | :stale_offline | :denied | :invalid) :: Guidance.t()
  def guidance(:fresh),
    do: %Guidance{key: :fresh, text: "Access is up to date.", action_label: "Continue"}

  def guidance(:stale_offline),
    do: %Guidance{
      key: :stale_offline,
      text:
        "Reconnect to update access. Downloaded lessons and progress stay available on this device.",
      action_label: "Reconnect"
    }

  def guidance(:denied),
    do: %Guidance{
      key: :denied,
      text: "Access is unavailable. Downloaded lessons and progress stay on this device.",
      action_label: "Check access"
    }

  def guidance(:invalid),
    do: %Guidance{key: :invalid, text: "Reconnect to check access.", action_label: "Reconnect"}

  def guidance(_), do: guidance(:invalid)

  @spec verify(binary(), VerificationContext.t() | map(), keyword()) :: Decision.t()
  def verify(compact, context, _opts \\ []) do
    with {:ok, context} <- VerificationContext.new(context),
         {:ok, header, payload_json, payload} <- parse_compact(compact),
         :ok <- validate_header(header),
         {:ok, key} <- local_key(header, context.public_keys),
         :ok <- verify_signature(key, compact),
         {:ok, claims} <- validate_claims(payload, payload_json, context),
         :ok <- validate_high_water(claims, context) do
      classify(claims, context.now)
    else
      {:error, reason} -> invalid(reason)
      _ -> invalid(:malformed)
    end
  rescue
    _ -> invalid(:malformed)
  end

  @spec invalid(atom()) :: Decision.t()
  def invalid(reason),
    do: %Decision{state: :invalid, reason: reason, next_action: :reconnect_required, claims: nil}

  defp parse_compact(compact) when is_binary(compact) and byte_size(compact) <= 16_384 do
    case String.split(compact, ".", trim: false) do
      [protected64, payload64, signature64] ->
        with {:ok, protected_json} <- Base.url_decode64(protected64, padding: false),
             {:ok, payload_json} <- Base.url_decode64(payload64, padding: false),
             {:ok, signature} <- Base.url_decode64(signature64, padding: false),
             true <- byte_size(signature) == 64,
             true <- duplicate_free_json?(protected_json),
             true <- duplicate_free_json?(payload_json),
             {:ok, header} <- Jason.decode(protected_json),
             {:ok, payload} <- Jason.decode(payload_json),
             true <- is_map(header) and is_map(payload) do
          {:ok, header, payload_json, payload}
        else
          _ -> {:error, :malformed}
        end

      _ ->
        {:error, :malformed}
    end
  end

  defp parse_compact(_), do: {:error, :malformed}

  defp validate_header(header) do
    cond do
      Map.get(header, "alg") != "ES256" ->
        {:error, :wrong_algorithm}

      Map.get(header, "typ") != @proof_type ->
        {:error, :wrong_type}

      not bounded_string?(Map.get(header, "kid"), 128) ->
        {:error, :malformed}

      Map.has_key?(header, "jku") or Map.has_key?(header, "x5u") or Map.has_key?(header, "jwk") ->
        {:error, :malformed}

      Map.get(header, "crit", []) != [] ->
        {:error, :malformed}

      Map.keys(header) |> Enum.sort() != ["alg", "kid", "typ"] ->
        {:error, :malformed}

      true ->
        :ok
    end
  end

  defp local_key(%{"kid" => kid}, keys) when is_list(keys) do
    case Enum.filter(keys, &(is_map(&1) and Map.get(&1, "kid") == kid)) do
      [key] -> validate_public_key(key)
      _ -> {:error, :unknown_key}
    end
  end

  defp local_key(_, _), do: {:error, :unknown_key}

  defp validate_public_key(key) do
    allowed = ["alg", "crv", "kid", "kty", "use", "x", "y"]

    with true <- Map.keys(key) |> Enum.sort() == allowed,
         true <- Map.get(key, "kty") == "EC" and Map.get(key, "crv") == "P-256",
         true <- Map.get(key, "use") == "sig" and Map.get(key, "alg") == "ES256",
         true <- bounded_string?(Map.get(key, "kid"), 128),
         {:ok, x} <- Base.url_decode64(Map.get(key, "x", ""), padding: false),
         {:ok, y} <- Base.url_decode64(Map.get(key, "y", ""), padding: false),
         true <- byte_size(x) == 32 and byte_size(y) == 32 do
      {:ok, key}
    else
      _ -> {:error, :unknown_key}
    end
  end

  defp verify_signature(key, compact) do
    case JOSE.JWS.verify_strict(JOSE.JWK.from(key), ["ES256"], compact) do
      {true, _payload, _jws} -> :ok
      _ -> {:error, :signature_invalid}
    end
  rescue
    _ -> {:error, :signature_invalid}
  end

  defp validate_claims(payload, payload_json, context) do
    with true <- duplicate_free_json?(payload_json),
         true <- Enum.sort(Map.keys(payload)) in [@allow_claims, @deny_claims],
         true <- payload["version"] == @version,
         :ok <- validate_identity(payload, context),
         {:ok, claims} <- claims_from(payload),
         :ok <- validate_temporal_bounds(claims, context.now) do
      {:ok, claims}
    else
      false -> {:error, :malformed}
      {:error, _} = error -> error
    end
  end

  defp claims_from(payload) do
    with true <- Enum.all?(["jti", "sub"], &bounded_string?(payload[&1], @max_string)),
         true <- is_integer(payload["revision"]) and payload["revision"] >= 0,
         true <-
           Enum.all?(
             ["iat", "nbf", "fresh_until"],
             &(is_integer(payload[&1]) and payload[&1] >= 0)
           ),
         true <- is_nil(payload["exp"]) or (is_integer(payload["exp"]) and payload["exp"] >= 0),
         true <- payload["disposition"] in ["allow", "deny"],
         {:ok, plans} <- normalized_strings(payload["plans"]),
         {:ok, features} <- normalized_strings(payload["features"]),
         {:ok, quantities} <- normalized_quantities(payload["quantities"]),
         :ok <- validate_allow_authority(payload["disposition"], plans, features, quantities),
         :ok <- validate_denial(payload) do
      {:ok,
       %Claims{
         version: payload["version"],
         issuer: payload["iss"],
         audience: payload["aud"],
         token_id: payload["jti"],
         subject: payload["sub"],
         confirmation: payload["cnf"]["jkt"],
         revision: payload["revision"],
         issued_at: payload["iat"],
         not_before: payload["nbf"],
         fresh_until: payload["fresh_until"],
         expires_at: payload["exp"],
         disposition: String.to_atom(payload["disposition"]),
         plans: plans,
         features: features,
         quantities: quantities,
         denial_reason: payload["denial_reason"]
       }}
    else
      _ -> {:error, :malformed}
    end
  end

  defp validate_identity(payload, context) do
    cond do
      payload["iss"] != context.issuer ->
        {:error, :wrong_issuer}

      payload["aud"] != context.audience ->
        {:error, :wrong_audience}

      payload["sub"] != context.account_subject ->
        {:error, :device_mismatch}

      not confirmation_matches?(payload["cnf"], context.device_thumbprint) ->
        {:error, :device_mismatch}

      true ->
        :ok
    end
  end

  defp validate_temporal_bounds(claims, now) do
    cond do
      claims.issued_at > claims.not_before or claims.not_before > claims.fresh_until or
          (is_integer(claims.expires_at) and claims.fresh_until > claims.expires_at) ->
        {:error, :malformed}

      claims.not_before > now or claims.issued_at > now ->
        {:error, :future_not_valid}

      is_integer(claims.expires_at) and claims.expires_at <= now ->
        {:error, :hard_expired}

      true ->
        :ok
    end
  end

  defp validate_high_water(claims, context) do
    high = context.clock_high_water || %{}

    cond do
      is_integer(Map.get(high, :now)) and context.now < Map.get(high, :now) ->
        {:error, :clock_rollback}

      claims.revision < max_integer(context.accepted_revision, Map.get(high, :revision)) ->
        {:error, :superseded}

      claims.revision == context.accepted_revision and context.accepted_disposition == :deny and
          claims.disposition == :allow ->
        {:error, :superseded}

      claims.issued_at < max_integer(context.accepted_iat, Map.get(high, :iat)) ->
        {:error, :superseded}

      claims.fresh_until < max_integer(context.accepted_fresh_until, Map.get(high, :fresh_until)) ->
        {:error, :superseded}

      true ->
        :ok
    end
  end

  defp classify(%Claims{disposition: :deny} = claims, _now),
    do: %Decision{
      state: :denied,
      reason: :signed_denial,
      next_action: :reconnect_required,
      claims: claims
    }

  defp classify(%Claims{fresh_until: fresh_until} = claims, now) when fresh_until > now,
    do: %Decision{state: :fresh, reason: :ok, next_action: :none, claims: claims}

  defp classify(claims, _now),
    do: %Decision{
      state: :stale_offline,
      reason: :revalidation_due,
      next_action: :reconnect_required,
      claims: claims
    }

  defp fresh_policy(action, %Claims{} = claims) do
    allowed =
      case action do
        :read_downloaded_lesson ->
          feature?(claims, "offline_study")

        :read_local_progress ->
          feature?(claims, "offline_study")

        :write_local_progress ->
          feature?(claims, "offline_study")

        :download_premium ->
          feature?(claims, "offline_study") and positive_quantity?(claims, "downloads")

        :enroll ->
          plan?(claims, "pro")

        :export ->
          feature?(claims, "export")

        _ ->
          false
      end

    policy(action, allowed, if(allowed, do: :none, else: :reconnect_required), :fresh)
  end

  defp fresh_policy(action, _), do: policy(action, false, :reconnect_required, :fresh)

  defp stale_policy(action)
       when action in [:read_downloaded_lesson, :read_local_progress, :write_local_progress],
       do: policy(action, true, :none, :stale_offline)

  defp stale_policy(action), do: policy(action, false, :reconnect_required, :stale_offline)

  defp unavailable_policy(action, state)
       when action in [:read_local_progress, :write_local_progress],
       do: policy(action, true, :none, state)

  defp unavailable_policy(action, :denied),
    do: policy(action, false, :access_unavailable, :denied)

  defp unavailable_policy(action, :invalid), do: policy(action, false, :check_access, :invalid)

  defp policy(action, allowed, next_action, guidance_key),
    do: %ActionPolicy{
      action: action,
      allowed: allowed,
      next_action: next_action,
      guidance_key: guidance_key
    }

  defp feature?(%Claims{features: features}, feature), do: feature in features
  defp plan?(%Claims{plans: plans}, plan), do: plan in plans

  defp positive_quantity?(%Claims{quantities: quantities}, key),
    do: is_integer(quantities[key]) and quantities[key] > 0

  defp confirmation_matches?(%{"jkt" => thumbprint}, expected),
    do: bounded_string?(thumbprint, @max_string) and thumbprint == expected

  defp confirmation_matches?(_, _), do: false

  defp validate_denial(%{"disposition" => "allow"} = payload),
    do: if(Map.has_key?(payload, "denial_reason"), do: {:error, :malformed}, else: :ok)

  defp validate_denial(%{"disposition" => "deny", "denial_reason" => reason})
       when is_binary(reason) and byte_size(reason) <= @max_string and reason in @denial_reasons,
       do: :ok

  defp validate_denial(%{"disposition" => "deny"}), do: {:error, :malformed}
  defp validate_denial(_), do: {:error, :malformed}

  # A signed allow without at least one effective entitlement is indistinguishable
  # from an accidental empty snapshot. Issuers must publish a deny tombstone instead.
  defp validate_allow_authority("allow", [], [], quantities) when map_size(quantities) == 0,
    do: {:error, :malformed}

  defp validate_allow_authority("allow", _plans, _features, _quantities), do: :ok
  defp validate_allow_authority("deny", _plans, _features, _quantities), do: :ok
  defp validate_allow_authority(_, _, _, _), do: {:error, :malformed}

  defp normalized_strings(values) when is_list(values) and length(values) <= @max_collection do
    if Enum.all?(values, &bounded_string?(&1, @max_string)) and values == Enum.sort(values) and
         values == Enum.uniq(values), do: {:ok, values}, else: {:error, :malformed}
  end

  defp normalized_strings(_), do: {:error, :malformed}

  defp normalized_quantities(values)
       when is_map(values) and map_size(values) <= @max_collection do
    if Enum.all?(values, fn {key, value} ->
         bounded_string?(key, @max_string) and is_integer(value) and value > 0
       end), do: {:ok, values}, else: {:error, :malformed}
  end

  defp normalized_quantities(_), do: {:error, :malformed}

  # Ordered objects preserve parsed (and therefore JSON-unescaped) member names.
  # Checking this tree rejects duplicate keys at every nesting level before the
  # ordinary map decoder is allowed to choose one of the ambiguous values.
  defp duplicate_free_json?(json) do
    with {:ok, value} <- Jason.decode(json, objects: :ordered_objects) do
      duplicate_free_value?(value)
    else
      _ -> false
    end
  end

  defp duplicate_free_value?(%Jason.OrderedObject{values: values}) do
    keys = Enum.map(values, &elem(&1, 0))

    length(keys) == MapSet.size(MapSet.new(keys)) and
      Enum.all?(values, fn {_, value} -> duplicate_free_value?(value) end)
  end

  defp duplicate_free_value?(values) when is_list(values),
    do: Enum.all?(values, &duplicate_free_value?/1)

  defp duplicate_free_value?(value) when is_map(value),
    do: Enum.all?(value, fn {_, nested} -> duplicate_free_value?(nested) end)

  defp duplicate_free_value?(_), do: true

  defp bounded_string?(value, max),
    do: is_binary(value) and byte_size(value) > 0 and byte_size(value) <= max

  defp max_integer(left, right) when is_integer(left) and is_integer(right), do: max(left, right)
  defp max_integer(left, _) when is_integer(left), do: left
  defp max_integer(_, right) when is_integer(right), do: right
  defp max_integer(_, _), do: 0
end
