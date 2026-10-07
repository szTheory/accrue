defmodule AccruePortal.ContextContractTest do
  use AccruePortal.ConnCase, async: false

  alias Accrue.Billing.Customer
  alias AccruePortal.TestRepo

  defmodule Actor do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :binary_id, autogenerate: false}
    schema "portal_test_users" do
    end
  end

  defmodule Organization do
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :string, autogenerate: false}
    schema "portal_test_organizations" do
    end
  end

  defmodule AuthAdapter do
    @behaviour Accrue.Auth
    alias AccruePortal.ContextContractTest.Actor

    @impl Accrue.Auth
    def current_user(%{"user_token" => "actor:" <> id}), do: %Actor{id: id}
    def current_user(_), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_, _), do: :ok

    @impl Accrue.Auth
    def actor_id(%{id: id}), do: id
  end

  defmodule ContextAdapter do
    alias AccruePortal.ContextContractTest.Actor
    alias AccruePortal.ContextContractTest.Organization
    @id "org-00000001"

    def resolve(%Actor{} = _actor, %{source: :session, values: %{"active_billable_id" => @id}}) do
      {:ok,
       %{
         billable: %Organization{id: @id},
         display_name: "Northwind Organization",
         display_detail: "Workspace billing",
         switch_path: "/accounts"
       }}
    end

    def resolve(%Actor{}, %{source: :session, values: %{"active_billable_id" => other}})
        when is_binary(other),
        do: {:error, :unavailable}

    def resolve(%Actor{}, _), do: {:error, :unavailable}

    def authorize(%Actor{}, %{billable: %Organization{}}, :read, _target), do: :ok
    def authorize(_, _, _, _), do: {:error, :forbidden}
  end

  defmodule CustomRouter do
    use Phoenix.Router
    import Phoenix.ConnTest, except: [get: 3, post: 3]
    import Accrue.Portal.Router

    accrue_portal("/custom-billing",
      session_keys: [:user_token, :active_billable_id],
      login_path: "/sign-in",
      context_adapter: ContextAdapter
    )
  end

  defmodule CustomEndpoint do
    use Phoenix.Endpoint, otp_app: :accrue_portal
    socket("/live", Phoenix.LiveView.Socket)

    plug(Plug.Session,
      store: :cookie,
      key: "_accrue_portal_custom_test_key",
      signing_salt: "accrue-portal-custom-test"
    )

    plug(CustomRouter)
  end

  @endpoint CustomEndpoint

  setup do
    previous_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    Application.put_env(:accrue_portal, CustomEndpoint,
      secret_key_base: String.duplicate("abcd1234", 8),
      server: false,
      url: [host: "localhost"],
      live_view: [signing_salt: "accrue-portal-custom-test"],
      render_errors: [formats: [html: &Phoenix.Controller.status_message_from_template/1]]
    )

    case CustomEndpoint.start_link() do
      {:ok, endpoint_pid} -> on_exit(fn -> Supervisor.stop(endpoint_pid) end)
      {:error, {:already_started, _endpoint_pid}} -> :ok
    end

    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, previous_auth) end)
    :ok
  end

  test "selected host billable renders HomeLive data for its exact Customer", %{conn: _conn} do
    id = "org-00000001"

    %{customer: customer, subscription: subscription} =
      Accrue.Test.Factory.active_subscription(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: id,
        name: "Northwind Organization"
      })

    collision = %Customer{
      owner_type: Actor.__accrue__(:billable_type),
      owner_id: id,
      processor: customer.processor,
      name: "Personal collision"
    }

    assert {:ok, _} = TestRepo.insert(Customer.changeset(collision))

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "user_token" => "actor:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => id
      })

    assert {:ok, _view, html} = Phoenix.LiveViewTest.live(conn, "/custom-billing")
    assert html =~ subscription.processor_id
    assert html =~ "Northwind Organization"
    refute html =~ "Personal collision"
  end
end
