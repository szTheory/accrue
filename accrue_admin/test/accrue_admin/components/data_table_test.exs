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
       |> Phoenix.Component.assign(:table_caption, Map.get(session, "table_caption"))}
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
        columns={[
          %{id: :label, label: "Label"},
          %{id: :status, label: "Status"},
          %{label: "Summary", render: &"#{&1.label} / #{&1.category}"}
        ]}
        card_title={& &1.label}
        card_fields={[
          %{id: :status, label: "Status"},
          %{id: :category, label: "Category"}
        ]}
        filter_fields={[
          %{id: :q, label: "Search"},
          %{id: :status, label: "Status", type: :select, options: [{"open", "Open"}, {"closed", "Closed"}]}
        ]}
        table_caption={@table_caption}
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
               session: %{"params" => %{"status" => "open"}, "table_caption" => "Fixture table title"}
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

    assert html =~ ~s(action="/admin/fixtures")
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

  test "renders card mode markup and supports visible-row bulk selection", %{conn: conn} do
    {:ok, view, html} =
      live_isolated(conn, TableLive, session: %{"params" => %{"status" => "open"}})

    assert html =~ ~s(data-role="card-list")
    assert html =~ "Category"
    assert html =~ "alpha"

    html = render_click(element(view, "[data-role='toggle-all']"))
    assert html =~ ~s(data-role="selected-count">2 selected<)

    html =
      render_click(
        element(view, ~s([data-role="card-list"] [data-role="toggle-row"][data-row-id="row-5"]))
      )

    assert html =~ ~s(data-role="selected-count">1 selected<)
  end

  test "renders default empty state copy from AccrueAdmin.Copy when no rows match", %{conn: conn} do
    FixtureStore.put_rows([])

    assert {:ok, _view, html} =
             live_isolated(conn, TableLive, session: %{"params" => %{}})

    assert html =~ "Nothing in this list yet"
    assert html =~ "Billing records appear here when they match this view"
  end

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
