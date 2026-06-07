defmodule AccrueHostWeb.UserLive.Login do
  use AccrueHostWeb, :live_view

  alias AccrueHost.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <% personas = AccrueHost.DemoBrand.personas() %>
      <% demo_password = AccrueHost.DemoBrand.demo_password() %>

      <div class="grid gap-6 lg:grid-cols-[minmax(0,26rem)_minmax(0,1fr)] lg:items-start">
        <section class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
          <div>
            <p class="text-sm font-semibold uppercase text-primary">
              {AccrueHost.DemoBrand.product_name()}
            </p>
            <h1 class="mt-2 text-3xl font-semibold">Sign in to your workspace</h1>
            <p class="mt-3 text-sm leading-6 text-base-content/65">
              <%= if @current_scope do %>
                Reauthenticate before changing sensitive account settings.
              <% else %>
                New here? <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-primary hover:underline"
                >Create a workspace account</.link>.
              <% end %>
            </p>
          </div>

          <div :if={local_mail_adapter?()} class="alert alert-info mt-5 rounded-lg">
            <.icon name="hero-information-circle" class="size-5 shrink-0" />
            <p class="text-sm">
              Local emails appear in <.link href="/dev/mailbox" class="underline">the dev mailbox</.link>.
            </p>
          </div>

          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
            class="mt-6"
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
              phx-mounted={JS.focus()}
            />
            <.button class="btn btn-primary w-full rounded-lg">
              Email me a sign-in link
            </.button>
          </.form>

          <div class="divider">or</div>

          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
          >
            <.input
              readonly={!!@current_scope}
              field={f[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              spellcheck="false"
              required
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              autocomplete="current-password"
              spellcheck="false"
            />
            <.button
              class="btn btn-primary w-full rounded-lg"
              name={@form[:remember_me].name}
              value="true"
            >
              Sign in and stay signed in
            </.button>
            <.button class="btn btn-outline w-full mt-2 rounded-lg">
              Sign in once
            </.button>
          </.form>
        </section>

        <aside class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="text-sm font-semibold uppercase text-secondary">Demo accounts</p>
              <h2 class="mt-2 text-2xl font-semibold">Choose a role</h2>
            </div>
            <span class="rounded-md bg-base-200 px-2 py-1 text-xs font-semibold text-base-content/60">
              {demo_password}
            </span>
          </div>

          <div class="mt-5 grid gap-3">
            <div :for={persona <- personas} class="rounded-md border border-base-300 p-3">
              <div class="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p class="font-semibold">{persona.label}</p>
                  <p class="text-sm text-base-content/60">{persona.workspace}</p>
                </div>
                <span class="text-xs font-semibold uppercase text-base-content/45">
                  {persona.state}
                </span>
              </div>
              <p class="mt-3 break-all rounded-md bg-base-200 px-3 py-2 text-sm font-semibold">
                {persona.email}
              </p>
            </div>
          </div>
        </aside>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:accrue_host, AccrueHost.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
