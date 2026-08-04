defmodule Accrue.Entitlements.Offline do
  @moduledoc """
  Public, public-key-only verification support for versioned offline entitlement proofs.
  """

  alias Accrue.Entitlements.Offline.{Challenge, KeyProvider, Proof, Registration}

  @spec challenge(Accrue.Entitlements.Account.t(), String.t(), keyword()) ::
          {:ok, Challenge.Value.t()} | {:error, :unauthorized | :invalid_request}
  def challenge(account, installation_id, opts \\ [])

  def challenge(%Accrue.Entitlements.Account{} = account, installation_id, opts)
      when is_binary(installation_id) and is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :offline, :challenge],
      %{action: :offline_challenge, outcome: :requested},
      fn -> create_challenge(account, installation_id, opts) end
    )
  end

  def challenge(_, _, _), do: {:error, :invalid_request}

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

  defp create_challenge(account, installation_id, opts) do
    if authorized?(opts, account, :offline_challenge) do
      now = Keyword.get(opts, :now, DateTime.utc_now())
      expires_at = DateTime.add(now, Keyword.get(opts, :challenge_ttl_seconds, 300), :second)
      nonce = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
      repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

      case repo.insert(
             Challenge.changeset(%Challenge{}, %{
               account_id: account.id,
               installation_id: installation_id,
               nonce_digest: digest(nonce),
               purpose: :registration,
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

  defp authorized?(opts, account, action) do
    case Keyword.get(opts, :authorize) do
      callback when is_function(callback, 2) -> callback.(account, action) == true
      _ -> false
    end
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)
end
