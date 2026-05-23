defmodule Accrue.Processor.Braintree do
  @moduledoc """
  Production Braintree adapter for the gateway subscription core slice.
  """

  @behaviour Accrue.Processor

  alias Accrue.APIError
  alias Accrue.Billing.Customer
  alias Accrue.Checkout.LocalSession
  alias Accrue.Config

  @impl Accrue.Processor
  def processor_name, do: "braintree"

  @impl Accrue.Processor
  def capabilities do
    %{
      customer: %{create: true, retrieve: true, update: true},
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
      checkout: %{create: true, fetch: true, hosted: true, embedded: false},
      invoice: %{lifecycle_webhook_projection: true},
      webhook: %{verify: true, parse: true},
      billing_portal: %{create: true},
      entitlements: %{local_mapping: true}
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

  @impl Accrue.Processor
  def fetch(:refund, id), do: retrieve_refund(id, [])

  @impl Accrue.Processor
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
    |> maybe_put_discounts(params)
  end

  @doc false
  def translate_subscription(%Braintree.Subscription{} = sub) do
    sub
    |> Map.from_struct()
    |> Map.put(:items, translated_items(sub))
  end

  # Customer
  @impl Accrue.Processor
  def create_customer(params, opts) when is_map(params) and is_list(opts) do
    case customer_gateway().create(translate_customer_params(params), opts) do
      {:ok, customer} -> {:ok, translate_customer(customer)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def retrieve_customer(id, opts) when is_binary(id) and is_list(opts) do
    case customer_gateway().find(id, opts) do
      {:ok, customer} -> {:ok, translate_customer(customer)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def update_customer(id, params, opts)
      when is_binary(id) and is_map(params) and is_list(opts) do
    case customer_gateway().update(id, translate_customer_params(params), opts) do
      {:ok, customer} -> {:ok, translate_customer(customer)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

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
  def list_payment_methods(%{customer: customer_id}, opts)
      when is_binary(customer_id) and is_list(opts) do
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
  def create_charge(params, opts) when is_map(params) and is_list(opts) do
    with {:ok, request} <- translate_charge_params(params),
         {:ok, transaction} <- transaction_gateway().sale(request, opts) do
      {:ok, translate_charge(transaction)}
    else
      {:error, %Elixir.Braintree.ErrorResponse{} = error} ->
        {:error, translate_charge_error(error)}

      {:error, %APIError{} = error} ->
        {:error, error}

      {:error, raw} ->
        {:error, to_accrue_error(raw)}
    end
  end

  @impl Accrue.Processor
  def retrieve_charge(_id, _opts), do: {:error, unsupported()}
  @impl Accrue.Processor
  def list_charges(_params, _opts), do: {:error, unsupported()}

  # Refund
  @impl Accrue.Processor
  def create_refund(params, opts) when is_map(params) and is_list(opts) do
    charge_id = params[:charge] || params["charge"]
    amount = params[:amount] || params["amount"]

    amount_str =
      case amount do
        nil -> nil
        a when is_integer(a) -> :erlang.float_to_binary(a / 100.0, [{:decimals, 2}])
        a when is_binary(a) -> a
        _ -> nil
      end

    with {:ok, transaction} <- transaction_gateway().find(charge_id, opts),
         :ok <- validate_refundable_status(transaction),
         {:ok, refund} <- transaction_gateway().refund(charge_id, amount_str, opts) do
      {:ok, translate_refund(refund)}
    else
      {:error, %Elixir.Braintree.ErrorResponse{} = e} ->
        {:error, invalid_request(e.message)}

      {:error, %APIError{} = error} ->
        {:error, error}

      {:error, raw} ->
        {:error, invalid_request(inspect(raw))}
    end
  end

  @impl Accrue.Processor
  def retrieve_refund(id, opts) when is_binary(id) and is_list(opts) do
    case transaction_gateway().find(id, opts) do
      {:ok, refund} -> {:ok, translate_refund(refund)}
      {:error, %Elixir.Braintree.ErrorResponse{} = e} -> {:error, to_accrue_error(e)}
      {:error, raw} -> {:error, to_accrue_error(raw)}
    end
  end

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
  def checkout_session_create(params, opts) when is_map(params) and is_list(opts) do
    with {:ok, customer} <- checkout_customer(params),
         {:ok, attrs} <- build_local_checkout_attrs(customer, params, opts),
         {:ok, session} <- LocalSession.create_or_reuse(customer, attrs) do
      {:ok, local_checkout_payload(session)}
    end
  end

  @impl Accrue.Processor
  def checkout_session_fetch(id, _opts) when is_binary(id) do
    case LocalSession.by_id(id) do
      %LocalSession{} = session -> {:ok, local_checkout_payload(session)}
      nil -> {:error, invalid_request("unknown local checkout session #{inspect(id)}")}
    end
  end

  @impl Accrue.Processor
  def portal_session_create(params, _opts) when is_map(params) do
    with :ok <- ensure_local_portal_available(),
         {:ok, customer} <- portal_customer(params) do
      {:ok,
       %{
         id: "bps_local_" <> customer.id,
         object: "billing_portal.session",
         customer: customer.processor_id,
         url: billing_portal_url(params),
         return_url: params["return_url"] || params[:return_url],
         data: %{
           processor: "braintree",
           local_portal: true,
           customer_processor_id: customer.processor_id,
           mount_path: Config.portal_mount_path()
         }
       }}
    end
  end

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
        translate_item_update(
          params[:items] || params["items"],
          params[:braintree_plan_ref] || params["braintree_plan_ref"],
          params[:proration_behavior] || params["proration_behavior"]
        )

      truthy?(params[:cancel_at_period_end] || params["cancel_at_period_end"]) ->
        {:error, unsupported_semantic("cancel at period end")}

      Map.has_key?(params, :cancel_at) or Map.has_key?(params, "cancel_at") ->
        {:error, unsupported_semantic("scheduled cancellation")}

      Map.has_key?(params, :pause_collection) or Map.has_key?(params, "pause_collection") ->
        {:error, unsupported_semantic("pause collection")}

      true ->
        {:error,
         invalid_request("Unsupported Braintree subscription update payload: #{inspect(params)}")}
    end
  end

  defp translate_item_update([item], plan_ref, proration_behavior) when is_map(item) do
    cond do
      quantity = item[:quantity] || item["quantity"] ->
        {:error,
         invalid_request(
           "Braintree subscriptions do not expose Accrue's quantity mutation semantics; " <>
             "requested quantity #{inspect(quantity)} is unsupported."
         )}

      plan_id = item[:price] || item["price"] ->
        with {:ok, resolved_plan} <- normalize_plan_ref(plan_ref, plan_id),
             {:ok, options} <- translate_proration_behavior(proration_behavior) do
          {:ok,
           %{
             plan_id: resolved_plan.processor_plan_id,
             price: minor_to_decimal_string(resolved_plan.unit_amount_minor),
             options: options
           }}
        end

      true ->
        {:error,
         invalid_request("Braintree plan swaps require a target plan_id/price reference.")}
    end
  end

  defp translate_item_update(items, _plan_ref, _proration_behavior) when is_list(items) do
    {:error,
     invalid_request(
       "Braintree subscription updates support exactly one plan mutation item; got #{length(items)}."
     )}
  end

  defp translate_item_update(_items, _plan_ref, _proration_behavior) do
    {:error, invalid_request("Braintree subscription updates require an items list.")}
  end

  defp normalize_plan_ref(
         %{processor_plan_id: plan_id, unit_amount_minor: amount_minor} = plan_ref,
         requested_price_id
       )
       when is_binary(plan_id) and is_integer(amount_minor) and amount_minor >= 0 do
    if Map.get(plan_ref, :price_id) in [nil, requested_price_id] do
      {:ok, plan_ref}
    else
      {:error,
       invalid_request(
         "Resolved Braintree plan metadata #{inspect(plan_ref.price_id)} does not match requested #{inspect(requested_price_id)}."
       )}
    end
  end

  defp normalize_plan_ref(_plan_ref, requested_price_id) do
    {:error,
     invalid_request(
       "Braintree plan swaps require resolved processor_plan_id and unit_amount_minor metadata for #{inspect(requested_price_id)}."
     )}
  end

  defp translate_proration_behavior(:create_prorations), do: {:ok, %{prorate_charges: true}}
  defp translate_proration_behavior(:none), do: {:ok, %{prorate_charges: false}}

  defp translate_proration_behavior(:always_invoice) do
    {:error,
     %APIError{
       code: "processor_operation_unsupported",
       http_status: 422,
       message:
         "Braintree swap_plan/3 does not support proration: :always_invoice. Use :create_prorations or :none."
     }}
  end

  defp translate_proration_behavior(nil), do: {:ok, %{}}

  defp translate_proration_behavior(other) do
    {:error, invalid_request("Unsupported Braintree proration behavior: #{inspect(other)}")}
  end

  defp minor_to_decimal_string(amount_minor)
       when is_integer(amount_minor) and amount_minor >= 0 do
    dollars = div(amount_minor, 100)
    cents = rem(amount_minor, 100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{dollars}.#{cents}"
  end

  defp validate_cancel_params(params) do
    invoice_now = truthy?(params[:invoice_now] || params["invoice_now"])
    prorate = truthy?(params[:prorate] || params["prorate"])

    cancel_at_period_end =
      truthy?(params[:cancel_at_period_end] || params["cancel_at_period_end"])

    cancel_at = params[:cancel_at] || params["cancel_at"]

    cond do
      cancel_at_period_end ->
        {:error, unsupported_semantic("cancel at period end")}

      not is_nil(cancel_at) ->
        {:error, unsupported_semantic("scheduled cancellation")}

      invoice_now ->
        {:error,
         invalid_request("Braintree immediate cancellation does not support invoice_now: true.")}

      prorate ->
        {:error,
         invalid_request("Braintree immediate cancellation does not support prorate: true.")}

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

  defp transaction_gateway do
    Application.get_env(:accrue, :braintree_transaction_gateway, Braintree.Transaction)
  end

  defp validate_refundable_status(transaction) do
    status = Map.get(transaction, :status) || Map.get(transaction, "status")

    if status in ["settling", "settled"] do
      :ok
    else
      {:error,
       invalid_request(
         "Braintree refunds require the sale to be settling or settled; got #{status}."
       )}
    end
  end

  defp translate_refund(%{} = transaction) do
    data = if is_struct(transaction), do: Map.from_struct(transaction), else: transaction

    raw_status = Map.get(data, :status) || Map.get(data, "status")

    normalized_status =
      case raw_status do
        s when s in ["settled", :settled] ->
          "succeeded"

        s
        when s in [
               "settling",
               :settling,
               "submitted_for_settlement",
               :submitted_for_settlement,
               "authorized",
               :authorized,
               "authorizing",
               :authorizing
             ] ->
          "pending"

        s
        when s in [
               "settlement_declined",
               :settlement_declined,
               "failed",
               :failed,
               "gateway_rejected",
               :gateway_rejected,
               "processor_declined",
               :processor_declined
             ] ->
          "failed"

        s when s in ["voided", :voided] ->
          "canceled"

        _ ->
          "pending"
      end

    %{
      id: Map.get(data, :id) || Map.get(data, "id"),
      status: normalized_status,
      amount: Map.get(data, :amount) || Map.get(data, "amount"),
      currency: Map.get(data, :currency_iso_code) || Map.get(data, "currency_iso_code"),
      charge: Map.get(data, :refunded_transaction_id) || Map.get(data, "refunded_transaction_id"),
      data: data
    }
  end

  defp translate_payment_method_create(params) do
    reference =
      get_in(params, [:vault_acquisition, :reference]) ||
        get_in(params, ["vault_acquisition", "reference"])

    customer_id = params[:customer] || params["customer"]

    cond do
      not is_binary(reference) or reference == "" ->
        {:error,
         invalid_request("Braintree create_payment_method requires vault_acquisition.reference.")}

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

  defp translate_customer(customer) do
    %{
      id: Map.get(customer, :id),
      name: customer_name(customer),
      email: Map.get(customer, :email),
      metadata: Map.get(customer, :custom_fields, %{})
    }
  end

  defp translate_customer_params(params) do
    params
    |> stringify_keys()
    |> maybe_move_name_to_company()
    |> maybe_move_metadata_to_custom_fields()
  end

  defp maybe_move_name_to_company(%{"name" => name} = params)
       when is_binary(name) and name != "" do
    params
    |> Map.put_new("company", name)
    |> Map.delete("name")
  end

  defp maybe_move_name_to_company(params), do: params

  defp maybe_move_metadata_to_custom_fields(%{"metadata" => metadata} = params)
       when is_map(metadata) do
    params
    |> Map.put("custom_fields", stringify_keys(metadata))
    |> Map.delete("metadata")
  end

  defp maybe_move_metadata_to_custom_fields(params), do: params

  defp translate_charge_params(params) do
    amount = params[:amount] || params["amount"]
    customer_id = params[:customer] || params["customer"]
    payment_method = params[:payment_method] || params["payment_method"]
    description = params[:description] || params["description"]
    metadata = params[:metadata] || params["metadata"] || %{}

    cond do
      not is_integer(amount) or amount < 0 ->
        {:error,
         invalid_request("Braintree charges require a positive integer amount in minor units.")}

      not is_binary(customer_id) or customer_id == "" ->
        {:error, invalid_request("Braintree charges require a customer id.")}

      not is_binary(payment_method) or payment_method == "" ->
        {:error, invalid_request("Braintree charges require a vaulted payment method token.")}

      true ->
        {:ok,
         %{
           amount: money_string(amount),
           customer_id: customer_id,
           payment_method_token: payment_method,
           options: %{submit_for_settlement: true},
           custom_fields: stringify_keys(metadata)
         }
         |> maybe_put_description(description)}
    end
  end

  defp maybe_put_description(request, description)
       when is_binary(description) and description != "" do
    Map.put(request, :order_id, description)
  end

  defp maybe_put_description(request, _description), do: request

  defp translate_charge(%{} = transaction) do
    data = if is_struct(transaction), do: Map.from_struct(transaction), else: transaction
    raw_status = Map.get(data, :status) || Map.get(data, "status")

    status =
      case raw_status do
        s
        when s in [
               "submitted_for_settlement",
               :submitted_for_settlement,
               "settling",
               :settling,
               "settled",
               :settled
             ] ->
          "succeeded"

        s when s in ["authorized", :authorized, "authorizing", :authorizing] ->
          "pending"

        s
        when s in [
               "processor_declined",
               :processor_declined,
               "gateway_rejected",
               :gateway_rejected,
               "settlement_declined",
               :settlement_declined
             ] ->
          "failed"

        _ ->
          "pending"
      end

    %{
      id: Map.get(data, :id) || Map.get(data, "id"),
      status: status,
      amount: Map.get(data, :amount) || Map.get(data, "amount"),
      currency: Map.get(data, :currency_iso_code) || Map.get(data, "currency_iso_code"),
      customer:
        get_in(data, [:customer_details, :id]) || get_in(data, ["customer_details", "id"]),
      payment_method:
        get_in(data, [:credit_card_details, :token]) ||
          get_in(data, ["credit_card_details", "token"]),
      data: data
    }
  end

  defp translate_charge_error(%Elixir.Braintree.ErrorResponse{message: message} = error) do
    cond do
      String.contains?(message, "Processor Declined") ->
        %Accrue.CardError{
          code: "card_declined",
          decline_code: "do_not_honor",
          message: message,
          processor_error: error
        }

      String.contains?(message, "Declined") ->
        %Accrue.CardError{
          code: "card_declined",
          decline_code: "declined",
          message: message,
          processor_error: error
        }

      true ->
        %APIError{
          code: "braintree_error",
          http_status: 400,
          message: message,
          processor_error: error
        }
    end
  end

  defp customer_name(customer) do
    company = Map.get(customer, :company)
    first_name = Map.get(customer, :first_name)
    last_name = Map.get(customer, :last_name)

    cond do
      is_binary(company) and company != "" ->
        company

      is_binary(first_name) and is_binary(last_name) ->
        String.trim("#{first_name} #{last_name}")

      is_binary(first_name) ->
        first_name

      is_binary(last_name) ->
        last_name

      true ->
        nil
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

  defp maybe_put_discounts(request, params) do
    case params[:discounts] || params["discounts"] do
      [%{} = discount | _] ->
        case discount[:discount_id] || discount["discount_id"] do
          id when is_binary(id) and id != "" ->
            Map.put(request, :discounts, %{add: [%{inherited_from_id: id}]})

          _ ->
            request
        end

      _ ->
        request
    end
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

  defp money_string(amount_minor) when is_integer(amount_minor) do
    :erlang.float_to_binary(amount_minor / 100.0, [{:decimals, 2}])
  end

  defp stringify_keys(params) do
    for {key, value} <- params, into: %{} do
      {to_string(key), value}
    end
  end

  defp invalid_request(message) do
    %APIError{
      code: "invalid_request_error",
      http_status: 400,
      message: message
    }
  end

  defp unsupported_semantic(semantic) do
    message =
      case semantic do
        "cancel at period end" ->
          "Braintree does not support Accrue's cancel at period end semantic. " <>
            "Use Accrue.Billing.cancel/2 when you need an immediate stop, or keep end-of-term " <>
            "non-renewal in a host-owned seam."

        "scheduled cancellation" ->
          "Braintree does not support Accrue's scheduled cancellation semantic. " <>
            "Use Accrue.Billing.cancel/2 when you need an immediate stop, or keep end-of-term " <>
            "non-renewal in a host-owned seam."

        "resume" ->
          "Braintree does not support Accrue's resume semantic. " <>
            "Create a new subscription when service should restart after cancellation."

        _ ->
          "Braintree does not support Accrue's #{semantic} semantic."
      end

    %APIError{
      code: "processor_operation_unsupported",
      http_status: 422,
      message: message
    }
  end

  defp unsupported do
    %APIError{
      code: "unsupported_operation",
      http_status: 501,
      message: "This operation is out of slice for the Braintree adapter."
    }
  end

  defp checkout_customer(params) do
    portal_customer(params)
  end

  defp portal_customer(params) do
    case params["customer"] || params[:customer] do
      customer_id when is_binary(customer_id) ->
        case Accrue.Repo.get_by(Customer, processor_id: customer_id, processor: "braintree") do
          %Customer{} = customer ->
            {:ok, customer}

          nil ->
            {:error,
             invalid_request("customer #{inspect(customer_id)} is not provisioned locally")}
        end

      _ ->
        {:error, invalid_request("local portal sessions require a customer id")}
    end
  end

  defp build_local_checkout_attrs(%Customer{} = customer, params, opts) do
    line_items = params["line_items"] || params[:line_items] || []
    operation_id = Keyword.get(opts, :operation_id)

    with {:ok, price_id} <- checkout_price_id(line_items) do
      {:ok,
       %{
         processor: "braintree",
         mode: params["mode"] || params[:mode] || "subscription",
         ui_mode: params["ui_mode"] || params[:ui_mode] || "hosted",
         price_id: price_id,
         line_items: line_items,
         success_url: params["success_url"] || params[:success_url],
         cancel_url: params["cancel_url"] || params[:cancel_url],
         return_url: params["return_url"] || params[:return_url],
         operation_id: operation_id,
         metadata: params["metadata"] || params[:metadata] || %{},
         data: %{
           customer_processor_id: customer.processor_id,
           automatic_tax: params["automatic_tax"] || params[:automatic_tax] || %{}
         }
       }}
    end
  end

  defp checkout_price_id([item | _]) when is_map(item) do
    case item[:price] || item["price"] do
      price when is_binary(price) and price != "" ->
        {:ok, price}

      _ ->
        {:error,
         invalid_request("Braintree checkout requires the first line item to carry a price id")}
    end
  end

  defp checkout_price_id(_),
    do: {:error, invalid_request("Braintree checkout requires at least one line item")}

  defp local_checkout_payload(%LocalSession{} = session) do
    %{
      id: session.id,
      object: "checkout.session",
      customer: customer_processor_id(session),
      mode: session.mode,
      ui_mode: session.ui_mode,
      status: session.status,
      payment_status: payment_status(session),
      url: Config.portal_url("#{Config.portal_mount_path()}/checkout/#{session.session_token}"),
      expires_at: session.expires_at,
      metadata: session.metadata,
      line_items: session.line_items,
      data:
        Map.merge(session.data || %{}, %{
          local_portal: true,
          price_id: session.price_id,
          session_token: session.session_token,
          mount_path: Config.portal_mount_path()
        })
    }
  end

  defp customer_processor_id(%LocalSession{customer_id: customer_id}) do
    case Accrue.Repo.get(Customer, customer_id) do
      %Customer{processor_id: processor_id} -> processor_id
      _ -> nil
    end
  end

  defp payment_status(%LocalSession{status: "completed"}), do: "paid"
  defp payment_status(_session), do: "unpaid"

  defp billing_portal_url(params) do
    base = Config.portal_mount_path()

    case params["return_url"] || params[:return_url] do
      value when is_binary(value) and value != "" ->
        Config.portal_url("#{base}?return_url=#{URI.encode_www_form(value)}")

      _ ->
        Config.portal_url(base)
    end
  end

  defp ensure_local_portal_available do
    case Config.portal_base_url() do
      base when is_binary(base) and base != "" ->
        :ok

      _ ->
        {:error, unsupported_gateway_portal()}
    end
  end

  defp unsupported_gateway_portal do
    %APIError{
      code: :unsupported_by_gateway,
      http_status: 422,
      message:
        "Braintree does not support a hosted billing portal unless the local Accrue portal is mounted and configured. See guides/braintree-local-portal.md."
    }
  end
end
