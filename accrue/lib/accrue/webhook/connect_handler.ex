defmodule Accrue.Webhook.ConnectHandler do
  @moduledoc """
  Webhook handler for events arriving on the `:connect` endpoint (D5-01, D5-05).

  Stripe Connect platforms receive two distinct webhook streams:

  1. **Platform events** (`/webhooks/stripe`) — account-scoped events
     targeting the platform account itself; dispatched to
     `Accrue.Webhook.DefaultHandler`.
  2. **Connect events** (`/webhooks/stripe/connect`) — events relayed by
     Stripe from a connected account (`account.updated`,
     `account.application.{authorized,deauthorized}`, `capability.updated`,
     `payout.*`, `person.*`); dispatched to this module.

  The `Accrue.Webhook.DispatchWorker` reads `row.endpoint` from the
  persisted `accrue_webhook_events` row and selects the handler module at
  dispatch time (Plan 05-01). This module implements the D5-05 reducer
  set on top of that plumbing.

  ## Reducer shape

  Every reducer runs inside `Accrue.Repo.transact/1` with an
  `Accrue.Events.record/1` call appended so the state mutation and audit
  row commit atomically (EVT-04). For events whose payload is needed
  beyond the `%Accrue.Webhook.Event{}` struct's `object_id`, the raw
  `accrue_webhook_events.data` jsonb row is refetched via
  `ctx.webhook_event_id` — the handler never trusts the lean Event
  struct alone for anything beyond routing.

  ## Out-of-order delivery (Pitfall 3)

  Stripe does not guarantee webhook delivery order. An `account.updated`
  for a just-created account can arrive before the local
  `accrue_connect_accounts` row has been inserted. The reducer handles
  this by calling `Accrue.Connect.retrieve_account/2`, which runs the
  canonical processor round-trip and upserts the local row via
  `Accrue.Connect.Account.force_status_changeset/2` — so a missing row
  is seeded from the latest Stripe state in the same transaction that
  would otherwise have failed. Later, in-order events arriving on a
  now-settled row update it the same way (idempotent).

  The reducer uses "refetch canonical" rather than "compare
  timestamps" for stale-event detection: because the Stripe round-trip
  always returns the current account state, a stale webhook replay
  overwrites the row with the same values it already has — a
  functional no-op — rather than clobbering later events with older
  snapshot data (Pitfall 3).

  ## Deauthorization tombstoning (D5-05)

  `account.application.deauthorized` NEVER hard-deletes the local row.
  It stamps `deauthorized_at` via `force_status_changeset/2` so the row
  survives for audit (T-05-06-02), and emits an ops telemetry event
  `[:accrue, :ops, :connect_account_deauthorized]` via
  `Accrue.Telemetry.Ops`.

  ## Scope

  Reducers for `person.*` log a debug line and no-op — Custom-account
  person KYC is deferred to v1.x.
  """

  use Accrue.Webhook.Handler

  require Logger

  alias Accrue.{Connect, Events, Repo}
  alias Accrue.Connect.Account
  alias Accrue.Telemetry.Ops
  alias Accrue.Webhook.WebhookEvent

  # ---------------------------------------------------------------------
  # Account lifecycle
  # ---------------------------------------------------------------------

  @impl Accrue.Webhook.Handler
  def handle_event("account.updated", %Accrue.Webhook.Event{object_id: acct_id} = _event, _ctx)
      when is_binary(acct_id) do
    span([:accrue, :connect, :account_updated], %{stripe_account_id: acct_id}, fn ->
      reduce_account_updated(acct_id)
    end)
  end

  def handle_event(
        "account.application.authorized",
        %Accrue.Webhook.Event{object_id: acct_id} = _event,
        _ctx
      )
      when is_binary(acct_id) do
    span(
      [:accrue, :connect, :account_application_authorized],
      %{stripe_account_id: acct_id},
      fn -> reduce_account_authorized(acct_id) end
    )
  end

  def handle_event(
        "account.application.deauthorized",
        %Accrue.Webhook.Event{object_id: acct_id} = _event,
        _ctx
      )
      when is_binary(acct_id) do
    span(
      [:accrue, :connect, :account_application_deauthorized],
      %{stripe_account_id: acct_id},
      fn -> reduce_account_deauthorized(acct_id) end
    )
  end

  # ---------------------------------------------------------------------
  # Capability lifecycle
  # ---------------------------------------------------------------------

  def handle_event("capability.updated", %Accrue.Webhook.Event{} = _event, ctx) do
    span([:accrue, :connect, :capability_updated], %{}, fn ->
      case payload_from_ctx(ctx) do
        {:ok, payload} -> reduce_capability_updated(payload)
        {:error, :no_payload} -> {:ok, :no_payload}
      end
    end)
  end

  # ---------------------------------------------------------------------
  # Payout lifecycle — events-only (no local payout schema in v1.0)
  # ---------------------------------------------------------------------

  def handle_event("payout.created", %Accrue.Webhook.Event{} = _event, ctx) do
    span([:accrue, :connect, :payout_created], %{}, fn ->
      reduce_payout(ctx, "connect.payout.created", :payout_created)
    end)
  end

  def handle_event("payout.paid", %Accrue.Webhook.Event{} = _event, ctx) do
    span([:accrue, :connect, :payout_paid], %{}, fn ->
      reduce_payout(ctx, "connect.payout.paid", :payout_paid)
    end)
  end

  def handle_event("payout.failed", %Accrue.Webhook.Event{} = _event, ctx) do
    span([:accrue, :connect, :payout_failed], %{}, fn ->
      reduce_payout(ctx, "connect.payout.failed", :payout_failed)
    end)
  end

  # ---------------------------------------------------------------------
  # Person lifecycle — Custom-account KYC, deferred
  # ---------------------------------------------------------------------

  def handle_event("person.created", _event, _ctx) do
    Logger.debug(
      "ConnectHandler: person.created — passthrough (Custom-account scope, deferred to v1.x)"
    )

    :ok
  end

  def handle_event("person.updated", _event, _ctx) do
    Logger.debug(
      "ConnectHandler: person.updated — passthrough (Custom-account scope, deferred to v1.x)"
    )

    :ok
  end

  # Catch-all — Connect events should always ack so Stripe stops
  # retrying. Unknown types (e.g. future account.external_account.*)
  # land here.
  def handle_event(_type, _event, _ctx), do: :ok

  # =====================================================================
  # Reducers
  # =====================================================================

  defp reduce_account_updated(acct_id) do
    Repo.transact(fn ->
      # `retrieve_account/2` upserts the local row via
      # `upsert_local/3`, which runs its OWN `Repo.transact/1` and
      # `Events.record/1` for the `connect.account.retrieved` event.
      # Nested transactions on the same Ecto.Repo collapse into a
      # single outer transaction, so if this outer block raises the
      # inner upsert is rolled back with it (EVT-04 invariant).
      case Connect.retrieve_account(acct_id) do
        {:ok, %Account{} = row} ->
          {:ok, _} =
            Events.record(%{
              type: "connect.account.updated",
              subject_type: "Accrue.Connect.Account",
              subject_id: row.stripe_account_id,
              data: %{"stripe_account_id" => row.stripe_account_id}
            })

          {:ok, row}

        {:error, err} ->
          {:error, err}
      end
    end)
  end

  defp reduce_account_authorized(acct_id) do
    Repo.transact(fn ->
      case Connect.retrieve_account(acct_id) do
        {:ok, %Account{} = row} ->
          {:ok, _} =
            Events.record(%{
              type: "connect.account.application.authorized",
              subject_type: "Accrue.Connect.Account",
              subject_id: row.stripe_account_id,
              data: %{"stripe_account_id" => row.stripe_account_id}
            })

          {:ok, row}

        {:error, err} ->
          {:error, err}
      end
    end)
  end

  defp reduce_account_deauthorized(acct_id) do
    Repo.transact(fn ->
      row =
        case Repo.repo().get_by(Account, stripe_account_id: acct_id) do
          %Account{} = existing ->
            existing

          nil ->
            # Seed the local row if the app was authorized before Accrue
            # was installed, so the tombstone has somewhere to land.
            case Connect.retrieve_account(acct_id) do
              {:ok, seeded} -> seeded
              {:error, _} -> nil
            end
        end

      case row do
        %Account{} = row ->
          now = DateTime.utc_now()

          {:ok, updated} =
            row
            |> Account.force_status_changeset(%{deauthorized_at: now})
            |> Repo.repo().update()

          {:ok, _} =
            Events.record(%{
              type: "connect.account.application.deauthorized",
              subject_type: "Accrue.Connect.Account",
              subject_id: updated.stripe_account_id,
              data: %{
                "stripe_account_id" => updated.stripe_account_id,
                "deauthorized_at" => DateTime.to_iso8601(now)
              }
            })

          Ops.emit(
            :connect_account_deauthorized,
            %{count: 1},
            %{stripe_account_id: updated.stripe_account_id, deauthorized_at: now}
          )

          {:ok, updated}

        nil ->
          # Row unresolvable (retrieve_account failed AND no local row).
          # Still record the audit event so the ledger captures the
          # deauthorization signal, and emit ops telemetry.
          {:ok, _} =
            Events.record(%{
              type: "connect.account.application.deauthorized",
              subject_type: "Accrue.Connect.Account",
              subject_id: acct_id,
              data: %{"stripe_account_id" => acct_id, "unresolved" => true}
            })

          Ops.emit(
            :connect_account_deauthorized,
            %{count: 1},
            %{stripe_account_id: acct_id, unresolved: true}
          )

          {:ok, :unresolved}
      end
    end)
  end

  defp reduce_capability_updated(payload) do
    acct_id = get(payload, "account")
    cap_name = get(payload, "id")
    cap_status = get(payload, "status")

    if is_binary(acct_id) and is_binary(cap_name) do
      Repo.transact(fn ->
        row =
          case Repo.repo().get_by(Account, stripe_account_id: acct_id) do
            %Account{} = existing ->
              existing

            nil ->
              case Connect.retrieve_account(acct_id) do
                {:ok, seeded} -> seeded
                {:error, _} -> nil
              end
          end

        case row do
          %Account{} = row ->
            prior_capabilities = row.capabilities || %{}
            prior_entry = Map.get(prior_capabilities, cap_name)

            prior_status =
              case prior_entry do
                %{"status" => s} -> s
                %{status: s} -> s
                s when is_binary(s) -> s
                _ -> nil
              end

            merged =
              Map.put(
                prior_capabilities,
                cap_name,
                %{"status" => cap_status, "requested" => get(payload, "requested")}
              )

            {:ok, updated} =
              row
              |> Account.force_status_changeset(%{capabilities: merged})
              |> Repo.repo().update()

            {:ok, _} =
              Events.record(%{
                type: "connect.capability.updated",
                subject_type: "Accrue.Connect.Account",
                subject_id: updated.stripe_account_id,
                data: %{
                  "stripe_account_id" => updated.stripe_account_id,
                  "capability" => cap_name,
                  "status" => cap_status,
                  "prior_status" => prior_status
                }
              })

            if prior_status == "active" and cap_status != "active" do
              Ops.emit(
                :connect_capability_lost,
                %{count: 1},
                %{
                  stripe_account_id: updated.stripe_account_id,
                  capability: cap_name,
                  from: prior_status,
                  to: cap_status
                }
              )
            end

            {:ok, updated}

          nil ->
            {:ok, :unresolved}
        end
      end)
    else
      :ok
    end
  end

  defp reduce_payout(ctx, event_type, ops_suffix) do
    case payload_from_ctx(ctx) do
      {:ok, payload} ->
        payout_id = get(payload, "id")
        destination = get(payload, "destination")
        amount = get(payload, "amount")
        currency = get(payload, "currency")
        status = get(payload, "status")

        Repo.transact(fn ->
          {:ok, _} =
            Events.record(%{
              type: event_type,
              subject_type: "Accrue.Connect.Account",
              subject_id: destination || payout_id || "unknown",
              data: %{
                "payout_id" => payout_id,
                "destination" => destination,
                "amount" => amount,
                "currency" => currency,
                "status" => status
              }
            })

          if ops_suffix == :payout_failed do
            Ops.emit(
              :connect_payout_failed,
              %{count: 1},
              %{
                stripe_account_id: destination,
                payout_id: payout_id,
                amount: amount,
                currency: currency,
                failure_code: get(payload, "failure_code")
              }
            )
          end

          {:ok, :recorded}
        end)

      {:error, :no_payload} ->
        :ok
    end
  end

  # =====================================================================
  # Helpers
  # =====================================================================

  # Loads the persisted WebhookEvent row via `ctx.webhook_event_id` and
  # extracts `data["data"]["object"]` (the Stripe event payload object).
  # Returns `{:error, :no_payload}` if the ctx lacks an id (e.g. tests
  # that invoke the handler directly without a persisted row) or if the
  # row is missing its data column.
  defp payload_from_ctx(%{webhook_event_id: id}) when not is_nil(id) do
    case Repo.repo().get(WebhookEvent, id) do
      %WebhookEvent{data: %{"data" => %{"object" => obj}}} when is_map(obj) ->
        {:ok, obj}

      _ ->
        {:error, :no_payload}
    end
  end

  defp payload_from_ctx(_), do: {:error, :no_payload}

  defp get(map, key) when is_map(map) and is_binary(key) do
    Map.get(map, key) ||
      Map.get(map, String.to_atom(key))
  end

  defp get(_, _), do: nil

  # Wraps a reducer in a `:telemetry.span/3` and normalizes the result
  # to the `handle_event/3` behaviour return type (`:ok | {:error, term}`).
  # Reducers return `{:ok, anything}` on success or `{:error, term}` on
  # failure; both collapse correctly here.
  defp span(event, metadata, fun) do
    :telemetry.span(event, metadata, fn ->
      result = fun.()
      {normalize_result(result), metadata}
    end)
  end

  defp normalize_result(:ok), do: :ok
  defp normalize_result({:ok, _}), do: :ok
  defp normalize_result({:error, _} = err), do: err
  defp normalize_result(other), do: {:error, {:unexpected_reducer_return, other}}
end
