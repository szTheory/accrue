defmodule Accrue.Billing.CustomerLocaleTimezoneTest do
  @moduledoc """
  Phase 6 Plan 01 Task 2 — per-customer preferred_locale + preferred_timezone
  (D6-03). Columns are free-form strings with no validate_inclusion; the
  library cannot know which locales the host's CLDR backend compiled in.
  """
  use Accrue.BillingCase, async: true

  alias Accrue.Billing.Customer

  defp base_attrs(extras \\ %{}) do
    Map.merge(
      %{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_locale_#{System.unique_integer([:positive])}",
        email: "locale@example.com"
      },
      extras
    )
  end

  describe "schema surface" do
    test "__schema__(:fields) includes :preferred_locale and :preferred_timezone" do
      fields = Customer.__schema__(:fields)
      assert :preferred_locale in fields
      assert :preferred_timezone in fields
    end
  end

  describe "changeset/2 locale + timezone" do
    test "round-trips preferred_locale and preferred_timezone" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(
          base_attrs(%{
            preferred_locale: "en-US",
            preferred_timezone: "America/Los_Angeles"
          })
        )
        |> Repo.insert()

      reloaded = Repo.get!(Customer, customer.id)
      assert reloaded.preferred_locale == "en-US"
      assert reloaded.preferred_timezone == "America/Los_Angeles"
    end

    test "persists nil when both fields omitted" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(base_attrs())
        |> Repo.insert()

      reloaded = Repo.get!(Customer, customer.id)
      assert reloaded.preferred_locale == nil
      assert reloaded.preferred_timezone == nil
    end

    test "accepts an unknown-but-well-formed locale (no validate_inclusion per D6-03)" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(base_attrs(%{preferred_locale: "xx-YY"}))
        |> Repo.insert()

      assert customer.preferred_locale == "xx-YY"
    end

    test "accepts an unknown timezone string (no validate_inclusion)" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(base_attrs(%{preferred_timezone: "Atlantis/Midtown"}))
        |> Repo.insert()

      assert customer.preferred_timezone == "Atlantis/Midtown"
    end

    test "round-trips a BCP-47 long form like az-Cyrl-AZ" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(
          base_attrs(%{
            preferred_locale: "az-Cyrl-AZ",
            preferred_timezone: "Asia/Baku"
          })
        )
        |> Repo.insert()

      assert customer.preferred_locale == "az-Cyrl-AZ"
      assert customer.preferred_timezone == "Asia/Baku"
    end
  end
end
