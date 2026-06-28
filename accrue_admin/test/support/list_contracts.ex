defmodule AccrueAdmin.ListContracts do
  @moduledoc """
  Test-only LIST propagation contract rows for Phase 197.

  Runtime LiveViews must continue to own query params, links, copy, and list
  behavior. This manifest gives ExUnit and Playwright one shared set of expected
  route/list/copy facts for the Phase 197 validation scaffold.
  """

  @loading_fixture_key "phase197_state"
  @loading_fixture_value "loading-skeleton"

  @contracts [
    %{
      id: :customers,
      route: "/billing/customers",
      owner: AccrueAdmin.CustomersLiveTest,
      live_view: AccrueAdmin.CustomersLive,
      list_id: "customers",
      default_lens: %{label: "All customers", params: %{"view" => "all"}},
      all_target: %{"view" => "all"},
      quick_lenses: [
        %{label: "Missing payment method", params: %{"has_default_payment_method" => "false"}}
      ],
      result_label: {"customer", "customers"},
      page_header: %{title: "Find a customer", description_key: :customers_index_description},
      states: %{
        first_run_empty: "No customers yet.",
        queue_empty: nil,
        filtered_empty: "No customers match these filters.",
        loading: "Loading customers."
      },
      clear_all_on_default?: false
    },
    %{
      id: :invoices,
      route: "/billing/invoices",
      owner: AccrueAdmin.InvoicesLiveTest,
      live_view: AccrueAdmin.InvoicesLive,
      list_id: "invoices",
      default_lens: %{label: "Needs collection", params: %{"status" => "open,uncollectible"}},
      all_target: %{
        "view" => "all",
        "q" => nil,
        "status" => nil,
        "customer_id" => nil,
        "collection_method" => nil,
        "cursor" => nil,
        @loading_fixture_key => nil
      },
      quick_lenses: [%{label: "All invoices", params: %{"view" => "all"}}],
      result_label: {"invoice", "invoices"},
      page_header: %{title: "Clear open receivables", description_key: :invoices_index_body},
      states: %{
        first_run_empty: "No invoices yet.",
        queue_empty: "No invoices need collection.",
        filtered_empty: "No invoices match these filters.",
        loading: "Loading invoices."
      },
      clear_all_on_default?: true
    },
    %{
      id: :payments,
      route: "/billing/payments",
      owner: AccrueAdmin.ChargesLiveTest,
      live_view: AccrueAdmin.ChargesLive,
      list_id: "payments",
      default_lens: %{label: "Failed payments", params: %{"status" => "failed"}},
      all_target: %{
        "view" => "all",
        "q" => nil,
        "status" => nil,
        "customer_id" => nil,
        "fees_settled" => nil,
        "cursor" => nil,
        @loading_fixture_key => nil
      },
      quick_lenses: [%{label: "All payments", params: %{"view" => "all"}}],
      result_label: {"payment", "payments"},
      page_header: %{
        title: "Recover failed payments",
        description_key: :charges_index_description
      },
      states: %{
        first_run_empty: "No payments yet.",
        queue_empty: "No failed payments.",
        filtered_empty: "No payments match these filters.",
        loading: "Loading payments."
      },
      clear_all_on_default?: true
    },
    %{
      id: :coupons,
      route: "/billing/coupons",
      owner: AccrueAdmin.CouponsLiveTest,
      live_view: AccrueAdmin.CouponsLive,
      list_id: "coupons",
      default_lens: %{label: "Valid coupons", params: %{"valid" => "true"}},
      all_target: %{
        "view" => "all",
        "q" => nil,
        "valid" => nil,
        "cursor" => nil,
        @loading_fixture_key => nil
      },
      quick_lenses: [%{label: "All coupons", params: %{"view" => "all"}}],
      result_label: {"coupon", "coupons"},
      page_header: %{
        title: "Review usable discounts",
        description_key: :coupons_index_description
      },
      states: %{
        first_run_empty: "No coupons yet.",
        queue_empty: "No valid coupons.",
        filtered_empty: "No coupons match these filters.",
        loading: "Loading coupons."
      },
      clear_all_on_default?: true
    },
    %{
      id: :promotion_codes,
      route: "/billing/promotion-codes",
      owner: AccrueAdmin.PromotionCodesLiveTest,
      live_view: AccrueAdmin.PromotionCodesLive,
      list_id: "promotion-codes",
      default_lens: %{label: "Active codes", params: %{"active" => "true"}},
      all_target: %{
        "view" => "all",
        "q" => nil,
        "active" => nil,
        "coupon_id" => nil,
        "cursor" => nil,
        @loading_fixture_key => nil
      },
      quick_lenses: [%{label: "All promotion codes", params: %{"view" => "all"}}],
      result_label: {"promotion code", "promotion codes"},
      page_header: %{
        title: "Find active codes",
        description_key: :promotion_codes_index_description
      },
      states: %{
        first_run_empty: "No promotion codes yet.",
        queue_empty: "No active codes.",
        filtered_empty: "No promotion codes match these filters.",
        loading: "Loading promotion codes."
      },
      clear_all_on_default?: true
    },
    %{
      id: :webhooks,
      route: "/billing/webhooks",
      owner: AccrueAdmin.WebhooksLiveTest,
      live_view: AccrueAdmin.WebhooksLive,
      list_id: "webhooks",
      default_lens: %{label: "Needs replay", params: %{"status" => "failed,dead"}},
      all_target: %{
        "view" => "all",
        "type" => nil,
        "status" => nil,
        "livemode" => nil,
        "cursor" => nil,
        @loading_fixture_key => nil
      },
      quick_lenses: [%{label: "All deliveries", params: %{"view" => "all"}}],
      result_label: {"webhook delivery", "webhook deliveries"},
      page_header: %{title: "Replay failed deliveries", description_key: :webhooks_index_subtitle},
      states: %{
        first_run_empty: "No webhook deliveries yet.",
        queue_empty: "Nothing needs replay.",
        filtered_empty: "No webhook deliveries match these filters.",
        loading: "Loading webhook deliveries."
      },
      clear_all_on_default?: true
    },
    %{
      id: :events,
      route: "/billing/events",
      owner: AccrueAdmin.EventsLiveTest,
      live_view: AccrueAdmin.EventsLive,
      list_id: "events",
      default_lens: %{label: "All ledger", params: %{"view" => "all"}},
      all_target: %{"view" => "all"},
      quick_lenses: [%{label: "Admin changes", params: %{"actor_type" => "admin"}}],
      result_label: {"event", "events"},
      page_header: %{
        title: "Trace billing activity",
        description_key: :billing_events_copy_global
      },
      states: %{
        first_run_empty: "No billing events yet.",
        queue_empty: nil,
        filtered_empty: "No ledger rows match these filters.",
        loading: "Loading billing events."
      },
      clear_all_on_default?: false
    },
    %{
      id: :connect,
      route: "/billing/connect",
      owner: AccrueAdmin.ConnectAccountsLiveTest,
      live_view: AccrueAdmin.ConnectAccountsLive,
      list_id: "connect-accounts",
      default_lens: %{label: "Needs attention", params: %{"needs_attention" => "true"}},
      all_target: %{
        "view" => "all",
        "q" => nil,
        "type" => nil,
        "charges_enabled" => nil,
        "payouts_enabled" => nil,
        "details_submitted" => nil,
        "deauthorized" => nil,
        "needs_attention" => nil,
        "cursor" => nil,
        @loading_fixture_key => nil
      },
      quick_lenses: [%{label: "All accounts", params: %{"view" => "all"}}],
      result_label: {"connected account", "connected accounts"},
      page_header: %{
        title: "Finish account readiness",
        description_key: :connect_accounts_page_copy_primary
      },
      states: %{
        first_run_empty: "No connected accounts yet.",
        queue_empty: "No accounts need attention.",
        filtered_empty: "No connected accounts match these filters.",
        loading: "Loading connected accounts."
      },
      clear_all_on_default?: true
    }
  ]

  @doc "Shared test-only loading fixture query parameter."
  def loading_fixture, do: {@loading_fixture_key, @loading_fixture_value}

  @doc "All Phase 197 target LIST contract rows in route order."
  def all, do: @contracts

  @doc "Fetch a contract row by id."
  def fetch!(id) when is_atom(id) do
    Enum.find(@contracts, &(&1.id == id)) ||
      raise ArgumentError, "unknown LIST contract #{inspect(id)}"
  end
end
