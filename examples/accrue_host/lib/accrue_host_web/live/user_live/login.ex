defmodule AccrueHostWeb.UserLive.Login do
  use AccrueHostWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <% product = AccrueHost.DemoBrand.product_name() %>
      <% personas = AccrueHost.DemoBrand.personas() %>

      <div class="mx-auto max-w-3xl">
        <div class="text-center">
          <p class="text-sm font-semibold uppercase text-primary">{product}</p>
          <h1 class="mt-2 text-3xl font-semibold">Choose a demo workspace</h1>
          <p class="mx-auto mt-3 max-w-xl text-base leading-7 text-base-content/65">
            Each is a live {product} workspace in a different billing state. Pick one to jump straight in — no sign-up, no password.
          </p>
        </div>

        <div class="mt-8 grid gap-4 sm:grid-cols-2">
          <div
            :for={persona <- personas}
            class="flex flex-col gap-3 rounded-lg border border-base-300 bg-base-100 p-5 shadow-sm"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-lg font-semibold">{persona.label}</p>
                <p class="text-sm text-base-content/60">{persona.workspace}</p>
              </div>
              <span class="shrink-0 rounded-md bg-base-200 px-2 py-1 text-xs font-semibold uppercase text-base-content/55">
                {persona.state}
              </span>
            </div>

            <p class="text-sm leading-6 text-base-content/65">{persona.description}</p>

            <.demo_login_form persona={persona} class="mt-auto">
              <button type="submit" class="btn btn-primary w-full rounded-lg">
                Enter workspace <.icon name="hero-arrow-right" class="size-4" />
              </button>
            </.demo_login_form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Choose a demo workspace")}
  end
end
