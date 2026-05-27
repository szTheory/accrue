defmodule AccrueHostWeb.AdvancedReportsLive do
  use AccrueHostWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Advanced Reports")}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Advanced Reports</h1>
      <p>You have access to this premium feature.</p>
    </div>
    """
  end
end
