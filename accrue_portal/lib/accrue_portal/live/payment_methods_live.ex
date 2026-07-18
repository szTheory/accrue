defmodule AccruePortal.Live.PaymentMethodsLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    {:ok,
     socket
     |> assign(:page_title, Copy.payment_methods_page_title())
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(
       :payment_methods,
       BillingReadModel.payment_methods(socket.assigns.current_customer)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <div class="portal-actions">
          <div class="portal-stack">
            <h1>{Copy.payment_methods_heading()}</h1>
          </div>
          <a href={Path.payment_methods(@base_path) <> "/new"} class="portal-button-primary">
            {Copy.payment_methods_add_cta()}
          </a>
        </div>

        <div :if={@payment_methods == []} class="portal-empty">
          <strong>{Copy.payment_methods_empty_title()}</strong>
          <p>{Copy.payment_methods_empty_body()}</p>
        </div>

        <ul :if={@payment_methods != []} class="portal-list">
          <li :for={payment_method <- @payment_methods}>
            <div>
              <strong>
                {payment_method.card_brand || Copy.payment_methods_card_fallback()}
                ending in {payment_method.card_last4}
              </strong>
              <p :if={payment_method.id == @current_customer.default_payment_method_id}>
                <span class="portal-status portal-status-active">
                  {Copy.payment_methods_default_badge()}
                </span>
              </p>
            </div>
            <div class="portal-actions">
              <form
                :if={payment_method.id != @current_customer.default_payment_method_id}
                action={Path.payment_method_default(@base_path, payment_method.id)}
                method="post"
              >
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
                <button type="submit" class="portal-button-secondary">
                  {Copy.payment_methods_set_default_cta()}
                </button>
              </form>
              <form action={Path.payment_method_delete(@base_path, payment_method.id)} method="post">
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
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
end
