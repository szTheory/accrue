defmodule Mix.Tasks.AccrueAdmin.ExportCopyStrings do
  @shortdoc "Export allow-listed AccrueAdmin.Copy strings as JSON for VERIFY-01 anti-drift checks"

  @moduledoc """
  Writes UTF-8 JSON `{\"function_name\" => \"returned string\"}` for a fixed allowlist of
  0-arity `AccrueAdmin.Copy` functions (including `defdelegate` targets).

  ## Example

      mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json

  """

  use Mix.Task

  @requirements ["app.config"]

  @allowlist ~w(
    subscription_drill_related_card_title
    subscription_drill_related_region_aria_label
    subscription_drill_link_customer
    subscription_drill_link_invoices_for_customer
    subscription_drill_link_charges_for_customer
    subscription_drill_link_events_index
    subscription_breadcrumb_subscriptions
    subscription_detail_eyebrow
    subscription_proration_create
    subscription_proration_none
    subscription_proration_always_invoice
    subscription_action_swap_plan
    subscription_action_cancel_at_period_end
    subscription_action_cancel_now
    subscription_action_resume
    subscription_action_update_quantity
    subscription_action_add_item
    subscription_action_update_item_quantity
    subscription_action_remove_item
    subscription_action_pause_collection
    subscription_action_create_comp_replacement
    subscription_action_default_guidance
    subscription_action_exception_guidance
    subscription_action_braintree_guidance
    subscription_action_braintree_swap_setup_guidance
    subscription_action_braintree_quantity_item_guidance
    subscription_action_stripe_guidance
    subscription_action_supported_change_guidance
    subscription_action_preview_heading
    subscription_action_preview_total_label
    subscription_action_item_id_label
    subscription_action_quantity_label
    subscription_action_single_item_quantity_guidance
    subscriptions_index_empty_title
    connect_accounts_headline
    connect_accounts_list_heading
    connect_accounts_table_empty_title
    connect_accounts_apply_filters
    connect_account_eyebrow
    connect_account_actions_heading
    connect_account_action_edit_platform_fee_override
    connect_account_save_platform_fee_override
    invoice_detail_eyebrow
    invoice_open_pdf_button
    invoices_index_headline
    invoices_list_heading
    data_table_clear_filters_label
    billing_events_heading_organization
    events_list_heading
    billing_events_table_empty_title
    billing_events_apply_filters
    coupon_index_headline
    coupons_list_heading
    promotion_codes_index_headline
    promotion_codes_list_heading
    customer_payment_methods_section_heading
    customer_payment_methods_empty_copy
    customer_payment_methods_section_body
    customer_payment_methods_row_fallback_label
    customer_payment_methods_card_last4_mask
    customer_payment_methods_sync_action
    customer_payment_methods_sync_success
    customer_payment_methods_set_default_action
    customer_payment_methods_set_default_success
    customer_payment_methods_delete_action
    customer_payment_methods_delete_success
    customer_payment_methods_delete_warning
    customer_payment_methods_cancel_action
    customer_payment_methods_delete_blocked_in_use
    customer_payment_methods_delete_blocked_replacement_required
    customer_payment_methods_replace_handoff
    customer_payment_methods_default_badge
    customer_payment_methods_in_use_badge
    entitlements_section_title
    entitlements_drift_section_title
    entitlements_active_plans_label
    entitlements_features_label
    entitlements_quantities_label
    entitlements_grace_label
    entitlements_unmapped_badge
    entitlements_unmapped_hint
    entitlements_empty_title
    entitlements_empty_copy
    entitlements_no_drift_copy
    entitlements_raw_map_label
    entitlements_error_copy
  )a

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [out: :string], aliases: [o: :out])

    out_path =
      case opts[:out] do
        nil ->
          Mix.raise("mix accrue_admin.export_copy_strings requires --out PATH")

        path ->
          path
      end

    Mix.Task.run("compile")

    exports = AccrueAdmin.Copy.__info__(:functions)

    map =
      for name <- @allowlist,
          {^name, 0} <- exports,
          into: %{} do
        {Atom.to_string(name), apply(AccrueAdmin.Copy, name, [])}
      end

    File.mkdir_p!(Path.dirname(out_path))
    File.write!(out_path, Jason.encode!(map) <> "\n")
    Mix.shell().info("Wrote #{map_size(map)} copy strings to #{out_path}")
  end
end
