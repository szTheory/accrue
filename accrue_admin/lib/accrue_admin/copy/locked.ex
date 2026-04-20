defmodule AccrueAdmin.Copy.Locked do
  @moduledoc """
  Verbatim operator strings with cross-surface test and E2E contracts (Phase 27).
  """

  def owner_access_denied, do: "You don't have access to billing for this organization."

  def ambiguous_replay_blocked,
    do:
      "Ownership couldn't be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."

  def replay_success_organization, do: "Replay requested for the active organization."

  def replay_success_global_webhook, do: "Webhook replay requested."

  def replay_blocked,
    do:
      "Replay is blocked because this webhook isn't linked to a billable row in the active organization."

  def single_replay_confirmation, do: "Replay webhook for the active organization?"

  def bulk_replay_success_organization, do: replay_success_organization()

  def bulk_replay_success_global, do: "Bulk replay requested"
end
