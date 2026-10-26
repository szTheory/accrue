defmodule AccruePortal.Live.PaymentMethodsLive do
  use Phoenix.LiveView

  alias Accrue.Portal.Context
  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(params, %{"accrue_portal" => portal}, socket) do
    context = socket.assigns.current_context
    customer = socket.assigns.current_customer

    with {:ok, minted_pin} <- Accrue.Portal.Context.mint_pin(context, socket.endpoint) do
      pin = socket.assigns[:current_context_pin] || minted_pin
      {read_state, payment_methods} = payment_method_state(customer)

      action_permissions =
        Map.new(payment_methods, fn payment_method ->
          default_replacement_required? =
            payment_method.id == customer.default_payment_method_id and
              Enum.any?(payment_methods, &(&1.id != payment_method.id))

          {payment_method.id,
           %{
             default:
               action_available?(
                 socket,
                 customer,
                 :payment_method_default,
                 :set_default,
                 payment_method
               ),
             delete:
               not default_replacement_required? and
                 action_available?(
                   socket,
                   customer,
                   :payment_method_delete,
                   :delete,
                   payment_method
                 ),
             delete_blocked: default_replacement_required?
           }}
        end)

      socket =
        socket
        |> assign(:page_title, Copy.payment_methods_page_title())
        |> assign(:portal, portal)
        |> assign(:base_path, portal["mount_path"])
        |> assign(:context_pin, pin)
        |> assign(:billed_identity, billed_identity(context, customer))
        |> assign(:payment_methods, payment_methods)
        |> assign(:payment_methods_read_state, read_state)
        |> assign(:payment_method_action_permissions, action_permissions)
        |> assign(
          :can_add_payment_method,
          action_available?(
            socket,
            customer,
            :payment_method_create,
            :vault_acquisition,
            customer
          ) and processor_supports?(customer, :create) and hosted_fields_provider?(customer)
        )

      if is_binary(Map.get(params, "context_pin")) do
        {:ok, socket}
      else
        send(self(), {:patch_context_pin, pin})
        {:ok, socket}
      end
    else
      _ -> {:ok, assign(socket, :context_pin, nil)}
    end
  end

  @impl true
  def handle_info({:patch_context_pin, pin}, socket) do
    {:noreply,
     Phoenix.LiveView.push_patch(socket,
       to:
         Path.payment_methods(socket.assigns.base_path) <>
           "?context_pin=" <> URI.encode_www_form(pin)
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <AccruePortal.Layouts.breadcrumb trail={[
        %{label: Copy.breadcrumb_home(), href: Path.home(@base_path)},
        %{label: Copy.payment_methods_heading(), href: nil}
      ]} />
      <section class="portal-card">
        <div class="portal-actions">
          <div class="portal-stack">
            <h1>{Copy.payment_methods_heading()}</h1>
            <p>Billing for <strong>{@billed_identity}</strong></p>
          </div>
          <a
            :if={@can_add_payment_method}
            href={Path.payment_methods_new(@base_path) <> "?context_pin=" <> URI.encode_www_form(@context_pin)}
            class="portal-button-primary"
          >
            {Copy.payment_methods_add_cta()}
          </a>
        </div>

        <div :if={@payment_methods_read_state == :unavailable} class="portal-empty" role="status" aria-live="polite">
          <strong>{Copy.payment_methods_unavailable_title()}</strong>
          <p>{Copy.payment_methods_unavailable_body()}</p>
          <a href={Path.context(Path.payment_methods(@base_path), @context_pin)} class="portal-button-secondary">
            {Copy.invoices_retry_cta()}
          </a>
        </div>

        <div :if={@payment_methods_read_state == :unsupported} class="portal-empty" role="status" aria-live="polite">
          <strong>{Copy.payment_methods_unsupported_title()}</strong>
          <p>{Copy.payment_methods_unsupported_body()}</p>
        </div>

        <div :if={@payment_methods_read_state == :ok and @payment_methods == []} class="portal-empty">
          <strong>{Copy.payment_methods_empty_title()}</strong>
          <p>
            {if @can_add_payment_method,
              do: Copy.payment_methods_empty_body(),
              else: Copy.payment_methods_empty_read_only_body()}
          </p>
        </div>

        <ul :if={@payment_methods_read_state == :ok and @payment_methods != []} class="portal-list">
          <li :for={payment_method <- @payment_methods}>
            <div>
              <strong>{card_label(payment_method)}</strong>
              <p :if={payment_method.id == @current_customer.default_payment_method_id}>
                <span class="portal-status portal-status-active">
                  {Copy.payment_methods_default_badge()}
                </span>
              </p>
              <p :if={Map.get(@payment_method_action_permissions[payment_method.id], :delete_blocked, false)}>
                {Copy.payment_methods_default_removal_blocked()}
              </p>
            </div>
            <div class="portal-actions">
              <form
                :if={payment_method.id != @current_customer.default_payment_method_id and Map.get(@payment_method_action_permissions[payment_method.id], :default, false)}
                action={Path.payment_method_default(@base_path, payment_method.id)}
                method="post"
                data-confirm={Copy.payment_methods_set_default_confirmation(@billed_identity, card_label(payment_method))}
              >
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
                <input type="hidden" name="context_pin" value={@context_pin} />
                <button type="submit" class="portal-button-secondary">
                  {Copy.payment_methods_set_default_cta()}
                </button>
              </form>
              <form
                :if={Map.get(@payment_method_action_permissions[payment_method.id], :delete, false)}
                action={Path.payment_method_delete(@base_path, payment_method.id)}
                method="post"
                data-confirm={Copy.payment_methods_delete_confirmation(@billed_identity, card_label(payment_method))}
              >
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
                <input type="hidden" name="context_pin" value={@context_pin} />
                <button type="submit" class="portal-button-secondary">
                  {Copy.payment_methods_delete_cta()}
                </button>
              </form>
            </div>
          </li>
        </ul>
      </section>
    </main>
    """
  end

  defp payment_method_state(customer) do
    case BillingReadModel.payment_method_result(customer) do
      {:ok, payment_methods} -> {:ok, payment_methods}
      {:error, :unavailable} -> {:unavailable, []}
      {:error, :unsupported} -> {:unsupported, []}
    end
  end

  defp action_available?(socket, customer, action, capability, target) do
    processor_supports?(customer, capability) and
      Context.authorize_action(
        socket.assigns.current_context,
        socket.assigns[:current_context_adapter],
        action,
        target
      ) == :ok
  end

  defp processor_supports?(%{processor: customer_processor}, capability) do
    processor = Accrue.Processor.__impl__()

    customer_processor == processor.processor_name() and
      Accrue.Processor.supports?([:payment_method, capability])
  rescue
    _ -> false
  end

  defp hosted_fields_provider?(%{processor: processor}), do: processor in ["braintree", "fake"]

  defp billed_identity(context, customer) do
    context.display_name || customer.name || customer.email || "this account"
  end

  defp card_label(payment_method) do
    brand = payment_method.card_brand || Copy.payment_methods_card_fallback()
    last_four = payment_method.card_last4 || "unavailable"
    "#{brand} ending in #{last_four}"
  end
end
