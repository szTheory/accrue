defmodule Accrue.EventLedgerImmutableError do
  @moduledoc """
  Raised when a caller attempts to UPDATE or DELETE a row in
  `accrue_events`. The append-only guarantee is enforced in two places:

    1. A Postgres `BEFORE UPDATE OR DELETE` trigger raises
       SQLSTATE `45A01` (D-09 primary defense).
    2. A REVOKE migration stub ships at
       `priv/accrue/templates/migrations/revoke_accrue_events_writes.exs`
       for host apps to run as defense-in-depth (D-10).

  The `Accrue.Events` module pattern-matches the underlying
  `Postgrex.Error` on the `pg_code: "45A01"` field (NOT on message string
  — D-11) and re-raises this exception so downstream callers see a clean
  domain error type.
  """

  defexception [:message, :event_id, :operation, :pg_code]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{operation: op}) when is_atom(op) and not is_nil(op),
    do: "accrue_events is append-only; #{op} forbidden"

  def message(_), do: "accrue_events is append-only; UPDATE and DELETE are forbidden"
end
