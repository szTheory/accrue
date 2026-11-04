defmodule AccrueAdmin.DataTableTest do
  use AccrueAdmin.LiveCase, async: false
  use Phoenix.Component
  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.DataTable
  alias AccrueAdmin.Queries.Cursor

  defmodule FixtureStore do
    use Agent

    def start_link(_opts) do
      Agent.start_link(
        fn ->
          %{rows: [], list_calls: [], count_calls: [], fail_lists?: false, fail_counts?: false}
        end,
        name: __MODULE__
      )
    end

    def put_rows(rows), do: Agent.update(__MODULE__, &Map.put(&1, :rows, rows))
    def fail_lists, do: Agent.update(__MODULE__, &Map.put(&1, :fail_lists?, true))
    def recover_lists, do: Agent.update(__MODULE__, &Map.put(&1, :fail_lists?, false))
    def fail_counts, do: Agent.update(__MODULE__, &Map.put(&1, :fail_counts?, true))
    def recover_counts, do: Agent.update(__MODULE__, &Map.put(&1, :fail_counts?, false))

    def consume_list_failure do
      Agent.get_and_update(__MODULE__, fn state ->
        {state.fail_lists?, state}
      end)
    end

    def record_list_call(opts) do
      Agent.update(__MODULE__, fn state ->
        Map.update!(state, :list_calls, &[opts | &1])
      end)
    end

    def record_count_call(opts) do
      Agent.update(__MODULE__, fn state ->
        Map.update!(state, :count_calls, &[opts | &1])
      end)
    end

    def list_calls, do: Agent.get(__MODULE__, &Enum.reverse(&1.list_calls))
    def count_calls, do: Agent.get(__MODULE__, &Enum.reverse(&1.count_calls))
    def rows, do: Agent.get(__MODULE__, & &1.rows)
    def count_failure?, do: Agent.get(__MODULE__, & &1.fail_counts?)
  end

  defmodule FixtureQuery do
    @behaviour AccrueAdmin.Queries.Behaviour

    alias AccrueAdmin.DataTableTest.FixtureStore
    alias AccrueAdmin.Queries.Cursor

    @impl true
    def list(opts \\ []) do
      FixtureStore.record_list_call(opts)

      if FixtureStore.consume_list_failure() do
        raise DBConnection.ConnectionError, message: "fixture database unavailable"
      end

      filter = Keyword.get(opts, :filter, %{})
      limit = AccrueAdmin.Queries.Behaviour.normalize_limit(opts)
      cursor = AccrueAdmin.Queries.Behaviour.decode_cursor(opts)

      FixtureStore.rows()
      |> apply_filter(filter)
      |> apply_cursor(cursor)
      |> Enum.take(limit + 1)
      |> AccrueAdmin.Queries.Behaviour.paginate(limit, :inserted_at)
    end

    @impl true
    def count_newer_than(opts \\ []) do
      FixtureStore.record_count_call(opts)

      if FixtureStore.count_failure?() do
        raise DBConnection.ConnectionError, message: "fixture database unavailable"
      end

      filter = Keyword.get(opts, :filter, %{})
      cursor = AccrueAdmin.Queries.Behaviour.decode_cursor(opts)

      FixtureStore.rows()
      |> apply_filter(filter)
      |> count_newer(cursor)
    end

    @impl true
    def decode_filter(params) when is_map(params) do
      %{
        q: normalize_string(Map.get(params, "q") || Map.get(params, :q)),
        status: normalize_string(Map.get(params, "status") || Map.get(params, :status))
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end

    @impl true
    def encode_filter(filter), do: Map.new(filter)

    defp apply_filter(rows, filter) do
      Enum.filter(rows, fn row ->
        matches_q?(row, Map.get(filter, :q)) and matches_status?(row, Map.get(filter, :status))
      end)
    end

    defp matches_q?(_row, nil), do: true

    defp matches_q?(row, query) do
      haystack = "#{row.label} #{row.category}" |> String.downcase()
      String.contains?(haystack, String.downcase(query))
    end

    defp matches_status?(_row, nil), do: true
    defp matches_status?(row, status), do: row.status == status

    defp apply_cursor(rows, nil), do: rows

    defp apply_cursor(rows, {%DateTime{} = inserted_at, id}) do
      Enum.filter(rows, fn row ->
        DateTime.compare(row.inserted_at, inserted_at) == :lt or
          (DateTime.compare(row.inserted_at, inserted_at) == :eq and row.id < id)
      end)
    end

    defp count_newer(_rows, nil), do: 0

    defp count_newer(rows, {%DateTime{} = inserted_at, id}) do
      Enum.count(rows, fn row ->
        DateTime.compare(row.inserted_at, inserted_at) == :gt or
          (DateTime.compare(row.inserted_at, inserted_at) == :eq and row.id > id)
      end)
    end

    defp normalize_string(nil), do: nil

    defp normalize_string(value) when is_binary(value) do
      case String.trim(value) do
        "" -> nil
        trimmed -> trimmed
      end
    end

    defp normalize_string(value), do: to_string(value)
  end

  defmodule TableLive do
    use Phoenix.LiveView

    alias AccrueAdmin.Components.DataTable

    @impl true
    def mount(_params, session, socket) do
      {:ok,
       socket
       |> Phoenix.Component.assign(:table_params, Map.get(session, "params", %{}))
       |> Phoenix.Component.assign(:path, "/admin/fixtures")
       |> Phoenix.Component.assign(:list_id, Map.get(session, "list_id", "fixtures"))
       |> Phoenix.Component.assign(:list_state, Map.get(session, "list_state"))
       |> Phoenix.Component.assign(:empty_reason, Map.get(session, "empty_reason"))
       |> Phoenix.Component.assign(:loading_state?, Map.get(session, "loading_state?", false))
       |> Phoenix.Component.assign(:clear_filters_patch, Map.get(session, "clear_filters_patch"))
       |> Phoenix.Component.assign(
         :render_filter_toolbar,
         Map.get(session, "render_filter_toolbar", true)
       )
       |> Phoenix.Component.assign(:poll_interval_ms, Map.get(session, "poll_interval_ms", 5_000))
       |> Phoenix.Component.assign(:table_caption, Map.get(session, "table_caption"))
       |> Phoenix.Component.assign(:limit, Map.get(session, "limit", 2))
       |> Phoenix.Component.assign(:total_count, Map.get(session, "total_count"))
       |> Phoenix.Component.assign(:test_pid, Map.get(session, "test_pid"))}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.live_component
        module={DataTable}
        id="fixtures"
        query_module={AccrueAdmin.DataTableTest.FixtureQuery}
        path={@path}
        params={@table_params}
        list_id={@list_id}
        list_state={@list_state}
        empty_reason={@empty_reason}
        loading_state?={@loading_state?}
        clear_filters_patch={@clear_filters_patch}
        render_filter_toolbar={@render_filter_toolbar}
        limit={@limit}
        total_count={@total_count}
        poll_interval_ms={@poll_interval_ms}
        selectable={true}
        bulk_action_label="Retry selected"
        bulk_action_event="retry_selected"
        row_label={{"result", "results"}}
        columns={[
          %{id: :label, label: "Label"},
          %{id: :status, label: "Status"},
          %{label: "Summary", render: &"#{&1.label} / #{&1.category}"}
        ]}
        card_title={& &1.label}
        resource_plural="fixture rows"
        card_fields={[
          %{id: :status, label: "Status"},
          %{id: :category, label: "Category"}
        ]}
        filter_fields={[
          %{id: :q, label: "Search"},
          %{id: :status, label: "Status", type: :select, options: [{"open", "Open"}, {"closed", "Closed"}]}
        ]}
        table_caption={@table_caption}
        filtered_empty_title="No fixtures match these filters"
        filtered_empty_copy="Adjust the filters above."
      />
      """
    end

    @impl true
    def handle_event("data_table_filter", params, socket) do
      if pid = socket.assigns[:test_pid] do
        send(pid, {:data_table_filter_received, Map.drop(params, ["_target", "_csrf_token"])})
      end

      {:noreply, socket}
    end

    def handle_event("change_query", params, socket) do
      params = if params == %{}, do: %{"status" => "closed"}, else: params

      {:noreply,
       socket
       |> Phoenix.Component.assign(:table_params, params)
       |> Phoenix.Component.assign(:total_count, nil)}
    end

    @impl true
    def handle_info({:data_table_bulk_action, event, ids}, socket) do
      if pid = socket.assigns[:test_pid] do
        send(pid, {:bulk_action_received, event, ids})
      end

      {:noreply, socket}
    end
  end

  defmodule FilterLive do
    use Phoenix.LiveView

    alias AccrueAdmin.Components.DataTable

    @impl true
    def mount(_params, session, socket) do
      {:ok,
       socket
       |> Phoenix.Component.assign(:table_params, Map.get(session, "params", %{}))
       |> Phoenix.Component.assign(:path, "/admin/fixtures")}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.live_component
        module={DataTable}
        id="filters"
        query_module={AccrueAdmin.DataTableTest.FixtureQuery}
        path={@path}
        params={@table_params}
        limit={2}
        poll_interval_ms={5_000}
        columns={[%{id: :label, label: "Label"}]}
        card_title={& &1.label}
        filter_fields={[
          %{
            id: :type,
            label: "Type",
            type: :datalist,
            options: ["invoice.paid", "invoice.payment_failed"]
          },
          %{
            id: :status,
            label: "Status",
            type: :select,
            options: [
              %{value: "dead", label: "Dead (2)", disabled: false},
              %{value: "open", label: "Open (0)", disabled: true}
            ]
          },
          %{
            id: :livemode,
            label: "Live mode",
            type: :segmented,
            options: [{"", "All"}, {"true", "Live"}, {"false", "Test"}]
          }
        ]}
      />
      """
    end
  end

  setup do
    start_supervised!(FixtureStore)

    rows =
      [
        %{
          id: "row-5",
          label: "Newest open",
          status: "open",
          category: "alpha",
          hidden: "do-not-render",
          inserted_at: ~U[2026-04-15 17:00:05Z]
        },
        %{
          id: "row-4",
          label: "Older open",
          status: "open",
          category: "beta",
          hidden: "do-not-render",
          inserted_at: ~U[2026-04-15 17:00:04Z]
        },
        %{
          id: "row-3",
          label: "Newest closed",
          status: "closed",
          category: "gamma",
          hidden: "do-not-render",
          inserted_at: ~U[2026-04-15 17:00:03Z]
        },
        %{
          id: "row-2",
          label: "Archived closed",
          status: "closed",
          category: "delta",
          hidden: "do-not-render",
          inserted_at: ~U[2026-04-15 17:00:02Z]
        },
        %{
          id: "row-1",
          label: "Oldest open",
          status: "open",
          category: "omega",
          hidden: "do-not-render",
          inserted_at: ~U[2026-04-15 17:00:01Z]
        }
      ]

    FixtureStore.put_rows(rows)
    :ok
  end

  test "optional table_caption renders visually hidden caption on desktop grid", %{conn: conn} do
    assert {:ok, _view, html} =
             live_isolated(conn, TableLive,
               session: %{
                 "params" => %{"status" => "open"},
                 "table_caption" => "Fixture table title"
               }
             )

    assert html =~ ~s(<caption)
    assert html =~ "Fixture table title"
    assert html =~ "ax-visually-hidden"
  end

  test "renders from the shared query contract and round-trips URL filters", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, TableLive,
        session: %{"params" => %{"q" => "closed", "status" => "closed"}}
      )

    # New SPA contract: the filter form drives the PARENT via data_table_filter,
    # not a full-page GET to the table path (no action= / method=get).
    refute html =~ ~s(action="/admin/fixtures")
    refute html =~ ~s(method="get")
    assert html =~ ~s(phx-change="data_table_filter")
    assert html =~ ~s(phx-submit="data_table_filter")
    assert html =~ ~s(name="q" value="closed")
    assert html =~ ~s(<option value="closed" selected="")
    assert html =~ "Newest closed"
    assert html =~ "Archived closed"
    refute html =~ "Newest open"
    refute html =~ "do-not-render"

    assert Enum.all?(FixtureStore.list_calls(), fn opts ->
             opts == [filter: %{q: "closed", status: "closed"}, cursor: nil, limit: 2]
           end)
  end

  test "loads additional rows via opaque cursor pagination without embedding resource fields", %{
    conn: conn
  } do
    {:ok, view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ "Newest open"
    assert html =~ "Older open"
    refute html =~ "Oldest open"

    html = render_click(element(view, "[data-role='load-more']"))

    assert html =~ "Oldest open"
    refute html =~ "Archived closed"

    [pagination_call | initial_calls] = Enum.reverse(FixtureStore.list_calls())

    assert Enum.all?(initial_calls, fn opts ->
             opts == [filter: %{status: "open"}, cursor: nil, limit: 2]
           end)

    assert pagination_call[:filter] == %{status: "open"}
    assert is_binary(pagination_call[:cursor])
    assert {:ok, {~U[2026-04-15 17:00:04Z], "row-4"}} = Cursor.decode(pagination_call[:cursor])
  end

  test "initial list failure is unavailable and retry restores results", %{conn: conn} do
    FixtureStore.fail_lists()

    {:ok, view, html} = live_isolated(conn, TableLive, session: %{"params" => %{}})

    assert html =~ ~s(data-ax-state="unavailable")
    assert html =~ ~s(data-role="unavailable-state")
    assert html =~ ~s(role="alert")
    assert html =~ "History unavailable"
    refute html =~ ~s(data-role="empty-state")
    refute html =~ "fixture database unavailable"

    FixtureStore.recover_lists()
    html = render_click(element(view, "[data-role='retry-read']"))

    assert html =~ ~s(data-ax-state="populated")
    assert html =~ "Newest open"
    refute html =~ ~s(data-role="unavailable-state")
  end

  test "poll count failure keeps rows visible and an explicit retry recovers", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{}, "poll_interval_ms" => 0})

    assert html =~ "Newest open"

    FixtureStore.put_rows([
      %{
        id: "row-6",
        label: "Newest added",
        status: "open",
        category: "zeta",
        inserted_at: ~U[2026-04-15 17:00:06Z]
      }
      | FixtureStore.rows()
    ])

    FixtureStore.fail_counts()
    Phoenix.LiveView.send_update(view.pid, DataTable, id: "fixtures", action: :poll)
    html = render(view)

    assert html =~ ~s(data-role="poll-read-error")
    assert html =~ "Newest open"
    refute html =~ ~s(data-role="unavailable-state")

    FixtureStore.recover_counts()
    html = render_click(element(view, "[data-role='retry-poll']"))

    refute html =~ ~s(data-role="poll-read-error")
    assert html =~ "1 new rows - click to load"
    assert html =~ "Newest open"
  end

  test "load-more failure keeps loaded rows and retry loads the failed page", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, TableLive, session: %{"params" => %{}})
    assert html =~ "Newest open"
    assert html =~ "Load more"

    FixtureStore.fail_lists()
    html = render_click(element(view, "[data-role='load-more']"))

    assert html =~ ~s(data-role="partial-read-error")

    assert html =~
             "Some results could not be loaded. The rows shown may be incomplete. Try again."

    [retry] = Floki.find(Floki.parse_document!(html), "[data-role='retry-read']")
    assert Floki.text(retry) =~ "Retry loading remaining rows"
    assert [target] = Floki.attribute(retry, "phx-target")
    assert target != ""
    assert html =~ "Newest open"
    refute html =~ "Oldest open"

    FixtureStore.recover_lists()
    html = render_click(element(view, "[data-role='retry-read']"))

    assert html =~ "Newest closed"
    refute html =~ ~s(data-role="partial-read-error")
  end

  test "first-page failure clears stale rows, pagination, and selection while preserving filters",
       %{
         conn: conn
       } do
    {:ok, view, _html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    html = render_click(element(view, "[data-role='toggle-all']"))
    assert html =~ "2 selected"
    assert html =~ ~s(data-role="load-more")

    FixtureStore.fail_lists()
    html = render_click(view, "change_query", %{})

    assert html =~ ~s(data-ax-state="unavailable")
    assert html =~ ~s(data-role="unavailable-state")
    refute html =~ "Newest open"
    refute html =~ "2 selected"
    refute html =~ ~s(data-role="load-more")
    assert html =~ ~s(name="status")

    FixtureStore.recover_lists()
    html = render_click(element(view, "[data-role='retry-read']"))

    assert html =~ "Newest closed"
    refute html =~ "Newest open"
    assert List.last(FixtureStore.list_calls())[:filter] == %{status: "closed"}
  end

  test "exposes Phase 190 data-display group contract and cursor-gated pagination", %{
    conn: conn
  } do
    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ ~s(data-component-group="table-empty-loading-error-pagination")
    assert html =~ ~s(data-role="load-more")

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

    assert html =~ ~s(data-role="pagination-progress">2 results loaded<)
    refute html =~ ~s(data-role="load-more")
  end

  test "emits Phase 191 focus anchors for filter, selection, and pagination controls", %{
    conn: conn
  } do
    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ ~s(data-phase191-focus="filter-form")
    assert html =~ ~s(data-phase191-focus="filter-q")
    assert html =~ ~s(data-phase191-focus="filter-status")
    assert html =~ ~s(data-phase191-focus="filter-submit")
    assert html =~ ~s(data-phase191-focus="clear-filters")
    assert html =~ ~s(data-phase191-focus="selection-status")
    assert html =~ ~s(data-phase191-focus="toggle-all")
    assert html =~ ~s(data-phase191-focus="toggle-row")
    assert html =~ ~s(data-phase191-focus="load-more")
  end

  test "distinguishes true-empty from filtered-empty recovery actions", %{conn: conn} do
    FixtureStore.put_rows([])

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{}})

    assert html =~ "Nothing in this list yet"
    refute html =~ ~s(data-role="clear-filters")
    refute html =~ "No fixtures match these filters"

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

    refute html =~ "Nothing in this list yet"
    assert html =~ "No fixtures match these filters"
    assert html =~ ~s(data-role="clear-filters")
    assert html =~ "Clear filters"
  end

  test "emits Phase 196 list markers for populated rows", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ ~s(data-ax-list="fixtures")
    assert html =~ ~s(data-ax-state="populated")
    refute html =~ ~s(data-ax-empty-reason)
  end

  test "emits first-run, filtered, and queue empty reason markers", %{conn: conn} do
    FixtureStore.put_rows([])

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{}})

    assert html =~ ~s(data-ax-list="fixtures")
    assert html =~ ~s(data-ax-state="first-run-empty")
    assert html =~ ~s(data-ax-empty-reason="first-run")
    refute html =~ ~s(data-role="clear-filters")

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

    assert html =~ ~s(data-ax-state="filtered-empty")
    assert html =~ ~s(data-ax-empty-reason="filter")
    assert html =~ ~s(data-role="clear-filters")

    {:ok, _view, html} =
      live_isolated(conn, TableLive,
        session: %{
          "params" => %{"status" => "past_due,canceling"},
          "empty_reason" => "queue",
          "clear_filters_patch" => "/admin/fixtures?view=all&org=acme"
        }
      )

    assert html =~ ~s(data-ax-state="filtered-empty")
    assert html =~ ~s(data-ax-empty-reason="queue")
    assert html =~ ~s(data-role="clear-filters")
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ ~s(href="/admin/fixtures?view=all&amp;org=acme")
  end

  test "keeps the empty-state wrapper non-interactive while clear action remains explicit", %{
    conn: conn
  } do
    FixtureStore.put_rows([])

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

    assert [_, empty_open_tag] = Regex.run(~r/(<div[^>]*data-role="empty-state"[^>]*>)/, html)
    assert empty_open_tag =~ ~s(class="ax-card ax-empty ax-data-table-empty")
    refute empty_open_tag =~ ~r/\srole=/
    refute empty_open_tag =~ ~r/\stabindex=/
    refute empty_open_tag =~ ~r/\sphx-click=/

    assert html =~ ~s(data-role="clear-filters")
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ "Clear filters"

    assert html =~
             ~r/class="ax-empty-content"[^>]*>.*No fixtures match these filters.*Adjust the filters above\..*Clear filters.*<\/div>/s
  end

  test "renders identity as separate primary and secondary lines with an exact copy action" do
    html =
      render_component(fn assigns ->
        assigns = assigns

        ~H"""
        <DataTable.identity_cell>
          <:primary><a href="/admin/invoices/in_123">Invoice № 42</a></:primary>
          <:secondary><button type="button" data-clipboard-text="in_123">Copy invoice ID</button></:secondary>
        </DataTable.identity_cell>
        """
      end)

    assert html =~ ~r/class="ax-data-table-identity-primary"[^>]*>.*Invoice № 42.*<\/span>/s
    assert html =~ ~r/class="ax-data-table-identity-secondary"[^>]*>.*in_123.*<\/span>/s
    assert html =~ ~s(data-clipboard-text="in_123")
  end

  test "renders loading skeleton as an accessible fixture state", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{}, "loading_state?" => true})

    assert html =~ ~s(data-ax-state="loading-skeleton")
    assert html =~ ~s(aria-busy="true")
    assert Regex.scan(~r/role="status"/, html) |> length() == 1
    assert html =~ "Loading"
    assert html =~ "ax-skeleton"
    assert html =~ ~s(aria-hidden="true")

    app_css = File.read!(app_css_path())
    assert app_css =~ ".ax-skeleton"
    assert app_css =~ "@media (prefers-reduced-motion: reduce)"
  end

  test "does not add production-only fake delay hooks for the loading skeleton" do
    source = File.read!("lib/accrue_admin/components/data_table.ex")

    refute source =~ "Process.sleep"
    refute source =~ ":timer.sleep"
    refute source =~ "fake_delay"
    refute source =~ "phase196_fake_delay"
  end

  test "exposes a DataTable-owned filter toolbar API for PageHeader slots" do
    html =
      render_component(&DataTable.filter_toolbar/1, %{
        id: "subscriptions",
        path: "/billing/subscriptions?org=acme",
        filter_params: %{
          "q" => "northwind",
          "org" => "acme",
          "status" => "past_due,canceling"
        },
        filter_fields: [
          %{id: :q, label: "Search", placeholder: "Search subscriptions"},
          %{
            id: :status,
            label: "Status",
            type: :select,
            options: [{"past_due,canceling", "At risk"}]
          }
        ],
        filter_submit_label: "Apply filters",
        clear_filters_patch: "/billing/subscriptions?view=all&org=acme"
      })

    assert html =~ ~s(phx-change="data_table_filter")
    assert html =~ ~s(phx-submit="data_table_filter")
    refute html =~ ~s(phx-target=)
    refute html =~ ~s(action="/billing/subscriptions)
    assert html =~ ~s(name="q" value="northwind")
    assert html =~ ~s(name="org" value="acme")
    assert html =~ ~s(<option value="past_due,canceling" selected>)
    assert html =~ "At risk"
    assert html =~ ~s(data-role="clear-filters")
    assert html =~ ~s(data-phx-link="patch")
    assert html =~ ~s(href="/billing/subscriptions?view=all&amp;org=acme")
  end

  test "keeps secondary categorical filters in an explicit disclosure with visible labels" do
    html =
      render_component(&DataTable.filter_toolbar/1, %{
        id: "invoices",
        path: "/billing/invoices?org=acme",
        filter_params: %{"q" => "Atelier Café", "collection_method" => "send_invoice"},
        filter_fields: [
          %{id: :q, label: "Search invoices", placeholder: "Search invoices"},
          %{
            id: :collection_method,
            label: "Collection method",
            type: :select,
            secondary: true,
            options: [{"send_invoice", "Email invoice"}]
          }
        ]
      })

    assert html =~ ~s(<label for="invoices-filter-q" class="ax-label">Search invoices</label>)
    assert html =~ ~s(<details class="ax-data-table-filter-disclosure">)
    assert html =~ "Filters"

    assert html =~
             ~s(<select id="invoices-filter-collection_method" name="collection_method" class="ax-select")

    assert html =~ ~s(<option value="send_invoice" selected>)
  end

  test "renders card mode fields and contextual selection controls", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ ~s(data-role="card-list")
    assert html =~ ~s(class="ax-card ax-data-table-shell")
    assert html =~ ~s(class="ax-data-table-cards")
    assert html =~ "Category"
    assert html =~ "alpha"
    refute html =~ "do-not-render"
    assert html =~ ~s(aria-label="Select Newest open")
    assert html =~ "Reset filters"
    assert html =~ ~s(aria-label="Select visible fixture rows")

    html = render_click(element(view, "[data-role='toggle-all']"))
    assert html =~ ~s(data-role="selected-count">2 selected<)
    assert html =~ ~s(aria-label="Selected Newest open")
    assert html =~ ~s(aria-label="Clear visible fixture rows")

    html =
      render_click(
        element(view, ~s([data-role="card-list"] [data-role="toggle-row"][data-row-id="row-5"]))
      )

    assert html =~ ~s(data-role="selected-count">1 selected<)
  end

  test "bulk-action button emits {:data_table_bulk_action, event, ids} to the parent", %{
    conn: conn
  } do
    {:ok, view, html} =
      live_isolated(conn, TableLive,
        session: %{"params" => %{"status" => "open"}, "test_pid" => self()}
      )

    # No selection yet → no bulk-action button rendered.
    refute html =~ ~s(data-role="bulk-action")

    html = render_click(element(view, "[data-role='toggle-all']"))
    assert html =~ ~s(data-role="bulk-action")
    assert html =~ "Retry selected"

    render_click(element(view, "[data-role='bulk-action']"))

    assert_receive {:bulk_action_received, "retry_selected", ids}
    assert Enum.sort(ids) == ["row-4", "row-5"]
  end

  test "renders :datalist, counted/disabled :select, and :segmented filter inputs", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, FilterLive, session: %{"params" => %{}})

    # :datalist — free-text input wired to a native <datalist> of real options.
    assert html =~ ~s(list="filters-filter-type-datalist")
    assert html =~ ~s(<datalist id="filters-filter-type-datalist">)
    assert html =~ ~s(<option value="invoice.payment_failed">)

    # :select — count in the label; zero-count option disabled.
    assert html =~ "Dead (2)"
    assert html =~ "Open (0)"
    assert html =~ ~s(<option value="open" disabled="")

    # :segmented — radiogroup of segments using the shared .ax-segmented* classes.
    assert html =~ ~s(class="ax-segmented")
    assert html =~ "ax-segmented-option"
    assert html =~ ~s(role="radiogroup")
  end

  test "does not disable the active :select value even at zero count", %{conn: conn} do
    {:ok, _view, html} =
      live_isolated(conn, FilterLive, session: %{"params" => %{"status" => "open"}})

    # "open" is zero-count (disabled in the spec) but is the active value — it must
    # stay selectable so the active filter is not stranded.
    assert html =~ ~s(<option value="open" selected="">)
    refute html =~ ~s(<option value="open" selected="" disabled="")
    refute html =~ ~s(<option value="open" disabled="" selected="")
  end

  test "renders default empty state copy from AccrueAdmin.Copy when no rows match", %{conn: conn} do
    FixtureStore.put_rows([])

    assert {:ok, _view, html} =
             live_isolated(conn, TableLive, session: %{"params" => %{}})

    assert html =~ "Nothing in this list yet"
    assert html =~ "Billing records appear here when they match this view"
  end

  describe "SPA filters + infinite-scroll contract (260621-io6)" do
    test "filter form is parent-targeted with debounced text inputs (no phx-target)", %{
      conn: conn
    } do
      {:ok, _view, html} =
        live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

      # phx-change/phx-submit land on the PARENT LiveView (no phx-target on the form).
      assert html =~ ~s(phx-change="data_table_filter")
      assert html =~ ~s(phx-submit="data_table_filter")
      refute html =~ ~s(action="/admin/fixtures")
      # Free-text q input debounces so typing does not patch on every keystroke.
      assert html =~ ~s(phx-debounce="300")
    end

    test "Clear is a LiveView patch link to the table path, not a full-page GET anchor", %{
      conn: conn
    } do
      FixtureStore.put_rows([])

      {:ok, _view, html} =
        live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

      # The filtered-empty Clear control is a patch link carrying the table path.
      assert html =~ ~s(data-role="clear-filters")
      assert html =~ ~s(data-phx-link="patch")
    end

    test "renders an observable boundary only while more rows can be loaded", %{
      conn: conn
    } do
      # More matches remain after the initial two rows.
      {:ok, view, html} =
        live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

      assert html =~ ~s(data-role="viewport-sentinel")
      assert html =~ ~s(phx-hook="Pagination")
      assert html =~ ~s(id="fixtures-scroll-container")
      assert html =~ "data-pagination-target"

      # Load more remains as the progressive keyboard/manual fallback.
      assert html =~ ~s(data-role="load-more")

      # A view with no further pages must not render the sentinel.
      {:ok, _view, closed_html} =
        live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

      refute closed_html =~ ~s(data-role="viewport-sentinel")
      refute closed_html =~ ~s(data-role="load-more")

      # Sentinel reuses the existing load-more event (parity with the button).
      loaded = render_click(element(view, "[data-role='load-more']"))
      assert loaded =~ "Oldest open"
    end

    test "the filter form submit reaches the PARENT LiveView (no phx-target)", %{conn: conn} do
      {:ok, view, _html} =
        live_isolated(conn, TableLive,
          session: %{"params" => %{"status" => "open"}, "test_pid" => self()}
        )

      view
      |> form(~s([data-role="filter-form"]), %{"q" => "closed", "status" => "closed"})
      |> render_submit()

      # Parent-targeted: the event lands on TableLive's handle_event, not the component.
      assert_receive {:data_table_filter_received, %{"q" => "closed", "status" => "closed"}}
    end
  end

  test "all lists keep every requested page beyond 100 rows and identify the final page", %{
    conn: conn
  } do
    FixtureStore.put_rows(
      Enum.map(125..1//-1, fn index ->
        %{
          id: "row-#{index}",
          label: "Customer #{index}",
          status: "open",
          category: "alpha",
          inserted_at: DateTime.add(~U[2026-04-15 17:00:00Z], index, :second)
        }
      end)
    )

    {:ok, view, html} =
      live_isolated(conn, TableLive,
        session: %{"params" => %{}, "limit" => 25, "total_count" => 125}
      )

    assert html =~ "25 of 125 results loaded"

    for expected <- [50, 75, 100, 125] do
      html = render_click(element(view, "[data-role='load-more']"))
      rows = Floki.find(Floki.parse_fragment!(html), "tr[data-row-id]")
      assert length(rows) == expected
      assert length(Enum.uniq(Floki.attribute(rows, "data-row-id"))) == expected
      assert html =~ "Customer 125"
      assert html =~ "#{expected} of 125 results loaded"
      assert has_element?(view, "[data-role='viewport-sentinel']") == expected < 125
    end

    html = render(view)
    refute html =~ ~s(data-role="load-more")
    assert has_element?(view, "[data-role='end-of-list']", "End of list")

    Phoenix.LiveView.send_update(view.pid, DataTable, id: "fixtures", action: :poll)
    assert render(view) =~ "125 of 125 results loaded"

    html = render_click(view, "change_query", %{"q" => "Customer 125"})
    assert html =~ "1 result loaded"
    refute html =~ "Customer 124"
    refute html =~ "of 125"
  end

  # ─── Nyquist structural guards (Phase 176-06) ───────────────────────────────
  #
  # These tests read source files directly to assert structural invariants that
  # cannot be caught by LiveView rendering alone. They follow the same File.read!
  # pattern established in dunning_banner_test.exs and component_registry_test.exs.
  #
  # Guard 1: the .ax-data-table-shell CSS breakpoint uses the --ax-bp-md token
  # (768px) not a bare pixel literal. Changing this to 1024px would regress ⑤
  # for all 9 list screens.
  #
  # Guard 2: ax-measure is not misapplied to columnar targets (ax-empty-copy,
  # ax-field-list). These receive their own width constraints; double-capping
  # them with ax-measure breaks layout.
  # ─────────────────────────────────────────────────────────────────────────────

  describe "Nyquist CSS breakpoint guard" do
    test "data-table card/table swap uses --ax-bp-md (768px) breakpoint token comment" do
      app_css = File.read!(app_css_path())

      # The @media block that shows .ax-data-table-shell at ≥768px must carry the
      # registered --ax-bp-md ↑ comment. Without this comment the token guard fails
      # and the next developer cannot verify the breakpoint is intentional.
      assert app_css =~ "min-width: 768px) { /* --ax-bp-md ↑ */",
             "ax-data-table-shell @media block must use 768px with --ax-bp-md ↑ comment"

      # Regression guard: the old 1024px breakpoint must NOT be adjacent to ax-data-table-shell.
      # We can't do a perfect line-proximity check in a string, but we can assert that
      # the CSS does not pair 1024px and ax-data-table-shell on the same logical line.
      # The pattern "1024px" in the data-table block would indicate the breakpoint reverted.
      #
      # Positive confirmation: verify at least 2 occurrences of the --ax-bp-md ↑ comment
      # (data-table block + ax-grid-2 block) — this proves the token is used consistently.
      match_count =
        app_css
        |> String.split("min-width: 768px) { /* --ax-bp-md ↑ */")
        |> length()
        |> Kernel.-(1)

      assert match_count >= 2,
             "Expected ≥2 occurrences of --ax-bp-md ↑ comment in app.css (data-table + grid blocks), got #{match_count}"
    end
  end

  describe "Nyquist ax-measure misapplication guard" do
    test "ax-measure is not applied to ax-empty-copy or ax-field-list in live templates" do
      live_files =
        Path.wildcard(live_files_glob())

      assert Enum.any?(live_files),
             "Expected live template files to exist at #{live_files_glob()}"

      contents =
        Enum.map_join(live_files, "\n", fn path ->
          case File.read(path) do
            {:ok, content} -> content
            {:error, _} -> ""
          end
        end)

      # ax-empty-copy already has its own max-width: 28rem cap — adding ax-measure
      # creates a double-cap that breaks the empty state layout.
      refute contents =~ "ax-empty-copy ax-measure",
             "ax-measure must NOT be applied to ax-empty-copy (it has its own width cap)"

      # ax-field-list is a columnar dl/dt/dd grid — applying ax-measure collapses
      # both columns to 68ch which destroys the 2-column field layout.
      refute contents =~ "ax-field-list ax-measure",
             "ax-measure must NOT be applied to ax-field-list (columnar layout, not prose)"
    end
  end

  defp app_css_path, do: Path.expand("../../../assets/css/app.css", __DIR__)

  defp live_files_glob do
    base = Path.expand("../../../lib/accrue_admin/live", __DIR__)
    base <> "/**/*_live.ex"
  end

  # ─── end Nyquist structural guards ──────────────────────────────────────────

  test "polls for newer rows and only reloads them when explicitly requested", %{conn: conn} do
    {:ok, view, _html} =
      live_isolated(conn, TableLive,
        session: %{"params" => %{"status" => "open"}, "poll_interval_ms" => 15}
      )

    FixtureStore.put_rows([
      %{
        id: "row-7",
        label: "Brand new open",
        status: "open",
        category: "sigma",
        hidden: "do-not-render",
        inserted_at: ~U[2026-04-15 17:00:07Z]
      },
      %{
        id: "row-6",
        label: "Another new open",
        status: "open",
        category: "tau",
        hidden: "do-not-render",
        inserted_at: ~U[2026-04-15 17:00:06Z]
      }
      | FixtureStore.rows()
    ])

    html = render_until(view, &String.contains?(&1, "2 new rows - click to load"))

    assert html =~ "2 new rows - click to load"
    assert FixtureStore.count_calls() != []

    html = render_click(element(view, "[data-role='load-newer']"))

    assert html =~ "Brand new open"
    assert html =~ "Another new open"
    refute html =~ "2 new rows - click to load"
  end

  test "poll updates preserve caller-positioned toolbar configuration", %{
    conn: conn
  } do
    {:ok, view, html} =
      live_isolated(conn, TableLive,
        session: %{
          "params" => %{"status" => "open"},
          "clear_filters_patch" => "/admin/fixtures?view=all&org=acme",
          "render_filter_toolbar" => false,
          "poll_interval_ms" => 15
        }
      )

    refute html =~ ~s(data-role="filter-form")

    html = render_until(view, fn _html -> FixtureStore.count_calls() != [] end)

    refute html =~ ~s(data-role="filter-form")
  end

  test "poll updates preserve caller-provided clear href configuration", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TableLive,
        session: %{
          "params" => %{"status" => "open"},
          "clear_filters_patch" => "/admin/fixtures?view=all&org=acme",
          "poll_interval_ms" => 15
        }
      )

    assert html =~ ~s(href="/admin/fixtures?view=all&amp;org=acme")

    html = render_until(view, fn _html -> FixtureStore.count_calls() != [] end)

    assert html =~ ~s(href="/admin/fixtures?view=all&amp;org=acme")
  end

  defp render_until(view, predicate, attempts \\ 20)

  defp render_until(view, predicate, attempts) when attempts > 0 do
    html = render(view)

    if predicate.(html) do
      html
    else
      Process.sleep(25)
      render_until(view, predicate, attempts - 1)
    end
  end

  defp render_until(_view, _predicate, 0) do
    flunk("condition was not rendered before timeout")
  end
end
