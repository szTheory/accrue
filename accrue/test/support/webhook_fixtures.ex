defmodule Accrue.WebhookFixtures do
  @moduledoc """
  Test fixtures for webhook payloads. Generates valid Stripe-signed
  webhook events using lattice_stripe's test signature helper.

  ## Usage

      {body, signature} = Accrue.WebhookFixtures.signed_event()
      conn =
        conn(:post, "/webhook/stripe", body)
        |> put_req_header("stripe-signature", signature)
        |> put_req_header("content-type", "application/json")

  """

  @default_secret "whsec_test_secret_for_accrue_tests"

  @doc "Returns the default webhook signing secret used in test configuration."
  def default_secret, do: @default_secret

  @doc """
  Builds a signed webhook request body and stripe-signature header.

  Returns `{body_string, signature_header}`.

  ## Options

    * `:secret` — signing secret (default: `default_secret/0`)
    * `:timestamp` — Unix timestamp for the signature (default: now)

  """
  def signed_event(attrs \\ %{}, opts \\ []) do
    secret = Keyword.get(opts, :secret, @default_secret)
    sig_opts = if ts = Keyword.get(opts, :timestamp), do: [timestamp: ts], else: []
    event = build_event(attrs)
    body = Jason.encode!(event)
    signature = LatticeStripe.Webhook.generate_test_signature(body, secret, sig_opts)
    {body, signature}
  end

  @doc """
  Builds a webhook event map (unsigned).

  Override any key by passing a map of string-keyed or atom-keyed overrides.
  """
  def build_event(overrides \\ %{}) do
    base = %{
      "id" => "evt_test_#{System.unique_integer([:positive])}",
      "object" => "event",
      "type" => "customer.created",
      "livemode" => false,
      "created" => DateTime.utc_now() |> DateTime.to_unix(),
      "data" => %{
        "object" => %{
          "id" => "cus_test_#{System.unique_integer([:positive])}",
          "object" => "customer",
          "email" => "test@example.com"
        }
      },
      "api_version" => "2026-03-25.dahlia"
    }

    Map.merge(base, stringify_keys(overrides))
  end

  @doc """
  Builds a tampered body (valid JSON but signature won't match).

  Signs the original event, then modifies the body so the signature
  becomes invalid. Returns `{tampered_body, original_signature}`.
  """
  def tampered_event(attrs \\ %{}, opts \\ []) do
    {_body, signature} = signed_event(attrs, opts)
    tampered = build_event(attrs) |> Map.put("tampered", true)
    tampered_body = Jason.encode!(tampered)
    {tampered_body, signature}
  end

  @doc """
  Builds a signed event with a specific Stripe event type.

  Convenience for `signed_event(%{"type" => type}, opts)`.
  """
  def signed_event_of_type(type, opts \\ []) when is_binary(type) do
    signed_event(%{"type" => type}, opts)
  end

  # --- internals ---

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end
end
