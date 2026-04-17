defmodule Accrue.Billing.TaxLocationTest do
  use Accrue.BillingCase, async: false

  alias Accrue.APIError
  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Events.Event
  alias Accrue.Processor

  @repair_message "Please update customer address or shipping before enabling automatic tax."

  test "update_customer_tax_location/2 persists a sanitized local customer projection" do
    customer = insert_customer!(%{email: "tax-success@example.com", name: "Tax Success"})

    attrs = %{
      name: "Tax Success",
      email: "tax-success@example.com",
      metadata: %{"segment" => "beta"},
      address: %{
        line1: "27 Fredrick Ave",
        city: "Albany",
        state: "NY",
        postal_code: "12207",
        country: "US"
      },
      shipping: %{
        name: "Tax Success",
        address: %{
          line1: "27 Fredrick Ave",
          city: "Albany",
          state: "NY",
          postal_code: "12207",
          country: "US"
        }
      },
      phone: "+1-555-0100",
      tax: %{ip_address: "203.0.113.10"}
    }

    assert {:ok, updated} = Billing.update_customer_tax_location(customer, attrs)
    assert updated.name == "Tax Success"
    assert updated.email == "tax-success@example.com"
    assert updated.metadata == %{"segment" => "beta"}
    assert data_has_key?(updated.data, :id)
    assert data_has_key?(updated.data, :metadata)
    refute data_has_key?(updated.data, :address)
    refute data_has_key?(updated.data, :shipping)
    refute data_has_key?(updated.data, :phone)
    refute data_has_key?(updated.data, :tax)

    event =
      Repo.one!(
        from(e in Event,
          where: e.type == "customer.tax_location_updated" and e.subject_id == ^updated.id,
          order_by: [desc: e.inserted_at],
          limit: 1
        )
      )

    assert event.data["validate_location"] == "immediately"
    assert Enum.sort(event.data["changed_fields"]) == ["address", "phone", "shipping", "tax"]
    refute inspect(event.data) =~ "27 Fredrick Ave"
    refute inspect(event.data) =~ "203.0.113.10"
  end

  test "update_customer_tax_location/2 returns a stable invalid-location API error" do
    customer = insert_customer!(%{email: "tax-invalid@example.com", name: "Tax Invalid"})

    assert {:error, %APIError{} = error} =
             Billing.update_customer_tax_location(customer, %{
               address: %{line1: "27 Fredrick Ave", country: "US"},
               tax: %{ip_address: "203.0.113.10"}
             })

    assert error.code == "customer_tax_location_invalid"
    assert error.message =~ @repair_message
  end

  test "subscribe/3 with automatic_tax: true surfaces the same stable invalid-location error" do
    customer =
      insert_customer!(
        %{email: "sub-invalid@example.com", name: "Sub Invalid"},
        %{
          address: %{line1: "27 Fredrick Ave", country: "US"}
        }
      )

    assert {:error, %APIError{} = error} =
             Billing.subscribe(customer, "price_basic", automatic_tax: true)

    assert error.code == "customer_tax_location_invalid"
    assert error.message == @repair_message
  end

  defp insert_customer!(attrs, processor_attrs \\ %{}) do
    {:ok, processor_customer} =
      Processor.create_customer(
        Map.merge(
          %{
            email: attrs.email,
            name: attrs.name,
            metadata: attrs[:metadata] || %{}
          },
          processor_attrs
        ),
        []
      )

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: processor_customer.id,
        name: attrs.name,
        email: attrs.email,
        metadata: attrs[:metadata] || %{},
        data: %{id: processor_customer.id}
      })
      |> Repo.insert()

    customer
  end

  defp data_has_key?(data, key) when is_map(data) do
    Map.has_key?(data, key) or Map.has_key?(data, Atom.to_string(key))
  end
end
