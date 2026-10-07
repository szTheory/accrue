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

    def resolve(%Actor{}, %{source: :session, values: %{"active_billable_id" => "org-invalid"}}),
      do: {:error, :unavailable}

    def resolve(%Actor{}, %{source: :session, values: %{"active_billable_id" => "org-" <> _ = id}}) do
      resolve_organization(id)
    end

    def resolve(%Actor{}, %{
          source: :pin,
          values: %{"owner_type" => "Organization", "owner_id" => "org-" <> _ = id}
        }) do
      resolve_organization(id)
    end

    def resolve(%Actor{}, %{source: :session, values: %{"active_billable_id" => other}})
        when is_binary(other),
        do: {:error, :unavailable}

    def resolve(%Actor{}, _), do: {:error, :unavailable}

    defp resolve_organization(id) do
      {:ok,
       %{
         billable: %Organization{id: id},
         display_name: "Northwind Organization",
         display_detail: "Workspace billing",
         switch_path: "/accounts"
       }}
    end

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
      {:ok, _endpoint_pid} -> :ok
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

    assert {:ok, _view, html} = live_pinned_context(conn, "/custom-billing")
    assert html =~ subscription.processor_id
    assert html =~ "Northwind Organization"
    assert html =~ "Workspace billing"
    refute html =~ "Personal collision"
  end

  test "a different processor Customer with matching owner does not supply HomeLive data" do
    id = "org-wrong-processor"

    wrong_processor_customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: Organization.__accrue__(:billable_type),
        owner_id: id,
        processor: "another-processor",
        processor_id: "cus_wrong_processor",
        name: "Wrong processor"
      })
      |> TestRepo.insert!()

    wrong_processor_subscription =
      AccruePortal.Fixtures.read_only_subscription_fixture!(wrong_processor_customer)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "user_token" => "actor:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => id
      })

    assert {:ok, _view, html} = live_pinned_context(conn, "/custom-billing")
    refute html =~ wrong_processor_subscription.processor_id

    assert %Customer{processor: processor} =
             TestRepo.get_by(Customer,
               owner_type: Organization.__accrue__(:billable_type),
               owner_id: id,
               processor: Accrue.Processor.name()
             )

    assert processor == Accrue.Processor.name()
  end

  test "authenticated unavailable selection renders a generic blocked page without provisioning" do
    customer_count_before = TestRepo.aggregate(Customer, :count, :id)
    provider_calls_before = Accrue.Processor.Fake.call_count(:create_customer)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "user_token" => "actor:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => "org-invalid"
      })

    assert {:error, {:redirect, %{to: "/custom-billing/blocked"}}} =
             Phoenix.LiveViewTest.live(conn, "/custom-billing")

    assert {:ok, _view, html} = Phoenix.LiveViewTest.live(conn, "/custom-billing/blocked")
    assert html =~ "Billing access unavailable"
    refute html =~ "org-invalid"
    assert TestRepo.aggregate(Customer, :count, :id) == customer_count_before
    assert Accrue.Processor.Fake.call_count(:create_customer) == provider_calls_before
  end

  test "authenticated unavailable HTTP action blocks before provisioning" do
    customer_count_before = TestRepo.aggregate(Customer, :count, :id)
    provider_calls_before = Accrue.Processor.Fake.call_count(:create_customer)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "user_token" => "actor:00000000-0000-0000-0000-000000000123",
        "active_billable_id" => "org-invalid"
      })
      |> Phoenix.ConnTest.post("/custom-billing/payment-methods", %{})

    assert Phoenix.ConnTest.redirected_to(conn) == "/custom-billing/blocked"
    assert TestRepo.aggregate(Customer, :count, :id) == customer_count_before
    assert Accrue.Processor.Fake.call_count(:create_customer) == provider_calls_before
  end

  test "custom mount with no explicit billable selection does not choose a first record" do
    customer_count_before = TestRepo.aggregate(Customer, :count, :id)
    provider_calls_before = Accrue.Processor.Fake.call_count(:create_customer)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{
        "user_token" => "actor:00000000-0000-0000-0000-000000000123"
      })

    assert {:error, {:redirect, %{to: "/custom-billing/blocked"}}} =
             Phoenix.LiveViewTest.live(conn, "/custom-billing")

    assert TestRepo.aggregate(Customer, :count, :id) == customer_count_before
    assert Accrue.Processor.Fake.call_count(:create_customer) == provider_calls_before
  end

  defp live_pinned_context(conn, path) do
    case Phoenix.LiveViewTest.live(conn, path) do
      {:error, {:live_redirect, %{to: pinned_path}}} ->
        Phoenix.LiveViewTest.live(conn, pinned_path)

      result ->
        result
    end
  end
end
