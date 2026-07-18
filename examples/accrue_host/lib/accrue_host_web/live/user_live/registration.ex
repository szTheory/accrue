defmodule AccrueHostWeb.UserLive.Registration do
  use AccrueHostWeb, :live_view

  alias AccrueHost.Accounts
  alias AccrueHost.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto grid max-w-4xl gap-6 lg:grid-cols-[minmax(0,26rem)_minmax(0,1fr)]">
        <section class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
          <p class="text-sm font-semibold uppercase text-primary">
            {AccrueHost.DemoBrand.product_name()}
          </p>
          <h1 class="mt-2 text-3xl font-semibold">Create a workspace account</h1>
          <p class="mt-3 text-sm leading-6 text-base-content/65">
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-primary hover:underline">
              Sign in to your workspace
            </.link>
          </p>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            class="mt-6"
          >
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
              phx-mounted={JS.focus()}
            />

            <.button phx-disable-with="Creating account..." class="btn btn-primary w-full rounded-lg">
              Create account
            </.button>
          </.form>
        </section>

        <aside class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
          <p class="text-sm font-semibold uppercase text-secondary">Workspace model</p>
          <h2 class="mt-2 text-2xl font-semibold">
            Projects, seats, and billing state stay together.
          </h2>
          <dl class="mt-6 grid gap-4">
            <div class="border-b border-base-300 pb-4">
              <dt class="text-sm font-semibold text-base-content/60">Organization billing</dt>
              <dd class="mt-1 text-sm leading-6">
                Every seeded account owns or operates a workspace with its own subscription lifecycle.
              </dd>
            </div>
            <div class="border-b border-base-300 pb-4">
              <dt class="text-sm font-semibold text-base-content/60">Customer portal</dt>
              <dd class="mt-1 text-sm leading-6">
                Members review payment methods, invoices, and subscription details under the Cadence brand.
              </dd>
            </div>
            <div>
              <dt class="text-sm font-semibold text-base-content/60">Operator console</dt>
              <dd class="mt-1 text-sm leading-6">
                Billing operators use Accrue Admin for events, invoices, recovery, and webhook inspection.
              </dd>
            </div>
          </dl>
        </aside>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: AccrueHostWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
