defmodule AccrueAdmin.DataTableTest do
  use AccrueAdmin.LiveCase, async: false

  alias AccrueAdmin.Components.DataTable
  alias AccrueAdmin.Queries.Cursor

  defmodule FixtureStore do
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> %{rows: [], list_calls: [], count_calls: []} end, name: __MODULE__)
    end

    def put_rows(rows), do: Agent.update(__MODULE__, &Map.put(&1, :rows, rows))

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
  end

  defmodule FixtureQuery do
    @behaviour AccrueAdmin.Queries.Behaviour

    alias AccrueAdmin.DataTableTest.FixtureStore
    alias AccrueAdmin.Queries.Cursor

    @impl true
    def list(opts \\ []) do
      FixtureStore.record_list_call(opts)

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
       |> Phoenix.Component.assign(:poll_interval_ms, Map.get(session, "poll_interval_ms", 5_000))
       |> Phoenix.Component.assign(:table_caption, Map.get(session, "table_caption"))
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
        limit={2}
        dom_limit={4}
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
        dom_limit={4}
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

  test "exposes Phase 190 data-display group contract and cursor-gated pagination", %{
    conn: conn
  } do
    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ ~s(data-component-group="table-empty-loading-error-pagination")
    assert html =~ ~s(data-role="load-more")

    {:ok, _view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "closed"}})

    assert html =~ ~s(data-role="row-count">Showing 2 results<)
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
    assert html =~ "Clear filters"
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
    test "filter form is parent-targeted with debounced text inputs (no phx-target)", %{conn: conn} do
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

    test "renders a viewport-bottom sentinel only while a next cursor exists under dom_limit", %{
      conn: conn
    } do
      # 5 rows, limit 2, dom_limit 4 → next_cursor present and rows (2) < dom_limit.
      {:ok, view, html} =
        live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

      assert html =~ ~s(data-role="viewport-sentinel")
      assert html =~ "phx-viewport-bottom"
      # Load more button remains for a11y / no-JS / past-cap loading.
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

    Process.sleep(60)
    html = render(view)

    assert html =~ "2 new rows - click to load"
    assert FixtureStore.count_calls() != []

    html = render_click(element(view, "[data-role='load-newer']"))

    assert html =~ "Brand new open"
    assert html =~ "Another new open"
    refute html =~ "2 new rows - click to load"
  end
end
