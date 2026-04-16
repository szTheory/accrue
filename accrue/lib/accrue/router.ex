defmodule Accrue.Router do
  @moduledoc """
  Router helpers for mounting Accrue webhook endpoints.

  ## Usage (Phoenix router)

      import Accrue.Router

      pipeline :accrue_webhook_raw_body do
        plug Plug.Parsers,
          parsers: [:json],
          pass: ["*/*"],
          json_decoder: Jason,
          body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
          length: 1_000_000
      end

      scope "/webhooks" do
        pipe_through :accrue_webhook_raw_body
        accrue_webhook "/stripe", :stripe
      end

  ## Multi-endpoint (Phase 4 Connect ready, D2-18)

  The macro accepts a processor atom. Calling `accrue_webhook/2` multiple
  times with different processors works natively:

      scope "/webhooks" do
        pipe_through :accrue_webhook_raw_body
        accrue_webhook "/stripe", :stripe
        accrue_webhook "/connect", :stripe_connect
      end

  Each resolves to its own signing secret via `Accrue.Config`.
  """

  @doc """
  Mounts the Accrue webhook plug at the given `path` for the specified
  `processor`.

  Expands to `forward path, Accrue.Webhook.Plug, processor: processor`.
  Must be called inside a scope that pipes through a pipeline containing
  `Plug.Parsers` with `body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}`.
  """
  defmacro accrue_webhook(path, processor) do
    quote do
      forward(unquote(path), Accrue.Webhook.Plug, processor: unquote(processor))
    end
  end
end
