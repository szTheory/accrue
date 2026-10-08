defmodule AccrueHostWeb.PageController do
  use AccrueHostWeb, :controller

  alias AccrueHost.DemoBrand
  alias AccrueHost.Billing.Plans

  def home(conn, _params) do
    render(conn, :home, personas: DemoBrand.personas())
  end

  def pricing(conn, %{"plan" => plan_id}) when is_binary(plan_id) do
    case Plans.get(plan_id) do
      %{id: id} ->
        conn
        |> put_session(:user_return_to, "/app/billing?plan=#{URI.encode_www_form(id)}")
        |> redirect(to: ~p"/users/log-in")

      nil ->
        conn
        |> put_flash(:error, "That plan is unavailable. Choose a plan from pricing to continue.")
        |> render(:pricing, plans: Plans.all())
    end
  end

  def pricing(conn, _params) do
    render(conn, :pricing, plans: Plans.all())
  end
end
