defmodule AccrueHostWeb.PageController do
  use AccrueHostWeb, :controller

  alias AccrueHost.DemoBrand
  alias AccrueHost.Billing.Plans

  def home(conn, _params) do
    render(conn, :home, personas: DemoBrand.personas())
  end

  def pricing(conn, _params) do
    render(conn, :pricing, plans: Plans.all())
  end
end
