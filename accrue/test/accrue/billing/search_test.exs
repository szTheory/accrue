defmodule Accrue.Billing.SearchTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Search
  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.Invoice

  defp insert_customer(attrs \\ %{}) do
    default_attrs = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_#{System.unique_integer([:positive])}",
      name: "Default Name",
      email: "default@example.com"
    }

    struct!(Customer, Map.merge(default_attrs, attrs))
    |> Repo.insert!()
  end

  describe "search_customers/2" do
    test "returns customers matching by email or name, sorted by similarity" do
      _c1 = insert_customer(%{name: "Alice Smith", email: "alice@example.com"})
      c2 = insert_customer(%{name: "Robert Jones", email: "rob.jones@example.com"})
      c3 = insert_customer(%{name: "Robert Tables", email: "robert@example.com"})

      # "robert" should match both c2 and c3.
      results = Search.search_customers(Customer, "robert") |> Repo.all()
      assert length(results) >= 2

      results_specific = Search.search_customers(Customer, "robert tables") |> Repo.all()
      assert hd(results_specific).id == c3.id

      results_email = Search.search_customers(Customer, "rob.jones@") |> Repo.all()
      assert hd(results_email).id == c2.id
    end
  end

  describe "search_subscriptions/2" do
    test "returns subscriptions matching by processor_id" do
      customer = insert_customer()

      s1 =
        %Subscription{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "sub_12345XYZ",
          status: :active
        }
        |> Repo.insert!()

      _s2 =
        %Subscription{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "sub_99999ABC",
          status: :active
        }
        |> Repo.insert!()

      results = Search.search_subscriptions(Subscription, "12345XYZ") |> Repo.all()
      assert length(results) == 1
      assert hd(results).id == s1.id
    end
  end

  describe "search_invoices/2" do
    test "returns invoices matching by processor_id or number" do
      customer = insert_customer()

      sub =
        %Subscription{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "sub_test",
          status: :active
        }
        |> Repo.insert!()

      i1 =
        %Invoice{
          customer_id: customer.id,
          subscription_id: sub.id,
          processor: "fake",
          processor_id: "in_abc123",
          number: "INV-0001",
          status: :open
        }
        |> Repo.insert!()

      i2 =
        %Invoice{
          customer_id: customer.id,
          subscription_id: sub.id,
          processor: "fake",
          processor_id: "in_def456",
          number: "INV-0002",
          status: :open
        }
        |> Repo.insert!()

      results_proc = Search.search_invoices(Invoice, "def456") |> Repo.all()
      assert length(results_proc) == 1
      assert hd(results_proc).id == i2.id

      results_num = Search.search_invoices(Invoice, "0001") |> Repo.all()
      assert length(results_num) == 1
      assert hd(results_num).id == i1.id
    end
  end
end
