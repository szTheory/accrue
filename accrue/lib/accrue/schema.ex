defmodule Accrue.Schema do
  @moduledoc """
  Shared Ecto schema setup for Accrue-owned database tables.

  Accrue tables live in the configured billing schema at compile time. Host
  applications that intentionally keep Accrue in `public` must set
  `config :accrue, :billing_schema, "public"` in compile-time config.
  """

  @billing_schema Application.compile_env(:accrue, :billing_schema, "billing")

  defmacro __using__(_opts) do
    billing_schema = Accrue.Config.validate_billing_schema!(@billing_schema)

    quote bind_quoted: [billing_schema: billing_schema] do
      use Ecto.Schema

      @schema_prefix billing_schema
    end
  end
end
