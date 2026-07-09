defmodule AccrueAdmin.Copy do
  @moduledoc """
  Tier A host-contract copy for admin surfaces (Phase 27).

  Strings here are the single source of truth for operator-facing empty states
  and related chrome described in `.planning/phases/27-microcopy-and-operator-strings/27-CONTEXT.md`.
  """

  alias AccrueAdmin.Copy.BillingEvent
  alias AccrueAdmin.Copy.Connect
  alias AccrueAdmin.Copy.Coupon
  alias AccrueAdmin.Copy.CustomerPaymentMethods
  alias AccrueAdmin.Copy.Dunning
  alias AccrueAdmin.Copy.Entitlements
  alias AccrueAdmin.Copy.Invoice
  alias AccrueAdmin.Copy.Locked
  alias AccrueAdmin.Copy.PromotionCode
  alias AccrueAdmin.Copy.Subscription

  @spec global_search_no_results_copy(String.t()) :: String.t()
  def global_search_no_results_copy(query) do
    normalized_query = normalize_search_query(query)

    ~s(No billing records match "#{normalized_query}". Adjust the search or open the customers list.)
  end

  def global_search_no_results_html(query) do
    escaped_query =
      query
      |> normalize_search_query()
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(No billing records match "#{escaped_query}". Adjust the search or open the customers list.)
    )
  end

  defp normalize_search_query(query), do: query |> to_string() |> String.trim()

  @phase199_resource_states %{
    customers: %{
      singular: "customer",
      plural: "customers",
      first_run: "checkout or imported billing activity creates customer records",
      first_run_heading: "No customers yet.",
      first_run_body: "Customers appear after checkout or imported billing activity.",
      queue: "No customers need billing follow-up.",
      queue_next: "Open the customers list to inspect the full customer ledger.",
      filtered_heading: "No customers match these filters.",
      filtered_body: "Clear filters or adjust the search to inspect matching customers.",
      loading_heading: "Loading customers.",
      loading_body: "Loading customers from the local billing projection."
    },
    invoices: %{
      singular: "invoice",
      plural: "invoices",
      first_run: "subscriptions activate or renew",
      first_run_heading: "No invoices yet.",
      first_run_body: "Invoices appear when subscriptions activate or renew.",
      queue: "No invoices need collection.",
      queue_next: "View all invoices to review the ledger.",
      filtered_heading: "No invoices match these filters.",
      filtered_body: "Clear filters or adjust the search to see invoices.",
      loading_heading: "Loading invoices.",
      loading_body: "Loading invoices from the local billing projection."
    },
    subscriptions: %{
      singular: "subscription",
      plural: "subscriptions",
      first_run: "a customer completes checkout",
      first_run_heading: "No subscriptions yet.",
      first_run_body: "Subscriptions appear after a customer completes checkout.",
      queue: "Nothing at risk.",
      queue_next: "No past-due or canceling subscriptions. View All to see every subscription.",
      filtered_heading: "No subscriptions match these filters.",
      filtered_body: "Clear filters or adjust the search to see subscriptions.",
      loading_heading: "Loading subscriptions.",
      loading_body: "Loading subscriptions from the local billing projection."
    },
    payments: %{
      singular: "payment",
      plural: "payments",
      first_run: "charges are recorded",
      first_run_heading: "No payments yet.",
      first_run_body: "Payments appear after charges are recorded.",
      queue: "No failed payments.",
      queue_next: "View all payments to inspect settled and pending charges.",
      filtered_heading: "No payments match these filters.",
      filtered_body: "Clear filters or adjust the search to see payments.",
      loading_heading: "Loading payments.",
      loading_body: "Loading payments from the local billing projection."
    },
    connect_accounts: %{
      singular: "connected account",
      plural: "connected accounts",
      first_run: "Connect onboarding starts",
      first_run_heading: "No connected accounts yet.",
      first_run_body: "Accounts appear after onboarding starts.",
      queue: "No connected accounts need attention.",
      queue_next: "View all connected accounts to inspect onboarded accounts.",
      filtered_heading: "No connected accounts match these filters.",
      filtered_body: "Clear filters or adjust readiness filters to see connected accounts.",
      loading_heading: "Loading connected accounts.",
      loading_body: "Loading connected accounts from the local billing projection."
    },
    webhooks: %{
      singular: "webhook delivery",
      plural: "webhook deliveries",
      first_run: "signed processor events are recorded",
      first_run_heading: "No webhook deliveries yet.",
      first_run_body: "Deliveries appear after signed processor events are recorded.",
      queue: "No webhook deliveries need replay.",
      queue_next: "View all webhook deliveries to inspect the full delivery log.",
      filtered_heading: "No webhook deliveries match these filters.",
      filtered_body: "Clear filters or adjust status and type filters to see deliveries.",
      loading_heading: "Loading webhook deliveries.",
      loading_body: "Loading webhook deliveries from the local billing projection."
    },
    events: %{
      singular: "event",
      plural: "billing events",
      first_run: "billing state changes are recorded",
      first_run_heading: "No billing events yet.",
      first_run_body: "Events appear when billing state changes are recorded.",
      queue: "No billing events need admin review.",
      queue_next: "Open all billing events to inspect the append-only ledger.",
      filtered_heading: "No event ledger rows match these filters.",
      filtered_body: "Clear filters or adjust actor and source filters to see ledger rows.",
      loading_heading: "Loading billing events.",
      loading_body: "Loading billing events from the local billing projection."
    },
    coupons: %{
      singular: "coupon",
      plural: "coupons",
      first_run: "coupon definitions are projected locally",
      first_run_heading: "No coupons yet.",
      first_run_body: "Coupons appear after discount definitions sync locally.",
      queue: "No valid coupons.",
      queue_next: "View all coupons to inspect invalid or expired definitions.",
      filtered_heading: "No coupons match these filters.",
      filtered_body: "Clear filters or adjust the search to see coupons.",
      loading_heading: "Loading coupons.",
      loading_body: "Loading coupons from the local billing projection."
    },
    promotion_codes: %{
      singular: "promotion code",
      plural: "promotion codes",
      first_run: "promotion code projections arrive from billing activity",
      first_run_heading: "No promotion codes yet.",
      first_run_body: "Codes appear after customer-facing discounts sync locally.",
      queue: "No active codes.",
      queue_next: "View all promotion codes to inspect inactive or expired codes.",
      filtered_heading: "No promotion codes match these filters.",
      filtered_body: "Clear filters or adjust the search to see promotion codes.",
      loading_heading: "Loading promotion codes.",
      loading_body: "Loading promotion codes from the local billing projection."
    },
    dunning: %{
      singular: "dunning campaign",
      plural: "dunning campaigns",
      first_run: "a subscription enters the configured past-due campaign",
      first_run_heading: "No dunning campaigns yet.",
      first_run_body:
        "Dunning campaigns appear after a subscription enters the configured past-due campaign.",
      queue: "No active dunning campaigns",
      queue_next: "All subscriptions in this window have recovered or exhausted their campaign.",
      filtered_heading: "No dunning campaigns match these filters.",
      filtered_body:
        "Clear filters or adjust the recovery window to inspect matching dunning campaigns.",
      loading_heading: "Loading at-risk subscriptions",
      loading_body: "Checking active dunning campaigns for this recovery window."
    }
  }

  @phase199_required_states [
    :first_run_empty,
    :queue_empty,
    :filtered_empty,
    :loading,
    :error,
    :permission_denied
  ]

  @spec resource_state_copy(atom(), atom(), keyword()) :: %{heading: String.t(), body: String.t()}
  def resource_state_copy(resource, state, opts \\ [])

  def resource_state_copy(resource, state, opts) when state in @phase199_required_states do
    resource
    |> resource_state_meta()
    |> build_resource_state_copy(state, opts)
  end

  @spec action_hidden_context(String.t(), keyword()) :: String.t()
  def action_hidden_context(action_label, opts) do
    resource = option(opts, :resource, "billing record")
    object = option(opts, :object, "this record")

    "#{String.trim(to_string(action_label))} #{resource} for #{object}"
  end

  @spec action_hidden_object_context(keyword()) :: String.t()
  def action_hidden_object_context(opts) do
    resource = option(opts, :resource, "billing action")
    object = option(opts, :object, "this record")

    " for #{resource} on #{object}"
  end

  defdelegate subscription_breadcrumb_subscriptions(), to: Subscription
  defdelegate subscription_detail_eyebrow(), to: Subscription
  defdelegate subscription_kpi_section_aria_label(), to: Subscription
  defdelegate subscription_proration_create(), to: Subscription
  defdelegate subscription_proration_none(), to: Subscription
  defdelegate subscription_proration_always_invoice(), to: Subscription
  defdelegate subscription_kpi_status_label(), to: Subscription
  defdelegate subscription_kpi_canonical_predicates_label(), to: Subscription
  defdelegate subscription_kpi_timeline_rows_label(), to: Subscription
  defdelegate subscription_action_cancel_now(), to: Subscription
  defdelegate subscription_action_cancel_at_period_end(), to: Subscription
  defdelegate subscription_action_resume(), to: Subscription
  defdelegate subscription_action_swap_plan(), to: Subscription
  defdelegate subscription_action_update_quantity(), to: Subscription
  defdelegate subscription_action_add_item(), to: Subscription
  defdelegate subscription_action_update_item_quantity(), to: Subscription
  defdelegate subscription_action_remove_item(), to: Subscription
  defdelegate subscription_action_pause_collection(), to: Subscription
  defdelegate subscription_action_create_comp_replacement(), to: Subscription
  defdelegate subscription_action_default_guidance(), to: Subscription
  defdelegate subscription_action_exception_guidance(), to: Subscription
  defdelegate subscription_action_braintree_guidance(), to: Subscription
  defdelegate subscription_action_braintree_swap_setup_guidance(), to: Subscription
  defdelegate subscription_action_braintree_quantity_item_guidance(), to: Subscription
  defdelegate subscription_action_stripe_guidance(), to: Subscription
  defdelegate subscription_action_supported_change_guidance(), to: Subscription
  defdelegate subscription_action_preview_heading(), to: Subscription
  defdelegate subscription_action_preview_total_label(), to: Subscription
  defdelegate subscription_action_item_id_label(), to: Subscription
  defdelegate subscription_action_quantity_label(), to: Subscription
  defdelegate subscription_action_single_item_quantity_guidance(), to: Subscription
  defdelegate subscription_confirm_workflow_message(action_type, opts), to: Subscription
  defdelegate subscription_lifecycle_ended_label(), to: Subscription
  defdelegate subscription_page_title(), to: Subscription
  defdelegate subscriptions_list_first_run_empty_title(), to: Subscription
  defdelegate subscriptions_list_first_run_empty_body(), to: Subscription
  defdelegate subscriptions_list_queue_empty_title(), to: Subscription
  defdelegate subscriptions_list_queue_empty_body(), to: Subscription
  defdelegate subscriptions_list_filtered_empty_title(), to: Subscription
  defdelegate subscriptions_list_filtered_empty_body(), to: Subscription
  defdelegate subscriptions_list_loading_label(), to: Subscription
  defdelegate subscriptions_list_plan_amount_unavailable(), to: Subscription

  defdelegate dunning_panel_eyebrow(), to: Dunning
  defdelegate dunning_panel_title(), to: Dunning
  defdelegate dunning_started_label(), to: Dunning
  defdelegate dunning_current_step_label(), to: Dunning
  defdelegate dunning_next_action_label(), to: Dunning
  defdelegate dunning_empty_state_heading(), to: Dunning
  defdelegate dunning_empty_state_body(), to: Dunning
  defdelegate dunning_next_action_done(), to: Dunning
  defdelegate dunning_next_action_unavailable(), to: Dunning
  defdelegate dunning_state_label(subscription), to: Dunning
  defdelegate dunning_state_active(), to: Dunning
  defdelegate dunning_state_none(), to: Dunning
  defdelegate dunning_state_recovered(), to: Dunning

  defdelegate invoices_index_empty_title(), to: Invoice
  defdelegate invoices_index_empty_copy(), to: Invoice
  defdelegate invoice_select_action_warning(), to: Invoice
  defdelegate invoice_pdf_open_info(), to: Invoice
  defdelegate invoice_action_recorded_info(), to: Invoice
  defdelegate invoices_page_title_index(), to: Invoice
  defdelegate invoices_index_breadcrumb_invoices(), to: Invoice
  defdelegate invoices_index_eyebrow(), to: Invoice
  defdelegate invoices_index_headline(), to: Invoice
  defdelegate invoices_index_body(), to: Invoice
  defdelegate invoices_list_heading(), to: Invoice
  defdelegate invoices_list_subtitle(), to: Invoice
  defdelegate invoices_list_first_run_empty_title(), to: Invoice
  defdelegate invoices_list_first_run_empty_body(), to: Invoice
  defdelegate invoices_list_queue_empty_title(), to: Invoice
  defdelegate invoices_list_queue_empty_body(), to: Invoice
  defdelegate invoices_list_filtered_empty_title(), to: Invoice
  defdelegate invoices_list_filtered_empty_body(), to: Invoice
  defdelegate invoices_list_loading_label(), to: Invoice
  defdelegate invoices_list_default_lens_label(), to: Invoice
  defdelegate invoices_list_all_lens_label(), to: Invoice
  defdelegate invoices_list_result_label_pair(), to: Invoice
  defdelegate invoices_kpi_section_aria_label(), to: Invoice
  defdelegate invoices_kpi_open_label(), to: Invoice
  defdelegate invoices_kpi_open_meta(), to: Invoice
  defdelegate invoices_kpi_paid_label(), to: Invoice
  defdelegate invoices_kpi_paid_meta(), to: Invoice
  defdelegate invoices_kpi_uncollectible_label(), to: Invoice
  defdelegate invoices_kpi_uncollectible_void_delta_suffix(), to: Invoice
  defdelegate invoices_kpi_uncollectible_meta(), to: Invoice
  defdelegate invoices_column_invoice(), to: Invoice
  defdelegate invoices_column_customer(), to: Invoice
  defdelegate invoices_column_billing_signals(), to: Invoice
  defdelegate invoices_column_status(), to: Invoice
  defdelegate invoices_column_balance(), to: Invoice
  defdelegate invoices_column_collection(), to: Invoice
  defdelegate invoices_card_customer(), to: Invoice
  defdelegate invoices_filter_search(), to: Invoice
  defdelegate invoices_filter_status(), to: Invoice
  defdelegate invoices_filter_customer_id(), to: Invoice
  defdelegate invoices_filter_collection(), to: Invoice
  defdelegate invoices_filter_status_draft(), to: Invoice
  defdelegate invoices_filter_status_open(), to: Invoice
  defdelegate invoices_filter_status_paid(), to: Invoice
  defdelegate invoices_filter_status_uncollectible(), to: Invoice
  defdelegate invoices_filter_status_void(), to: Invoice
  defdelegate invoices_filter_collection_automatic(), to: Invoice
  defdelegate invoices_filter_collection_send_invoice(), to: Invoice
  defdelegate invoices_balance_word_due(), to: Invoice
  defdelegate invoices_balance_word_paid(), to: Invoice
  defdelegate invoices_balance_word_remaining(), to: Invoice
  defdelegate invoices_balance_sep(), to: Invoice
  defdelegate invoices_balance_summary(due, paid, remaining), to: Invoice
  defdelegate invoice_page_title_detail(), to: Invoice
  defdelegate invoice_breadcrumb_invoices(), to: Invoice
  defdelegate invoice_detail_eyebrow(), to: Invoice
  defdelegate invoice_detail_due_prefix(), to: Invoice
  defdelegate invoice_detail_kpi_section_aria_label(), to: Invoice
  defdelegate invoice_kpi_status_label(), to: Invoice
  defdelegate invoice_kpi_amount_due_label(), to: Invoice
  defdelegate invoice_kpi_amount_due_delta_suffix(), to: Invoice
  defdelegate invoice_kpi_amount_remaining_meta_suffix(), to: Invoice
  defdelegate invoice_kpi_line_items_label(), to: Invoice
  defdelegate invoice_kpi_line_items_meta(), to: Invoice
  defdelegate invoice_tax_risk_eyebrow(), to: Invoice
  defdelegate invoice_tax_risk_heading(), to: Invoice
  defdelegate invoice_tax_disabled_reason_label(), to: Invoice
  defdelegate invoice_tax_finalization_failure_label(), to: Invoice
  defdelegate invoice_tax_recovery_body(), to: Invoice
  defdelegate invoice_actions_eyebrow(), to: Invoice
  defdelegate invoice_actions_heading(), to: Invoice
  defdelegate invoice_actions_body(), to: Invoice
  defdelegate invoice_action_finalize(), to: Invoice
  defdelegate invoice_action_add_line_item(), to: Invoice
  defdelegate invoice_action_manual_pay(), to: Invoice
  defdelegate invoice_action_void(), to: Invoice
  defdelegate invoice_action_mark_uncollectible(), to: Invoice
  defdelegate invoice_action_documents(), to: Invoice
  defdelegate invoice_drill_collection_actions(), to: Invoice
  defdelegate invoice_drill_tax_documents(), to: Invoice
  defdelegate invoice_drawer_subtitle(), to: Invoice
  defdelegate invoice_documents_drawer_title(), to: Invoice
  defdelegate invoice_lazy_activity_prompt(), to: Invoice
  defdelegate invoice_lazy_json_prompt(), to: Invoice
  defdelegate invoice_json_payload_label(), to: Invoice
  defdelegate invoice_confirm_panel_label(), to: Invoice
  defdelegate invoice_confirm_action_verb(), to: Invoice
  defdelegate invoice_confirm_cancel(), to: Invoice
  defdelegate invoice_confirm_workflow_message(action_label, source_suffix), to: Invoice
  defdelegate invoice_confirm_source_event_suffix(source_event_id), to: Invoice
  defdelegate invoice_pdf_section_eyebrow(), to: Invoice
  defdelegate invoice_pdf_heading(), to: Invoice
  defdelegate invoice_pdf_body(), to: Invoice
  defdelegate invoice_open_pdf_button(), to: Invoice
  defdelegate invoice_processor_pdf_link(), to: Invoice
  defdelegate invoice_hosted_invoice_link(), to: Invoice
  defdelegate invoice_open_rendered_pdf_link(), to: Invoice
  defdelegate invoice_download_rendered_pdf_link(), to: Invoice
  defdelegate invoice_line_items_eyebrow(), to: Invoice
  defdelegate invoice_line_items_heading(), to: Invoice
  defdelegate invoice_line_item_qty_prefix(), to: Invoice
  defdelegate invoice_line_item_proration_suffix(), to: Invoice
  defdelegate invoice_line_item_period_separator(), to: Invoice
  defdelegate invoice_line_items_empty(), to: Invoice
  defdelegate invoice_timeline_eyebrow(), to: Invoice
  defdelegate invoice_timeline_heading(), to: Invoice
  defdelegate invoice_timeline_label(), to: Invoice
  defdelegate invoice_timeline_empty(), to: Invoice
  defdelegate invoice_source_event_label(), to: Invoice
  defdelegate invoice_source_event_none(), to: Invoice
  defdelegate invoice_pdf_render_failed_prefix(), to: Invoice
  defdelegate invoice_pdf_summary_processor_ready(), to: Invoice
  defdelegate invoice_pdf_summary_hosted_ready(), to: Invoice
  defdelegate invoice_pdf_summary_render_on_demand(), to: Invoice
  defdelegate invoice_add_manual_item_cta(), to: Invoice
  defdelegate invoice_empty_manual_items_heading(), to: Invoice
  defdelegate invoice_empty_manual_items_body(), to: Invoice
  defdelegate invoice_add_manual_item_error(), to: Invoice
  defdelegate invoice_remove_manual_item_confirm(), to: Invoice
  defdelegate invoice_add_manual_item_success(), to: Invoice
  defdelegate invoice_remove_manual_item_success(), to: Invoice
  defdelegate invoice_draft_locked_guidance(), to: Invoice
  defdelegate invoice_manual_row_badge(), to: Invoice
  defdelegate invoice_not_found(), to: Invoice

  defdelegate coupon_breadcrumb_coupons(), to: Coupon
  defdelegate coupon_index_eyebrow(), to: Coupon
  defdelegate coupon_index_headline(), to: Coupon
  defdelegate coupon_index_body_primary(), to: Coupon
  defdelegate coupons_list_heading(), to: Coupon
  defdelegate coupons_list_subtitle(), to: Coupon
  defdelegate coupons_list_first_run_empty_title(), to: Coupon
  defdelegate coupons_list_first_run_empty_body(), to: Coupon
  defdelegate coupons_list_queue_empty_title(), to: Coupon
  defdelegate coupons_list_queue_empty_body(), to: Coupon
  defdelegate coupons_list_filtered_empty_title(), to: Coupon
  defdelegate coupons_list_filtered_empty_body(), to: Coupon
  defdelegate coupons_list_loading_label(), to: Coupon
  defdelegate coupons_list_default_lens_label(), to: Coupon
  defdelegate coupons_list_all_lens_label(), to: Coupon
  defdelegate coupons_list_result_label_pair(), to: Coupon
  defdelegate coupon_index_body_link_prefix(), to: Coupon
  defdelegate coupon_index_promotion_codes_link_text(), to: Coupon
  defdelegate coupon_index_kpi_section_aria_label(), to: Coupon
  defdelegate coupon_kpi_label_coupons(), to: Coupon
  defdelegate coupon_kpi_meta_all_local_coupons(), to: Coupon
  defdelegate coupon_kpi_label_valid(), to: Coupon
  defdelegate coupon_kpi_invalid_suffix(), to: Coupon
  defdelegate coupon_kpi_meta_validity_projection(), to: Coupon
  defdelegate coupon_kpi_label_promotion_codes(), to: Coupon
  defdelegate coupon_kpi_meta_promotion_codes_child(), to: Coupon
  defdelegate coupon_kpi_redemptions_suffix(), to: Coupon
  defdelegate coupon_table_column_coupon(), to: Coupon
  defdelegate coupon_table_column_discount(), to: Coupon
  defdelegate coupon_table_column_redemptions(), to: Coupon
  defdelegate coupon_table_column_status(), to: Coupon
  defdelegate coupon_table_column_redeem_by(), to: Coupon
  defdelegate coupon_filter_label_search(), to: Coupon
  defdelegate coupon_filter_label_validity(), to: Coupon
  defdelegate coupon_filter_option_valid(), to: Coupon
  defdelegate coupon_filter_option_invalid(), to: Coupon
  defdelegate coupon_table_empty_title(), to: Coupon
  defdelegate coupon_table_empty_copy(), to: Coupon
  defdelegate coupon_page_title_index(), to: Coupon
  defdelegate coupon_detail_eyebrow(), to: Coupon
  defdelegate coupon_detail_kpi_section_aria_label(), to: Coupon
  defdelegate coupon_kpi_label_redemptions(), to: Coupon
  defdelegate coupon_detail_section_promotion_codes_eyebrow(), to: Coupon
  defdelegate coupon_detail_section_codes_heading(), to: Coupon
  defdelegate coupon_detail_promotion_codes_empty(), to: Coupon
  defdelegate coupon_detail_section_projection_eyebrow(), to: Coupon
  defdelegate coupon_detail_section_projection_heading(), to: Coupon
  defdelegate coupon_detail_label_duration(), to: Coupon
  defdelegate coupon_detail_label_currency(), to: Coupon
  defdelegate coupon_detail_label_processor(), to: Coupon
  defdelegate coupon_json_payload_label(), to: Coupon
  defdelegate coupon_lazy_activity_heading(), to: Coupon
  defdelegate coupon_lazy_activity_label(), to: Coupon
  defdelegate coupon_lazy_activity_prompt(), to: Coupon
  defdelegate coupon_lazy_activity_empty_label(), to: Coupon
  defdelegate coupon_lazy_activity_empty_body(), to: Coupon
  defdelegate coupon_lazy_raw_data_heading(), to: Coupon
  defdelegate coupon_lazy_raw_data_prompt(), to: Coupon
  defdelegate coupon_kpi_meta_redemptions_cap(), to: Coupon
  defdelegate coupon_kpi_meta_promotion_codes_linked(), to: Coupon
  defdelegate coupon_kpi_label_redeem_by(), to: Coupon
  defdelegate coupon_kpi_meta_redeem_by(), to: Coupon
  defdelegate coupon_page_title_show(), to: Coupon
  defdelegate coupon_status_valid(), to: Coupon
  defdelegate coupon_status_invalid(), to: Coupon
  defdelegate coupon_redeem_by_no_expiry(), to: Coupon
  defdelegate coupon_discount_processor_defined(), to: Coupon
  defdelegate coupon_promotion_code_status_active(), to: Coupon
  defdelegate coupon_promotion_code_status_inactive(), to: Coupon
  defdelegate coupon_promotion_code_status_active_until_prefix(), to: Coupon
  defdelegate coupon_not_found(), to: Coupon

  defdelegate promotion_codes_breadcrumb_index(), to: PromotionCode
  defdelegate promotion_codes_index_eyebrow(), to: PromotionCode
  defdelegate promotion_codes_index_headline(), to: PromotionCode
  defdelegate promotion_codes_index_body_primary(), to: PromotionCode
  defdelegate promotion_codes_list_heading(), to: PromotionCode
  defdelegate promotion_codes_list_subtitle(), to: PromotionCode
  defdelegate promotion_codes_list_first_run_empty_title(), to: PromotionCode
  defdelegate promotion_codes_list_first_run_empty_body(), to: PromotionCode
  defdelegate promotion_codes_list_queue_empty_title(), to: PromotionCode
  defdelegate promotion_codes_list_queue_empty_body(), to: PromotionCode
  defdelegate promotion_codes_list_filtered_empty_title(), to: PromotionCode
  defdelegate promotion_codes_list_filtered_empty_body(), to: PromotionCode
  defdelegate promotion_codes_list_loading_label(), to: PromotionCode
  defdelegate promotion_codes_list_default_lens_label(), to: PromotionCode
  defdelegate promotion_codes_list_all_lens_label(), to: PromotionCode
  defdelegate promotion_codes_list_result_label_pair(), to: PromotionCode
  defdelegate promotion_codes_index_kpi_section_aria_label(), to: PromotionCode
  defdelegate promotion_codes_kpi_label_codes(), to: PromotionCode
  defdelegate promotion_codes_kpi_meta_all_local_rows(), to: PromotionCode
  defdelegate promotion_codes_kpi_label_active(), to: PromotionCode
  defdelegate promotion_codes_kpi_inactive_suffix(), to: PromotionCode
  defdelegate promotion_codes_kpi_meta_activation_state(), to: PromotionCode
  defdelegate promotion_codes_kpi_label_expiring(), to: PromotionCode
  defdelegate promotion_codes_kpi_redemptions_suffix(), to: PromotionCode
  defdelegate promotion_codes_kpi_meta_expiring(), to: PromotionCode
  defdelegate promotion_codes_table_column_code(), to: PromotionCode
  defdelegate promotion_codes_table_column_coupon(), to: PromotionCode
  defdelegate promotion_codes_table_column_status(), to: PromotionCode
  defdelegate promotion_codes_table_column_redemptions(), to: PromotionCode
  defdelegate promotion_codes_table_column_expires(), to: PromotionCode
  defdelegate promotion_codes_filter_label_search(), to: PromotionCode
  defdelegate promotion_codes_filter_label_status(), to: PromotionCode
  defdelegate promotion_codes_filter_option_active(), to: PromotionCode
  defdelegate promotion_codes_filter_option_inactive(), to: PromotionCode
  defdelegate promotion_codes_filter_label_coupon_id(), to: PromotionCode
  defdelegate promotion_codes_table_empty_title(), to: PromotionCode
  defdelegate promotion_codes_table_empty_copy(), to: PromotionCode
  defdelegate promotion_codes_page_title_index(), to: PromotionCode
  defdelegate promotion_code_detail_eyebrow(), to: PromotionCode
  defdelegate promotion_code_detail_kpi_section_aria_label(), to: PromotionCode
  defdelegate promotion_code_kpi_label_coupon(), to: PromotionCode
  defdelegate promotion_code_kpi_meta_parent_discount(), to: PromotionCode
  defdelegate promotion_code_kpi_label_redemptions(), to: PromotionCode
  defdelegate promotion_code_kpi_label_expires(), to: PromotionCode
  defdelegate promotion_code_kpi_meta_expiry_boundary(), to: PromotionCode
  defdelegate promotion_code_section_parent_coupon_eyebrow(), to: PromotionCode
  defdelegate promotion_code_section_navigate_heading(), to: PromotionCode
  defdelegate promotion_code_redemption_boundaries_heading(), to: PromotionCode
  defdelegate promotion_code_detail_no_coupon_projection(), to: PromotionCode
  defdelegate promotion_code_json_payload_label(), to: PromotionCode
  defdelegate promotion_code_lazy_activity_heading(), to: PromotionCode
  defdelegate promotion_code_lazy_activity_label(), to: PromotionCode
  defdelegate promotion_code_lazy_activity_prompt(), to: PromotionCode
  defdelegate promotion_code_lazy_activity_empty_label(), to: PromotionCode
  defdelegate promotion_code_lazy_activity_empty_body(), to: PromotionCode
  defdelegate promotion_code_lazy_raw_data_heading(), to: PromotionCode
  defdelegate promotion_code_lazy_raw_data_prompt(), to: PromotionCode
  defdelegate promotion_code_page_title_show(), to: PromotionCode
  defdelegate promotion_codes_coupon_none_label(), to: PromotionCode
  defdelegate promotion_codes_status_active(), to: PromotionCode
  defdelegate promotion_codes_status_inactive(), to: PromotionCode
  defdelegate promotion_codes_status_active_expires_separator(), to: PromotionCode
  defdelegate promotion_code_redeem_by_no_expiry(), to: PromotionCode
  defdelegate promotion_codes_expires_summary_no_expiry(), to: PromotionCode
  defdelegate promotion_code_kpi_meta_unlimited_cap(), to: PromotionCode
  defdelegate promotion_code_not_found(), to: PromotionCode

  defdelegate connect_accounts_page_title(), to: Connect
  defdelegate connect_accounts_breadcrumb_connect(), to: Connect
  defdelegate connect_accounts_eyebrow(), to: Connect
  defdelegate connect_accounts_headline(), to: Connect
  defdelegate connect_accounts_page_copy_primary(), to: Connect
  defdelegate connect_accounts_list_heading(), to: Connect
  defdelegate connect_accounts_list_subtitle(), to: Connect
  defdelegate connect_accounts_list_first_run_empty_title(), to: Connect
  defdelegate connect_accounts_list_first_run_empty_body(), to: Connect
  defdelegate connect_accounts_list_queue_empty_title(), to: Connect
  defdelegate connect_accounts_list_queue_empty_body(), to: Connect
  defdelegate connect_accounts_list_filtered_empty_title(), to: Connect
  defdelegate connect_accounts_list_filtered_empty_body(), to: Connect
  defdelegate connect_accounts_list_loading_label(), to: Connect
  defdelegate connect_accounts_list_default_lens_label(), to: Connect
  defdelegate connect_accounts_list_all_lens_label(), to: Connect
  defdelegate connect_accounts_list_result_label_pair(), to: Connect
  defdelegate connect_accounts_kpi_section_aria_label(), to: Connect
  defdelegate connect_accounts_kpi_label_accounts(), to: Connect
  defdelegate connect_accounts_kpi_meta_all_accounts(), to: Connect
  defdelegate connect_accounts_kpi_label_charges_enabled(), to: Connect
  defdelegate connect_accounts_kpi_delta_submitted_suffix(), to: Connect
  defdelegate connect_accounts_kpi_meta_capability_onboarding(), to: Connect
  defdelegate connect_accounts_kpi_label_overrides(), to: Connect
  defdelegate connect_accounts_kpi_delta_deauthorized_suffix(), to: Connect
  defdelegate connect_accounts_kpi_meta_platform_fee_override(), to: Connect
  defdelegate connect_accounts_table_column_account(), to: Connect
  defdelegate connect_accounts_table_column_owner(), to: Connect
  defdelegate connect_accounts_table_column_readiness(), to: Connect
  defdelegate connect_accounts_table_column_override(), to: Connect
  defdelegate connect_accounts_table_column_status(), to: Connect
  defdelegate connect_accounts_filter_label_search(), to: Connect
  defdelegate connect_accounts_filter_label_type(), to: Connect
  defdelegate connect_accounts_filter_option_type_standard(), to: Connect
  defdelegate connect_accounts_filter_option_type_express(), to: Connect
  defdelegate connect_accounts_filter_option_type_custom(), to: Connect
  defdelegate connect_accounts_filter_label_charges(), to: Connect
  defdelegate connect_accounts_filter_option_charges_enabled(), to: Connect
  defdelegate connect_accounts_filter_option_charges_disabled(), to: Connect
  defdelegate connect_accounts_filter_label_payouts(), to: Connect
  defdelegate connect_accounts_filter_option_payouts_enabled(), to: Connect
  defdelegate connect_accounts_filter_option_payouts_disabled(), to: Connect
  defdelegate connect_accounts_filter_label_onboarding(), to: Connect
  defdelegate connect_accounts_filter_option_onboarding_submitted(), to: Connect
  defdelegate connect_accounts_filter_option_onboarding_pending(), to: Connect
  defdelegate connect_accounts_filter_label_authorization(), to: Connect
  defdelegate connect_accounts_filter_option_authorization_deauthorized(), to: Connect
  defdelegate connect_accounts_filter_option_authorization_active(), to: Connect
  defdelegate connect_accounts_table_empty_title(), to: Connect
  defdelegate connect_accounts_table_empty_copy(), to: Connect
  defdelegate connect_accounts_apply_filters(), to: Connect
  defdelegate connect_accounts_row_owner_fallback(), to: Connect
  defdelegate connect_accounts_readiness_needs_onboarding(), to: Connect
  defdelegate connect_accounts_readiness_joiner(), to: Connect
  defdelegate connect_accounts_override_default_only(), to: Connect
  defdelegate connect_accounts_override_saved(), to: Connect
  defdelegate connect_accounts_status_deauthorized_prefix(), to: Connect
  defdelegate connect_accounts_status_no_email(), to: Connect
  defdelegate connect_accounts_error_view_failed(), to: Connect

  defdelegate connect_account_page_title(), to: Connect
  defdelegate connect_account_breadcrumb_connect(), to: Connect
  defdelegate connect_account_eyebrow(), to: Connect
  defdelegate connect_account_actions_eyebrow(), to: Connect
  defdelegate connect_account_actions_heading(), to: Connect
  defdelegate connect_account_actions_body(), to: Connect
  defdelegate connect_account_action_edit_platform_fee_override(), to: Connect
  defdelegate connect_account_summary_label_readiness(), to: Connect
  defdelegate connect_account_summary_label_owner(), to: Connect
  defdelegate connect_account_summary_label_country(), to: Connect
  defdelegate connect_account_summary_label_charges_enabled(), to: Connect
  defdelegate connect_account_summary_label_payouts_enabled(), to: Connect
  defdelegate connect_account_summary_label_onboarding(), to: Connect
  defdelegate connect_account_summary_label_override(), to: Connect
  defdelegate connect_account_summary_label_activity(), to: Connect
  defdelegate connect_account_activity_summary(), to: Connect
  defdelegate connect_account_readiness_ready(), to: Connect
  defdelegate connect_account_readiness_needs_attention(), to: Connect
  defdelegate connect_account_kpi_section_aria_label(), to: Connect
  defdelegate connect_account_kpi_label_charges(), to: Connect
  defdelegate connect_account_kpi_meta_payouts_prefix(), to: Connect
  defdelegate connect_account_kpi_label_onboarding(), to: Connect
  defdelegate connect_account_kpi_meta_country_prefix(), to: Connect
  defdelegate connect_account_kpi_label_override(), to: Connect
  defdelegate connect_account_override_state_saved(), to: Connect
  defdelegate connect_account_override_state_default_only(), to: Connect
  defdelegate connect_account_kpi_meta_default_policy_prefix(), to: Connect
  defdelegate connect_account_section_capabilities_eyebrow(), to: Connect
  defdelegate connect_account_drills_aria_label(), to: Connect
  defdelegate connect_account_section_capabilities_heading(), to: Connect
  defdelegate connect_account_detail_label_owner(), to: Connect
  defdelegate connect_account_detail_label_email(), to: Connect
  defdelegate connect_account_detail_label_type(), to: Connect
  defdelegate connect_account_detail_label_capabilities(), to: Connect
  defdelegate connect_account_detail_label_requirements(), to: Connect
  defdelegate connect_account_section_effective_fee_eyebrow(), to: Connect
  defdelegate connect_account_section_effective_fee_heading(), to: Connect
  defdelegate connect_account_detail_label_stored_override(), to: Connect
  defdelegate connect_account_detail_label_default_policy(), to: Connect
  defdelegate connect_account_detail_label_preview_gross(), to: Connect
  defdelegate connect_account_detail_label_computed_fee(), to: Connect
  defdelegate connect_account_section_platform_fee_eyebrow(), to: Connect
  defdelegate connect_account_section_platform_fee_heading(), to: Connect
  defdelegate connect_account_section_platform_fee_body(), to: Connect
  defdelegate connect_account_drawer_title(account_label), to: Connect
  defdelegate connect_account_drawer_subtitle(), to: Connect
  defdelegate connect_account_activity_heading(), to: Connect
  defdelegate connect_account_timeline_label(), to: Connect
  defdelegate connect_account_timeline_empty(), to: Connect
  defdelegate connect_account_lazy_activity_prompt(), to: Connect
  defdelegate connect_account_raw_data_heading(), to: Connect
  defdelegate connect_account_json_payload_label(), to: Connect
  defdelegate connect_account_lazy_json_prompt(), to: Connect
  defdelegate connect_account_label_percent(), to: Connect
  defdelegate connect_account_label_fixed_minor_units(), to: Connect
  defdelegate connect_account_label_min_minor_units(), to: Connect
  defdelegate connect_account_label_max_minor_units(), to: Connect
  defdelegate connect_account_label_preview_gross_minor_units(), to: Connect
  defdelegate connect_account_label_preview_currency(), to: Connect
  defdelegate connect_account_save_platform_fee_override(), to: Connect
  defdelegate connect_account_flash_override_saved(), to: Connect
  defdelegate connect_account_step_up_unavailable(), to: Connect
  defdelegate connect_account_override_state_no_override_saved(), to: Connect
  defdelegate connect_account_preview_fee_unable(), to: Connect
  defdelegate connect_account_preview_gross_invalid(), to: Connect
  defdelegate connect_account_status_deauthorized_prefix(), to: Connect
  defdelegate connect_account_status_active_authorization(), to: Connect
  defdelegate connect_account_enabled_label_true(), to: Connect
  defdelegate connect_account_enabled_label_false(), to: Connect
  defdelegate connect_account_enabled_label_unknown(), to: Connect
  defdelegate connect_account_capabilities_none(), to: Connect
  defdelegate connect_account_requirements_none(), to: Connect
  defdelegate connect_account_requirements_currently_due_prefix(), to: Connect
  defdelegate connect_account_error_preview_amount_invalid(), to: Connect
  defdelegate connect_account_error_preview_currency_unknown(), to: Connect
  defdelegate connect_account_error_field_must_be_decimal(field_label), to: Connect
  defdelegate connect_account_error_field_must_be_integer_minor(field_label), to: Connect
  defdelegate connect_account_not_found(), to: Connect

  defdelegate billing_events_page_title(), to: BillingEvent
  defdelegate billing_events_breadcrumb_events(), to: BillingEvent
  defdelegate events_list_heading(), to: BillingEvent
  defdelegate events_list_subtitle(), to: BillingEvent
  defdelegate events_list_first_run_empty_title(), to: BillingEvent
  defdelegate events_list_first_run_empty_body(), to: BillingEvent
  defdelegate events_list_filtered_empty_title(), to: BillingEvent
  defdelegate events_list_filtered_empty_body(), to: BillingEvent
  defdelegate events_list_loading_label(), to: BillingEvent
  defdelegate events_list_default_lens_label(), to: BillingEvent
  defdelegate events_list_all_lens_label(), to: BillingEvent
  defdelegate events_list_admin_changes_label(), to: BillingEvent
  defdelegate events_list_result_label_pair(), to: BillingEvent
  defdelegate billing_events_kpi_section_aria_label(), to: BillingEvent
  defdelegate billing_events_kpi_label_ledger_rows(), to: BillingEvent
  defdelegate billing_events_kpi_meta_total_append_only(), to: BillingEvent
  defdelegate billing_events_kpi_label_webhook_sourced(), to: BillingEvent
  defdelegate billing_events_kpi_delta_admin_suffix(), to: BillingEvent
  defdelegate billing_events_kpi_meta_webhook_cause_chain(), to: BillingEvent
  defdelegate billing_events_kpi_label_last_24h(), to: BillingEvent
  defdelegate billing_events_kpi_delta_subject_types_suffix(), to: BillingEvent
  defdelegate billing_events_kpi_meta_recent_cross_resource(), to: BillingEvent
  defdelegate billing_events_table_column_event(), to: BillingEvent
  defdelegate billing_events_table_column_subject(), to: BillingEvent
  defdelegate billing_events_table_column_actor(), to: BillingEvent
  defdelegate billing_events_table_column_webhook_source(), to: BillingEvent
  defdelegate billing_events_table_column_when(), to: BillingEvent
  defdelegate billing_events_filter_label_search(), to: BillingEvent
  defdelegate billing_events_filter_label_event_type(), to: BillingEvent
  defdelegate billing_events_filter_label_actor_type(), to: BillingEvent
  defdelegate billing_events_filter_label_subject_type(), to: BillingEvent
  defdelegate billing_events_filter_label_source_webhook_id(), to: BillingEvent
  defdelegate billing_events_table_empty_title(), to: BillingEvent
  defdelegate billing_events_table_empty_copy(), to: BillingEvent
  defdelegate billing_events_apply_filters(), to: BillingEvent
  defdelegate billing_events_eyebrow_organization(), to: BillingEvent
  defdelegate billing_events_eyebrow_global(), to: BillingEvent
  defdelegate billing_events_heading_organization(), to: BillingEvent
  defdelegate billing_events_heading_global(), to: BillingEvent
  defdelegate billing_events_copy_organization(), to: BillingEvent
  defdelegate billing_events_copy_global(), to: BillingEvent
  defdelegate billing_events_webhook_source_direct(), to: BillingEvent
  defdelegate billing_events_when_unknown(), to: BillingEvent
  defdelegate billing_event_not_found(), to: BillingEvent
  defdelegate event_detail_eyebrow(), to: BillingEvent
  defdelegate event_detail_section_heading(), to: BillingEvent
  defdelegate event_detail_related_resources_title(), to: BillingEvent
  defdelegate event_detail_related_resources_empty(), to: BillingEvent
  defdelegate event_detail_lazy_activity_heading(), to: BillingEvent
  defdelegate event_detail_lazy_activity_label(), to: BillingEvent
  defdelegate event_detail_lazy_activity_prompt(), to: BillingEvent
  defdelegate event_detail_lazy_activity_empty_label(), to: BillingEvent
  defdelegate event_detail_lazy_activity_empty_body(), to: BillingEvent
  defdelegate event_detail_json_payload_label(), to: BillingEvent
  defdelegate event_detail_lazy_raw_data_prompt(), to: BillingEvent

  def page_state_copy(:true_empty, opts) do
    resource = option(opts, :resource, "billing records")
    owner_scope = option(opts, :owner_scope, "the active organization")

    %{
      heading: "No billing records yet",
      body:
        "Records appear here after Accrue records activity for #{owner_scope}. If you expected #{resource}, confirm owner scope or seed state."
    }
  end

  def page_state_copy(:filtered_empty, opts) do
    resource = option(opts, :resource, "billing records")
    owner_scope = option(opts, :owner_scope, "the active organization")

    %{
      heading: "No records match these filters",
      body: "Clear filters or adjust owner scope #{owner_scope} to review matching #{resource}."
    }
  end

  def page_state_copy(:data_unavailable, opts) do
    resource = option(opts, :resource, "billing data")
    recovery = option(opts, :recovery, "retry the request")

    %{
      heading: "#{sentence_case(resource)} unavailable",
      body:
        "The #{resource} projection is unavailable. #{sentence_case(recovery)}; if it persists, inspect logs for the owner scope."
    }
  end

  def page_state_copy(:permission_denied, opts) do
    object = option(opts, :object, "this billing record")
    owner_scope = option(opts, :owner_scope, "the active organization")

    %{
      heading: "Access restricted",
      body:
        "This admin account cannot view #{object}. Switch #{owner_scope} or ask an administrator to grant billing admin access."
    }
  end

  def page_state_copy(:disconnected, opts) do
    resource = option(opts, :resource, "billing actions")

    %{
      heading: "#{sentence_case(resource)} paused",
      body: "Connection lost. Reconnecting before actions can run."
    }
  end

  def page_state_copy(:reconnecting, opts) do
    resource = option(opts, :resource, "billing actions")

    %{
      heading: "#{sentence_case(resource)} restored",
      body: "Connection restored. Review the current state before running an action."
    }
  end

  def page_state_copy(:recoverable_error, opts) do
    resource = option(opts, :resource, "billing record")
    owner_scope = option(opts, :owner_scope, "the active organization")
    recovery = option(opts, :recovery, "retry the request")

    %{
      heading: "#{sentence_case(resource)} could not load",
      body:
        "This #{resource} could not load. #{sentence_case(recovery)}; if it persists, inspect logs for owner scope #{owner_scope}."
    }
  end

  @doc """
  Shared DataTable footer count, plural-aware on the `{singular, plural}` row_label tuple.

      data_table_row_count(1, {"event", "events"})  #=> "Showing 1 event"
      data_table_row_count(3, {"event", "events"})  #=> "Showing 3 events"
  """
  def data_table_row_count(count, {singular, plural}) do
    word = if count == 1, do: singular, else: plural
    "Showing #{count} #{word}"
  end

  def data_table_default_empty_title, do: "Nothing in this list yet"

  @doc "Shared DataTable filter toolbar primary submit (VERIFY-01 / UI-SPEC secondary CTA)."
  def data_table_filter_submit_label, do: "Apply filters"

  def data_table_default_empty_copy,
    do:
      "Billing records appear here when they match this view. If you expected rows, check filters or organization scope."

  def data_table_filtered_empty_title, do: "No billing records match these filters"

  def data_table_filtered_empty_copy,
    do: "Clear or adjust the filters above to inspect matching billing records."

  # Filtered-to-zero affordance (Phase 171): keep the screen's tailored empty copy,
  # but offer a way back when a filter is what emptied the list.
  def data_table_clear_filters_label, do: "Clear filters"

  def customers_index_heading, do: "Customers"

  def customers_index_description,
    do:
      "Everyone you bill through Accrue for this organization. Search by name, email, or customer ID."

  def customers_list_heading, do: "Find a customer"

  def customers_list_subtitle, do: "Look up a customer and inspect their billing state."

  def customers_list_first_run_empty_title, do: "No customers yet."

  def customers_list_first_run_empty_body,
    do: "Customers appear after checkout or imported billing activity."

  def customers_list_filtered_empty_title, do: "No customers match these filters."

  def customers_list_filtered_empty_body,
    do: "Clear filters or adjust the search to inspect matching customers."

  def customers_list_loading_label, do: "Loading customers."

  def customers_list_default_lens_label, do: "All customers"

  def customers_list_all_lens_label, do: "All customers"

  def customers_list_missing_payment_method_label, do: "Missing payment method"

  def customers_list_result_label_pair, do: {"customer", "customers"}

  def customers_index_empty_title, do: "No customers for this organization yet"

  def customers_index_empty_copy,
    do:
      "Customers show up when someone pays through Accrue for this organization. If you expected a customer, widen filters or confirm you are in the right organization."

  def subscriptions_index_empty_title, do: "No subscriptions for this organization yet"

  def subscriptions_index_empty_copy,
    do:
      "Subscriptions appear when billing is active for this organization. If you expected one, adjust filters or confirm organization scope."

  def charges_index_empty_title, do: "No charges for this organization yet"

  def charges_index_empty_copy,
    do:
      "Charges appear when payments are recorded for this organization. If you expected charges, adjust filters or confirm organization scope."

  # --- Index page headers (h1 + subtitle) for inline-literal pages

  def subscriptions_index_heading, do: "Subscriptions"

  def subscriptions_index_subtitle,
    do:
      "Every subscription for this organization and where it sits in its lifecycle. Filter by status or search by customer to find the ones that need attention."

  def charges_index_heading, do: "Payments"

  def charges_index_subtitle,
    do:
      "Every charge and refund for this organization. Filter by status, or open a charge to see its fees, payment method, and any failure."

  def payments_list_heading, do: "Recover failed payments"

  def payments_list_subtitle, do: "Inspect charges that need follow-up."

  def payments_list_first_run_empty_title, do: "No payments yet."

  def payments_list_first_run_empty_body, do: "Payments appear after charges are recorded."

  def payments_list_queue_empty_title, do: "No failed payments."

  def payments_list_queue_empty_body,
    do: "View all payments to inspect settled and pending charges."

  def payments_list_filtered_empty_title, do: "No payments match these filters."

  def payments_list_filtered_empty_body,
    do: "Clear filters or adjust the search to see payments."

  def payments_list_loading_label, do: "Loading payments."

  def payments_list_default_lens_label, do: "Failed payments"

  def payments_list_all_lens_label, do: "All payments"

  def payments_list_result_label_pair, do: {"payment", "payments"}

  def webhooks_index_heading, do: "Webhooks"

  def webhooks_index_subtitle,
    do:
      "Inbound webhook deliveries, the failed ones first. Open a delivery for its full payload, or select deliveries to replay."

  def webhooks_list_heading, do: "Replay failed deliveries"

  def webhooks_list_subtitle, do: "Inspect webhook deliveries that need operator action."

  def webhooks_list_first_run_empty_title, do: "No webhook deliveries yet."

  def webhooks_list_first_run_empty_body,
    do: "Deliveries appear after signed processor events are recorded."

  def webhooks_list_queue_empty_title, do: "No webhook deliveries need replay."

  def webhooks_list_queue_empty_body,
    do: "View all deliveries to inspect the full delivery log."

  def webhooks_list_filtered_empty_title, do: "No webhook deliveries match these filters."

  def webhooks_list_filtered_empty_body,
    do: "Clear filters or adjust status and type filters to see deliveries."

  def webhooks_list_loading_label, do: "Loading webhook deliveries."

  def webhooks_list_default_lens_label, do: "Needs replay"

  def webhooks_list_all_lens_label, do: "All deliveries"

  def webhooks_list_result_label_pair, do: {"webhook delivery", "webhook deliveries"}

  defdelegate webhook_replay_drawer_title(), to: Locked, as: :replay_drawer_title
  defdelegate webhook_replay_step_up_unavailable(), to: Locked, as: :replay_step_up_unavailable

  defdelegate webhook_replay_unavailable_status(status),
    to: Locked,
    as: :replay_unavailable_status

  defdelegate webhook_single_replay_confirmation(webhook_id, opts),
    to: Locked,
    as: :single_replay_confirmation

  def recovery_index_heading, do: "Revenue Recovery"

  def recovery_index_subtitle,
    do:
      "Track the dunning funnel and customers at risk of churn — how many recover after a failed payment, and which are nearing cancellation."

  def recovery_cutoff_link_label, do: "Showing data since 2024-01-01"

  def recovery_recovered_mrr_label(currency),
    do: "Recovered MRR (#{String.upcase(to_string(currency))})"

  def recovery_recovered_mrr_delta, do: "Amount saved by successful Dunning"

  def recovery_recovered_mrr_meta, do: "Money Saved"

  def recovery_exhausted_mrr_label(currency),
    do: "Exhausted MRR (#{String.upcase(to_string(currency))})"

  def recovery_exhausted_mrr_delta,
    do:
      "Annualized MRR snapshot at the exhaustion event — e.g., a $120/yr plan contributes $10/mo to Exhausted MRR."

  def recovery_exhausted_mrr_meta, do: "Churned Revenue"

  def subscription_select_action_warning, do: "Select an action before confirming."

  def subscription_action_recorded_info, do: "Subscription action recorded."

  # --- Subscription drill (SubscriptionLive) — Phase 49, ADM-02

  def subscription_drill_related_card_title, do: "Related billing"

  def subscription_drill_related_region_aria_label,
    do: "Related billing links for this subscription's customer"

  def subscription_drill_link_customer, do: "Customer profile"

  def subscription_drill_link_invoices_for_customer,
    do: "Invoices for this customer (not subscription-filtered)"

  def subscription_drill_link_invoices_for_subscription,
    do: "Subscription invoice queue"

  def subscription_drill_link_charges_for_customer,
    do: "Charges for this customer (not subscription-filtered)"

  def subscription_drill_link_events_index,
    do: "All billing events (full ledger)"

  def subscription_drill_link_events_for_subscription,
    do: "Subscription events"

  def payment_processor_action_warning(payment_intent),
    do: "Processor requires action: " <> inspect(payment_intent)

  def charge_not_found,
    do: "Charge not found. Open the payments list and confirm owner scope before retrying."

  def charge_prepare_refund_warning, do: "Prepare a refund before confirming."

  def charge_refund_confirm_message(opts) do
    charge_id = option(opts, :charge_id, "this charge")
    amount = option(opts, :amount, "the selected amount")
    audit_subject = option(opts, :audit_subject, "a refund ledger row")

    source =
      opts
      |> Keyword.get(:source_event_id)
      |> charge_refund_source_suffix()

    "Refund charge #{charge_id}: This will create a #{amount} refund, record #{audit_subject}, and record an admin audit row.#{source} Confirm refund."
  end

  def charge_refund_created_info,
    do: "Refund created with fee-aware fields from the billing facade."

  def charge_refund_braintree_eligibility_info,
    do: "Refunds apply to settled or settling transactions. Pre-settlement voids are separate."

  def charge_refund_not_final_truth_warning,
    do:
      "API success is not final lifecycle truth; child refunds must converge via webhook or reconcile backstop."

  def charge_refund_child_fact_disclaimer,
    do: "Repeated partial refunds will appear as separate child facts."

  def customer_detail_no_subscriptions, do: "No subscriptions for this customer yet."

  def customer_detail_no_invoices, do: "No invoices for this customer yet."

  defdelegate customer_payment_methods_section_heading(),
    to: CustomerPaymentMethods,
    as: :section_heading

  defdelegate customer_payment_methods_empty_copy(), to: CustomerPaymentMethods, as: :empty_copy

  defdelegate customer_payment_methods_section_body(),
    to: CustomerPaymentMethods,
    as: :section_body

  defdelegate customer_payment_methods_row_fallback_label(),
    to: CustomerPaymentMethods,
    as: :row_fallback_label

  defdelegate customer_payment_methods_card_last4_mask(),
    to: CustomerPaymentMethods,
    as: :card_last4_mask

  defdelegate customer_payment_methods_sync_action(), to: CustomerPaymentMethods, as: :sync_action

  defdelegate customer_payment_methods_sync_success(),
    to: CustomerPaymentMethods,
    as: :sync_success

  defdelegate customer_payment_methods_set_default_action(),
    to: CustomerPaymentMethods,
    as: :set_default_action

  defdelegate customer_payment_methods_set_default_success(),
    to: CustomerPaymentMethods,
    as: :set_default_success

  defdelegate customer_payment_methods_set_default_drawer_body(),
    to: CustomerPaymentMethods,
    as: :set_default_drawer_body

  defdelegate customer_payment_methods_already_default_warning(),
    to: CustomerPaymentMethods,
    as: :already_default_warning

  defdelegate customer_payment_methods_delete_action(),
    to: CustomerPaymentMethods,
    as: :delete_action

  defdelegate customer_payment_methods_delete_success(),
    to: CustomerPaymentMethods,
    as: :delete_success

  defdelegate customer_payment_methods_delete_drawer_body(),
    to: CustomerPaymentMethods,
    as: :delete_drawer_body

  defdelegate customer_payment_methods_delete_warning(),
    to: CustomerPaymentMethods,
    as: :delete_warning

  defdelegate customer_payment_methods_drawer_subtitle(),
    to: CustomerPaymentMethods,
    as: :drawer_subtitle

  defdelegate customer_payment_methods_cancel_action(),
    to: CustomerPaymentMethods,
    as: :cancel_action

  defdelegate customer_payment_methods_delete_blocked_in_use(),
    to: CustomerPaymentMethods,
    as: :delete_blocked_in_use

  defdelegate customer_payment_methods_delete_blocked_replacement_required(),
    to: CustomerPaymentMethods,
    as: :delete_blocked_replacement_required

  defdelegate customer_payment_methods_replace_handoff(),
    to: CustomerPaymentMethods,
    as: :replace_handoff

  defdelegate customer_payment_methods_default_badge(),
    to: CustomerPaymentMethods,
    as: :default_badge

  defdelegate customer_payment_methods_in_use_badge(),
    to: CustomerPaymentMethods,
    as: :in_use_badge

  defdelegate entitlements_section_title(), to: Entitlements, as: :section_title

  defdelegate entitlements_drift_section_title(), to: Entitlements, as: :drift_section_title

  defdelegate entitlements_active_plans_label(), to: Entitlements, as: :active_plans_label

  defdelegate entitlements_features_label(), to: Entitlements, as: :features_label

  defdelegate entitlements_quantities_label(), to: Entitlements, as: :quantities_label

  defdelegate entitlements_grace_label(), to: Entitlements, as: :grace_label

  defdelegate entitlements_unmapped_badge(), to: Entitlements, as: :unmapped_badge

  defdelegate entitlements_unmapped_hint(), to: Entitlements, as: :unmapped_hint

  defdelegate entitlements_empty_title(), to: Entitlements, as: :empty_title

  defdelegate entitlements_empty_copy(), to: Entitlements, as: :empty_copy

  defdelegate entitlements_no_drift_copy(), to: Entitlements, as: :no_drift_copy

  defdelegate entitlements_raw_map_label(), to: Entitlements, as: :raw_map_label

  defdelegate entitlements_error_copy(), to: Entitlements, as: :error_copy

  def webhooks_index_empty_title, do: "No webhook deliveries for this organization yet"

  def webhooks_index_empty_copy,
    do:
      "Webhook deliveries appear here after Stripe events are recorded for this organization. If you expected deliveries, check filters or confirm your endpoint is receiving traffic."

  def webhooks_index_filtered_empty_title, do: "No webhook deliveries match these filters"

  def webhooks_index_filtered_empty_copy,
    do: "Adjust or clear the status, type, or live-mode filters above to see matching deliveries."

  @doc "Helper line above the webhooks table — plain-language JTBD framing."
  def webhooks_retry_selected_helper,
    do:
      "Events that failed every automatic retry land here. Filter, select the ones to re-run, then Retry selected."

  @doc "Primary selection action on the webhooks list."
  def webhooks_retry_selected_label, do: "Retry selected"

  @doc "Secondary action that dismisses bulk retry confirmation."
  def webhooks_retry_cancel_label, do: "Cancel"

  @doc """
  Plural-aware confirm question for retrying selected webhook events.
  `opts` is accepted for symmetry with scoped copy but currently unused.
  """
  def webhooks_retry_confirm_question(count), do: webhooks_retry_confirm_question(count, [])

  def webhooks_retry_confirm_question(count, _opts) do
    word = if count == 1, do: "webhook event", else: "webhook events"

    "Retry #{count} #{word}? They failed every automatic retry — retrying runs them through processing again."
  end

  @doc "Guard flash when Retry selected is triggered with nothing selected."
  def webhooks_retry_no_selection_warning, do: "Select at least one event to retry first."

  @doc "Success flash after retrying selected events (plural-aware)."
  def webhooks_retry_success(count) do
    word = if count == 1, do: "event", else: "events"
    "Retrying #{count} #{word}…"
  end

  def step_up_submit_label, do: "Verify identity"

  @doc "Step-up modal eyebrow label."
  def step_up_eyebrow, do: "Sensitive action"

  @doc "Step-up modal title."
  def step_up_title, do: "Step-up required"

  @doc "Default challenge body when none is supplied."
  def step_up_default_challenge_message, do: "Confirm your identity to continue."

  @doc "Step-up dismiss control label."
  def step_up_cancel_label, do: "Cancel"

  def customers_index_table_caption, do: "Customers"

  def webhooks_index_table_caption, do: "Replay, inspect, and trace webhook delivery"

  # --- Operator dashboard (DashboardLive) — Phase 35, OPS-05

  def dashboard_breadcrumb_home, do: "Dashboard"

  def dashboard_chrome_eyebrow, do: "Command center"

  def dashboard_display_headline, do: "What needs attention now"

  def dashboard_page_copy_primary,
    do:
      "Start with the highest-signal billing exceptions, then jump into the customer, revenue, recovery, or operations queue that can resolve them."

  def dashboard_kpi_section_aria_label, do: "Billing KPI summary"

  def dashboard_activity_section_aria_label, do: "Dashboard activity"

  def dashboard_kpi_customers_label, do: "Customers"

  def dashboard_kpi_active_subscriptions_label, do: "Active subscriptions"

  def dashboard_kpi_open_invoice_balance_label, do: "Open invoice balance"

  def dashboard_kpi_webhook_backlog_label, do: "Webhook backlog"

  def dashboard_kpi_recovery_risk_label, do: "Recovery risk"

  def dashboard_kpi_customers_meta, do: "Total local customer records"

  def dashboard_kpi_active_subscriptions_meta, do: "Canonical active + trialing predicates"

  def dashboard_kpi_open_invoice_balance_meta,
    do: "Remaining amount due from local invoice projections"

  def dashboard_kpi_webhook_backlog_meta,
    do: "Failed + dead webhook rows waiting for operator attention"

  def dashboard_kpi_recovery_risk_meta,
    do: "Past-due subscriptions that may need dunning or support follow-up"

  def dashboard_meter_reporting_failures_label, do: "Meter reporting failures"

  def dashboard_meter_reporting_failures_meta,
    do:
      "Counts accrue_meter_events rows in stripe_status=\"failed\" (terminal meter reporting failures)."

  def dashboard_meter_reporting_failures_aria_label,
    do: "Open billing event ledger; events list is not limited to meter rows."

  def dashboard_kpi_customers_aria_label, do: "Open customers list"

  def dashboard_kpi_subscriptions_aria_label, do: "Open subscriptions list"

  def dashboard_kpi_invoices_aria_label, do: "Open invoices list"

  def dashboard_kpi_webhooks_aria_label, do: "Open webhooks list"

  def dashboard_kpi_recovery_aria_label, do: "Open recovery dashboard"

  def dashboard_kpi_active_subscriptions_canceling_suffix, do: " canceling"

  def dashboard_kpi_open_invoice_delta_suffix, do: " open invoices"

  def dashboard_kpi_webhook_events_suffix, do: " events in 24h"

  def dashboard_activity_event_ledger_eyebrow, do: "Event ledger"

  def dashboard_activity_recent_local_heading, do: "Recent local activity"

  def dashboard_activity_webhook_health_eyebrow, do: "Webhook health"

  def dashboard_activity_projection_pipeline_heading, do: "Projection pipeline"

  def dashboard_timeline_events_label, do: "Recent event ledger rows"

  def dashboard_timeline_events_empty, do: "No local events recorded yet"

  def dashboard_timeline_webhooks_label, do: "Recent webhook processing rows"

  def dashboard_timeline_webhooks_empty, do: "No webhook rows recorded yet"

  # --- Home start page (DashboardLive IA — Phase 169 / v1.50 AUI-03)
  # Task-launcher home: attention rail → JTBD launchers → demoted KPIs → activity.

  def home_intro_headline, do: "Billing operations"

  def home_intro_copy,
    do:
      "Check billing health first, then open the invoice, dunning, webhook, or customer workspace that resolves the issue."

  def home_tasks_heading, do: "Jump to a task"

  def home_attention_all_signals, do: "Review all signals"

  def home_attention_empty_title, do: "You're all caught up"

  def home_attention_empty_copy,
    do: "No billing exceptions need attention right now. Pick up a task below."

  def home_attention_action_review, do: "Review"

  def home_attention_action_recover, do: "Open recovery queue"

  def home_attention_action_investigate, do: "Investigate"

  def home_attention_action_work, do: "Work queue"

  def home_attention_webhooks_label, do: "dead-lettered — failed every retry"

  def home_attention_past_due_label, do: "past due — at risk of churn"

  def home_attention_meter_label, do: "failed to report — usage not billed"

  def home_search_customers_title, do: "Find one customer"

  def home_search_customers_placeholder, do: "Search customers; open billing 360 detail"

  def home_launcher_customers_title, do: "Browse customer records"

  def home_launcher_customers_copy,
    do: "Use the customer directory when list context matters."

  def home_launcher_customers_meta, do: "Secondary customer directory"

  def home_launcher_invoices_title, do: "Clear the invoice queue"

  def home_launcher_invoices_copy, do: "Review, void, or chase open receivables."

  def home_launcher_recovery_title, do: "Watch the dunning funnel + at-risk"

  def home_launcher_recovery_copy,
    do: "Open recovery analytics to monitor failed-payment recovery and at-risk customers."

  def home_launcher_recovery_meta, do: "Recovery analytics"

  def home_launcher_developer_title, do: "Investigate an incident"

  def home_launcher_developer_copy,
    do: "Inspect payloads, replay dead-letters, and trace events."

  def home_kpi_heading, do: "At a glance"

  def home_activity_events_link, do: "Open event log"

  def home_activity_webhooks_link, do: "Open webhooks"

  defp resource_state_meta(resource) do
    Map.fetch!(
      @phase199_resource_states,
      resource |> to_string() |> String.to_existing_atom()
    )
  end

  defp build_resource_state_copy(meta, :first_run_empty, opts) do
    %{
      heading: Map.get(meta, :first_run_heading, "No #{meta.plural} yet"),
      body: first_run_empty_body(meta, opts)
    }
  end

  defp build_resource_state_copy(meta, :queue_empty, opts) do
    %{
      heading: Map.get(meta, :queue_heading, meta.queue),
      body: queue_empty_body(meta, opts)
    }
  end

  defp build_resource_state_copy(meta, :filtered_empty, _opts) do
    %{
      heading: Map.get(meta, :filtered_heading, "No #{meta.plural} match these filters"),
      body:
        Map.get(
          meta,
          :filtered_body,
          "Clear filters or adjust the search to inspect matching #{meta.plural}."
        )
    }
  end

  defp build_resource_state_copy(meta, :loading, _opts) do
    %{
      heading: Map.get(meta, :loading_heading, "Loading #{meta.plural}"),
      body:
        Map.get(meta, :loading_body, "Loading #{meta.plural} from the local billing projection.")
    }
  end

  defp build_resource_state_copy(meta, :error, opts) do
    owner_scope = option(opts, :owner_scope, "the active organization")

    %{
      heading: "#{sentence_case(meta.plural)} could not load",
      body:
        "Open the #{meta.singular} view and reload #{meta.plural} for #{owner_scope}; if it persists, inspect logs."
    }
  end

  defp build_resource_state_copy(meta, :permission_denied, opts) do
    object = option(opts, :object, "this #{meta.singular}")
    owner_scope = option(opts, :owner_scope, "the active organization")

    %{
      heading: "#{sentence_case(meta.plural)} restricted",
      body:
        "This admin account cannot view #{object}. Switch #{owner_scope} or ask an administrator for billing admin access."
    }
  end

  defp first_run_empty_body(%{singular: "subscription"} = meta, opts) do
    if Keyword.get(opts, :surface) == :customer_detail,
      do: customer_detail_no_subscriptions(),
      else: default_first_run_empty_body(meta)
  end

  defp first_run_empty_body(%{singular: "invoice"} = meta, opts) do
    if Keyword.get(opts, :surface) == :customer_detail,
      do: customer_detail_no_invoices(),
      else: default_first_run_empty_body(meta)
  end

  defp first_run_empty_body(meta, _opts) do
    default_first_run_empty_body(meta)
  end

  defp default_first_run_empty_body(meta) do
    Map.get(
      meta,
      :first_run_body,
      "#{sentence_case(meta.plural)} appear after #{meta.first_run}."
    )
  end

  defp queue_empty_body(%{singular: "dunning campaign"} = meta, opts) do
    if Keyword.get(opts, :surface) == :subscription_detail,
      do: dunning_empty_state_body(),
      else: default_queue_empty_body(meta)
  end

  defp queue_empty_body(meta, _opts), do: default_queue_empty_body(meta)

  defp default_queue_empty_body(meta), do: Map.get(meta, :queue_body, meta.queue_next)

  defp charge_refund_source_suffix(nil), do: ""
  defp charge_refund_source_suffix(""), do: ""

  defp charge_refund_source_suffix(source_event_id),
    do: " Source event ##{source_event_id} will be linked."

  defp option(opts, key, default) do
    opts
    |> Keyword.get(key, default)
    |> to_string()
  end

  defp sentence_case(""), do: ""

  defp sentence_case(<<first::binary-size(1), rest::binary>>) do
    String.upcase(first) <> rest
  end
end
