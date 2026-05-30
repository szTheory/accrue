defmodule AccrueAdmin.Components.CampaignTimeline do
  use Phoenix.Component

  alias AccrueAdmin.Components.StatusBadge

  attr(:arcs, :list, required: true)
  attr(:invoice_map, :map, required: true)
  attr(:class, :string, default: nil)

  def campaign_timeline(assigns) do
    ~H"""
    <section class={["ax-campaign-timeline", @class]}>
      <div :if={@arcs == []} class="ax-empty-state" data-role="empty-state">
        <p class="ax-heading">No dunning history found</p>
        <p class="ax-body">This subscription has no recorded dunning events.</p>
      </div>

      <div :for={{_anchor, events} <- @arcs} class="ax-campaign-arc">
        <.arc_rows events={events} invoice_map={@invoice_map} />
      </div>
    </section>
    """
  end

  defp arc_rows(assigns) do
    step_events_indexed =
      assigns.events
      |> Enum.filter(&(&1.type == "dunning.step_sent"))
      |> Enum.with_index(1)

    assigns = assign(assigns, :step_events_indexed, step_events_indexed)

    ~H"""
    <div :for={event <- @events}>
      <%= if event.type == "dunning.step_sent" do %>
        <.step_row
          event={event}
          invoice_map={@invoice_map}
          attempt={elem(Enum.find(@step_events_indexed, fn {e, _idx} -> e.id == event.id end), 1)}
        />
      <% else %>
        <.campaign_row event={event} invoice_map={@invoice_map} />
      <% end %>
    </div>
    """
  end

  defp campaign_row(%{event: %{type: "dunning.campaign_started"}} = assigns) do
    ~H"""
    <div class="ax-campaign-timeline-anchor">
      <div class="ax-timeline-dot ax-timeline-dot-cobalt"></div>
      <p>Campaign started</p>
      <p>{format_datetime(@event.inserted_at)}</p>
      <% invoice_ctx = Map.get(@invoice_map, @event.data["invoice_id"]) %>
      <%= if invoice_ctx do %>
        <p>{Map.get(invoice_ctx, "failure_code") || Map.get(invoice_ctx, "failure_message") || "—"}</p>
      <% else %>
        <p>—</p>
      <% end %>
    </div>
    """
  end

  defp campaign_row(assigns) do
    ~H"""
    <div class="ax-campaign-timeline-terminal">
      <% tone = if @event.type == "dunning.recovered", do: "moss", else: "amber" %>
      <% label = if @event.type == "dunning.recovered", do: "Recovered", else: "Exhausted" %>
      <div class={["ax-timeline-dot", "ax-timeline-dot-#{tone}"]}></div>
      <StatusBadge.status_badge status={@event.type} tone={tone} label={label} />
      <p>{format_datetime(@event.inserted_at)}</p>
      <p>{format_amount(@event.data["mrr_value_cents"])}</p>
    </div>
    """
  end

  defp step_row(assigns) do
    ~H"""
    <div class="ax-campaign-timeline-step">
      <div class="ax-timeline-dot ax-timeline-dot-slate"></div>
      <% invoice_ctx = Map.get(@invoice_map, @event.data["invoice_id"]) %>
      <p>Attempt {@attempt}</p>
      <p>{format_datetime(@event.inserted_at)}</p>
      <%= if invoice_ctx do %>
        <StatusBadge.status_badge status={invoice_ctx.status} />
        <p>{format_amount(invoice_ctx.amount_due_cents)}</p>
      <% else %>
        <p>—</p>
      <% end %>
    </div>
    """
  end

  defp format_amount(nil), do: "—"

  defp format_amount(cents) do
    currency = Accrue.Config.get!(:default_currency)
    locale = Accrue.Config.default_locale()
    Accrue.Invoices.Render.format_money(cents, currency, locale)
  end

  defp format_datetime(%DateTime{} = value) do
    Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  end

  defp format_datetime(_), do: "—"
end
