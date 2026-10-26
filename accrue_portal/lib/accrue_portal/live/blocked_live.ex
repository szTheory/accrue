defmodule AccruePortal.Live.BlockedLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <main class="portal-page" aria-labelledby="blocked-heading">
      <section class="portal-card" role="alert">
        <h1 id="blocked-heading" tabindex="-1" autofocus>Billing access unavailable</h1>
        <p>We couldn't open billing for the selected account. Choose an account in your app and try again.</p>
        <a href="/">Return to your app</a>
      </section>
    </main>
    """
  end
end
