defmodule AccruePortal.BillingReadModel do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.{Charge, Customer, Invoice, PaymentMethod, Subscription}
  alias Accrue.Repo

  def dashboard(%Customer{} = customer) do
    %{
      subscriptions: subscription_result(customer),
      payment_methods: payment_method_result(customer),
      invoices: invoice_result(customer)
    }
  end

  def subscriptions(%Customer{id: customer_id}) do
    list_subscriptions(customer_id)
  end

  @doc "Returns a distinct successful or unavailable outcome for customer-facing subscription reads."
  def subscription_result(%Customer{} = customer) do
    reader =
      Application.get_env(
        :accrue_portal,
        :subscription_reader,
        fn %Customer{id: customer_id} -> list_subscriptions(customer_id) end
      )

    case reader.(customer) do
      {:ok, subscriptions} when is_list(subscriptions) -> {:ok, subscriptions}
      subscriptions when is_list(subscriptions) -> {:ok, subscriptions}
      {:error, _reason} -> {:error, :unavailable}
      _ -> {:error, :unavailable}
    end
  rescue
    _exception in [DBConnection.ConnectionError, Postgrex.Error] -> {:error, :unavailable}
  end

  defp list_subscriptions(customer_id) do
    from(subscription in Subscription,
      where: subscription.customer_id == ^customer_id,
      order_by: [desc: subscription.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:subscription_items)
  end

  def subscription(%Customer{} = customer, id) when is_binary(id) do
    lookup =
      Application.get_env(
        :accrue_portal,
        :subscription_lookup,
        fn %Customer{id: customer_id}, subscription_id ->
          Repo.get_by(Subscription, id: subscription_id, customer_id: customer_id)
        end
      )

    case lookup.(customer, id) do
      {:ok, %Subscription{} = subscription} ->
        {:ok, Repo.preload(subscription, :subscription_items)}

      %Subscription{} = subscription ->
        {:ok, Repo.preload(subscription, :subscription_items)}

      nil ->
        {:error, :not_found}

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, _reason} ->
        {:error, :unavailable}

      _ ->
        {:error, :unavailable}
    end
  rescue
    _exception in [DBConnection.ConnectionError, Postgrex.Error] -> {:error, :unavailable}
  end

  @doc "Whether this subscription has a currently supported customer-facing cancellation mode."
  def subscription_cancel_available?(%Subscription{} = subscription) do
    capabilities = processor_capabilities(subscription.processor)

    cancellation_supported? =
      Accrue.Processor.Capabilities.supports?(capabilities, [:subscription, :cancel]) and
        if(subscription.processor == "braintree",
          do:
            Accrue.Processor.Capabilities.supports?(
              capabilities,
              [:subscription, :cancel_immediately]
            ),
          else:
            Accrue.Processor.Capabilities.supports?(
              capabilities,
              [:subscription, :cancel_at_period_end]
            )
        )

    cancellation_supported? and cancellation_state_eligible?(subscription)
  end

  @doc "Whether this subscription has a supported self-serve plan-change preview and commit."
  def subscription_plan_change_available?(%Subscription{} = subscription) do
    capabilities = processor_capabilities(subscription.processor)

    Accrue.Processor.Capabilities.supports?(capabilities, [:subscription, :swap_plan]) and
      Accrue.Processor.Capabilities.supports?(
        capabilities,
        [:invoice, :preview_upcoming_invoice]
      ) and
      Subscription.active?(subscription) and not Subscription.paused?(subscription) and
      not Subscription.canceled?(subscription) and subscription.cancel_at_period_end == false and
      is_nil(subscription.cancel_at)
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

  @doc "Returns a distinct successful or unavailable outcome for customer-facing card reads."
  def payment_method_result(%Customer{} = customer) do
    cond do
      not current_processor?(customer) ->
        {:error, :unsupported}

      not Accrue.Processor.supports?([:payment_method, :list]) ->
        {:error, :unsupported}

      true ->
        reader =
          Application.get_env(
            :accrue_portal,
            :payment_method_reader,
            &Accrue.Billing.list_payment_methods/1
          )

        case reader.(customer) do
          {:ok, methods} when is_list(methods) -> {:ok, methods}
          methods when is_list(methods) -> {:ok, methods}
          {:error, _reason} -> {:error, :unavailable}
          _ -> {:error, :unavailable}
        end
    end
  rescue
    _exception in [DBConnection.ConnectionError, Postgrex.Error] -> {:error, :unavailable}
  end

  defp current_processor?(%Customer{processor: customer_processor}) do
    processor = Accrue.Processor.__impl__()
    customer_processor == processor.processor_name()
  rescue
    _ -> false
  end

  def payment_method(%Customer{id: customer_id}, id) when is_binary(id) do
    case Repo.get_by(PaymentMethod, id: id, customer_id: customer_id) do
      %PaymentMethod{} = payment_method -> {:ok, payment_method}
      nil -> {:error, :not_found}
    end
  end

  def payment_method!(%Customer{id: customer_id}, id) do
    Repo.get_by!(PaymentMethod, id: id, customer_id: customer_id)
  end

  def invoices(%Customer{id: customer_id}) do
    list_invoices(customer_id)
  end

  @doc "Returns an explicit invoice read outcome for customer-facing surfaces."
  def invoice_result(%Customer{id: customer_id}) do
    reader = Application.get_env(:accrue_portal, :invoice_reader, &list_invoices/1)

    case reader.(customer_id) do
      {:ok, invoices} when is_list(invoices) -> {:ok, invoices}
      invoices when is_list(invoices) -> {:ok, invoices}
      {:error, _reason} -> {:error, :unavailable}
      _ -> {:error, :unavailable}
    end
  rescue
    _exception in [DBConnection.ConnectionError, Postgrex.Error] ->
      {:error, :unavailable}
  end

  defp list_invoices(customer_id) do
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

  defp cancellation_state_eligible?(%Subscription{} = subscription) do
    (Subscription.active?(subscription) or Subscription.past_due?(subscription)) and
      not Subscription.paused?(subscription) and not Subscription.canceled?(subscription) and
      subscription.cancel_at_period_end == false and is_nil(subscription.cancel_at) and
      (subscription.processor == "braintree" or
         match?(%DateTime{}, subscription.current_period_end))
  end

  defp processor_capabilities("fake"),
    do: Accrue.Processor.Capabilities.for(Accrue.Processor.Fake)

  defp processor_capabilities("stripe"),
    do: Accrue.Processor.Capabilities.for(Accrue.Processor.Stripe)

  defp processor_capabilities("braintree"),
    do: Accrue.Processor.Capabilities.for(Accrue.Processor.Braintree)

  defp processor_capabilities(_), do: %{}
end
