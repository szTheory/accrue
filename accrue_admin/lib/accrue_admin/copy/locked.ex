defmodule AccrueAdmin.Copy.Locked do
  @moduledoc """
  Verbatim operator strings with cross-surface test and E2E contracts (Phase 27).
  """

  def owner_access_denied,
    do:
      "Access restricted. This admin account cannot view billing for this organization. Switch owner scope or ask an administrator to grant billing admin access."

  def ambiguous_replay_blocked,
    do:
      "Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."

  def replay_success_organization, do: "Replay requested for the active organization."

  def replay_success_global_webhook, do: "Webhook replay requested."

  def replay_blocked,
    do:
      "Replay is blocked because this webhook isn't linked to a billable row in the active organization."

  def replay_drawer_title, do: "Confirm webhook replay"

  def replay_step_up_unavailable,
    do: "Webhook replay requires step-up verification before the delivery can be requeued."

  def replay_unavailable_status(status) do
    "Replay is unavailable while this webhook is #{humanize_status(status)}."
  end

  def single_replay_confirmation,
    do: single_replay_confirmation("this webhook", owner_scope: "the active organization")

  def single_replay_confirmation(webhook_id, opts) do
    owner_scope = opts |> Keyword.get(:owner_scope, "the active organization") |> to_string()

    "Replay webhook #{webhook_id} for #{owner_scope}: This will requeue the webhook delivery and record an admin audit event. Confirm replay."
  end

  defp humanize_status(status) when is_atom(status),
    do: status |> Atom.to_string() |> humanize_status()

  defp humanize_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize_status(_status), do: "Unknown"
end
