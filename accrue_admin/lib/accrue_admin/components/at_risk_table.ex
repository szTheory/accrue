defmodule AccrueAdmin.Components.AtRiskTable do
  @moduledoc """
  Table of subscriptions currently in an active dunning campaign.

  Renders as the Recovery work queue before the supporting funnel on
  `/billing/analytics/recovery`.

  ## Per-row map contract

  Each map in `rows` must contain these keys (from `Accrue.Analytics.Dunning.at_risk_subscriptions/1`):

  | key | type | display |
  |-----|------|---------|
  | `:subscription_id` | binary UUID | drill-down href |
  | `:customer_id` | binary UUID | unused directly (href uses subscription_id) |
  | `:customer_label` | `String.t() | nil` | Customer cell text (name or email) |
  | `:amount_due_minor` | `integer() | nil` | optional amount currently at risk |
  | `:currency` | `String.t() | atom() | nil` | optional currency for amount display |
  | `:days_in_campaign` | `non_neg_integer()` | displayed as "N days" |
  | `:current_step` | `non_neg_integer()` | 0 → "Pending"; N → "Step N" |
  | `:next_step_eta` | `%DateTime{} | nil` | shared exact timestamp control; nil → "—" |
  | `:failure_reason` | `map() | nil` | most-recent `invoice.payment_failed` data; extracts `failure_code`/`failure_message` keys; nil or missing invoice → "—" |

  ## Example

      <AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />

  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Timestamp
  alias AccrueAdmin.ScopedPath

  attr(:rows, :list, required: true)
  attr(:base_path, :string, default: "/billing")
  attr(:owner_scope, :any, default: nil)
  attr(:current_window, :string, default: "30d")
  attr(:class, :string, default: nil)
  attr(:loading, :boolean, default: false)
  attr(:error, :any, default: nil)
  attr(:next_cursor, :string, default: nil)
  attr(:load_more_href, :string, default: nil)
  attr(:empty_copy, :map, default: nil)

  def at_risk_table(assigns) do
    assigns =
      assigns
      |> assign(:state, state(assigns))
      |> assign(
        :empty_copy,
        normalize_state_copy(assigns[:empty_copy], %{
          heading: "No subscriptions currently need payment retry",
          body: "All subscriptions in this window recovered or exhausted their retry schedule."
        })
      )

    ~H"""
    <section
      class={["ax-card", "ax-at-risk-table", @class]}
      data-component-group="table-empty-loading-error-pagination"
      data-state={@state}
    >
      <header class="ax-at-risk-header">
        <p class="ax-label">At-Risk Subscriptions</p>
        <p :if={@state not in ["loading", "error"]} class="ax-body ax-muted">
          {length(@rows)} subscriptions with active payment retries in this window
        </p>
      </header>

      <div :if={@state == "loading"} class="ax-at-risk-state" data-state="loading" role="status">
        <p class="ax-heading">Loading at-risk subscriptions</p>
            <p class="ax-body">Checking payment retry status for this recovery window.</p>
      </div>

      <div :if={@state == "error"} class="ax-at-risk-state ax-at-risk-state-error" data-state="error" role="alert">
        <p class="ax-heading">This data display could not load.</p>
        <p class="ax-body">{error_message(@error)}</p>
      </div>

      <div
        :if={@state in ["no-pagination", "has-pagination"]}
        class="ax-at-risk-scroll-region"
        role="region"
        aria-label="At-risk subscriptions table"
        tabindex="0"
      >
        <table class="ax-at-risk-grid">
          <thead>
            <tr>
              <th scope="col" class="ax-label">Customer</th>
              <th scope="col" class="ax-label">Current subscription status</th>
              <th scope="col" class="ax-label">Amount</th>
              <th scope="col" class="ax-label">Campaign Age</th>
              <th scope="col" class="ax-label">Current Step</th>
              <th scope="col" class="ax-label">Next-Step ETA</th>
              <th scope="col" class="ax-label">Last Failure Reason</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows}>
              <td>
                <a
                  href={subscription_href(@base_path, row, @owner_scope, @current_window)}
                  class="ax-link"
                >
                  {row.customer_label || "—"}
                </a>
              </td>
              <td class="ax-body">{current_status(row)}</td>
              <td class="ax-body">{format_amount(row)}</td>
              <td class="ax-body">{campaign_age(row)}</td>
              <td class="ax-body">{step_label(row)}</td>
              <td class="ax-body">{eta_cell(row.next_step_eta, row.subscription_id, :table)}</td>
              <td class="ax-body ax-muted">{format_failure(row.failure_reason)}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@state in ["no-pagination", "has-pagination"]} class="ax-at-risk-cards" data-role="card-list">
        <article :for={row <- @rows} class="ax-at-risk-card">
          <header class="ax-at-risk-card-header">
            <div class="ax-at-risk-card-identity">
              <p class="ax-eyebrow">Subscription</p>
              <h3 class="ax-heading">{row.customer_label || "—"}</h3>
            </div>
            <span class="ax-at-risk-card-status">{step_label(row)}</span>
          </header>

          <dl class="ax-at-risk-card-facts">
            <div>
              <dt class="ax-label">Current subscription status</dt>
              <dd class="ax-body">{current_status(row)}</dd>
            </div>
            <div>
              <dt class="ax-label">Amount</dt>
              <dd class="ax-body">{format_amount(row)}</dd>
            </div>
            <div>
              <dt class="ax-label">Timing</dt>
              <dd class="ax-body">{campaign_age(row)}</dd>
            </div>
            <div>
              <dt class="ax-label">Next step</dt>
              <dd class="ax-body">{eta_cell(row.next_step_eta, row.subscription_id, :card)}</dd>
            </div>
            <div>
              <dt class="ax-label">Historical failure reason</dt>
              <dd class="ax-body ax-muted">{format_failure(row.failure_reason)}</dd>
            </div>
          </dl>

          <a
            href={subscription_href(@base_path, row, @owner_scope, @current_window)}
            class="ax-button ax-button-secondary"
            aria-label={"Open recovery campaign for #{row.customer_label || row.subscription_id}"}
          >
            Review campaign
          </a>
        </article>
      </div>

      <div :if={@state == "empty"} class="ax-empty-state" data-role="empty-state" data-state="empty">
        <p class="ax-heading"><%= @empty_copy.heading %></p>
        <p class="ax-body"><%= @empty_copy.body %></p>
      </div>

      <footer :if={@state in ["no-pagination", "has-pagination"]} class="ax-at-risk-footer">
        <p class="ax-body" data-role="pagination-state">
          <%= if @next_cursor do %>
            More at-risk subscriptions are available.
          <% else %>
            No pagination control is shown for this recovery window.
          <% end %>
        </p>
        <a
          :if={@next_cursor}
          href={load_more_href(@base_path, @next_cursor, @load_more_href, @owner_scope)}
          class="ax-button ax-button-secondary"
          data-role="load-more"
        >
          Load more
        </a>
      </footer>
    </section>
    """
  end

  defp state(%{error: error}) when error not in [nil, false, ""], do: "error"
  defp state(%{loading: true}), do: "loading"
  defp state(%{rows: []}), do: "empty"
  defp state(%{next_cursor: cursor}) when cursor not in [nil, ""], do: "has-pagination"
  defp state(_assigns), do: "no-pagination"

  defp normalize_state_copy(%{heading: heading, body: body}, _fallback)
       when is_binary(heading) and is_binary(body),
       do: %{heading: heading, body: body}

  defp normalize_state_copy(_copy, fallback), do: fallback

  defp subscription_href(base_path, row, owner_scope, current_window) do
    return_to =
      ScopedPath.build(base_path, "/analytics/recovery", owner_scope, %{
        "window" => current_window
      })

    ScopedPath.build(
      base_path,
      "/analytics/recovery/subscriptions/" <> row.subscription_id,
      owner_scope,
      %{"return_to" => return_to}
    )
  end

  defp current_status(%{current_status: status}) when is_atom(status), do: Atom.to_string(status)
  defp current_status(%{current_status: status}) when is_binary(status), do: status
  defp current_status(_row), do: "Unavailable"

  defp load_more_href(_base_path, _next_cursor, href, _owner_scope)
       when is_binary(href) and href != "",
       do: href

  defp load_more_href(base_path, next_cursor, _href, owner_scope) do
    ScopedPath.build(base_path, "/analytics/recovery", owner_scope, %{"cursor" => next_cursor})
  end

  defp campaign_age(row), do: "Past due #{row.days_in_campaign} days"

  defp step_label(%{current_step: 0}), do: "Pending"
  defp step_label(row), do: "Step #{row.current_step}"

  defp error_message(message) when is_binary(message), do: message

  defp error_message(_message),
    do: "Retry the query; if it persists, inspect logs for the active owner scope."

  defp format_amount(%{amount_due_minor: amount_minor, currency: currency})
       when is_integer(amount_minor) do
    case normalize_currency(currency) do
      nil ->
        "Amount unavailable"

      normalized ->
        Accrue.Invoices.Render.format_money(
          amount_minor,
          normalized,
          Accrue.Config.default_locale()
        )
    end
  end

  defp format_amount(_row), do: "Amount unavailable"

  defp normalize_currency(currency) when is_atom(currency), do: currency

  defp normalize_currency(currency) when is_binary(currency) do
    currency
    |> String.downcase()
    |> String.to_existing_atom()
  rescue
    ArgumentError -> nil
  end

  defp normalize_currency(_currency), do: nil

  defp eta_cell(nil, _subscription_id, _surface), do: "—"

  defp eta_cell(%DateTime{} = value, subscription_id, surface) do
    assigns = %{value: value, id: "at-risk-#{surface}-eta-#{subscription_id}"}

    ~H"""
    <Timestamp.timestamp value={@value} id={@id} />
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end

  defp format_failure(nil), do: "—"

  defp format_failure(data) when is_map(data) do
    Map.get(data, "failure_code") || Map.get(data, "failure_message") || "—"
  end
end
