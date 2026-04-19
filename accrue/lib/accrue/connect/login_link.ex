defmodule Accrue.Connect.LoginLink do
  @moduledoc """
  Express dashboard return credential for a connected account.

  The `:url` field is a single-use, short-lived bearer credential that
  logs the Express connected account owner into their Stripe Express
  dashboard. **Login Links are only valid for `type: "express"`
  connected accounts** — calling Stripe with a Standard or Custom
  account returns HTTP 400. `Accrue.Connect.create_login_link/2` fails
  fast locally before reaching the processor.

  As with `Accrue.Connect.AccountLink`, the `:url` field is masked in
  Inspect output. Create-only resource.
  """

  @enforce_keys [:url, :created]
  defstruct [:url, :created, object: "login_link"]

  @type t :: %__MODULE__{
          url: String.t(),
          created: DateTime.t(),
          object: String.t()
        }

  @doc """
  Projects a raw processor response (atom- or string-keyed map, or a
  bare processor struct unwrapped to map form) into a tightly-typed
  `t()`. The Unix integer `created` timestamp is converted to
  `DateTime` via `DateTime.from_unix!/1`.
  """
  @spec from_stripe(map() | struct()) :: t()
  def from_stripe(%_{} = struct), do: from_stripe(Map.from_struct(struct))

  def from_stripe(map) when is_map(map) do
    %__MODULE__{
      url: get(map, :url),
      created: to_datetime(get(map, :created)),
      object: get(map, :object) || "login_link"
    }
  end

  defp get(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp to_datetime(nil), do: nil
  defp to_datetime(%DateTime{} = dt), do: dt
  defp to_datetime(unix) when is_integer(unix), do: DateTime.from_unix!(unix)
end

defimpl Inspect, for: Accrue.Connect.LoginLink do
  import Inspect.Algebra

  # `:url` is a single-use short-lived bearer credential.
  def inspect(%Accrue.Connect.LoginLink{} = link, opts) do
    fields = [
      url: if(link.url, do: "<redacted>", else: nil),
      created: link.created,
      object: link.object
    ]

    pairs =
      fields
      |> Enum.map(fn {k, v} ->
        concat([Atom.to_string(k), ": ", to_doc(v, opts)])
      end)
      |> Enum.intersperse(", ")

    concat(["#Accrue.Connect.LoginLink<" | pairs] ++ [">"])
  end
end
