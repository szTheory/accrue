defmodule AccruePortal.BillingReadModel do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.{Charge, Customer, Invoice, PaymentMethod, Subscription}
  alias Accrue.Repo

  def dashboard(%Customer{} = customer) do
    %{
      subscriptions: subscriptions(customer),
      payment_methods: payment_methods(customer),
      invoices: invoices(customer),
      charges: charges(customer)
    }
  end

  def subscriptions(%Customer{id: customer_id}) do
    from(subscription in Subscription,
      where: subscription.customer_id == ^customer_id,
      order_by: [desc: subscription.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:subscription_items)
  end

  def subscription(%Customer{id: customer_id}, id) when is_binary(id) do
    case Repo.get_by(Subscription, id: id, customer_id: customer_id) do
      %Subscription{} = subscription ->
        {:ok, Repo.preload(subscription, :subscription_items)}

      nil ->
        {:error, :not_found}
    end
  end

  def active_subscription(%Customer{} = customer) do
    customer
    |> subscriptions()
    |> Enum.find(&Subscription.active?/1)
  end

  def payment_methods(%Customer{} = customer) do
    {:ok, methods} = Accrue.Billing.list_payment_methods(customer)
    methods
  end

  def payment_method!(%Customer{id: customer_id}, id) do
    Repo.get_by!(PaymentMethod, id: id, customer_id: customer_id)
  end

  def invoices(%Customer{id: customer_id}) do
    from(invoice in Invoice,
      where: invoice.customer_id == ^customer_id,
      order_by: [desc: invoice.inserted_at],
      limit: 20
    )
    |> Repo.all()
  end

  def charges(%Customer{id: customer_id}) do
    from(charge in Charge,
      where: charge.customer_id == ^customer_id,
      order_by: [desc: charge.inserted_at],
      limit: 20
    )
    |> Repo.all()
  end
end
