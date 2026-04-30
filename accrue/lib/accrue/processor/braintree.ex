defmodule Accrue.Processor.Braintree do
  @moduledoc """
  Production Braintree adapter for the gateway subscription core slice.
  """

  @behaviour Accrue.Processor

  alias Accrue.APIError

  @impl Accrue.Processor
  def processor_name, do: "braintree"

  @impl Accrue.Processor
  def capabilities do
    %{
      payment_method: %{
        vault_acquisition: true,
        create: true,
        list: true,
        update: true,
        delete: true,
        set_default: true
      },
      subscription: %{
        direct_create: true,
        cancel: true,
        fetch: true,
        lifecycle_webhook_projection: true,
        update: true,
        cancel_at_period_end: false,
        cancel_immediately: true,
        pause: false,
        resume: false
      },
      invoice: %{lifecycle_webhook_projection: true},
      webhook: %{verify: true, parse: true}
    }
  end

  @impl Accrue.Processor
  def create_subscription(params, opts) when is_map(params) and is_list(opts) do
    braintree_params = build_request(params)

    case subscription_gateway().create(braintree_params, opts) do
      {:ok, sub} -> {:ok, translate_subscription(sub)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def retrieve_subscription(id, opts) when is_binary(id) and is_list(opts) do
    case subscription_gateway().find(id, opts) do
      {:ok, sub} -> {:ok, translate_subscription(sub)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def fetch(:subscription, id), do: retrieve_subscription(id, [])
  def fetch(_type, _id), do: {:error, unsupported()}

  @doc false
  def build_request(params) do
    payment_method = params[:payment_method] || params["payment_method"] || %{}
    vault = payment_method[:vault_acquisition] || payment_method["vault_acquisition"] || %{}
    token = vault[:reference] || vault["reference"]

    items = params[:items] || params["items"] || []
    first_item = List.first(items) || %{}
    plan_id = first_item[:price] || first_item["price"]

    %{
      payment_method_token: token,
      plan_id: plan_id
    }
  end

  @doc false
  def translate_subscription(%Braintree.Subscription{} = sub) do
    sub
    |> Map.from_struct()
    |> Map.put(:items, translated_items(sub))
  end
  # Customer
  @impl Accrue.Processor
  def create_customer(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def retrieve_customer(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def update_customer(_id, _params, _opts), do: {:error, unsupported()}

  # Subscription
  @impl Accrue.Processor
  def update_subscription(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    with {:ok, braintree_params} <- translate_update_params(params),
         {:ok, sub} <- subscription_gateway().update(id, braintree_params, opts) do
      {:ok, translate_subscription(sub)}
    else
      {:error, %APIError{} = error} -> {:error, error}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def cancel_subscription(id, opts) when is_binary(id) and is_list(opts) do
    case subscription_gateway().cancel(id, opts) do
      {:ok, sub} -> {:ok, translate_subscription(sub)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def cancel_subscription(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    with :ok <- validate_cancel_params(params),
         {:ok, sub} <- subscription_gateway().cancel(id, opts) do
      {:ok, translate_subscription(sub)}
    else
      {:error, %APIError{} = error} -> {:error, error}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def resume_subscription(_id, _opts), do: {:error, unsupported_semantic("resume")}

  @impl Accrue.Processor
  def pause_subscription_collection(_id, _behavior, _params, _opts),
    do: {:error, unsupported_semantic("pause collection")}

  # Invoice
  @impl Accrue.Processor
  def create_invoice(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def retrieve_invoice(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def update_invoice(_id, _params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def finalize_invoice(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def void_invoice(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def pay_invoice(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def send_invoice(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def mark_uncollectible_invoice(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def create_invoice_preview(_params, _opts), do: {:error, unsupported()}

  # PaymentIntent
  @impl Accrue.Processor
  def create_payment_intent(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def retrieve_payment_intent(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def confirm_payment_intent(_id, _params, _opts), do: {:error, unsupported()}

  # SetupIntent
  @impl Accrue.Processor
  def create_setup_intent(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def retrieve_setup_intent(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def confirm_setup_intent(_id, _params, _opts), do: {:error, unsupported()}

  # PaymentMethod
  @impl Accrue.Processor
  def create_payment_method(params, opts) when is_map(params) and is_list(opts) do
    with {:ok, request} <- translate_payment_method_create(params),
         {:ok, payment_method} <- payment_method_gateway().create(request, opts) do
      {:ok, translate_payment_method(payment_method)}
    else
      {:error, %APIError{} = error} -> {:error, error}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def retrieve_payment_method(id, opts) when is_binary(id) and is_list(opts) do
    case payment_method_gateway().find(id, opts) do
      {:ok, payment_method} -> {:ok, translate_payment_method(payment_method)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def attach_payment_method(_id, _params, _opts), do: {:error, unsupported()}

  @impl Accrue.Processor
  def detach_payment_method(id, opts) when is_binary(id) and is_list(opts) do
    case payment_method_gateway().delete(id, opts) do
      :ok -> {:ok, %{id: id}}
      {:ok, %{token: token}} -> {:ok, %{id: token}}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def list_payment_methods(%{customer: customer_id}, opts) when is_binary(customer_id) and is_list(opts) do
    case customer_gateway().find(customer_id, opts) do
      {:ok, customer} -> {:ok, %{data: translate_customer_payment_methods(customer)}}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  def list_payment_methods(_params, _opts),
    do: {:error, invalid_request("Braintree payment-method listing requires a customer id.")}

  @impl Accrue.Processor
  def update_payment_method(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    with {:ok, request} <- translate_payment_method_update(id, params),
         {:ok, payment_method} <- payment_method_gateway().update(id, request, opts) do
      {:ok, translate_payment_method(payment_method)}
    else
      {:error, %APIError{} = error} -> {:error, error}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def set_default_payment_method(customer_id, params, opts)
      when is_binary(customer_id) and is_map(params) and is_list(opts) do
    payment_method_id =
      get_in(params, [:invoice_settings, :default_payment_method]) ||
        get_in(params, ["invoice_settings", "default_payment_method"])

    with id when is_binary(id) <- payment_method_id,
         {:ok, _customer} <-
           customer_gateway().update(customer_id, %{default_payment_method_token: id}, opts) do
      {:ok, %{id: customer_id, default_payment_method: id}}
    else
      nil ->
        {:error,
         invalid_request(
           "Braintree set_default_payment_method requires invoice_settings.default_payment_method."
         )}

      {:error, raw} ->
        {:error, to_accrue_error(raw)}
    end
  end

  # Charge
  @impl Accrue.Processor
  def create_charge(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def retrieve_charge(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def list_charges(_params, _opts), do: {:error, unsupported()}

  # Refund
  @impl Accrue.Processor
  def create_refund(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def retrieve_refund(_id, _opts), do: {:error, unsupported()}

  # Meter event
  @impl Accrue.Processor
  def report_meter_event(_event), do: {:error, unsupported()}

  # Subscription items
  @impl Accrue.Processor
  def subscription_item_create(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def subscription_item_update(_id, _params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def subscription_item_delete(_id, _params, _opts), do: {:error, unsupported()}

  # Subscription schedules
  @impl Accrue.Processor
  def subscription_schedule_create(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def subscription_schedule_update(_id, _params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def subscription_schedule_release(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def subscription_schedule_cancel(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def subscription_schedule_fetch(_id, _opts), do: {:error, unsupported()}

  # Coupons + Promotion Codes
  @impl Accrue.Processor
  def coupon_create(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def coupon_retrieve(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def promotion_code_create(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def promotion_code_retrieve(_id, _opts), do: {:error, unsupported()}

  # Checkout + Customer Portal
  @impl Accrue.Processor
  def checkout_session_create(_params, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def checkout_session_fetch(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def portal_session_create(_params, _opts), do: {:error, unsupported()}

  # --- Translation Helpers ---

  defp to_accrue_error(raw) do
    %APIError{
      code: "braintree_error",
      http_status: 400,
      message: inspect(raw)
    }
  end

  defp translate_update_params(params) do
    cond do
      Map.has_key?(params, :items) or Map.has_key?(params, "items") ->
        translate_item_update(params[:items] || params["items"])

      truthy?(params[:cancel_at_period_end] || params["cancel_at_period_end"]) ->
        {:error, unsupported_semantic("cancel at period end")}

      Map.has_key?(params, :cancel_at) or Map.has_key?(params, "cancel_at") ->
        {:error, unsupported_semantic("scheduled cancellation")}

      Map.has_key?(params, :pause_collection) or Map.has_key?(params, "pause_collection") ->
        {:error, unsupported_semantic("pause collection")}

      true ->
        {:error, invalid_request("Unsupported Braintree subscription update payload: #{inspect(params)}")}
    end
  end

  defp translate_item_update([item]) when is_map(item) do
    cond do
      quantity = item[:quantity] || item["quantity"] ->
        {:error,
         invalid_request(
           "Braintree subscriptions do not expose Accrue's quantity mutation semantics; " <>
             "requested quantity #{inspect(quantity)} is unsupported."
         )}

      plan_id = item[:price] || item["price"] ->
        {:ok, %{plan_id: plan_id}}

      true ->
        {:error, invalid_request("Braintree plan swaps require a target plan_id/price reference.")}
    end
  end

  defp translate_item_update(items) when is_list(items) do
    {:error,
     invalid_request(
       "Braintree subscription updates support exactly one plan mutation item; got #{length(items)}."
     )}
  end

  defp translate_item_update(_items) do
    {:error, invalid_request("Braintree subscription updates require an items list.")}
  end

  defp validate_cancel_params(params) do
    invoice_now = truthy?(params[:invoice_now] || params["invoice_now"])
    prorate = truthy?(params[:prorate] || params["prorate"])

    cond do
      invoice_now ->
        {:error,
         invalid_request(
           "Braintree immediate cancellation does not support invoice_now: true."
         )}

      prorate ->
        {:error,
         invalid_request("Braintree immediate cancellation does not support prorate: true.")
         }

      true ->
        :ok
    end
  end

  defp translated_items(%Braintree.Subscription{id: id, plan_id: plan_id}) do
    [
      %{
        id: "#{id}:plan",
        price: %{id: plan_id, product: nil},
        quantity: 1
      }
    ]
  end

  defp subscription_gateway do
    Application.get_env(:accrue, :braintree_subscription_gateway, Braintree.Subscription)
  end

  defp customer_gateway do
    Application.get_env(:accrue, :braintree_customer_gateway, Braintree.Customer)
  end

  defp payment_method_gateway do
    Application.get_env(:accrue, :braintree_payment_method_gateway, Braintree.PaymentMethod)
  end

  defp translate_payment_method_create(params) do
    reference =
      get_in(params, [:vault_acquisition, :reference]) ||
        get_in(params, ["vault_acquisition", "reference"])

    customer_id = params[:customer] || params["customer"]

    cond do
      not is_binary(reference) or reference == "" ->
        {:error, invalid_request("Braintree create_payment_method requires vault_acquisition.reference.")}

      not is_binary(customer_id) or customer_id == "" ->
        {:error, invalid_request("Braintree create_payment_method requires a customer id.")}

      true ->
        {:ok, %{customer_id: customer_id, payment_method_nonce: reference}}
    end
  end

  defp translate_payment_method_update(id, params) do
    reference = params[:replacement_reference] || params["replacement_reference"]
    make_default = truthy?(params[:make_default] || params["make_default"])

    if is_binary(reference) and reference != "" do
      {:ok,
       %{
         payment_method_nonce: reference,
         options: %{make_default: make_default}
       }}
    else
      {:error,
       invalid_request(
         "Braintree update_payment_method requires replacement_reference for replacement semantics on #{id}."
       )}
    end
  end

  defp translate_customer_payment_methods(customer) do
    default_token = Map.get(customer, :default_payment_method_token)

    cards =
      Map.get(customer, :credit_cards) ||
        Map.get(customer, :payment_methods) ||
        []

    cards
    |> Enum.map(fn card ->
      card
      |> translate_payment_method()
      |> Map.put(:default, card.default || card.token == default_token)
    end)
  end

  defp translate_payment_method(payment_method) do
    %{
      id: Map.get(payment_method, :token),
      object: "payment_method",
      type: "card",
      customer: Map.get(payment_method, :customer_id),
      default: Map.get(payment_method, :default, false),
      card: %{
        brand: Map.get(payment_method, :card_type),
        last4: Map.get(payment_method, :last_4),
        exp_month: Map.get(payment_method, :expiration_month),
        exp_year: Map.get(payment_method, :expiration_year),
        fingerprint: Map.get(payment_method, :unique_number_identifier)
      }
    }
  end

  defp truthy?(value), do: value in [true, "true", 1, "1"]

  defp invalid_request(message) do
    %APIError{
      code: "invalid_request_error",
      http_status: 400,
      message: message
    }
  end

  defp unsupported_semantic(semantic) do
    %APIError{
      code: "processor_operation_unsupported",
      http_status: 422,
      message: "Braintree does not support Accrue's #{semantic} semantic."
    }
  end

  defp unsupported do
    %APIError{
      code: "unsupported_operation",
      http_status: 501,
      message: "This operation is out of slice for the Braintree adapter."
    }
  end
end
