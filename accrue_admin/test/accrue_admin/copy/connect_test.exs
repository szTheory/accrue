defmodule AccrueAdmin.Copy.ConnectTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Copy

  test "connect index empty state matches UI-SPEC" do
    assert Copy.connect_accounts_table_empty_title() == "No connected accounts yet"

    assert String.starts_with?(
             Copy.connect_accounts_table_empty_copy(),
             "Stripe projections will appear here"
           )
  end

  test "connect primary and secondary CTAs match UI-SPEC" do
    assert Copy.connect_account_save_platform_fee_override() == "Save platform fee override"
    assert Copy.connect_accounts_apply_filters() == "Apply filters"
  end

  test "generic Connect error copy matches UI-SPEC prefix" do
    assert String.starts_with?(
             Copy.connect_accounts_error_view_failed(),
             "This Connect view failed to load"
           )
  end
end
