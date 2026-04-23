defmodule AccrueAdmin.Copy.Connect do
  @moduledoc false

  # --- Index (ConnectAccountsLive) — prefix connect_accounts_*

  def connect_accounts_breadcrumb_connect, do: "Connect"

  def connect_accounts_page_title, do: "Connect"

  def connect_accounts_eyebrow, do: "Marketplace operations"

  def connect_accounts_headline, do: "Connected accounts and payout readiness"

  def connect_accounts_page_copy_primary,
    do:
      "Operators can filter connected-account projections, inspect onboarding state, and jump into per-account platform-fee configuration."

  def connect_accounts_kpi_section_aria_label, do: "Connect summary"

  def connect_accounts_kpi_label_accounts, do: "Accounts"

  def connect_accounts_kpi_meta_all_accounts, do: "All locally projected connected accounts"

  def connect_accounts_kpi_label_charges_enabled, do: "Charges enabled"

  def connect_accounts_kpi_delta_submitted_suffix, do: " submitted"

  def connect_accounts_kpi_meta_capability_onboarding,
    do: "Capability and onboarding state from the local projection"

  def connect_accounts_kpi_label_overrides, do: "Overrides"

  def connect_accounts_kpi_delta_deauthorized_suffix, do: " deauthorized"

  def connect_accounts_kpi_meta_platform_fee_override,
    do: "Accounts carrying a local platform-fee override"

  def connect_accounts_table_column_account, do: "Account"

  def connect_accounts_table_column_owner, do: "Owner"

  def connect_accounts_table_column_readiness, do: "Readiness"

  def connect_accounts_table_column_override, do: "Override"

  def connect_accounts_table_column_status, do: "Status"

  def connect_accounts_filter_label_search, do: "Search"

  def connect_accounts_filter_label_type, do: "Type"

  def connect_accounts_filter_option_type_standard, do: "Standard"

  def connect_accounts_filter_option_type_express, do: "Express"

  def connect_accounts_filter_option_type_custom, do: "Custom"

  def connect_accounts_filter_label_charges, do: "Charges"

  def connect_accounts_filter_option_charges_enabled, do: "Enabled"

  def connect_accounts_filter_option_charges_disabled, do: "Disabled"

  def connect_accounts_filter_label_payouts, do: "Payouts"

  def connect_accounts_filter_option_payouts_enabled, do: "Enabled"

  def connect_accounts_filter_option_payouts_disabled, do: "Disabled"

  def connect_accounts_filter_label_onboarding, do: "Onboarding"

  def connect_accounts_filter_option_onboarding_submitted, do: "Submitted"

  def connect_accounts_filter_option_onboarding_pending, do: "Pending"

  def connect_accounts_filter_label_authorization, do: "Authorization"

  def connect_accounts_filter_option_authorization_deauthorized, do: "Deauthorized"

  def connect_accounts_filter_option_authorization_active, do: "Active"

  def connect_accounts_table_empty_title, do: "No connected accounts yet"

  def connect_accounts_table_empty_copy,
    do:
      "Stripe projections will appear here after your integration creates Connect accounts. Check webhooks and owner scope if you expect rows."

  def connect_accounts_apply_filters, do: "Apply filters"

  def connect_accounts_row_owner_fallback, do: "Owner"

  def connect_accounts_readiness_needs_onboarding, do: "Needs onboarding"

  def connect_accounts_readiness_joiner, do: " · "

  def connect_accounts_override_default_only, do: "Default only"

  def connect_accounts_override_saved, do: "Override saved"

  def connect_accounts_status_deauthorized_prefix, do: "Deauthorized · "

  def connect_accounts_status_no_email, do: "No email"

  def connect_accounts_error_view_failed,
    do:
      "This Connect view failed to load. Retry from the Connect list; if it persists, inspect logs for the owner scope you selected."

  # --- Detail (ConnectAccountLive) — prefix connect_account_*

  def connect_account_page_title, do: "Connect Account"

  def connect_account_breadcrumb_connect, do: "Connect"

  def connect_account_eyebrow, do: "Connect account detail"

  def connect_account_kpi_section_aria_label, do: "Connect account summary"

  def connect_account_kpi_label_charges, do: "Charges"

  def connect_account_kpi_meta_payouts_prefix, do: "Payouts: "

  def connect_account_kpi_label_onboarding, do: "Onboarding"

  def connect_account_kpi_meta_country_prefix, do: "Country: "

  def connect_account_kpi_label_override, do: "Override"

  def connect_account_override_state_saved, do: "Override saved"

  def connect_account_override_state_default_only, do: "Default only"

  def connect_account_kpi_meta_default_policy_prefix, do: "Default policy: "

  def connect_account_section_capabilities_eyebrow, do: "Capabilities"

  def connect_account_section_capabilities_heading, do: "Operator-safe account readiness"

  def connect_account_detail_label_owner, do: "Owner:"

  def connect_account_detail_label_email, do: "Email:"

  def connect_account_detail_label_capabilities, do: "Capabilities:"

  def connect_account_detail_label_requirements, do: "Requirements:"

  def connect_account_section_effective_fee_eyebrow, do: "Effective fee preview"

  def connect_account_section_effective_fee_heading, do: "Current default plus account override"

  def connect_account_detail_label_stored_override, do: "Stored override:"

  def connect_account_detail_label_preview_gross, do: "Preview gross:"

  def connect_account_detail_label_computed_fee, do: "Computed fee:"

  def connect_account_section_platform_fee_eyebrow, do: "Platform fee override"

  def connect_account_section_platform_fee_heading, do: "Save a per-account fee policy"

  def connect_account_section_platform_fee_body,
    do:
      "Empty fields fall back to the global `Accrue.Config` default. Validation and preview both use `Accrue.Connect.platform_fee/2` before anything is persisted."

  def connect_account_label_percent, do: "Percent"

  def connect_account_label_fixed_minor_units, do: "Fixed minor units"

  def connect_account_label_min_minor_units, do: "Min minor units"

  def connect_account_label_max_minor_units, do: "Max minor units"

  def connect_account_label_preview_gross_minor_units, do: "Preview gross minor units"

  def connect_account_label_preview_currency, do: "Preview currency"

  def connect_account_save_platform_fee_override, do: "Save platform fee override"

  def connect_account_flash_override_saved, do: "Platform fee override saved."

  def connect_account_override_state_no_override_saved, do: "No override saved"

  def connect_account_preview_fee_unable, do: "Unable to compute preview"

  def connect_account_preview_gross_invalid, do: "Invalid preview gross"

  def connect_account_status_deauthorized_prefix, do: "deauthorized "

  def connect_account_status_active_authorization, do: "active authorization"

  def connect_account_enabled_label_true, do: "Enabled"

  def connect_account_enabled_label_false, do: "Disabled"

  def connect_account_enabled_label_unknown, do: "Unknown"

  def connect_account_capabilities_none, do: "No capabilities projected"

  def connect_account_requirements_none, do: "No outstanding requirements"

  def connect_account_requirements_currently_due_prefix, do: "currently due: "

  def connect_account_error_preview_amount_invalid,
    do: "Preview amount must be an integer minor-unit amount"

  def connect_account_error_preview_currency_unknown,
    do: "Preview currency must be a known ISO code"

  def connect_account_error_field_must_be_decimal(field_label),
    do: "#{field_label} must be a decimal value"

  def connect_account_error_field_must_be_integer_minor(field_label),
    do: "#{field_label} must be an integer minor-unit amount"
end
