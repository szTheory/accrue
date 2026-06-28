defmodule AccrueAdmin.Copy.Coupon do
  @moduledoc false

  def coupon_breadcrumb_coupons, do: "Coupons"

  def coupon_index_eyebrow, do: "Discount management"

  def coupon_index_headline, do: "Coupons"

  def coupon_index_body_primary,
    do:
      "Discounts you can apply to subscriptions and invoices. Filter by validity or search to find a coupon and see how often it's been redeemed."

  def coupons_list_heading, do: "Review usable discounts"

  def coupons_list_subtitle, do: "Check which coupon definitions can still be applied."

  def coupons_list_first_run_empty_title, do: "No coupons yet."

  def coupons_list_first_run_empty_body,
    do: "Coupons appear after discount definitions sync locally."

  def coupons_list_queue_empty_title, do: "No valid coupons."

  def coupons_list_queue_empty_body,
    do: "View all coupons to inspect invalid or expired definitions."

  def coupons_list_filtered_empty_title, do: "No coupons match these filters."

  def coupons_list_filtered_empty_body,
    do: "Clear filters or adjust the search to see coupons."

  def coupons_list_loading_label, do: "Loading coupons."

  def coupons_list_default_lens_label, do: "Valid coupons"

  def coupons_list_all_lens_label, do: "All coupons"

  def coupons_list_result_label_pair, do: {"coupon", "coupons"}

  def coupon_index_body_link_prefix, do: "Promotion codes have their own list and detail surface:"

  def coupon_index_promotion_codes_link_text, do: "open promotion codes"

  def coupon_index_kpi_section_aria_label, do: "Coupon summary"

  def coupon_kpi_label_coupons, do: "Coupons"

  def coupon_kpi_meta_all_local_coupons, do: "All local coupon rows"

  def coupon_kpi_label_valid, do: "Valid"

  def coupon_kpi_invalid_suffix, do: " invalid"

  def coupon_kpi_meta_validity_projection, do: "Current validity flag from the local projection"

  def coupon_kpi_label_promotion_codes, do: "Promotion codes"

  def coupon_kpi_meta_promotion_codes_child,
    do: "Separate child-code surface linked back to coupons"

  def coupon_kpi_redemptions_suffix, do: " coupon redemptions"

  def coupon_table_column_coupon, do: "Coupon"

  def coupon_table_column_discount, do: "Discount"

  def coupon_table_column_redemptions, do: "Redemptions"

  def coupon_table_column_status, do: "Status"

  def coupon_table_column_redeem_by, do: "Redeem by"

  def coupon_filter_label_search, do: "Search"

  def coupon_filter_label_validity, do: "Validity"

  def coupon_filter_option_valid, do: "Valid"

  def coupon_filter_option_invalid, do: "Invalid"

  def coupon_table_empty_title, do: "No coupons matched"

  def coupon_table_empty_copy,
    do: "Adjust the discount filters or wait for the next projection sync."

  def coupon_page_title_index, do: "Coupons"

  def coupon_detail_eyebrow, do: "Coupon detail"

  def coupon_detail_kpi_section_aria_label, do: "Coupon summary"

  def coupon_kpi_label_redemptions, do: "Redemptions"

  def coupon_detail_section_promotion_codes_eyebrow, do: "Promotion codes"

  def coupon_detail_section_codes_heading, do: "Codes linked to this coupon"

  def coupon_detail_promotion_codes_empty,
    do: "No promotion codes currently reference this coupon."

  def coupon_detail_section_projection_eyebrow, do: "Projection details"

  def coupon_detail_section_projection_heading, do: "Coupon metadata and processor mirror"

  def coupon_detail_label_duration, do: "Duration:"

  def coupon_detail_label_currency, do: "Currency:"

  def coupon_detail_label_processor, do: "Processor:"

  def coupon_json_payload_label, do: "Coupon payload"

  def coupon_kpi_meta_redemptions_cap, do: "Unlimited cap"

  def coupon_kpi_meta_promotion_codes_linked, do: "Explicit child codes linked to this coupon"

  def coupon_kpi_label_redeem_by, do: "Redeem by"

  def coupon_kpi_meta_redeem_by, do: "Local expiry boundary for operator review"

  def coupon_page_title_show, do: "Coupon"

  def coupon_status_valid, do: "Valid"

  def coupon_status_invalid, do: "Invalid"

  def coupon_redeem_by_no_expiry, do: "No expiry"

  def coupon_discount_processor_defined, do: "Processor-defined"

  def coupon_promotion_code_status_active, do: "Active"

  def coupon_promotion_code_status_inactive, do: "Inactive"

  def coupon_promotion_code_status_active_until_prefix, do: "Active until "

  def coupon_not_found,
    do: "Coupon not found. Open the coupons list and confirm owner scope before retrying."
end
