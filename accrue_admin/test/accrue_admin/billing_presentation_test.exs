defmodule AccrueAdmin.BillingPresentationTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.BillingPresentation

  describe "tax_health/1" do
    test "off when automatic tax is disabled and no risk flags" do
      assert :off ==
               BillingPresentation.tax_health(%{
                 "automatic_tax" => false,
                 "automatic_tax_disabled_reason" => nil,
                 "last_finalization_error_code" => nil
               })
    end

    test "active when automatic tax is enabled and no invalid signals" do
      assert :active ==
               BillingPresentation.tax_health(%{
                 "automatic_tax" => true,
                 "automatic_tax_disabled_reason" => nil,
                 "last_finalization_error_code" => nil
               })
    end

    test "invalid_or_blocked when finalization code is customer_tax_location_invalid" do
      assert :invalid_or_blocked ==
               BillingPresentation.tax_health(%{
                 "automatic_tax" => true,
                 "automatic_tax_disabled_reason" => nil,
                 "last_finalization_error_code" => "customer_tax_location_invalid"
               })
    end

    test "invalid_or_blocked wins when automatic tax is active but disabled reason is present" do
      assert :invalid_or_blocked ==
               BillingPresentation.tax_health(%{
                 "automatic_tax" => true,
                 "automatic_tax_disabled_reason" => "finalization_requires_location_inputs",
                 "last_finalization_error_code" => nil
               })
    end
  end

  describe "ownership_class/1" do
    test "classifies Organization rows" do
      assert :org == BillingPresentation.ownership_class(%{"owner_type" => "Organization"})
    end

    test "defaults other owner types to user" do
      assert :user == BillingPresentation.ownership_class(%{"owner_type" => "User"})
    end
  end
end
