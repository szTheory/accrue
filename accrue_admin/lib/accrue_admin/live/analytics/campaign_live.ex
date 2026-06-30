defmodule AccrueAdmin.Live.Analytics.CampaignLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, CampaignTimeline, Detail}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(%{"id" => subscription_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    owner_scope = socket.assigns.current_owner_scope

    case Subscriptions.detail(subscription_id, owner_scope) do
      {:ok, _subscription} ->
        arcs = Dunning.campaign_timeline_grouped(subscription_id)
        invoice_map = Dunning.invoices_for_campaign(subscription_id)

        {:ok,
         socket
         |> assign_shell(admin, owner_scope)
         |> assign(:subscription_id, subscription_id)
         |> assign(:arcs, arcs)
         |> assign(:invoice_map, invoice_map)}

      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to:
             ScopedPath.build(
               admin["mount_path"] || "/billing",
               "/analytics/recovery",
               owner_scope
             )
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page" aria-label="Dunning timeline for subscription">
        <Breadcrumbs.breadcrumbs items={[
          %{label: "Analytics"},
          %{label: "Recovery", href: @current_path},
          %{label: "Subscription"}
        ]} />

        <Detail.summary_card eyebrow="Campaign history" title="Dunning Timeline">
          <:facts>
            <span>{@subscription_id}</span>
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list rows={summary_rows(@subscription_id, @arcs, @invoice_map, @admin_mount_path, @current_owner_scope)} />

        <CampaignTimeline.campaign_timeline arcs={@arcs} invoice_map={@invoice_map} />
      </section>
    </AppShell.app_shell>
    """
  end

  defp summary_rows(subscription_id, [], invoice_map, mount_path, owner_scope) do
    (empty_campaign_summary(subscription_id) ++
       [
         %{label: "Invoice count", value: invoice_count_label(invoice_map)}
       ])
    |> add_subscription_action(subscription_id, mount_path, owner_scope)
  end

  defp summary_rows(subscription_id, arcs, invoice_map, mount_path, owner_scope) do
    (campaign_fact_rows(subscription_id, arcs) ++
       [
         %{label: "Invoice count", value: invoice_count_label(invoice_map)},
         %{label: "Last boundary", value: latest_boundary(arcs)}
       ])
    |> add_subscription_action(subscription_id, mount_path, owner_scope)
  end

  defp campaign_fact_rows(subscription_id, arcs) do
    [
      %{label: "Subscription", value: subscription_id},
      %{label: "Campaign state", value: campaign_state(arcs)},
      %{label: "Timeline events", value: event_count_label(arcs)}
    ]
  end

  defp empty_campaign_summary(subscription_id) do
    copy = Copy.resource_state_copy(:dunning, :first_run_empty)

    [
      %{label: "Subscription", value: subscription_id},
      %{label: "Campaign state", value: copy.heading},
      %{label: "Timeline events", value: "0 events"},
      %{label: "Last boundary", value: copy.body}
    ]
  end

  defp campaign_state(arcs) do
    case latest_event(arcs) do
      %{type: "dunning.recovered"} -> "Recovered"
      %{type: "dunning.exhausted"} -> "Exhausted"
      %{type: "dunning.campaign_started"} -> "Campaign started"
      %{type: "dunning.step_sent"} -> "In progress"
      %{type: type} when is_binary(type) -> event_label(type)
      _event -> Copy.resource_state_copy(:dunning, :first_run_empty).heading
    end
  end

  defp event_count_label(arcs) do
    count = arcs |> timeline_events() |> length()

    case count do
      1 -> "1 event"
      count -> "#{count} events"
    end
  end

  defp invoice_count_label(invoice_map) when map_size(invoice_map) == 0, do: "No linked invoices"
  defp invoice_count_label(invoice_map) when map_size(invoice_map) == 1, do: "1 linked invoice"
  defp invoice_count_label(invoice_map), do: "#{map_size(invoice_map)} linked invoices"

  defp latest_boundary(arcs) do
    case latest_event(arcs) do
      %{type: type, inserted_at: inserted_at} ->
        "#{event_label(type)} at #{format_datetime(inserted_at)}"

      _event ->
        Copy.resource_state_copy(:dunning, :first_run_empty).body
    end
  end

  defp add_subscription_action(rows, subscription_id, mount_path, owner_scope) do
    subscription_href =
      ScopedPath.build(mount_path, "/subscriptions/#{subscription_id}", owner_scope)

    Enum.map(rows, fn
      %{label: "Subscription"} = row ->
        Map.merge(row, %{
          action_label: "View",
          action_context:
            Copy.action_hidden_context("View",
              resource: "subscription detail",
              object: "dunning campaign for subscription #{subscription_id}"
            ),
          action_href: subscription_href
        })

      row ->
        row
    end)
  end

  defp latest_event(arcs) do
    arcs
    |> timeline_events()
    |> List.last()
  end

  defp timeline_events(arcs) do
    Enum.flat_map(arcs, fn {_anchor, events} -> events end)
  end

  defp event_label("dunning.campaign_started"), do: "Campaign started"
  defp event_label("dunning.step_sent"), do: "Step sent"
  defp event_label("dunning.recovered"), do: "Recovered"
  defp event_label("dunning.exhausted"), do: "Exhausted"

  defp event_label(type) when is_binary(type) do
    type
    |> String.replace_prefix("dunning.", "")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_datetime(%DateTime{} = value) do
    Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  end

  defp format_datetime(_value), do: "Unknown time"

  defp assign_shell(socket, admin, owner_scope) do
    mount_path = admin["mount_path"] || "/billing"

    socket
    |> assign(:page_title, "Dunning Timeline")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, mount_path)
    |> assign(:current_path, ScopedPath.build(mount_path, "/analytics/recovery", owner_scope))
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
