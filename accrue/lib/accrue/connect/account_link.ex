defmodule Accrue.Connect.AccountLink do
  @moduledoc """
  Onboarding/update bearer credential for a connected account (D5-06).

  The `:url` field is a single-use short-lived (~5 minute) bearer
  credential that authorizes the recipient to complete Stripe's hosted
  onboarding flow for the connected account. Any leak via Logger, APM,
  crash dumps, or telemetry handlers is a takeover vector — Inspect
  masks `:url` as `<redacted>` just like Phase 4
  `Accrue.BillingPortal.Session` (T-05-03-01).

  Create-only resource: Stripe exposes no retrieve/update/delete/list
  endpoint for AccountLinks — build a new one each time.
  """

  @enforce_keys [:url, :expires_at, :created, :object]
  defstruct [:url, :expires_at, :created, :object]

  @type t :: %__MODULE__{
          url: String.t(),
          expires_at: DateTime.t(),
          created: DateTime.t(),
          object: String.t()
        }

  @doc """
  Projects a raw processor response (atom- or string-keyed map, or a
  bare processor struct unwrapped to map form) into a tightly-typed
  `t()`. Unix integer timestamps are converted to `DateTime` via
  `DateTime.from_unix!/1`.
  """
  @spec from_stripe(map() | struct()) :: t()
  def from_stripe(%_{} = struct), do: from_stripe(Map.from_struct(struct))

  def from_stripe(map) when is_map(map) do
    %__MODULE__{
      url: get(map, :url),
      expires_at: to_datetime(get(map, :expires_at)),
      created: to_datetime(get(map, :created)),
      object: get(map, :object) || "account_link"
    }
  end

  # Dual-key (atom or string) getter — mirrors
  # `Accrue.BillingPortal.Session.get/2`.
  defp get(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp to_datetime(nil), do: nil
  defp to_datetime(%DateTime{} = dt), do: dt
  defp to_datetime(unix) when is_integer(unix), do: DateTime.from_unix!(unix)
end

defimpl Inspect, for: Accrue.Connect.AccountLink do
  import Inspect.Algebra

  # T-05-03-01: `:url` is a single-use short-lived bearer credential.
  # Mask in Inspect output the same way Phase 4 masks
  # `Accrue.BillingPortal.Session.url`.
  def inspect(%Accrue.Connect.AccountLink{} = link, opts) do
    fields = [
      url: if(link.url, do: "<redacted>", else: nil),
      expires_at: link.expires_at,
      created: link.created,
      object: link.object
    ]

    pairs =
      fields
      |> Enum.map(fn {k, v} ->
        concat([Atom.to_string(k), ": ", to_doc(v, opts)])
      end)
      |> Enum.intersperse(", ")

    concat(["#Accrue.Connect.AccountLink<" | pairs] ++ [">"])
  end
end
