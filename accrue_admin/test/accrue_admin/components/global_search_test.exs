defmodule AccrueAdmin.Components.GlobalSearchTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.GlobalSearch
  alias AccrueAdmin.Components.Topbar
  alias AccrueAdmin.OwnerScope

  describe "path/2 nil-guard (regression: WR-03 fix)" do
    test "renders without crashing when mount_path is nil (pre-update/2 state)" do
      # GlobalSearch.mount/1 initialises mount_path to nil.  The template calls
      # path(@mount_path, ...) four times in the @query == "" branch, so a
      # render triggered before update/2 delivers mount_path used to raise
      # ArgumentError.  This test verifies the component renders cleanly with
      # mount_path: nil and produces "#" hrefs rather than crashing.
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: nil,
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      # Component must render without raising
      assert html =~ "Choose a customer, invoice, or subscription"

      # All four shortcut links should fall back to "#"
      assert html =~ ~s(data-path="#")
      assert html =~ ~s(href="#")
    end

    test "builds correct paths when mount_path is set" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      assert html =~ ~s(data-path="/billing/customers")
      assert html =~ ~s(href="/billing/customers")
      assert html =~ ~s(data-path="/billing/invoices")
      assert html =~ ~s(data-path="/billing/subscriptions")
      refute html =~ "Open invoice queue to $0.00"
    end

    test "preserves organization owner scope in shortcut and result paths" do
      owner_scope = %OwnerScope{
        mode: :organization,
        current_admin: %{id: "admin_1", role: :admin},
        organization_id: "org_1",
        organization_slug: "acme",
        organization_display_name: "Acme",
        platform_admin?: false,
        admin_org_ids: ["org_1"],
        active_organization_id: "org_1",
        active_organization_slug: "acme"
      }

      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          current_owner_scope: owner_scope,
          query: "",
          results: %{
            customers: [],
            invoices: [],
            subscriptions: []
          },
          is_open: true,
          loading: false
        })

      assert html =~ ~s(data-path="/billing/customers?org=acme")
      assert html =~ ~s(data-path="/billing/invoices?org=acme")
      assert html =~ ~s(data-path="/billing/subscriptions?org=acme")
    end
  end

  describe "command palette group contract" do
    test "renders modal-layer dialog markup with active-result styling proof" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      css = File.read!("assets/css/app.css")

      assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-label="Global search")
      assert css =~ ".ax-command-palette-wrapper"
      assert css =~ "z-index: var(--ax-z-modal)"
      assert css =~ ".ax-command-palette-item.ax-active"
      assert css =~ "var(--ax-interactive-selected)"
    end

    test "does not expose modal dialog semantics while closed" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: false,
          loading: false
        })

      assert html =~ ~s(data-component-group="toolbar-search-filter-sort")
      refute html =~ ~s(role="dialog")
      refute html =~ ~s(aria-modal="true")
      refute html =~ "Jump to"
    end

    test "renders command rows as native pointer-activatable links" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      assert html =~
               ~s(<a id="global-search-option-shortcut-customers" role="option" aria-selected="false" class="ax-command-palette-item" href="/billing/customers" data-path="/billing/customers")

      assert html =~
               ~s(<a id="global-search-option-shortcut-invoices" role="option" aria-selected="false" class="ax-command-palette-item" href="/billing/invoices" data-path="/billing/invoices")
    end

    test "exposes grouped results as combobox options with stable active-target ids" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "ada",
          results: %{
            customers: [
              %{
                id: "cus_accessible",
                name: "Ada",
                email: "ada@example.com",
                owner_type: nil,
                owner_id: nil,
                processor: nil,
                processor_id: nil
              }
            ],
            invoices: [],
            subscriptions: []
          },
          is_open: true,
          loading: false
        })

      assert html =~ ~s(role="combobox")
      assert html =~ ~s(aria-haspopup="listbox")

      assert html =~ ~s(id="global-search-options-customers")
      assert html =~ ~s(role="listbox" aria-label="Customers")

      assert html =~
               ~s(id="global-search-option-customers-cus_accessible" role="option" aria-selected="false")
    end

    test "Phase 199 command palette declares Overlay-backed or overlay-equivalent source markers" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      overlay_backed? =
        html =~ ~s(data-phx-portal="#ax-overlay-root") and html =~ ~s(phx-hook="Overlay")

      named_wrapper? =
        html =~ ~s(data-ax-command-palette-shell) and
          html =~ ~s(data-ax-command-palette-backdrop) and
          html =~ ~s(data-ax-command-palette-panel) and
          html =~ ~s(data-focus-trap-close-event="close") and
          html =~ ~s(data-focus-trap-close-target) and
          html =~ ~s(data-focus-trap-initial) and
          html =~ ~s(data-focus-trap-fallback)

      assert overlay_backed? or named_wrapper?,
             "command palette must either use Overlay or declare equivalent focus/portal markers"
    end

    test "no matches are distinct from failed lookups" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "missing-acme",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      assert html =~ ~s(No billing records match "missing-acme")
      refute html =~ "Some lookups are unavailable"
    end

    test "partial failure retains successful groups and offers a read retry" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "ada@example.com",
          results: %{
            customers: [
              %{
                id: "cus_exact_123",
                name: "Ada Lovelace",
                email: "ada@example.com",
                owner_type: "Organization",
                owner_id: "org-1",
                processor: "stripe",
                processor_id: "cus_stripe_9"
              }
            ],
            invoices: [],
            subscriptions: []
          },
          failures: [:invoices],
          is_open: true,
          loading: false
        })

      assert html =~ "Results couldn't be loaded"
      assert html =~ "Retry failed groups"
      assert html =~ "Ada Lovelace"
      assert html =~ "ada@example.com"
      assert html =~ "Organization org-1"
      assert html =~ "stripe cus_stripe_9"
      assert html =~ "Customer ID: cus_exact_123"
      assert html =~ ~s(href="/billing/customers/cus_exact_123")
    end

    test "keeps same-name records as distinct scoped links and describes the active result status" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "Ada Lovelace",
          results: %{
            customers: [
              %{
                id: "cus_first",
                name: "Ada Lovelace",
                email: "ada@example.com",
                owner_id: nil,
                owner_type: nil,
                processor_id: nil,
                processor: nil
              },
              %{
                id: "cus_second",
                name: "Ada Lovelace",
                email: "ada@example.com",
                owner_id: nil,
                owner_type: nil,
                processor_id: nil,
                processor: nil
              }
            ],
            invoices: [],
            subscriptions: []
          },
          failures: [],
          is_open: true,
          loading: false
        })

      assert html =~ ~s(aria-describedby="global-search-help global-search-active-result")
      assert html =~ ~s(id="global-search-active-result" class="ax-visually-hidden" role="status")
      assert html =~ ~s(href="/billing/customers/cus_first")
      assert html =~ ~s(href="/billing/customers/cus_second")
      assert html =~ "Customer ID: cus_first"
      assert html =~ "Customer ID: cus_second"
    end

    test "retry fetch preserves completed groups while replacing only the retried group" do
      customer = %{id: "cus_preserved"}
      invoice = %{id: "inv_retried"}
      initial = %{customers: [customer], invoices: [], subscriptions: []}

      {results, failures} =
        GlobalSearch.run_group_lookups([:invoices], initial, fn :invoices ->
          {[invoice], nil}
        end)

      assert results == %{customers: [customer], invoices: [invoice], subscriptions: []}
      assert failures == []

      {failed_results, failed_groups} =
        GlobalSearch.run_group_lookups([:invoices], initial, fn :invoices ->
          raise "invoice query unavailable"
        end)

      assert failed_results == initial
      assert failed_groups == [:invoices]

      # A fresh full query deliberately starts from an empty result map.
      {fresh_results, _} =
        GlobalSearch.run_group_lookups(
          [:customers],
          %{customers: [], invoices: [], subscriptions: []},
          fn :customers ->
            {[], nil}
          end
        )

      assert fresh_results == %{customers: [], invoices: [], subscriptions: []}
    end

    test "help copy names the supported record groups without adding more instructions" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "ada",
          results: %{customers: [], invoices: [], subscriptions: []},
          failures: [],
          is_open: true,
          loading: false
        })

      assert html =~ "Search billing records across customers, invoices, and subscriptions"
      refute html =~ "Customers: name, email, owner ID, processor ID"
      refute html =~ "Up to five results per group"
      refute html =~ "Type customer name, email, or ID"
      refute html =~ "Open invoice queue to $0.00"
    end

    test "keeps the initial dialog orientation compact and uses the approved billing copy" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: false
        })

      assert html =~ "Choose a customer, invoice, or subscription"
      refute html =~ "Open a scoped list"
      refute html =~ "Up to five results per group"
      assert html =~ "Navigate"
      assert html =~ "Select"
      assert html =~ "Close"
    end

    test "topbar trigger is a single-line billing search with destinations and shortcut" do
      html = render_component(&Topbar.topbar/1, %{theme: "light", theme_forced: false})

      assert html =~ "Search billing"
      assert html =~ "customers, invoices, and subscriptions"
      assert html =~ "⌘K"
      refute html =~ "Customer billing lookup"
      refute html =~ "Search customers now"
    end

    test "sizes the current loading indicator and makes hidden win in authored CSS" do
      html =
        render_component(GlobalSearch, %{
          id: "global-search",
          mount_path: "/billing",
          query: "ada",
          results: %{customers: [], invoices: [], subscriptions: []},
          is_open: true,
          loading: true
        })

      css = File.read!("assets/css/app.css")

      assert html =~ ~s(class="ax-spinner ax-spinner-md" hidden={false}) or
               html =~ ~s(class="ax-spinner ax-spinner-md")

      assert html =~ "Searching billing records"
      assert css =~ ~r/\.ax-spinner\[hidden\]\s*\{[^}]*display:\s*none/s
      assert css =~ "@media (prefers-reduced-motion: reduce)"
    end

    test "async replies are accepted only for the current query, scope and generation" do
      source = File.read!("lib/accrue_admin/components/global_search.ex")

      assert source =~ "query == socket.assigns.query"
      assert source =~ "owner_scope == socket.assigns.current_owner_scope"
      assert source =~ "generation == socket.assigns.generation"
      assert source =~ "Task.start(fn ->"
      assert source =~ "view_pid = self()"
      assert source =~ "send_update(view_pid, __MODULE__,"
      assert source =~ "current_owner_scope: next_scope"
      assert source =~ "generation: socket.assigns.generation + 1"
    end

    test "late results cannot replace the current query results" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          query: "current query",
          current_owner_scope: nil,
          generation: 4,
          results: %{customers: [%{id: "current"}], invoices: [], subscriptions: []},
          failures: [],
          loading: false
        }
      }

      assert {:ok, updated} =
               GlobalSearch.update(
                 %{
                   action: "search_results",
                   query: "old query",
                   owner_scope: nil,
                   generation: 3,
                   results: %{customers: [%{id: "stale"}], invoices: [], subscriptions: []},
                   failures: []
                 },
                 socket
               )

      assert updated.assigns.results.customers == [%{id: "current"}]
    end

    test "changing owner scope clears query and prior results" do
      owner_scope = %OwnerScope{
        mode: :organization,
        current_admin: %{id: "admin_1", role: :admin},
        organization_id: "org_1",
        organization_slug: "acme",
        organization_display_name: "Acme",
        platform_admin?: false,
        admin_org_ids: ["org_1"],
        active_organization_id: "org_1",
        active_organization_slug: "acme"
      }

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          __changed__: %{},
          query: "stale query",
          current_owner_scope: nil,
          generation: 1,
          results: %{customers: [%{id: "foreign"}], invoices: [], subscriptions: []},
          failures: [],
          loading: true
        }
      }

      assert {:ok, updated} =
               GlobalSearch.update(%{current_owner_scope: owner_scope}, socket)

      assert updated.assigns.current_owner_scope == owner_scope
      assert updated.assigns.query == ""
      assert updated.assigns.results == %{customers: [], invoices: [], subscriptions: []}
      refute updated.assigns.loading
      assert updated.assigns.generation == 2
    end

    test "Phase 199 search source uses owner-scoped query modules" do
      source = File.read!("lib/accrue_admin/components/global_search.ex")

      refute source =~ "Billing.search_customers"
      refute source =~ "Billing.search_invoices"
      refute source =~ "Billing.search_subscriptions"
      assert source =~ "Customers.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope)"
      assert source =~ "Invoices.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope)"

      assert source =~
               "Subscriptions.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope)"

      assert source =~ "ScopedPath.build(mount_path, suffix, owner_scope)"
    end
  end
end
