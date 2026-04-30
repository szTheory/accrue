defmodule Accrue.Billing.PaymentMethodActionsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.Processor.Fake

  setup do
    previous = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_pm_guard",
        email: "pm-guard@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  test "list_payment_methods/2 returns the local projection", %{customer: customer} do
    assert {:ok, []} = Billing.list_payment_methods(customer, [])
  end

  test "list_payment_methods!/2 returns the local projection", %{customer: customer} do
    assert [] = Billing.list_payment_methods!(customer, [])
  end

  test "canonical payment-method CRUD verbs are exported from Accrue.Billing" do
    exports = Accrue.Billing.module_info(:exports)

    assert {:add_payment_method, 3} in exports
    assert {:add_payment_method!, 3} in exports
    assert {:update_payment_method, 3} in exports
    assert {:update_payment_method!, 3} in exports
    assert {:delete_payment_method, 2} in exports
    assert {:delete_payment_method!, 2} in exports
    assert {:sync_payment_methods, 2} in exports
    assert {:sync_payment_methods!, 2} in exports
  end

  test "delete_payment_method/2 preserves processor-scoped opts", %{customer: customer} do
    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm("pm_delete_opts", "4242")})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm("pm_delete_opts", "4242")})
    {:ok, payment_method} = Billing.attach_payment_method(customer, "pm_delete_opts")

    parent = self()

    Fake.stub(:detach_payment_method, fn id, opts ->
      send(parent, {:detach_payment_method, id, opts})
      {:ok, scripted_pm(id, "4242")}
    end)

    Fake.stub(:list_payment_methods, fn _params, opts ->
      send(parent, {:list_payment_methods, opts})
      {:ok, %{data: []}}
    end)

    assert {:ok, _deleted} =
             Billing.delete_payment_method(payment_method, actor: %{id: "admin_1"}, scope: :test_scope)

    assert_receive {:detach_payment_method, "pm_delete_opts", opts}
    assert opts[:actor] == %{id: "admin_1"}
    assert opts[:scope] == :test_scope

    assert_receive {:list_payment_methods, opts}
    assert opts[:actor] == %{id: "admin_1"}
    assert opts[:scope] == :test_scope
  end

  defp scripted_pm(id, last4) do
    %{
      id: id,
      type: "card",
      metadata: %{},
      card: %{
        brand: "visa",
        last4: last4,
        exp_month: 1,
        exp_year: 2032,
        fingerprint: "fp_#{id}"
      }
    }
  end
end
