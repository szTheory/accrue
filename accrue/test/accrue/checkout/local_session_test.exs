defmodule Accrue.Checkout.LocalSessionTest do
  use Accrue.BillingCase, async: false

  import Ecto.Changeset

  alias Accrue.Checkout.LocalSession
  alias Accrue.Test.CheckoutSessionFixture

  test "create_or_reuse/2 persists the phase 101 contract and reuses operation ids" do
    customer = CheckoutSessionFixture.build_customer()

    attrs = %{
      processor: "braintree",
      mode: "subscription",
      ui_mode: "hosted",
      price_id: "price_pro",
      line_items: [%{"price" => "price_pro"}],
      success_url: "https://app.example.test/billing/success",
      cancel_url: "https://app.example.test/billing/cancel",
      return_url: "https://app.example.test/settings/billing",
      operation_id: "checkout-op-1",
      metadata: %{"campaign" => "spring"},
      data: %{"local_portal" => true}
    }

    assert {:ok, created} = LocalSession.create_or_reuse(customer, attrs)
    assert created.customer_id == customer.id
    assert created.processor == "braintree"
    assert created.mode == "subscription"
    assert created.ui_mode == "hosted"
    assert created.status == "open"
    assert created.price_id == "price_pro"
    assert created.line_items == [%{"price" => "price_pro"}]
    assert created.success_url == "https://app.example.test/billing/success"
    assert created.cancel_url == "https://app.example.test/billing/cancel"
    assert created.return_url == "https://app.example.test/settings/billing"
    assert created.operation_id == "checkout-op-1"
    assert created.metadata == %{"campaign" => "spring"}
    assert created.data == %{"local_portal" => true}
    assert created.session_token =~ ~r/^chk_local_/
    assert %DateTime{} = created.expires_at

    assert {:ok, reused} = LocalSession.create_or_reuse(customer, attrs)
    assert reused.id == created.id
    assert LocalSession.by_token(created.session_token).id == created.id
    assert LocalSession.by_id(created.id).id == created.id
  end

  test "mark_completed/1 updates the persisted row" do
    customer = CheckoutSessionFixture.build_customer()
    session = CheckoutSessionFixture.local_session_fixture(customer)

    assert {:ok, completed} = LocalSession.mark_completed(session)
    assert completed.status == "completed"
    assert LocalSession.by_id(session.id).status == "completed"
  end

  test "unique constraints reject duplicate session tokens and operation ids" do
    customer = CheckoutSessionFixture.build_customer()
    session = CheckoutSessionFixture.local_session_fixture(customer, %{operation_id: "dup-op"})

    duplicate_token =
      LocalSession.changeset(%LocalSession{}, %{
        customer_id: customer.id,
        processor: "braintree",
        session_token: session.session_token,
        mode: "subscription",
        ui_mode: "hosted",
        status: "open",
        price_id: "price_dup",
        line_items: [%{"price" => "price_dup"}]
      })

    assert {:error, changeset} = Repo.insert(duplicate_token)
    assert "has already been taken" in errors_on(changeset).session_token

    duplicate_operation =
      LocalSession.changeset(%LocalSession{}, %{
        customer_id: customer.id,
        processor: "braintree",
        session_token:
          "chk_local_" <> Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false),
        mode: "subscription",
        ui_mode: "hosted",
        status: "open",
        price_id: "price_dup_2",
        line_items: [%{"price" => "price_dup_2"}],
        operation_id: "dup-op"
      })

    assert {:error, changeset} = Repo.insert(duplicate_operation)
    assert "has already been taken" in errors_on(changeset).operation_id
  end

  defp errors_on(changeset) do
    traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
