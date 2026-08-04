defmodule Accrue.Entitlements.Offline do
  @moduledoc """
  Public, public-key-only verification support for versioned offline entitlement proofs.
  """

  alias Accrue.Entitlements.Offline.{KeyProvider, Proof}

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
end
