defmodule AccrueAdmin.CopyTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Copy

  alias AccrueAdmin.Copy.{
    BillingEvent,
    Connect,
    Coupon,
    Invoice,
    Locked,
    PromotionCode,
    Subscription
  }

  @vague_standalone ~r/\A(?:failed|forbidden|invalid|not found|could not load|something went wrong|oops)\.?\z/i
  @raw_generic_guard ~r/No results|Try again|Submit|Continue|Something went wrong/
  @voice_guard ~r/\b(production-grade|batteries-included|bank-grade|modern alternative|seamless|powerful|robust|effortless|best-in-class|world-class|wallet|funds)\b/i

  test "PAGE-02 and CPY-01 page state helpers distinguish state classes" do
    states = %{
      true_empty:
        Copy.page_state_copy(:true_empty,
          resource: "billing records",
          owner_scope: "organization org_phase191"
        ),
      filtered_empty:
        Copy.page_state_copy(:filtered_empty,
          resource: "invoice records",
          owner_scope: "organization org_phase191"
        ),
      data_unavailable:
        Copy.page_state_copy(:data_unavailable,
          resource: "webhook delivery data",
          recovery: "retry from the Webhooks queue"
        ),
      permission_denied:
        Copy.page_state_copy(:permission_denied,
          object: "invoice in_phase191",
          owner_scope: "organization org_phase191"
        ),
      disconnected: Copy.page_state_copy(:disconnected, resource: "billing actions"),
      reconnecting: Copy.page_state_copy(:reconnecting, resource: "billing actions"),
      recoverable_error:
        Copy.page_state_copy(:recoverable_error,
          resource: "Connect account acct_phase191",
          owner_scope: "organization org_phase191",
          recovery: "retry from the Connect list"
        )
    }

    assert states.true_empty.heading == "No billing records yet"
    assert states.filtered_empty.heading == "No records match these filters"
    assert states.permission_denied.heading == "Access restricted"
    assert states.disconnected.body == "Connection lost. Reconnecting before actions can run."

    assert states.reconnecting.body ==
             "Connection restored. Review the current state before running an action."

    headings = states |> Map.values() |> Enum.map(& &1.heading)
    bodies = states |> Map.values() |> Enum.map(& &1.body)

    assert Enum.uniq(headings) == headings
    assert Enum.uniq(bodies) == bodies

    assert states.true_empty.body =~ "Accrue records activity"
    assert states.filtered_empty.body =~ "Clear filters"
    assert states.data_unavailable.body =~ "webhook delivery data"
    assert String.downcase(states.data_unavailable.body) =~ "retry from the webhooks queue"
    assert states.permission_denied.body =~ "invoice in_phase191"
    assert states.permission_denied.body =~ "organization org_phase191"
    assert states.recoverable_error.body =~ "Connect account acct_phase191"
    assert states.recoverable_error.body =~ "logs"

    refute_vague_copy!(states)
  end

  test "CPY-02 destructive and consequential helpers name object, billing effect, and audit consequence" do
    invoice =
      Invoice.invoice_confirm_workflow_message(
        "Void invoice",
        "invoice in_phase191",
        "move the invoice to void without contacting the processor",
        "record an admin audit row for the invoice action",
        Invoice.invoice_confirm_source_event_suffix("evt_phase191")
      )

    subscription =
      Subscription.subscription_confirm_workflow_message("cancel_now",
        subscription_id: "sub_phase191",
        customer_id: "cus_phase191",
        source_event_id: "evt_phase191"
      )

    charge =
      Copy.charge_refund_confirm_message(
        charge_id: "ch_phase191",
        amount: "$12.00 USD",
        audit_subject: "refund ledger row"
      )

    single_webhook =
      Locked.single_replay_confirmation("wh_phase191",
        owner_scope: "organization org_phase191"
      )

    bulk_webhooks = Copy.webhooks_retry_confirm_question(3)

    assert invoice =~ "Void invoice"
    assert invoice =~ "invoice in_phase191"
    assert invoice =~ "void"
    assert invoice =~ "admin audit row"
    assert invoice =~ "evt_phase191"

    assert subscription =~ "sub_phase191"
    assert subscription =~ "cus_phase191"
    assert subscription =~ "billing period"
    assert subscription =~ "admin audit row"
    assert subscription =~ "evt_phase191"

    assert charge =~ "Refund charge ch_phase191"
    assert charge =~ "$12.00 USD"
    assert charge =~ "refund ledger row"
    assert charge =~ "admin audit row"

    assert single_webhook =~ "Replay webhook wh_phase191"
    assert single_webhook =~ "organization org_phase191"
    assert single_webhook =~ "admin audit event"

    assert bulk_webhooks =~ "Retry 3 webhook events"
    assert bulk_webhooks =~ "failed every automatic retry"
    assert Copy.webhooks_retry_cancel_label() == "Cancel"

    refute_vague_copy!([
      invoice,
      subscription,
      charge,
      single_webhook,
      bulk_webhooks,
      Copy.webhooks_retry_cancel_label()
    ])
  end

  test "CPY-03 domain vocabulary stays exact across copy modules" do
    strings = [
      Copy.invoices_index_headline(),
      Copy.subscriptions_index_empty_copy(),
      Copy.charges_index_empty_copy(),
      Coupon.coupon_index_headline(),
      PromotionCode.promotion_codes_index_headline(),
      Connect.connect_accounts_headline(),
      BillingEvent.billing_events_heading_organization(),
      Locked.owner_access_denied(),
      Copy.webhooks_index_empty_copy()
    ]

    joined = strings |> Enum.join(" ") |> String.downcase()

    for required <- [
          "invoice",
          "subscription",
          "charge",
          "coupon",
          "promotion code",
          "connect",
          "event",
          "webhook",
          "organization"
        ] do
      assert joined =~ required
    end

    refute_vague_copy!(strings)
  end

  test "Phase 197 list copy helpers expose JTBD headings and state-specific copy" do
    pages = [
      %{
        heading: Copy.customers_list_heading(),
        subtitle: Copy.customers_list_subtitle(),
        expected_heading: "Find a customer",
        expected_subtitle: "Look up a customer and inspect their billing state.",
        states: [
          Copy.customers_list_first_run_empty_title(),
          Copy.customers_list_filtered_empty_title(),
          Copy.customers_list_loading_label()
        ],
        labels: [
          Copy.customers_list_default_lens_label(),
          Copy.customers_list_all_lens_label(),
          Copy.customers_list_missing_payment_method_label()
        ],
        result_label: Copy.customers_list_result_label_pair()
      },
      %{
        heading: Copy.invoices_list_heading(),
        subtitle: Copy.invoices_list_subtitle(),
        expected_heading: "Clear open receivables",
        expected_subtitle: "Work invoices that need collection.",
        states: [
          Copy.invoices_list_first_run_empty_title(),
          Copy.invoices_list_queue_empty_title(),
          Copy.invoices_list_filtered_empty_title(),
          Copy.invoices_list_loading_label()
        ],
        labels: [
          Copy.invoices_list_default_lens_label(),
          Copy.invoices_list_all_lens_label()
        ],
        result_label: Copy.invoices_list_result_label_pair()
      },
      %{
        heading: Copy.payments_list_heading(),
        subtitle: Copy.payments_list_subtitle(),
        expected_heading: "Recover failed payments",
        expected_subtitle: "Inspect charges that need follow-up.",
        states: [
          Copy.payments_list_first_run_empty_title(),
          Copy.payments_list_queue_empty_title(),
          Copy.payments_list_filtered_empty_title(),
          Copy.payments_list_loading_label()
        ],
        labels: [
          Copy.payments_list_default_lens_label(),
          Copy.payments_list_all_lens_label()
        ],
        result_label: Copy.payments_list_result_label_pair()
      },
      %{
        heading: Copy.coupons_list_heading(),
        subtitle: Copy.coupons_list_subtitle(),
        expected_heading: "Review usable discounts",
        expected_subtitle: "Check which coupon definitions can still be applied.",
        states: [
          Copy.coupons_list_first_run_empty_title(),
          Copy.coupons_list_queue_empty_title(),
          Copy.coupons_list_filtered_empty_title(),
          Copy.coupons_list_loading_label()
        ],
        labels: [
          Copy.coupons_list_default_lens_label(),
          Copy.coupons_list_all_lens_label()
        ],
        result_label: Copy.coupons_list_result_label_pair()
      },
      %{
        heading: Copy.promotion_codes_list_heading(),
        subtitle: Copy.promotion_codes_list_subtitle(),
        expected_heading: "Find active codes",
        expected_subtitle: "Review customer-facing codes tied to coupons.",
        states: [
          Copy.promotion_codes_list_first_run_empty_title(),
          Copy.promotion_codes_list_queue_empty_title(),
          Copy.promotion_codes_list_filtered_empty_title(),
          Copy.promotion_codes_list_loading_label()
        ],
        labels: [
          Copy.promotion_codes_list_default_lens_label(),
          Copy.promotion_codes_list_all_lens_label()
        ],
        result_label: Copy.promotion_codes_list_result_label_pair()
      },
      %{
        heading: Copy.webhooks_list_heading(),
        subtitle: Copy.webhooks_list_subtitle(),
        expected_heading: "Replay failed deliveries",
        expected_subtitle: "Inspect webhook deliveries that need operator action.",
        states: [
          Copy.webhooks_list_first_run_empty_title(),
          Copy.webhooks_list_queue_empty_title(),
          Copy.webhooks_list_filtered_empty_title(),
          Copy.webhooks_list_loading_label()
        ],
        labels: [
          Copy.webhooks_list_default_lens_label(),
          Copy.webhooks_list_all_lens_label()
        ],
        result_label: Copy.webhooks_list_result_label_pair()
      },
      %{
        heading: Copy.events_list_heading(),
        subtitle: Copy.events_list_subtitle(),
        expected_heading: "Trace billing activity",
        expected_subtitle: "Read the append-only billing event ledger.",
        states: [
          Copy.events_list_first_run_empty_title(),
          Copy.events_list_filtered_empty_title(),
          Copy.events_list_loading_label()
        ],
        labels: [
          Copy.events_list_default_lens_label(),
          Copy.events_list_all_lens_label(),
          Copy.events_list_admin_changes_label()
        ],
        result_label: Copy.events_list_result_label_pair()
      },
      %{
        heading: Copy.connect_accounts_list_heading(),
        subtitle: Copy.connect_accounts_list_subtitle(),
        expected_heading: "Finish account readiness",
        expected_subtitle: "Find connected accounts that need onboarding or capability work.",
        states: [
          Copy.connect_accounts_list_first_run_empty_title(),
          Copy.connect_accounts_list_queue_empty_title(),
          Copy.connect_accounts_list_filtered_empty_title(),
          Copy.connect_accounts_list_loading_label()
        ],
        labels: [
          Copy.connect_accounts_list_default_lens_label(),
          Copy.connect_accounts_list_all_lens_label()
        ],
        result_label: Copy.connect_accounts_list_result_label_pair()
      }
    ]

    for page <- pages do
      assert page.heading == page.expected_heading
      assert page.subtitle == page.expected_subtitle
      assert Enum.uniq(page.states) == page.states
      assert Enum.all?(page.states, &(&1 != ""))
      assert Enum.all?(page.labels, &(&1 != ""))
      assert {singular, plural} = page.result_label
      assert singular != plural

      refute_vague_copy!([page.heading, page.subtitle | page.states ++ page.labels])
    end
  end

  test "not-found copy names recovery instead of ending at a bare missing state" do
    samples = [
      Invoice.invoice_not_found(),
      Copy.charge_not_found(),
      Coupon.coupon_not_found(),
      PromotionCode.promotion_code_not_found(),
      Connect.connect_account_not_found(),
      BillingEvent.billing_event_not_found()
    ]

    for sample <- samples do
      refute sample =~ @vague_standalone
      assert sample =~ "Open"
      assert sample =~ "owner scope"
    end
  end

  test "CPY-01 command-palette no-results copy names the billing search domain" do
    copy = Copy.global_search_no_results_copy("missing-acme")

    assert copy ==
             ~s(No billing records match "missing-acme". Adjust the search or open the customers list.)

    refute copy =~ ~r/\bno results\b/i
    refute_vague_copy!(copy)
  end

  test "CPY-01 repeated action hidden-context helpers name object and next action" do
    contexts = [
      Copy.action_hidden_context("Change",
        resource: "collection method",
        object: "invoice in_phase199"
      ),
      Copy.action_hidden_context("View",
        resource: "recovery activity",
        object: "subscription sub_phase199"
      ),
      Copy.action_hidden_context("Replay",
        resource: "webhook delivery",
        object: "evt_phase199_dead"
      )
    ]

    assert contexts == [
             "Change collection method for invoice in_phase199",
             "View recovery activity for subscription sub_phase199",
             "Replay webhook delivery for evt_phase199_dead"
           ]

    refute_vague_copy!(contexts)
  end

  test "CPY-01 resource state helpers cover required page states for page call sites" do
    resources = %{
      customers: "customer",
      invoices: "invoice",
      subscriptions: "subscription",
      payments: "payment",
      connect_accounts: "connected account",
      webhooks: "webhook",
      events: "event",
      coupons: "coupon",
      promotion_codes: "promotion code",
      dunning: "dunning"
    }

    required_states = [
      :first_run_empty,
      :queue_empty,
      :filtered_empty,
      :loading,
      :error,
      :permission_denied
    ]

    for {resource, label} <- resources do
      copies =
        Map.new(required_states, fn state ->
          copy =
            Copy.resource_state_copy(resource, state,
              object: "#{label} phase199",
              owner_scope: "organization org_phase199"
            )

          assert %{heading: heading, body: body} = copy
          assert heading != ""
          assert body != ""
          assert heading != body

          text = String.downcase("#{heading} #{body}")
          assert text =~ label

          {state, copy}
        end)

      headings = copies |> Map.values() |> Enum.map(& &1.heading)
      bodies = copies |> Map.values() |> Enum.map(& &1.body)

      assert Enum.uniq(headings) == headings
      assert Enum.uniq(bodies) == bodies
      assert copies.filtered_empty.body =~ "Clear filters"
      assert copies.permission_denied.body =~ "organization org_phase199"

      refute_vague_copy!(Map.values(copies))
    end
  end

  test "CPY-01 list and recovery page call sites use the shared resource-state helpers" do
    call_sites = %{
      "lib/accrue_admin/live/customers_live.ex" => :customers,
      "lib/accrue_admin/live/invoices_live.ex" => :invoices,
      "lib/accrue_admin/live/charges_live.ex" => :payments,
      "lib/accrue_admin/live/webhooks_live.ex" => :webhooks,
      "lib/accrue_admin/live/connect_accounts_live.ex" => :connect_accounts,
      "lib/accrue_admin/live/subscriptions_live.ex" => :subscriptions,
      "lib/accrue_admin/live/coupons_live.ex" => :coupons,
      "lib/accrue_admin/live/promotion_codes_live.ex" => :promotion_codes,
      "lib/accrue_admin/live/events_live.ex" => :events,
      "lib/accrue_admin/live/analytics/recovery_live.ex" => :dunning
    }

    for {path, resource} <- call_sites do
      source = File.read!(Path.expand("../../#{path}", __DIR__))

      assert source =~ "Copy.resource_state_copy(:#{resource}",
             "#{path} must route list-state copy through Copy.resource_state_copy/3"
    end
  end

  test "CPY-01 copy modules avoid generic fallbacks and bare action terms" do
    assert copy_module_guard(@raw_generic_guard) == []
  end

  test "CPY-01 copy modules stay within measured admin voice" do
    assert copy_module_guard(@voice_guard) == []
  end

  defp refute_vague_copy!(%{} = copy_map) do
    copy_map
    |> Map.values()
    |> Enum.each(&refute_vague_copy!/1)
  end

  defp refute_vague_copy!(%{heading: heading, body: body}) do
    refute heading =~ @vague_standalone
    refute body =~ @vague_standalone
  end

  defp refute_vague_copy!(strings) when is_list(strings) do
    Enum.each(strings, &refute_vague_copy!/1)
  end

  defp refute_vague_copy!(string) when is_binary(string) do
    refute string =~ @vague_standalone
  end

  defp copy_module_guard(pattern) do
    [Path.expand("../../lib/accrue_admin/copy.ex", __DIR__)]
    |> Kernel.++(Path.wildcard(Path.expand("../../lib/accrue_admin/copy/*.ex", __DIR__)))
    |> Enum.flat_map(fn file ->
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_number} ->
        if line =~ pattern do
          ["#{Path.relative_to_cwd(file)}:#{line_number}:#{String.trim(line)}"]
        else
          []
        end
      end)
    end)
  end
end
