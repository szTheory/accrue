defmodule Accrue.Entitlements.Offline do
  @moduledoc """
  Public, public-key-only verification support for versioned offline entitlement proofs.
  """

  alias Accrue.Entitlements.Offline.{
    Challenge,
    Issuance,
    Issuer,
    KeyProvider,
    Proof,
    Reconnect,
    Registration
  }

  @spec reconnect(Accrue.Entitlements.Account.t(), Reconnect.Request.t(), keyword()) ::
          {:ok, Reconnect.Outcome.t()} | {:error, atom()}
  def reconnect(account, request, opts \\ [])

  def reconnect(account, %Reconnect.Request{} = request, opts),
    do: Reconnect.reconnect(account, request, opts)

  def reconnect(_, _, _), do: {:error, :invalid_request}

  @doc """
  Rejects direct proof issuance.

  A compact entitlement proof is minted only after the authenticated reconnect
  flow has verified a one-time device proof-of-possession. Hosts must use
  `reconnect/3`; accepting an account and device id here would make either an
  allow proof or a deny tombstone forgeable without that admission boundary.
  """
  @spec issue(Accrue.Entitlements.Account.t(), Issuer.Request.t(), keyword()) ::
          {:error, :unauthorized}
  def issue(account, request, opts \\ [])

  def issue(%Accrue.Entitlements.Account{}, %Issuer.Request{}, opts) when is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :issue],
      %{action: :offline_issue, disposition: :rejected, reason: :unauthorized},
      fn -> {:error, :unauthorized} end
    )
  end

  def issue(_, _, _), do: {:error, :unauthorized}

  @spec challenge(Accrue.Entitlements.Account.t(), String.t(), keyword()) ::
          {:ok, Challenge.Value.t()} | {:error, :unauthorized | :invalid_request}
  def challenge(account, installation_id, opts \\ [])

  def challenge(%Accrue.Entitlements.Account{} = account, installation_id, opts)
      when is_binary(installation_id) and is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :challenge],
      %{action: :offline_challenge, outcome: :requested},
      fn -> create_challenge(account, installation_id, :registration, opts) end
    )
  end

  def challenge(_, _, _), do: {:error, :invalid_request}

  @doc "Creates a one-time challenge for an authenticated device reconnect."
  @spec reconnect_challenge(Accrue.Entitlements.Account.t(), String.t(), keyword()) ::
          {:ok, Challenge.Value.t()} | {:error, :unauthorized | :invalid_request}
  def reconnect_challenge(account, installation_id, opts \\ [])

  def reconnect_challenge(%Accrue.Entitlements.Account{} = account, installation_id, opts)
      when is_binary(installation_id) and is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :reconnect_challenge],
      %{action: :offline_reconnect_challenge, outcome: :requested},
      fn -> create_challenge(account, installation_id, :reconnect, opts) end
    )
  end

  def reconnect_challenge(_, _, _), do: {:error, :invalid_request}

  @spec register_device(Accrue.Entitlements.Account.t(), Registration.Request.t(), keyword()) ::
          {:ok, Registration.Result.t()} | {:error, atom()}
  def register_device(account, request, opts \\ [])

  def register_device(account, %Registration.Request{} = request, opts) do
    Registration.register(account, request, opts)
  end

  def register_device(_, _, _), do: {:error, :invalid_request}

  @spec verify(binary(), Proof.VerificationContext.t() | map(), keyword()) ::
          {:ok, Proof.Decision.t()}
  def verify(compact, context, opts \\ [])

  def verify(compact, context, opts) when is_binary(compact) and is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :verify],
      %{
        action: :verify,
        proof_size: byte_size(compact),
        source: Keyword.get(opts, :source, :local)
      },
      fn -> {:ok, Proof.verify(compact, context, opts)} end
    )
  end

  def verify(_, _, _), do: {:ok, Proof.invalid(:malformed)}

  @doc "Returns the bounded client-side action policy for a verified offline decision."
  @spec action_policy(Proof.Decision.t(), atom()) :: Proof.ActionPolicy.t()
  def action_policy(decision, action), do: Proof.action_policy(decision, action)

  @doc "Returns the typed learner-facing guidance seed for a public proof state."
  @spec guidance(:fresh | :stale_offline | :denied | :invalid) :: Proof.Guidance.t()
  def guidance(state), do: Proof.guidance(state)

  @spec verification_keys(keyword()) ::
          {:ok, %{required(String.t()) => [map()]}} | {:error, :config_invalid}
  def verification_keys(opts \\ [])

  def verification_keys(opts) when is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :verification_keys],
      %{
        action: :verification_keys,
        source: if(Keyword.has_key?(opts, :keys), do: :explicit, else: :provider)
      },
      fn -> render_verification_keys(opts) end
    )
  end

  def verification_keys(_), do: {:error, :config_invalid}

  @doc """
  Renders public verification keys while enforcing retirement requirements derived
  from actual issued proofs.

  Unlike `verification_keys/1`, this operation requires a Repo. Call it from the
  host's JWKS publication path; explicit keys and injected providers can use the
  pure renderer with precomputed `:retention_requirements` instead.
  """
  @spec verification_keys_with_issued_retention(keyword()) ::
          {:ok, %{required(String.t()) => [map()]}} | {:error, :config_invalid}
  def verification_keys_with_issued_retention(opts \\ [])

  def verification_keys_with_issued_retention(opts) when is_list(opts) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())
    now = Keyword.get(opts, :now, DateTime.utc_now())
    requirements = Issuance.retirement_requirements(repo, now, opts)

    verification_keys(Keyword.put(opts, :retention_requirements, requirements))
  end

  def verification_keys_with_issued_retention(_), do: {:error, :config_invalid}

  defp render_verification_keys(opts) do
    with {:ok, keys} <- public_keys(opts) do
      KeyProvider.render_public_keys(keys, Keyword.get(opts, :retention_requirements, %{}))
    else
      _ -> {:error, :config_invalid}
    end
  end

  defp public_keys(opts) do
    case Keyword.fetch(opts, :keys) do
      {:ok, keys} -> {:ok, keys}
      :error -> configured_public_keys(opts)
    end
  end

  defp configured_public_keys(opts) do
    provider = Keyword.get(opts, :provider, Application.get_env(:accrue, :offline_key_provider))

    if is_atom(provider) and Code.ensure_loaded?(provider) and
         function_exported?(provider, :public_keys, 1) do
      provider.public_keys(opts)
    else
      {:error, :config_invalid}
    end
  rescue
    _ -> {:error, :config_invalid}
  end

  defp create_challenge(account, installation_id, purpose, opts) do
    if authorized?(opts, account, challenge_action(purpose)) do
      now = Keyword.get(opts, :now, DateTime.utc_now())
      expires_at = DateTime.add(now, Keyword.get(opts, :challenge_ttl_seconds, 300), :second)
      nonce = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
      repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

      case repo.insert(
             Challenge.changeset(%Challenge{}, %{
               account_id: account.id,
               installation_id: installation_id,
               nonce_digest: digest(nonce),
               purpose: purpose,
               expires_at: expires_at
             })
           ) do
        {:ok, challenge} ->
          {:ok,
           %Challenge.Value{
             id: challenge.id,
             nonce: nonce,
             expires_at: challenge.expires_at,
             purpose: challenge.purpose
           }}

        {:error, _} ->
          {:error, :invalid_request}
      end
    else
      {:error, :unauthorized}
    end
  end

  defp challenge_action(:registration), do: :offline_challenge
  defp challenge_action(:reconnect), do: :offline_reconnect_challenge

  defp authorized?(opts, account, action) do
    case Keyword.get(opts, :authorize) do
      callback when is_function(callback, 2) -> callback.(account, action) == true
      _ -> false
    end
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)
end
