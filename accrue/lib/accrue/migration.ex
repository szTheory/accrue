defmodule Accrue.Migration do
  @moduledoc """
  Helpers for Accrue-owned migrations.

  The host owns the Repo, but Accrue owns its billing tables. These helpers keep
  migration prefixes and raw SQL table qualification aligned with
  `config :accrue, :billing_schema`.
  """

  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/

  def billing_prefix, do: Accrue.Config.billing_schema()

  def create_billing_schema do
    prefix = billing_prefix()

    if prefix != "public" do
      Ecto.Migration.execute("CREATE SCHEMA IF NOT EXISTS #{quote_identifier(prefix)}")
    end
  end

  def table(name, opts \\ []) do
    Ecto.Migration.table(name, Keyword.put_new(opts, :prefix, billing_prefix()))
  end

  def references(name, opts \\ []) do
    Ecto.Migration.references(name, Keyword.put_new(opts, :prefix, billing_prefix()))
  end

  def index(table, columns, opts \\ []) do
    Ecto.Migration.index(table, columns, Keyword.put_new(opts, :prefix, billing_prefix()))
  end

  def unique_index(table, columns, opts \\ []) do
    Ecto.Migration.unique_index(table, columns, Keyword.put_new(opts, :prefix, billing_prefix()))
  end

  def qualified_table(name), do: qualified_name(billing_prefix(), name)

  def qualified_name(prefix, name) do
    quote_identifier(prefix) <> "." <> quote_identifier(name)
  end

  def quote_identifier(identifier) when is_atom(identifier),
    do: identifier |> Atom.to_string() |> quote_identifier()

  def quote_identifier(identifier) when is_binary(identifier) do
    if Regex.match?(@identifier, identifier) do
      ~s("#{identifier}")
    else
      raise ArgumentError, "invalid PostgreSQL identifier: #{inspect(identifier)}"
    end
  end
end
