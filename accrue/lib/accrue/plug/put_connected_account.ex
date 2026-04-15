defmodule Accrue.Plug.PutConnectedAccount do
  @moduledoc """
  Stashes a per-request Connect `stripe_account` id into the process
  dictionary (D5-01, CONN-11).

  The scope value is resolved from a compile-time MFA tuple — never
  from a raw HTTP header or query parameter (T-05-02-01). The configured
  tenancy function receives the `%Plug.Conn{}` as its last argument so
  the host app can read `conn.assigns`, session data, or subdomain to
  decide which connected account the request operates on.

  ## Usage

      plug Accrue.Plug.PutConnectedAccount,
        from: {MyAppWeb.Tenancy, :current_stripe_account, []}

  `MyAppWeb.Tenancy.current_stripe_account/1` (note: Accrue appends
  `conn` as the trailing argument, so the declared arity is
  `length(args) + 1`) must return one of:

    * `nil` — platform scope (default; plug is a no-op)
    * a binary `"acct_..."` id
    * an `%Accrue.Connect.Account{}` struct

  Any other return shape raises `ArgumentError`.
  """

  @behaviour Plug

  alias Accrue.Connect
  alias Accrue.Connect.Account

  @impl true
  def init(opts) when is_list(opts) do
    case Keyword.fetch(opts, :from) do
      {:ok, {mod, fun, args}} when is_atom(mod) and is_atom(fun) and is_list(args) ->
        opts

      {:ok, other} ->
        raise ArgumentError,
              "Accrue.Plug.PutConnectedAccount expected `:from` to be an MFA tuple " <>
                "{Module, :function, args}, got: #{inspect(other)}"

      :error ->
        raise ArgumentError,
              "Accrue.Plug.PutConnectedAccount requires a `:from` MFA tuple option"
    end
  end

  @impl true
  def call(conn, opts) do
    {mod, fun, args} = Keyword.fetch!(opts, :from)

    case apply(mod, fun, args ++ [conn]) do
      nil ->
        conn

      id when is_binary(id) ->
        :ok = Connect.put_account_id(id)
        conn

      %Account{stripe_account_id: id} when is_binary(id) ->
        :ok = Connect.put_account_id(id)
        conn

      other ->
        raise ArgumentError,
              "Accrue.Plug.PutConnectedAccount MFA returned unexpected value: " <>
                inspect(other)
    end
  end
end
