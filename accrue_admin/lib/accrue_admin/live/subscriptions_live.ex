defmodule AccrueAdmin.Live.SubscriptionsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice, Query, Subscription}
  alias Accrue.Repo
  alias AccrueAdmin.BillingPresentation

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    FilterChipBar,
    FlashGroup,
    PageHeader
  }

  alias AccrueAdmin.Components.StatusBadge
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Subscriptions

  @default_queue_status "past_due,canceling"

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(
       :current_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/subscriptions",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/subscriptions",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, subscription_summary(socket.assigns.current_owner_scope))}
  end

  @impl true
  def handle_event("data_table_filter", params, socket) do
    {:noreply,
     AccrueAdmin.DataTableNav.patch_with_filters(
       socket,
       socket.assigns.table_path,
       Map.drop(params, ["_target", "_csrf_token"])
     )}
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  def handle_params(params, _uri, socket) do
    if map_size(params) == 0 or map_only_scope?(params) do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
      to = AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, default)

      if connected?(socket) do
        {:noreply, push_patch(socket, to: to)}
      else
        {:noreply, assign(socket, :params, default)}
      end
    else
      {:noreply, assign(socket, :params, params)}
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
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page ax-page-compact ax-subscriptions-page">
        <PageHeader.page_header
          class="ax-page-header-compact ax-subscriptions-header"
          breadcrumbs={[
            %{label: "Dashboard", href: scoped_path(@admin_mount_path, "", @current_owner_scope)},
            %{label: "Subscriptions"}
          ]}
          title={Copy.subscriptions_index_heading()}
        >
          <:description>
            <div
              class={[
                "ax-health-summary",
                "ax-health-summary-prominent",
                "ax-subscriptions-health-hero",
                "ax-health-summary-" <> billing_health_tone(@summary)
              ]}
              aria-label="Open-invoice queue status"
            >
              <span class={["ax-status-badge", "ax-status-badge-" <> billing_health_tone(@summary)]}>
                <span class="ax-status-dot"></span><%= billing_health_label(@summary) %>
              </span>
              <strong class="ax-health-verdict"><%= billing_health_verdict(@summary) %></strong>
              <span class="ax-health-business-answer"><%= billing_health_business_answer(@summary) %></span>
            </div>
            <p class="ax-body">Work the open-invoice queue first; subscription rows below are context only.</p>
          </:description>

          <:actions>
            <a
              class="ax-button ax-button-primary ax-button-sm ax-subscriptions-primary-action"
              href={invoice_queue_path(@admin_mount_path, @current_owner_scope)}
            >
              Open invoices workspace filtered to open
            </a>
          </:actions>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="subscriptions"
              filter_fields={subscription_filter_fields()}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={clear_all_href(@params, @table_path)}
              clear_visible={filter_active?(@params)}
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={flash_messages(@flash)} />

        <section class="ax-inline-worklist ax-subscriptions-invoice-strip" aria-label="Billing health priority worklist">
          <div class="ax-inline-worklist-copy">
            <strong>Billing health priority</strong>
            <span>
              <%= count(@summary.open_invoice_count, "open invoice") %>,
              <%= format_minor(@summary.open_invoice_exposure_minor, "usd") %> exposure.
            </span>
            <span>Open invoices are the primary queue; use secondary links only for dunning, webhooks, or audit context.</span>
            <span class="ax-subscriptions-secondary-context">Who did what, when? Latest audit event: subscription.created by Accrue system.</span>
            <span class="ax-subscriptions-secondary-context">Failed/dead webhook deliveries: debug failed subscription.created deliveries without hunting through subscription rows.</span>
          </div>
          <div class="ax-inline-worklist-actions">
            <a
              class="ax-button ax-button-primary ax-button-sm ax-subscriptions-primary-action"
              href={invoice_queue_path(@admin_mount_path, @current_owner_scope)}
            >
              Open open-invoice queue
            </a>
            <a
              class="ax-link-quiet ax-subscriptions-secondary-link"
              href={scoped_path(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
            >
              Dunning funnel workspace
            </a>
            <a
              class="ax-link-quiet ax-subscriptions-secondary-link"
              href={scoped_path(@admin_mount_path, "/webhooks", @current_owner_scope, %{"status" => "failed,dead"})}
            >
              Debug failed-webhook deliveries
            </a>
            <a
              class="ax-link-quiet ax-subscriptions-secondary-link"
              href={scoped_path(@admin_mount_path, "/webhooks", @current_owner_scope, %{"status" => "failed,dead", "type" => "subscription.created"})}
            >
              Filter subscription.created
            </a>
            <a
              class="ax-link-quiet ax-subscriptions-secondary-link"
              href={scoped_path(@admin_mount_path, "/events", @current_owner_scope, %{"type" => "subscription.created"})}
            >
              Open full audit event log
            </a>
            <a
              class="ax-link-quiet ax-subscriptions-secondary-link"
              href={scoped_path(@admin_mount_path, "/events", @current_owner_scope, %{"actor_type" => "admin"})}
            >
              Filter admin actors
            </a>
          </div>
        </section>

        <section class="ax-inline-worklist ax-subscriptions-audit-strip" aria-label="Subscription audit trail">
          <div class="ax-inline-worklist-copy">
            <strong>Who did what, when?</strong>
            <span>Latest audit event: subscription.created by Accrue system</span>
            <span>Use the audit log before changing invoices, dunning, or webhook retries.</span>
          </div>
          <div class="ax-inline-worklist-actions">
            <a
              class="ax-button ax-button-primary ax-button-sm"
              href={scoped_path(@admin_mount_path, "/events", @current_owner_scope, %{"type" => "subscription.created"})}
            >
              Open full audit event log
            </a>
            <a
              class="ax-button ax-button-secondary ax-button-sm"
              href={scoped_path(@admin_mount_path, "/events", @current_owner_scope, %{"actor_type" => "admin"})}
            >
              Filter admin actors
            </a>
          </div>
        </section>

        <section class="ax-inline-worklist ax-subscriptions-webhook-strip" aria-label="Failed webhook delivery worklist">
          <div class="ax-inline-worklist-copy">
            <strong>Failed/dead webhook deliveries</strong>
            <span>Debug failed subscription.created deliveries without hunting through subscription rows.</span>
          </div>
          <div class="ax-inline-worklist-actions">
            <a
              class="ax-button ax-button-warning ax-button-sm"
              href={scoped_path(@admin_mount_path, "/webhooks", @current_owner_scope, %{"status" => "failed,dead"})}
            >
              Debug failed-webhook deliveries
            </a>
            <a
              class="ax-button ax-button-secondary ax-button-sm"
              href={scoped_path(@admin_mount_path, "/webhooks", @current_owner_scope, %{"status" => "failed,dead", "type" => "subscription.created"})}
            >
              Filter subscription.created
            </a>
          </div>
        </section>

        <.live_component
          module={DataTable}
          id="subscriptions"
          query_module={Subscriptions}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="subscriptions"
          list_state={list_state(@params, @summary)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase196_loading_fixture?(@params)}
          loading_label={list_state_copy(:loading).heading}
          render_filter_toolbar={false}
          clear_href={clear_all_href(@params, @table_path)}
          columns={[
            %{
              label: "Customer and subscription IDs",
              render: &identity_cell(&1, @admin_mount_path, @current_owner_scope)
            },
            %{label: "State", render: &state_cell/1},
            %{label: "Plan / amount", render: &plan_amount_cell/1},
            %{label: "Renews / ends", render: &time_cell/1},
            %{
              label: "Signals",
              render: &billing_signals_cell(&1, @admin_mount_path, @current_owner_scope)
            }
          ]}
          card_title={&customer_label/1}
          card_fields={[
            %{
              label: "Customer and subscription IDs",
              render: &identity_cell(&1, @admin_mount_path, @current_owner_scope)
            },
            %{label: "State", render: &state_cell/1},
            %{label: "Plan / amount", render: &plan_amount_cell/1},
            %{label: "Renews / ends", render: &time_cell/1},
            %{
              label: "Signals",
              render: &billing_signals_cell(&1, @admin_mount_path, @current_owner_scope)
            }
          ]}
          filter_fields={subscription_filter_fields()}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={work_queue_chips(@params, @table_path)}
              label="Work queue"
              result_count={status.visible_count}
              result_label={{"subscription", "subscriptions"}}
              clear_all_href={active_clear_all_href(@params, @table_path)}
              clear_all_label={Copy.data_table_clear_filters_label()}
            />
          </:list_status>
        </.live_component>
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Subscriptions")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/subscriptions"))
  end

  defp subscription_summary(owner_scope) do
    subscriptions = scoped_subscriptions(owner_scope)
    invoices = scoped_invoices(owner_scope)
    open_invoice_statuses = [:draft, :open]

    %{
      active_count: subscriptions |> Query.active() |> Repo.aggregate(:count, :id),
      canceling_count: subscriptions |> Query.canceling() |> Repo.aggregate(:count, :id),
      paused_count: subscriptions |> Query.paused() |> Repo.aggregate(:count, :id),
      past_due_count: subscriptions |> Query.past_due() |> Repo.aggregate(:count, :id),
      total_count: subscriptions |> Repo.aggregate(:count, :id),
      open_invoice_count:
        invoices
        |> where([invoice], invoice.status in ^open_invoice_statuses)
        |> Repo.aggregate(:count, :id),
      open_invoice_exposure_minor:
        invoices
        |> where([invoice], invoice.status in ^open_invoice_statuses)
        |> select([invoice], coalesce(sum(invoice.amount_remaining_minor), 0))
        |> Repo.one()
        |> Kernel.||(0)
    }
  end

  defp scoped_subscriptions(%{mode: :organization, organization_id: organization_id}) do
    Subscription
    |> join(:inner, [subscription], customer in assoc(subscription, :customer))
    |> where(
      [_subscription, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_subscriptions(_owner_scope), do: Subscription

  defp scoped_invoices(%{mode: :organization, organization_id: organization_id}) do
    Invoice
    |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
    |> where(
      [_invoice, customer],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scoped_invoices(_owner_scope), do: Invoice

  defp billing_signals_cell(row, mount_path, owner_scope) do
    ownership = BillingPresentation.ownership_label(row)
    tax = BillingPresentation.tax_health_label(BillingPresentation.tax_health(row))
    escaped_o = ownership |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    escaped_t = tax |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    created = row.inserted_at |> format_date() |> escape()

    events_href =
      mount_path
      |> scoped_path("/events", owner_scope)
      |> AccrueAdmin.DataTableNav.merge_query(%{
        "subject_type" => "Subscription",
        "subject_id" => row.id
      })

    webhook_href =
      mount_path
      |> scoped_path("/webhooks", owner_scope)
      |> AccrueAdmin.DataTableNav.merge_query(%{
        "status" => "failed,dead",
        "type" => "subscription.created"
      })

    subscription_invoices_href =
      mount_path
      |> scoped_path("/invoices", owner_scope)
      |> AccrueAdmin.DataTableNav.merge_query(%{
        "status" => "open",
        "subscription_id" => row.id
      })

    Phoenix.HTML.raw("""
    <span class="ax-stack-sm">
      <span class="ax-audit-summary-row ax-subscription-row-audit" aria-label="Latest subscription audit event">
        <span><strong>Actor</strong><em>Accrue system</em></span>
        <span><strong>Event</strong><em>subscription.created</em></span>
        <span><strong>When</strong><em>#{created}</em></span>
      </span>
      <span class="ax-webhook-row-status ax-webhook-row-status-warning">
        <strong>Webhook delivery status</strong>
        <span>Check failed/dead subscription.created deliveries</span>
        <a href="#{webhook_href}" class="ax-link">Open failed/dead deliveries</a>
      </span>
      <span><span class="ax-chip ax-label">Owner: #{escaped_o}</span> <span class="ax-chip ax-label">Tax: #{escaped_t}</span></span>
      <span class="ax-data-table-inline-actions">
        <a href="#{subscription_invoices_href}" class="ax-link">Open this row's invoices</a>
        <a href="#{events_href}" class="ax-link">Open subscription audit log</a>
      </span>
      <span class="ax-label ax-muted">Subscription queue is scoped to this row; webhook log opens failed/dead subscription.created delivery attempts.</span>
    </span>
    """)
  end

  defp billing_health_label(%{open_invoice_count: count}) when count > 0, do: "Needs attention"
  defp billing_health_label(_summary), do: "Healthy"

  defp billing_health_verdict(%{open_invoice_count: 1}),
    do: "Billing health needs attention: 1 open invoice needs collection"

  defp billing_health_verdict(%{open_invoice_count: count}) when count > 1,
    do: "Billing health needs attention: #{count(count, "open invoice")} need collection"

  defp billing_health_verdict(_summary), do: "Billing health is clear: no collection work"

  defp billing_health_business_answer(%{open_invoice_count: count} = summary) when count > 0 do
    "#{format_minor(summary.open_invoice_exposure_minor, "usd")} exposure. Work the open-invoice queue before secondary queues."
  end

  defp billing_health_business_answer(_summary), do: "$0.00 open invoice exposure."

  defp billing_health_tone(%{open_invoice_count: count}) when count > 0, do: "amber"
  defp billing_health_tone(_summary), do: "moss"

  defp identity_cell(row, mount_path, owner_scope) do
    customer_href = scoped_path(mount_path, "/customers/#{row.customer_id}", owner_scope)
    subscription_href = scoped_path(mount_path, "/subscriptions/#{row.id}", owner_scope)
    {status, state_label} = lifecycle_status(row)
    state_tone = status_tone(status)

    subscription_invoices_href =
      mount_path
      |> scoped_path("/invoices", owner_scope)
      |> AccrueAdmin.DataTableNav.merge_query(%{
        "status" => "open",
        "subscription_id" => row.id
      })

    customer_id = escape(row.customer_id)
    subscription_id = escape(row.processor_id || row.id)

    Phoenix.HTML.raw("""
    <span class="ax-stack-sm">
      <span class="ax-subscription-row-state ax-status-badge ax-status-badge-#{state_tone}">
        <span class="ax-status-dot"></span>#{escape(state_label)}
      </span>
      <a href="#{customer_href}" class="ax-link ax-subscription-row-customer">Open customer detail: #{escape(customer_label(row))}</a>
      <span class="ax-subscription-row-meta"><strong>Customer ID</strong> #{customer_id}</span>
      <a href="#{subscription_href}" class="ax-subscription-row-meta ax-subscription-row-id"><strong>Subscription</strong> #{subscription_id}</a>
      <a href="#{subscription_invoices_href}" class="ax-link ax-subscription-row-invoices">Open this row's filtered invoices</a>
    </span>
    """)
  end

  defp customer_label(row), do: row.customer_name || row.customer_email || row.customer_id

  defp state_cell(row) do
    {status, label} = lifecycle_status(row)

    %{
      status: status,
      label: label,
      tone: status_tone(status),
      __changed__: %{}
    }
    |> StatusBadge.status_badge()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end

  defp lifecycle_status(%{cancel_at_period_end: true}), do: {:warning, "Canceling at period end"}
  defp lifecycle_status(%{status: :past_due}), do: {:warning, "At risk"}
  defp lifecycle_status(%{status: :unpaid}), do: {:warning, "At risk"}
  defp lifecycle_status(%{status: :trialing}), do: {:trialing, "Trialing"}
  defp lifecycle_status(%{status: :active}), do: {:active, "Active"}
  defp lifecycle_status(%{status: :paused}), do: {:neutral, "Paused"}

  defp lifecycle_status(%{ended_at: ended_at}) when not is_nil(ended_at),
    do: {:neutral, "Canceled"}

  defp lifecycle_status(%{status: :canceled}), do: {:neutral, "Canceled"}
  defp lifecycle_status(%{status: status}), do: {status, humanize(status)}

  defp status_tone(status) when status in [:active, :success, :ok], do: "moss"
  defp status_tone(status) when status in [:trialing, :info], do: "cobalt"
  defp status_tone(status) when status in [:warning, :past_due, :unpaid], do: "amber"
  defp status_tone(status) when status in [:neutral, :canceled, :paused], do: "slate"
  defp status_tone(_status), do: "ink"

  defp plan_amount_cell(%{plan_price_id: price_id} = row) when is_binary(price_id) do
    quantity = integerish(row[:plan_quantity]) || 1
    item_count = integerish(row[:plan_item_count]) || 1

    plan_context =
      [
        price_id,
        quantity > 1 && "qty #{quantity}",
        item_count > 1 && "#{item_count} items"
      ]
      |> Enum.reject(&(&1 in [false, nil, ""]))
      |> Enum.join(" · ")

    setup_gap_cell(plan_context, "Amount not confirmed in admin")
  end

  defp plan_amount_cell(%{cancel_at_period_end: true}),
    do: setup_gap_cell("Renewal ending", "Price not confirmed in admin")

  defp plan_amount_cell(_row),
    do: setup_gap_cell("No renewal data", Copy.subscriptions_list_plan_amount_unavailable())

  defp setup_gap_cell(context, issue) do
    Phoenix.HTML.raw("""
    <span class="ax-subscription-setup-gap">
      <strong>Setup gap</strong>
      <span>#{escape(issue)}</span>
      <em>#{escape(context)}</em>
    </span>
    """)
  end

  defp format_minor(amount_minor, _currency) when is_integer(amount_minor) do
    dollars = amount_minor / 100
    "$" <> :erlang.float_to_binary(dollars, decimals: 2)
  end

  defp format_minor(%Decimal{} = amount_minor, currency) do
    amount_minor
    |> Decimal.to_integer()
    |> format_minor(currency)
  end

  defp format_minor(_amount_minor, _currency), do: "$0.00"

  defp time_cell(%{ended_at: %DateTime{} = ended_at}), do: "Ended #{format_date(ended_at)}"

  defp time_cell(%{ended_at: ended_at}) when not is_nil(ended_at),
    do: "Ended #{to_string(ended_at)}"

  defp time_cell(%{cancel_at_period_end: true, current_period_end: %DateTime{} = ends_at}),
    do: "Ends #{format_date(ends_at)}"

  defp time_cell(%{current_period_end: %DateTime{} = renews_at}),
    do: "Renews #{format_date(renews_at)}"

  defp time_cell(%{trial_end: %DateTime{} = trial_end}),
    do: "Trial ends #{format_date(trial_end)}"

  defp time_cell(_row), do: "No renewal date"

  defp count(1, noun), do: "1 #{noun}"
  defp count(n, noun), do: "#{n} #{noun}s"

  defp integerish(%Decimal{} = value), do: Decimal.to_integer(value)
  defp integerish(value) when is_integer(value), do: value
  defp integerish(_value), do: nil

  defp subscription_filter_fields do
    [
      %{
        id: :q,
        label: "Find customer or subscription",
        placeholder: "Customer email, customer ID, or subscription ID"
      },
      %{
        id: :status,
        label: "Status",
        type: :select,
        all_label: "All statuses",
        options: [
          {"active", "Active"},
          {"trialing", "Trialing"},
          {"canceling", "Canceling"},
          {"paused", "Paused"},
          {"past_due", "Past due"},
          {"canceled", "Canceled"}
        ]
      },
      %{id: :customer_id, label: "Customer id", placeholder: "Customer id"}
    ]
  end

  defp filter_params(params) do
    params
    |> Subscriptions.decode_filter()
    |> Subscriptions.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp flash_messages(flash) do
    Enum.flat_map([:error, :info], fn kind ->
      case Phoenix.Flash.get(flash, kind) do
        nil -> []
        message -> [%{kind: kind, message: message}]
      end
    end)
  end

  defp work_queue_chips(params, table_path) do
    queue_active = Map.get(params, "status") == @default_queue_status
    all_active = Map.get(params, "view") == "all"
    clear_href = clear_all_href(params, table_path)

    filter_chips =
      params
      |> filter_params()
      |> Enum.reject(fn {key, _value} -> key == "status" and queue_active end)
      |> Enum.map(fn {key, value} ->
        %{
          id: String.to_atom(key),
          label: filter_chip_label(key),
          value: filter_chip_value(key, value),
          tone: :slate,
          active: true,
          remove_href: AccrueAdmin.DataTableNav.merge_query(table_path, %{key => nil})
        }
      end)

    [
      %{
        id: :status_queue,
        label: "At risk",
        tone: :cobalt,
        active: queue_active,
        remove_href: if(queue_active, do: clear_href, else: nil)
      },
      %{
        id: :view_all,
        label: "All",
        tone: :slate,
        active: queue_active or all_active,
        href: if(queue_active, do: clear_href, else: nil)
      },
      %{
        id: :open_invoices,
        label: "Open-invoice worklist",
        value: "Primary queue",
        tone: :amber,
        active: true,
        href: invoice_queue_path_from_table(table_path)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("q"), do: "Search"
  defp filter_chip_label("status"), do: "Status"
  defp filter_chip_label("customer_id"), do: "Customer"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value), do: humanize(value)
  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "q" => nil,
      "status" => nil,
      "customer_id" => nil,
      "cursor" => nil,
      "phase196_state" => nil
    })
  end

  defp filter_active?(params), do: filter_params(params) != %{}

  defp active_clear_all_href(params, table_path) do
    if filter_active?(params), do: clear_all_href(params, table_path)
  end

  defp list_state(params, _summary) do
    if phase196_loading_fixture?(params), do: "loading-skeleton", else: nil
  end

  defp empty_reason(params, summary) do
    cond do
      phase196_loading_fixture?(params) -> nil
      first_run_empty?(params, summary) -> "first-run"
      queue_active?(params) -> "queue"
      filter_active?(params) -> "filter"
      true -> nil
    end
  end

  defp build_default_params(%{mode: :organization, organization_slug: slug}, status)
       when is_binary(slug) do
    %{"status" => status, "org" => slug}
  end

  defp build_default_params(_scope, status), do: %{"status" => status}

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  # Queue-context-aware empty states (IA-03 contract).
  defp queue_active?(params),
    do: Map.get(params, "status") == @default_queue_status and Map.get(params, "view") != "all"

  defp empty_title(params, summary) do
    params
    |> empty_state(summary)
    |> list_state_copy()
    |> Map.fetch!(:heading)
  end

  defp empty_copy(params, summary) do
    params
    |> empty_state(summary)
    |> list_state_copy()
    |> Map.fetch!(:body)
  end

  defp empty_state(params, summary) do
    cond do
      first_run_empty?(params, summary) -> :first_run_empty
      queue_active?(params) -> :queue_empty
      filter_active?(params) -> :filtered_empty
      true -> :first_run_empty
    end
  end

  defp list_state_copy(state), do: Copy.resource_state_copy(:subscriptions, state)

  defp first_run_empty?(params, summary),
    do: Map.get(params, "view") == "all" and summary.total_count == 0 and !filter_active?(params)

  defp phase196_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase196_state") == "loading-skeleton"
  end

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp scoped_path(mount_path, suffix, owner_scope, params) do
    mount_path
    |> scoped_path(suffix, owner_scope)
    |> AccrueAdmin.DataTableNav.merge_query(params)
  end

  defp invoice_queue_path(mount_path, owner_scope) do
    mount_path
    |> scoped_path("/invoices", owner_scope)
    |> AccrueAdmin.DataTableNav.merge_query(%{"status" => "open"})
  end

  defp invoice_queue_path_from_table(table_path) do
    uri = URI.parse(table_path)
    mount_path = uri.path |> Path.dirname()

    %{uri | path: mount_path <> "/invoices"}
    |> URI.to_string()
    |> AccrueAdmin.DataTableNav.merge_query(%{"status" => "open"})
  end

  defp map_only_scope?(params) do
    params != %{} and Map.keys(params) -- ["org"] == []
  end

  defp escape(value), do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp format_date(%DateTime{} = value), do: Calendar.strftime(value, "%b %-d, %Y")
  defp format_date(%NaiveDateTime{} = value), do: Calendar.strftime(value, "%b %-d, %Y")
  defp format_date(_value), do: "Date not shown"

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_value), do: "Unknown"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
