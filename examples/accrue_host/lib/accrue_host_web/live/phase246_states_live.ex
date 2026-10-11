defmodule AccrueHostWeb.Phase246StatesLive do
  @moduledoc false

  use AccrueHostWeb, :live_view

  alias AccrueAdmin.Components.{AppShell, DataTable, GlobalSearch, IdBadge}

  @table_id "phase246-state-table"
  @impl true
  def mount(params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    table_case = valid_table_case(params["table"])

    {:ok,
     assign(socket,
       page_title: "Phase 246 Search States",
       brand: admin["brand"] || %{},
       theme: admin["theme"] || "system",
       csp_nonce: admin["csp_nonce"],
       brand_css_path: admin["brand_css_path"],
       assets_css_path: admin["assets_css_path"],
       assets_js_path: admin["assets_js_path"],
       admin_mount_path: admin["mount_path"] || "/admin",
       current_path: "/admin/__phase246/states",
       table_case: table_case,
       table_attrs: table_attrs(table_case),
       search_case: "success",
       search_attrs: search_attrs("success"),
       columns: columns()
     )}
  end

  @impl true
  def handle_event("show-table-case", %{"case" => test_case}, socket) do
    attrs = table_attrs(test_case)
    send_update(DataTable, Keyword.merge([id: @table_id, params: %{}], Map.to_list(attrs)))
    {:noreply, assign(socket, table_case: test_case, table_attrs: attrs)}
  end

  def handle_event("show-search-case", %{"case" => test_case}, socket) do
    attrs = search_attrs(test_case)
    send_update(GlobalSearch, Keyword.merge([id: "global-search"], Map.to_list(attrs)))
    {:noreply, assign(socket, search_case: test_case, search_attrs: attrs)}
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
      current_owner_scope={@current_owner_scope}
    >
      <main class="phase246-state-fixture" data-testid="phase246-states">
        <h1>Phase 246 mounted search states</h1>

        <section aria-labelledby="table-states-heading">
          <h2 id="table-states-heading">Collection state</h2>
          <p data-testid="table-state">{@table_case}</p>
          <div class="phase246-state-controls">
            <button
              :for={
                test_case <- [
                  "loading",
                  "initial-error",
                  "partial-error",
                  "success",
                  "zero",
                  "one",
                  "many",
                  "long"
                ]
              }
              type="button"
              phx-click="show-table-case"
              phx-value-case={test_case}
            >
              Table {test_case}
            </button>
          </div>
          <.live_component
            module={DataTable}
            id="phase246-state-table"
            query_module={AccrueHostWeb.Phase246StatesQuery}
            current_owner_scope={@current_owner_scope}
            path="/admin/customers"
            params={%{}}
            rows={@table_attrs.rows}
            next_cursor={nil}
            columns={@columns}
            list_id="phase246-search-results"
            list_state={@table_attrs.list_state}
            empty_reason={nil}
            filter_params={%{}}
            filter_fields={[]}
            render_filter_toolbar={false}
            loading_fixture={@table_attrs.loading_fixture}
            read_error={@table_attrs.read_error}
            enable_polling={false}
            show_row_count={false}
            poll_interval_ms={0}
          />
        </section>

        <section aria-labelledby="search-states-heading">
          <h2 id="search-states-heading">Global search state</h2>
          <p data-testid="search-state">{@search_case}</p>
          <div class="phase246-state-controls">
            <button
              :for={test_case <- ["loading", "success", "partial", "zero", "one", "many", "long"]}
              type="button"
              phx-click="show-search-case"
              phx-value-case={test_case}
            >
              Search {test_case}
            </button>
          </div>
        </section>
      </main>
    </AppShell.app_shell>
    """
  end

  defp table_attrs("loading") do
    %{rows: [], list_state: "loading-skeleton", loading_fixture: true, read_error: nil}
  end

  defp table_attrs("initial-error") do
    %{rows: [], list_state: "unavailable", loading_fixture: false, read_error: :initial}
  end

  defp table_attrs("partial-error") do
    %{
      rows: [row("Retained result", "cus_phase246_retained")],
      list_state: "partial",
      loading_fixture: false,
      read_error: :partial
    }
  end

  defp table_attrs("zero"),
    do: %{rows: [], list_state: "first-run-empty", loading_fixture: false, read_error: nil}

  defp table_attrs("one"),
    do: %{
      rows: [row("One matching record", "cus_phase246_one")],
      list_state: "populated",
      loading_fixture: false,
      read_error: nil
    }

  defp table_attrs("many") do
    %{
      rows: [
        row("First result", "cus_phase246_first"),
        row("Second result", "cus_phase246_second"),
        row("Third result", "cus_phase246_third")
      ],
      list_state: "populated",
      loading_fixture: false,
      read_error: nil
    }
  end

  defp table_attrs("long") do
    %{
      rows: [row("Zoë 世界 — Long identity", "cus_" <> String.duplicate("unbroken", 18))],
      list_state: "populated",
      loading_fixture: false,
      read_error: nil
    }
  end

  defp table_attrs(_),
    do: %{
      rows: [row("Ada Lovelace", "cus_phase246_success")],
      list_state: "populated",
      loading_fixture: false,
      read_error: nil
    }

  defp row(name, id), do: %{id: id, name: name, status: "Active"}

  defp columns do
    [
      %{id: :identity, label: "Record", render: &identity_cell/1},
      %{id: :status, label: "Status"}
    ]
  end

  defp valid_table_case(case_name) when case_name in ["long"], do: case_name
  defp valid_table_case(_), do: "populated"

  defp identity_cell(row) do
    assigns = %{__changed__: %{}, row: row}

    ~H"""
    <DataTable.identity_cell>
      <:primary><span class="ax-link">{@row.name}</span></:primary>
      <:secondary>
        <IdBadge.id_badge id={"phase246-copy-#{@row.id}"} id_value={@row.id} label="Copy record ID" />
      </:secondary>
    </DataTable.identity_cell>
    """
  end

  defp search_attrs("loading"), do: search_base("loading", [], [], true)
  defp search_attrs("partial"), do: search_base("needle", [customer()], [], false, [:invoices])
  defp search_attrs("zero"), do: search_base("no-match", [], [], false)
  defp search_attrs("one"), do: search_base("needle", [customer()], [], false)

  defp search_attrs("many"),
    do:
      search_base(
        "needle",
        [customer(), customer("cus_phase246_second")],
        [invoice(), invoice("in_phase246_second")],
        false
      )

  defp search_attrs("long"),
    do:
      search_base(
        "needle",
        [customer("cus_" <> String.duplicate("unbroken", 18), "Zoë 世界 — 世界 世界")],
        [],
        false
      )

  defp search_attrs(_), do: search_base("", [], [], false)

  defp search_base(query, customers, invoices, loading, failures \\ [], subscriptions \\ []) do
    %{
      query: query,
      results: %{customers: customers, invoices: invoices, subscriptions: subscriptions},
      failures: failures,
      is_open: true,
      loading: loading
    }
  end

  defp customer(id \\ "cus_phase246_success", name \\ "Ada Lovelace") do
    %{
      id: id,
      name: name,
      email: "ada@example.com",
      owner_type: nil,
      owner_id: nil,
      processor: "stripe",
      processor_id: "cus_stripe_phase246"
    }
  end

  defp invoice(id \\ "in_phase246_success") do
    %{
      id: id,
      number: "INV-246",
      customer_name: "Ada Lovelace",
      customer_email: "ada@example.com",
      processor_id: "in_stripe_phase246"
    }
  end
end

defmodule AccrueHostWeb.Phase246StatesQuery do
  @moduledoc false

  def decode_filter(_params), do: %{}
  def encode_filter(_filter), do: %{}
  def list(_opts), do: {[], nil}
end
