defmodule AccrueHostWeb.AdvancedReportsLive do
  use AccrueHostWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Advanced Reports")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="rounded-lg border border-base-300 bg-base-100 p-6 shadow-sm">
        <p class="text-sm font-semibold uppercase text-primary">
          {AccrueHost.DemoBrand.product_name()} reports
        </p>
        <h1 class="mt-2 text-3xl font-semibold">Team performance</h1>
        <p class="mt-3 max-w-2xl text-sm leading-6 text-base-content/65">
          This workspace has access to advanced project reporting through its active plan.
        </p>
      </section>
    </Layouts.app>
    """
  end
end
