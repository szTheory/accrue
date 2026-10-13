defmodule AccrueAdmin.Live.WebhooksLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Auth, Events}
  alias Accrue.Webhook.WebhookEvent
  alias Accrue.Webhooks.DLQ

  alias AccrueAdmin.Components.{
    AppShell,
    DataTable,
    IdBadge,
    FilterChipBar,
    FlashGroup,
    PageHeader,
    StatStrip,
    StepUpAuthModal,
    Timestamp
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Webhooks
  alias AccrueAdmin.StepUp

  @default_queue_status "failed,dead"

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
         "/webhooks",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(
       :table_path,
       scoped_path(
         admin["mount_path"] || "/billing",
         "/webhooks",
         socket.assigns.current_owner_scope
       )
     )
     |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))
     |> assign(:flashes, [])
     |> assign(:bulk_replay_result, nil)
     |> assign(:pending_bulk_replay, nil)
     |> assign(:step_up_pending, false)
     |> assign(:step_up_action, nil)
     |> assign(:step_up_challenge, nil)
     |> assign(:step_up_error, nil)
     |> assign(:step_up_continuation, nil)}
  end

  @impl true
  def handle_params(%{"view" => "all"} = params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))}
  end

  def handle_params(params, _uri, socket) do
    summary = webhook_summary(socket.assigns.current_owner_scope)

    if map_size(params) == 0 or map_only_scope?(params) do
      default = build_default_params(socket.assigns[:current_owner_scope], @default_queue_status)
      to = AccrueAdmin.DataTableNav.merge_query(socket.assigns.table_path, default)

      if connected?(socket) do
        {:noreply,
         socket
         |> assign(:summary, summary)
         |> push_patch(to: to)}
      else
        {:noreply,
         socket
         |> assign(:params, default)
         |> assign(:summary, summary)}
      end
    else
      {:noreply,
       socket
       |> assign(:params, params)
       |> assign(:summary, summary)}
    end
  end

  @impl true
  def handle_info({:data_table_bulk_action, "retry_selected", ids}, socket) do
    ids = canonical_ids(ids)

    if ids == [] do
      {:noreply, push_flash(socket, :warning, Copy.webhooks_retry_no_selection_warning())}
    else
      reviewed = review_bulk_selection(ids, socket)

      {:noreply,
       socket
       |> assign(:bulk_replay_result, nil)
       |> assign(:pending_bulk_replay, reviewed)}
    end
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

  def handle_event("cancel_bulk_replay", _params, socket) do
    {:noreply, assign(socket, :pending_bulk_replay, nil)}
  end

  def handle_event(
        "confirm_retry_selected",
        params,
        %{assigns: %{pending_bulk_replay: %{ids: ids} = review}} = socket
      ) do
    socket = assign(socket, :pending_bulk_replay, nil)

    selection_matches? = reviewed_selection_matches?(params, ids)

    case StepUp.require_fresh(
           socket,
           bulk_step_up_action(),
           &execute_bulk_replay(&1, review, selection_matches?)
         ) do
      {:ok, socket} ->
        {:noreply, socket}

      {:challenge, socket} ->
        {:noreply, socket}

      {:error, _reason, socket} ->
        {:noreply,
         socket
         |> clear_step_up()
         |> push_flash(:error, Copy.webhook_replay_step_up_unavailable())}
    end
  end

  def handle_event("confirm_retry_selected", _params, socket) do
    {:noreply, push_flash(socket, :warning, Copy.webhooks_retry_no_selection_warning())}
  end

  def handle_event("step_up_submit", params, %{assigns: %{step_up_pending: true}} = socket) do
    case StepUp.verify(socket, params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, _reason, socket} -> {:noreply, socket}
    end
  end

  def handle_event("step_up_submit", _params, socket), do: {:noreply, socket}

  def handle_event("step_up_escape", _params, socket), do: {:noreply, dismiss_step_up(socket)}
  def handle_event("step_up_dismiss", _params, socket), do: {:noreply, dismiss_step_up(socket)}

  defp execute_bulk_replay(socket, review, selection_matches?) do
    result =
      if selection_matches? and
           review.scope_key == scope_key(socket.assigns.current_owner_scope) and
           review.actor_id == Auth.actor_id(socket.assigns.current_admin) do
        replay_scoped_rows(review, socket.assigns.current_owner_scope)
      else
        denied_bulk_result(review)
      end

    socket
    |> record_bulk_replay(result)
    |> assign(:summary, webhook_summary(socket.assigns.current_owner_scope))
    |> assign(:bulk_replay_result, bulk_replay_result_rows(result, socket))
    |> push_flash(:info, Copy.webhooks_retry_result(result))
  end

  defp bulk_replay_result_rows(result, socket) do
    Enum.map(result.outcomes, fn outcome ->
      detail_available? =
        outcome[:detail_available?] == true and outcome.outcome != :denied and
          outcome[:reread] != :unknown

      %{
        selected_id: outcome.selected_id,
        outcome: Copy.webhooks_retry_outcome(outcome.outcome, outcome.attempted),
        href:
          if detail_available? do
            scoped_path(
              socket.assigns.admin_mount_path,
              "/webhooks/#{outcome.selected_id}",
              socket.assigns.current_owner_scope
            )
          end,
        next_step:
          if outcome.outcome == :unknown or outcome[:reread] == :unknown do
            if detail_available?,
              do: Copy.webhooks_retry_unknown_next_step(),
              else: Copy.webhooks_retry_detail_unavailable()
          end
      }
    end)
  end

  defp reviewed_selection_matches?(params, ids) do
    case Map.get(params, "reviewed_ids") || Map.get(params, "reviewed-ids") do
      nil ->
        true

      reviewed_ids when is_binary(reviewed_ids) ->
        canonical_ids(String.split(reviewed_ids, ",")) == ids

      _other ->
        false
    end
  end

  defp review_bulk_selection(ids, socket) do
    owner_scope = socket.assigns.current_owner_scope

    rows =
      Enum.zip(ids, Enum.map(ids, &selected_replay_row(&1, owner_scope)))
      |> Enum.map(fn {selected_id, row} -> Map.put(row, :selected_id, selected_id) end)

    %{
      ids: ids,
      count: length(ids),
      rows: rows,
      scope_key: scope_key(owner_scope),
      scope_label: owner_scope_label(owner_scope),
      eligible_count: Enum.count(rows, &(&1.status in [:dead, :failed])),
      actor_id: Auth.actor_id(socket.assigns.current_admin)
    }
  end

  defp replay_scoped_rows(%{ids: ids, rows: reviewed_rows}, owner_scope) do
    selected_rows =
      ids
      |> Enum.zip(reviewed_rows)
      |> Enum.map(fn {id, reviewed} ->
        current = selected_replay_row(id, owner_scope)

        Map.merge(current, %{
          selected_id: id,
          reviewed_status: reviewed[:status],
          reviewed_id: reviewed[:id]
        })
      end)
      |> Enum.sort_by(
        fn %{id: id, row: row} ->
          received_at =
            if row && row.received_at,
              do: DateTime.to_unix(row.received_at, :microsecond),
              else: 0

          {received_at, id || ""}
        end,
        :desc
      )

    eligible =
      Enum.count(selected_rows, fn %{row: row} -> row && row.status in [:failed, :dead] end)

    outcomes =
      Enum.map(selected_rows, &replay_outcome(&1, owner_scope))

    queued = Enum.count(outcomes, &(&1.outcome == :queued))

    %{
      selected: length(ids),
      eligible: eligible,
      attempted: Enum.count(outcomes, & &1.attempted),
      queued: queued,
      skipped: Enum.count(outcomes, &(&1.outcome == :skipped)),
      denied: Enum.count(outcomes, &(&1.outcome == :denied)),
      failed: Enum.count(outcomes, &(&1.outcome == :failed)),
      unknown: Enum.count(outcomes, &(&1.outcome == :unknown)),
      reread_unknown: Enum.count(outcomes, &(&1[:reread] == :unknown)),
      outcomes: outcomes
    }
  end

  defp denied_bulk_result(review) do
    outcomes =
      Enum.map(review.ids, &%{id: &1, selected_id: &1, outcome: :denied, attempted: false})

    %{
      selected: length(review.ids),
      eligible: 0,
      attempted: 0,
      queued: 0,
      skipped: 0,
      denied: length(review.ids),
      failed: 0,
      unknown: 0,
      reread_unknown: 0,
      outcomes: outcomes
    }
  end

  defp selected_replay_row(id, owner_scope) do
    case replay_detail(id, owner_scope) do
      {:ok, row} -> %{id: row.id, row: row, status: row.status, authorized?: true}
      _inaccessible -> %{id: nil, row: nil, status: nil, authorized?: false}
    end
  rescue
    _read_error -> %{id: nil, row: nil, status: nil, authorized?: false, read_failed?: true}
  end

  defp replay_detail(id, owner_scope) do
    if Mix.env() == :test do
      case Application.get_env(:accrue_admin, :webhook_replay_detail_fun) do
        fun when is_function(fun, 2) -> fun.(id, owner_scope)
        _configured_fun -> Webhooks.detail(id, owner_scope)
      end
    else
      Webhooks.detail(id, owner_scope)
    end
  end

  defp replay_outcome(selection, owner_scope) do
    selection
    |> do_replay_outcome(owner_scope)
    |> Map.put_new(:selected_id, selection.selected_id)
    |> Map.put_new(:detail_available?, selection[:authorized?])
  end

  defp do_replay_outcome(%{read_failed?: true}, _owner_scope),
    do: %{id: nil, outcome: :unknown, attempted: false}

  defp do_replay_outcome(%{id: nil}, _owner_scope),
    do: %{id: nil, outcome: :skipped, attempted: false}

  defp do_replay_outcome(%{id: id, row: %{status: status}}, _owner_scope)
       when status not in [:failed, :dead],
       do: %{id: id, outcome: :skipped, attempted: false, reread: :not_applicable}

  defp do_replay_outcome(
         %{id: id, row: %{status: status}, reviewed_status: reviewed},
         _owner_scope
       )
       when status != reviewed,
       do: %{id: id, outcome: :skipped, attempted: false, reread: :not_applicable}

  defp do_replay_outcome(%{id: id} = selection, owner_scope) do
    enqueue_result =
      try do
        requeue_delivery(id, owner_scope)
      rescue
        _queue_error -> :unknown_dispatch_outcome
      end

    case enqueue_result do
      {:ok, _queued} ->
        %{
          id: id,
          selected_id: selection.selected_id,
          detail_available?: selection[:authorized?],
          outcome: :queued,
          attempted: true,
          reread: post_enqueue_status(id, owner_scope)
        }

      {:error, :out_of_scope} ->
        %{
          id: nil,
          selected_id: selection.selected_id,
          outcome: :denied,
          attempted: false,
          reread: :not_applicable
        }

      {:error, reason} when reason in [:already_replayed, :not_dead_lettered, :not_found] ->
        %{
          id: id,
          selected_id: selection.selected_id,
          detail_available?: selection[:authorized?],
          outcome: :skipped,
          attempted: false,
          reread: :not_applicable
        }

      {:error, _reason} ->
        %{
          id: id,
          selected_id: selection.selected_id,
          detail_available?: selection[:authorized?],
          outcome: :failed,
          attempted: true,
          reread: :not_applicable
        }

      _unclassifiable ->
        %{
          id: id,
          selected_id: selection.selected_id,
          detail_available?: selection[:authorized?],
          outcome: :unknown,
          attempted: true,
          reread: :not_applicable
        }
    end
  end

  defp post_enqueue_status(id, owner_scope) do
    case selected_replay_row(id, owner_scope) do
      %{row: %{status: status}} -> status
      _unavailable -> :unknown
    end
  rescue
    _read_error -> :unknown
  end

  defp scope_key(%{mode: mode, organization_id: organization_id, organization_slug: slug}),
    do: {mode, organization_id, slug}

  defp scope_key(_scope), do: :global

  defp owner_scope_label(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "Organization #{slug}"

  defp owner_scope_label(_scope), do: "Global admin"

  defp canonical_ids(ids) do
    ids
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp requeue_delivery(id, owner_scope) do
    authorize_fun = &Webhooks.owner_scope_allows_replay?(&1, owner_scope)

    if Mix.env() == :test do
      case Application.get_env(:accrue_admin, :webhook_requeue_fun) do
        fun when is_function(fun, 2) -> fun.(id, authorize_fun)
        _configured_fun -> DLQ.requeue(id, authorize_fun)
      end
    else
      DLQ.requeue(id, authorize_fun)
    end
  end

  defp bulk_step_up_action do
    %{type: "admin.webhook.bulk_replay", subject_type: "WebhookBatch", subject_id: "selected"}
  end

  defp dismiss_step_up(socket) do
    if socket.assigns[:step_up_pending], do: StepUp.dismiss_challenge(socket), else: socket
  end

  defp clear_step_up(socket) do
    socket
    |> assign(:step_up_pending, false)
    |> assign(:step_up_action, nil)
    |> assign(:step_up_challenge, nil)
    |> assign(:step_up_error, nil)
    |> assign(:step_up_continuation, nil)
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
      <section class="ax-page">
        <PageHeader.page_header
          breadcrumb_group="Developer"
          breadcrumbs={[
            %{label: Copy.webhooks_index_heading()}
          ]}
          title={Copy.webhooks_list_heading()}
        >
          <:description>
            <p class="ax-body"><%= Copy.webhooks_list_subtitle() %></p>
          </:description>

          <:stat_strip>
            <StatStrip.stat_strip label="Webhook summary">
              <:stat label="Received" value={Integer.to_string(@summary.received_count)} />
              <:stat
                label="Blocked"
                value={Integer.to_string(@summary.blocked_count)}
                tone={if @summary.blocked_count > 0, do: "amber"}
              />
              <:stat
                label="Replayed"
                value={Integer.to_string(@summary.replayed_count)}
              />
            </StatStrip.stat_strip>
          </:stat_strip>

          <:filter_toolbar>
            <DataTable.filter_toolbar
              id="webhooks"
              filter_fields={webhook_filter_fields(@current_owner_scope)}
              filter_params={filter_params(@params)}
              path={@table_path}
              clear_href={reset_href(@table_path)}
              clear_visible={!default_view?(@params, @current_owner_scope)}
              clear_label="Reset filters"
            />
          </:filter_toolbar>
        </PageHeader.page_header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section
          :if={@bulk_replay_result}
          id="bulk-replay-results"
          class="ax-card"
          data-role="bulk-replay-results"
          aria-label="Bulk replay results"
        >
          <h2 class="ax-heading">Delivery results</h2>
          <ul class="ax-list">
            <li
              :for={item <- @bulk_replay_result}
              class="ax-body"
              data-delivery-id={item.selected_id}
            >
              <code><%= item.selected_id %></code>
              <span><%= item.outcome %></span>
              <a :if={item.href} href={item.href} class="ax-link">Open delivery</a>
              <span :if={item.next_step}><%= item.next_step %></span>
            </li>
          </ul>
        </section>

        <p class="ax-body ax-page-copy" data-role="webhooks-retry-helper">
          <%= Copy.webhooks_retry_selected_helper() %>
        </p>

        <section
          :if={@pending_bulk_replay}
          id="bulk-replay-confirm"
          class="ax-card"
          data-role="bulk-replay-confirm"
          phx-hook="FocusTrap"
          data-focus-trap-active="false"
          data-focus-trap-return-to="[data-role='bulk-action']"
          data-focus-trap-initial="#confirm-retry-selected"
        >
          <p class="ax-body">
            <%= Copy.webhooks_retry_confirm_question(@pending_bulk_replay.count) %>
          </p>
          <p class="ax-body" data-role="bulk-replay-review-scope">
            Reviewed for <%= @pending_bulk_replay.scope_label %> ·
            <%= @pending_bulk_replay.eligible_count %> of
            <%= @pending_bulk_replay.count %> currently eligible
          </p>
          <ul class="ax-list" data-role="bulk-replay-reviewed-deliveries">
            <li :for={reviewed <- @pending_bulk_replay.rows} class="ax-body">
              <code><%= reviewed.selected_id %></code> ·
              <%= if reviewed.row, do: humanize(reviewed.status), else: "Unavailable in this scope" %>
            </li>
          </ul>
          <div class="ax-page-header">
            <button
              type="button"
              phx-click="confirm_retry_selected"
              phx-value-reviewed-ids={Enum.join(@pending_bulk_replay.ids, ",")}
              class="ax-button ax-button-primary"
              id="confirm-retry-selected"
              data-role="confirm-retry-selected"
            >
              <%= Copy.webhooks_retry_queue_label() %>
            </button>
            <button
              type="button"
              phx-click="cancel_bulk_replay"
              class="ax-button ax-button-ghost"
            >
              <%= Copy.webhooks_retry_cancel_label() %>
            </button>
          </div>
        </section>

        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />

        <div :if={@step_up_pending} hidden aria-hidden="true" data-role="step-up-test-mirror">
          <form phx-submit="step_up_submit">
            <input type="text" name="code" value="" />
            <button type="submit" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
          </form>
        </div>

        <.live_component
          module={DataTable}
          id="webhooks"
          query_module={Webhooks}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          list_id="webhooks"
          list_state={list_state(@params)}
          empty_reason={empty_reason(@params, @summary)}
          loading_fixture={phase197_loading_fixture?(@params)}
          loading_label={list_state_copy(:loading).heading}
          render_filter_toolbar={false}
          clear_href={reset_href(@table_path)}
          empty_action_href={if queue_active?(@params), do: clear_all_href(@params, @table_path), else: reset_href(@table_path)}
          empty_action_label={if queue_active?(@params), do: "View all deliveries", else: "Reset filters"}
          show_row_count={false}
          selectable={true}
          row_label={{"delivery", "deliveries"}}
          bulk_action_label={Copy.webhooks_retry_selected_label()}
          bulk_action_event="retry_selected"
          columns={[
            %{label: "Webhook", render: &webhook_link(&1, @admin_mount_path, @current_owner_scope, :table)},
            %{id: :type, label: "Type"},
            %{label: "Status", render: &status_summary/1},
            %{label: "Endpoint", render: &endpoint_summary/1},
            %{label: "Received", render: fn row -> received_summary(row, :table) end}
          ]}
          card_title={&webhook_link(&1, @admin_mount_path, @current_owner_scope, :card)}
          card_fields={[
            %{label: "Status", render: &status_summary/1},
            %{label: "Endpoint", render: &endpoint_summary/1},
            %{label: "Received", render: fn row -> received_summary(row, :card) end}
          ]}
          filter_fields={webhook_filter_fields(@current_owner_scope)}
          empty_title={empty_title(@params, @summary)}
          empty_copy={empty_copy(@params, @summary)}
          filtered_empty_title={empty_title(@params, @summary)}
          filtered_empty_copy={empty_copy(@params, @summary)}
          table_caption={Copy.webhooks_index_table_caption()}
        >
          <:list_status :let={status}>
            <FilterChipBar.filter_chip_bar
              items={work_queue_chips(@params, @table_path)}
              label="Webhook view"
              compact={true}
              result_count={status.visible_count}
              result_label={Copy.webhooks_list_result_label_pair()}
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
    |> assign(:page_title, "Webhooks")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/webhooks"))
  end

  # Status filter options carry their live count in the label and disable zero-count
  # statuses (the active value is never disabled — handled in DataTable.filter_input/1).
  defp webhook_filter_fields(owner_scope) do
    [
      %{
        id: :status,
        label: "Status",
        type: :select,
        all_label: "All statuses",
        options: status_filter_options(owner_scope)
      },
      %{
        id: :type,
        label: "Type",
        type: :datalist,
        options: Webhooks.distinct_types(owner_scope)
      },
      %{
        id: :livemode,
        label: "Live mode",
        type: :segmented,
        options: [{"", "All"}, {"true", "Live"}, {"false", "Test"}]
      }
    ]
  end

  defp status_filter_options(owner_scope) do
    counts = Webhooks.status_counts(owner_scope)

    Enum.map(WebhookEvent.statuses(), fn status ->
      count = Map.get(counts, status, 0)

      %{
        value: Atom.to_string(status),
        label: "#{humanize(status)} (#{count})",
        disabled: count == 0
      }
    end)
  end

  defp webhook_summary(owner_scope) do
    %{
      received_count: Webhooks.count(owner_scope),
      blocked_count: Webhooks.count(owner_scope, %{status: [:failed, :dead]}),
      dead_count: Webhooks.count(owner_scope, %{status: :dead}),
      replayed_count: Webhooks.count(owner_scope, %{status: :replayed}),
      livemode_count: Webhooks.count(owner_scope, %{livemode: true})
    }
  end

  defp filter_params(params) do
    params
    |> Webhooks.decode_filter()
    |> Webhooks.encode_filter()
    |> Map.new(fn {key, value} -> {to_string(key), to_string(value)} end)
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
        label: Copy.webhooks_list_default_lens_label(),
        tone: :cobalt,
        active: queue_active,
        remove_href: if(queue_active, do: clear_href)
      },
      %{
        id: :view_all,
        label: Copy.webhooks_list_all_lens_label(),
        tone: :slate,
        active: queue_active or all_active,
        href: if(queue_active, do: clear_href)
      }
    ] ++ filter_chips
  end

  defp filter_chip_label("status"), do: "Status"
  defp filter_chip_label("type"), do: "Type"
  defp filter_chip_label("livemode"), do: "Live mode"
  defp filter_chip_label(key), do: humanize(key)

  defp filter_chip_value("status", value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map_join(", ", &humanize/1)
  end

  defp filter_chip_value("livemode", "true"), do: "Live"
  defp filter_chip_value("livemode", "false"), do: "Test"
  defp filter_chip_value(_key, value), do: value

  defp clear_all_href(_params, table_path) do
    AccrueAdmin.DataTableNav.merge_query(table_path, %{
      "view" => "all",
      "type" => nil,
      "status" => nil,
      "livemode" => nil,
      "cursor" => nil,
      "phase197_state" => nil
    })
  end

  defp filter_active?(params), do: filter_params(params) != %{}

  defp reset_href(table_path), do: table_path

  defp default_view?(params, scope),
    do: params == build_default_params(scope, @default_queue_status)

  defp list_state(params) do
    if phase197_loading_fixture?(params), do: "loading-skeleton", else: nil
  end

  defp empty_reason(params, summary) do
    cond do
      phase197_loading_fixture?(params) -> nil
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

  defp list_state_copy(state), do: Copy.resource_state_copy(:webhooks, state)

  defp first_run_empty?(params, summary),
    do:
      Map.get(params, "view") == "all" and summary.received_count == 0 and !filter_active?(params)

  defp phase197_loading_fixture?(params) do
    Application.get_env(:accrue_admin, :env) == :test and
      Map.get(params, "phase197_state") == "loading-skeleton"
  end

  defp record_bulk_replay(socket, result) do
    current_admin = socket.assigns.current_admin
    scoped_ids = result.outcomes |> Enum.map(& &1.id) |> Enum.reject(&is_nil/1)
    scoped_outcomes = Enum.reject(result.outcomes, &is_nil(&1.id))

    {:ok, _event} =
      Events.record(%{
        type: "admin.webhook.bulk_replay.completed",
        subject_type: "WebhookBatch",
        subject_id: "selected",
        actor_type: "admin",
        actor_id: Auth.actor_id(current_admin),
        data: %{
          "selected" => result.selected,
          "eligible" => result.eligible,
          "attempted" => result.attempted,
          "queued" => result.queued,
          "skipped" => result.skipped,
          "denied" => result.denied,
          "failed" => result.failed,
          "unknown" => result.unknown,
          "reread_unknown" => result.reread_unknown,
          "ids" => scoped_ids,
          "outcomes" =>
            Enum.map(scoped_outcomes, fn outcome ->
              %{
                "id" => outcome.id,
                "outcome" => Atom.to_string(outcome.outcome),
                "reread" => outcome[:reread] && to_string(outcome.reread)
              }
            end)
        }
      })

    :ok =
      Auth.log_audit(current_admin, %{
        type: "admin.webhook.bulk_replay.completed",
        selected: result.selected,
        eligible: result.eligible,
        attempted: result.attempted,
        queued: result.queued,
        skipped: result.skipped,
        denied: result.denied,
        failed: result.failed,
        unknown: result.unknown,
        reread_unknown: result.reread_unknown,
        ids: scoped_ids,
        source: :accrue_admin
      })

    socket
  end

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp webhook_link(row, mount_path, owner_scope, presentation) do
    label = row.processor_event_id || row.id

    assigns = %{
      href: scoped_path(mount_path, "/webhooks/#{row.id}", owner_scope),
      label: humanize(row.type),
      badge_id:
        "ax-id-badge-webhook-event-#{row.id}#{if presentation == :card, do: "-card", else: ""}",
      id_value: to_string(label)
    }

    ~H"""
    <DataTable.identity_cell label={@label}>
      <:primary><.link href={@href} class="ax-link"><%= @label %></.link></:primary>
      <:secondary><IdBadge.id_badge id={@badge_id} id_value={@id_value} label="Copy webhook event ID" copy_label="webhook event ID" /></:secondary>
    </DataTable.identity_cell>
    """
  end

  defp status_summary(row) do
    text = humanize(row.status) |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="ax-body">#{text}</span>))
  end

  defp endpoint_summary(row) do
    text = "#{humanize(row.endpoint)} · #{mode_label(row.livemode)}"
    escaped = text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<span class="ax-body">#{escaped}</span>))
  end

  defp received_summary(%{received_at: %DateTime{} = value} = row, surface) do
    assigns = %{value: value, id: "webhook-#{surface}-received-#{row.id}"}

    ~H"""
    <Timestamp.timestamp value={@value} id={@id} />
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Phoenix.HTML.raw()
  end

  defp received_summary(_row, _surface), do: "Unknown"

  defp mode_label(true), do: "live"
  defp mode_label(false), do: "test"

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp map_only_scope?(params) do
    params != %{} and Map.keys(params) -- ["org"] == []
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
