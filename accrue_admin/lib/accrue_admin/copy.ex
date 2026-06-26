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
  alias AccrueAdmin.Copy.PromotionCode
  alias AccrueAdmin.Copy.Subscription

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
  defdelegate subscription_action_stripe_guidance(), to: Subscription
  defdelegate subscription_confirm_workflow_message(action_type, opts), to: Subscription
  defdelegate subscription_lifecycle_ended_label(), to: Subscription
  defdelegate subscription_page_title(), to: Subscription

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
  defdelegate invoice_action_manual_pay(), to: Invoice
  defdelegate invoice_action_void(), to: Invoice
  defdelegate invoice_action_mark_uncollectible(), to: Invoice
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
  defdelegate promotion_code_detail_no_coupon_projection(), to: PromotionCode
  defdelegate promotion_code_json_payload_label(), to: PromotionCode
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
  defdelegate connect_account_section_capabilities_heading(), to: Connect
  defdelegate connect_account_detail_label_owner(), to: Connect
  defdelegate connect_account_detail_label_email(), to: Connect
  defdelegate connect_account_detail_label_capabilities(), to: Connect
  defdelegate connect_account_detail_label_requirements(), to: Connect
  defdelegate connect_account_section_effective_fee_eyebrow(), to: Connect
  defdelegate connect_account_section_effective_fee_heading(), to: Connect
  defdelegate connect_account_detail_label_stored_override(), to: Connect
  defdelegate connect_account_detail_label_preview_gross(), to: Connect
  defdelegate connect_account_detail_label_computed_fee(), to: Connect
  defdelegate connect_account_section_platform_fee_eyebrow(), to: Connect
  defdelegate connect_account_section_platform_fee_heading(), to: Connect
  defdelegate connect_account_section_platform_fee_body(), to: Connect
  defdelegate connect_account_label_percent(), to: Connect
  defdelegate connect_account_label_fixed_minor_units(), to: Connect
  defdelegate connect_account_label_min_minor_units(), to: Connect
  defdelegate connect_account_label_max_minor_units(), to: Connect
  defdelegate connect_account_label_preview_gross_minor_units(), to: Connect
  defdelegate connect_account_label_preview_currency(), to: Connect
  defdelegate connect_account_save_platform_fee_override(), to: Connect
  defdelegate connect_account_flash_override_saved(), to: Connect
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

  def data_table_filtered_empty_title, do: "No results match these filters"

  def data_table_filtered_empty_copy, do: "Clear or adjust the filters above to see results."

  # Filtered-to-zero affordance (Phase 171): keep the screen's tailored empty copy,
  # but offer a way back when a filter is what emptied the list.
  def data_table_clear_filters_label, do: "Clear filters"

  def customers_index_heading, do: "Customers"

  def customers_index_description,
    do:
      "Everyone you bill through Accrue for this organization. Search by name, email, or customer ID."

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

  def webhooks_index_heading, do: "Webhooks"

  def webhooks_index_subtitle,
    do:
      "Inbound webhook deliveries, the failed ones first. Open a delivery for its full payload, or select deliveries to replay."

  def recovery_index_heading, do: "Revenue Recovery"

  def recovery_index_subtitle,
    do:
      "Track the dunning funnel and customers at risk of churn — how many recover after a failed payment, and which are nearing cancellation."

  def subscription_select_action_warning, do: "Select an action before confirming."

  def subscription_action_recorded_info, do: "Subscription action recorded."

  # --- Subscription drill (SubscriptionLive) — Phase 49, ADM-02

  def subscription_drill_related_card_title, do: "Related billing"

  def subscription_drill_related_region_aria_label,
    do: "Related billing links for this subscription's customer"

  def subscription_drill_link_customer, do: "Customer profile"

  def subscription_drill_link_invoices_for_customer,
    do: "Invoices for this customer (not subscription-filtered)"

  def subscription_drill_link_charges_for_customer,
    do: "Charges for this customer (not subscription-filtered)"

  def subscription_drill_link_events_index,
    do: "All billing events (full ledger)"

  def payment_processor_action_warning(payment_intent),
    do: "Processor requires action: " <> inspect(payment_intent)

  def charge_not_found,
    do: "Charge not found. Open the payments list and confirm owner scope before retrying."

  def charge_prepare_refund_warning, do: "Prepare a refund before confirming."

  def charge_refund_confirm_message(opts) do
    charge_id = option(opts, :charge_id, "this charge")
    amount = option(opts, :amount, "the selected amount")
    audit_subject = option(opts, :audit_subject, "a refund ledger row")

    "Refund charge #{charge_id}: This will create a #{amount} refund, record #{audit_subject}, and record an admin audit row. Continue?"
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

  defdelegate customer_payment_methods_delete_action(),
    to: CustomerPaymentMethods,
    as: :delete_action

  defdelegate customer_payment_methods_delete_success(),
    to: CustomerPaymentMethods,
    as: :delete_success

  defdelegate customer_payment_methods_delete_warning(),
    to: CustomerPaymentMethods,
    as: :delete_warning

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
    do: "Start with what needs you, then jump straight to the task that resolves it."

  def home_tasks_heading, do: "Jump to a task"

  def home_attention_all_signals, do: "Review all signals"

  def home_attention_empty_title, do: "You're all caught up"

  def home_attention_empty_copy,
    do: "No billing exceptions need attention right now. Pick up a task below."

  def home_attention_action_review, do: "Review"

  def home_attention_action_recover, do: "Recover"

  def home_attention_action_investigate, do: "Investigate"

  def home_attention_action_work, do: "Work queue"

  def home_attention_webhooks_label, do: "dead-lettered — failed every retry"

  def home_attention_past_due_label, do: "past due — at risk of churn"

  def home_attention_meter_label, do: "failed to report — usage not billed"

  def home_launcher_customers_title, do: "Look up a customer"

  def home_launcher_customers_copy,
    do: "Search by name, email, or ID, then open their billing 360."

  def home_launcher_invoices_title, do: "Clear the invoice queue"

  def home_launcher_invoices_copy, do: "Review, void, or chase open receivables."

  def home_launcher_recovery_title, do: "Recover at-risk revenue"

  def home_launcher_recovery_copy, do: "Work the dunning funnel and at-risk subscriptions."

  def home_launcher_developer_title, do: "Investigate an incident"

  def home_launcher_developer_copy,
    do: "Inspect payloads, replay dead-letters, and trace events."

  def home_kpi_heading, do: "At a glance"

  def home_activity_events_link, do: "Open event log"

  def home_activity_webhooks_link, do: "Open webhooks"

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
