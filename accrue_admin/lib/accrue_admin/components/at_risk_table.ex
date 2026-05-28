defmodule AccrueAdmin.Components.AtRiskTable do
  @moduledoc """
  Table of subscriptions currently in an active dunning campaign.

  Renders below the Recovery Funnel on `/billing/analytics/recovery`.

  ## Per-row map contract

  Each map in `rows` must contain these keys (from `Accrue.Analytics.Dunning.at_risk_subscriptions/1`):

  | key | type | display |
  |-----|------|---------|
  | `:subscription_id` | binary UUID | drill-down href |
  | `:customer_id` | binary UUID | unused directly (href uses subscription_id) |
  | `:customer_label` | `String.t() | nil` | Customer cell text (name or email) |
  | `:days_in_campaign` | `non_neg_integer()` | displayed as "N days" |
  | `:current_step` | `non_neg_integer()` | 0 → "Pending"; N → "Step N" |
  | `:next_step_eta` | `%DateTime{} | nil` | formatted as date-time string; nil → "—" |
  | `:failure_reason` | `map() | nil` | most-recent `invoice.payment_failed` data; extracts `failure_code`/`failure_message` keys; nil or missing invoice → "—" |

  ## Example

      <AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />

  """

  use Phoenix.Component

  attr(:rows, :list, required: true)
  attr(:base_path, :string, default: "/billing")
  attr(:class, :string, default: nil)

  def at_risk_table(assigns) do
    ~H"""
    <section class={["ax-card", "ax-at-risk-table", @class]}>
      <header class="ax-at-risk-header">
        <p class="ax-label">At-Risk Subscriptions</p>
        <p class="ax-body ax-muted">{length(@rows)} active dunning campaigns in this window</p>
      </header>

      <table :if={not Enum.empty?(@rows)} class="ax-at-risk-grid">
        <thead>
          <tr>
            <th scope="col" class="ax-label">Customer</th>
            <th scope="col" class="ax-label">Days in Campaign</th>
            <th scope="col" class="ax-label">Current Step</th>
            <th scope="col" class="ax-label">Next-Step ETA</th>
            <th scope="col" class="ax-label">Last Failure Reason</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={row <- @rows}>
            <td>
              <a
                href={@base_path <> "/analytics/recovery/subscriptions/" <> row.subscription_id}
                class="ax-link"
              >
                {row.customer_label || "—"}
              </a>
            </td>
            <td class="ax-body">{row.days_in_campaign} days</td>
            <td class="ax-body">{if row.current_step == 0, do: "Pending", else: "Step #{row.current_step}"}</td>
            <td class="ax-body">{format_eta(row.next_step_eta)}</td>
            <td class="ax-body ax-muted">{format_failure(row.failure_reason)}</td>
          </tr>
        </tbody>
      </table>

      <div :if={Enum.empty?(@rows)} class="ax-empty-state" data-role="empty-state">
        <p class="ax-heading">No active dunning campaigns</p>
        <p class="ax-body">All subscriptions in this window have recovered or exhausted their campaign.</p>
      </div>
    </section>
    """
  end

  defp format_eta(nil), do: "—"

  defp format_eta(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  end

  defp format_failure(nil), do: "—"

  defp format_failure(data) when is_map(data) do
    Map.get(data, "failure_code") || Map.get(data, "failure_message") || "—"
  end
end
