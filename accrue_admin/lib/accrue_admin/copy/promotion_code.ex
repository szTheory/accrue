defmodule AccrueAdmin.Copy.PromotionCode do
  @moduledoc false

  def promotion_codes_breadcrumb_index, do: "Promotion codes"

  def promotion_codes_index_eyebrow, do: "Discount management"

  def promotion_codes_index_headline, do: "Promotion codes as a dedicated admin surface"

  def promotion_codes_index_body_primary,
    do:
      "Promotion codes are searchable independently from coupons, with direct links back to their parent discount definition."

  def promotion_codes_index_kpi_section_aria_label, do: "Promotion code summary"

  def promotion_codes_kpi_label_codes, do: "Codes"

  def promotion_codes_kpi_meta_all_local_rows, do: "All local promotion code rows"

  def promotion_codes_kpi_label_active, do: "Active"

  def promotion_codes_kpi_inactive_suffix, do: " inactive"

  def promotion_codes_kpi_meta_activation_state, do: "Operator-visible activation state"

  def promotion_codes_kpi_label_expiring, do: "Expiring"

  def promotion_codes_kpi_redemptions_suffix, do: " redemptions"

  def promotion_codes_kpi_meta_expiring, do: "Codes with an explicit expiry timestamp"

  def promotion_codes_table_column_code, do: "Promotion code"

  def promotion_codes_table_column_coupon, do: "Coupon"

  def promotion_codes_table_column_status, do: "Status"

  def promotion_codes_table_column_redemptions, do: "Redemptions"

  def promotion_codes_table_column_expires, do: "Expires"

  def promotion_codes_filter_label_search, do: "Search"

  def promotion_codes_filter_label_status, do: "Status"

  def promotion_codes_filter_option_active, do: "Active"

  def promotion_codes_filter_option_inactive, do: "Inactive"

  def promotion_codes_filter_label_coupon_id, do: "Coupon id"

  def promotion_codes_table_empty_title, do: "No promotion codes matched"

  def promotion_codes_table_empty_copy, do: "Adjust the code filters or wait for the next projection sync."

  def promotion_codes_page_title_index, do: "Promotion Codes"

  def promotion_code_detail_eyebrow, do: "Promotion code detail"

  def promotion_code_detail_kpi_section_aria_label, do: "Promotion code summary"

  def promotion_code_kpi_label_coupon, do: "Coupon"

  def promotion_code_kpi_meta_parent_discount, do: "Parent discount definition"

  def promotion_code_kpi_label_redemptions, do: "Redemptions"

  def promotion_code_kpi_label_expires, do: "Expires"

  def promotion_code_kpi_meta_expiry_boundary, do: "Operator-visible expiry boundary"

  def promotion_code_section_parent_coupon_eyebrow, do: "Parent coupon"

  def promotion_code_section_navigate_heading, do: "Navigate back to the discount definition"

  def promotion_code_detail_no_coupon_projection, do: "No coupon projection is linked to this promotion code."

  def promotion_code_json_payload_label, do: "Promotion code payload"

  def promotion_code_page_title_show, do: "Promotion Code"

  def promotion_codes_coupon_none_label, do: "No coupon linked"

  def promotion_codes_status_active, do: "Active"

  def promotion_codes_status_inactive, do: "Inactive"

  def promotion_codes_status_active_expires_separator, do: "Active · expires "

  def promotion_code_redeem_by_no_expiry, do: "No expiry"

  def promotion_codes_expires_summary_no_expiry, do: "No expiry"

  def promotion_code_kpi_meta_unlimited_cap, do: "Unlimited cap"
end
