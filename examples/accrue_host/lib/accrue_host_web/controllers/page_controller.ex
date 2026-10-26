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
        selection_id = Ecto.UUID.generate()

        conn
        |> put_session(
          :user_return_to,
          "/app/billing?#{URI.encode_query(plan: id, selection: selection_id)}"
        )
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
