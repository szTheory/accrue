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
            <span class="mt-1 text-xs font-medium text-base-content/45">Tap any field to copy</span>
          </div>

          <div class="mt-5 grid gap-3">
            <div :for={{persona, idx} <- Enum.with_index(personas)} class="rounded-md border border-base-300 p-3">
              <div class="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p class="font-semibold">{persona.label}</p>
                  <p class="text-sm text-base-content/60">{persona.workspace}</p>
                </div>
                <span class="text-xs font-semibold uppercase text-base-content/45">
                  {persona.state}
                </span>
              </div>
              <div class="mt-3 grid gap-2">
                <div>
                  <p class="mb-1 text-xs font-semibold uppercase text-base-content/45">Email</p>
                  <button
                    type="button"
                    id={"copy-email-#{idx}"}
                    phx-hook="Clipboard"
                    data-clipboard-text={persona.email}
                    data-copy-label="email address"
                    aria-label={"Copy email address #{persona.email}"}
                    class="copy-chip flex w-full items-center justify-between gap-2 break-all rounded-md bg-base-200 px-3 py-2 text-left text-sm font-semibold transition-colors hover:bg-base-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-base-100"
                  >
                    <span>{persona.email}</span>
                    <.icon name="hero-clipboard-document" class="copy-chip-idle size-4 shrink-0 text-base-content/40" />
                    <.icon name="hero-check" class="copy-chip-done size-4 shrink-0 text-success" />
                  </button>
                </div>
                <div>
                  <p class="mb-1 text-xs font-semibold uppercase text-base-content/45">Password</p>
                  <button
                    type="button"
                    id={"copy-pass-#{idx}"}
                    phx-hook="Clipboard"
                    data-clipboard-text={demo_password}
                    data-copy-label="password"
                    aria-label="Copy password"
                    class="copy-chip flex w-full items-center justify-between gap-2 break-all rounded-md bg-base-200 px-3 py-2 text-left text-sm font-semibold transition-colors hover:bg-base-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-base-100"
                  >
                    <span>{demo_password}</span>
                    <.icon name="hero-clipboard-document" class="copy-chip-idle size-4 shrink-0 text-base-content/40" />
                    <.icon name="hero-check" class="copy-chip-done size-4 shrink-0 text-success" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </aside>
      </div>

      <div id="copy-toast-root" class="toast toast-top toast-end z-[60]" aria-live="polite" aria-atomic="true"></div>
      <template id="copy-toast-template">
        <div class="copy-toast alert alert-success w-72 shadow-lg">
          <.icon name="hero-check-circle" class="size-5 shrink-0" />
          <span data-copy-toast-label>Copied</span>
        </div>
      </template>
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
