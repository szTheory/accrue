defmodule Accrue.Entitlements.Offline do
  @moduledoc """
  Public, public-key-only verification support for versioned offline entitlement proofs.
  """

  alias Accrue.Entitlements.Offline.Proof

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
end
