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

  test "fee review copy separates stored observations and local policy" do
    assert Copy.Connect.connect_account_section_platform_fee_body() =~
             "does not update Stripe readiness or capabilities"

    assert Copy.Connect.connect_account_provider_snapshot_note() =~ "last stored Stripe snapshot"

    assert Copy.Connect.connect_account_provider_snapshot_note() =~
             "does not track when Stripe last reported them"

    assert Copy.Connect.connect_account_drawer_subtitle() =~
             "Cancel closes this review without saving"

    assert Copy.Connect.connect_account_review_stale() =~ "changed after review"
    assert Copy.Connect.connect_account_override_unchanged() =~ "already matches this policy"

    assert Copy.Connect.connect_account_default_policy_unavailable() ==
             "No default fee policy configured"

    assert Copy.Connect.connect_account_proposed_use_default() ==
             "Remove local override; use the global default"

    assert Copy.Connect.connect_account_back_to_connect() == "Back to Connect accounts"
  end
end
