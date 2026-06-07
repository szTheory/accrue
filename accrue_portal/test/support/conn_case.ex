defmodule AccruePortal.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :accrue_portal,
    adapter: Ecto.Adapters.Postgres
end

defmodule AccruePortal.TestRouter do
  use Phoenix.Router

  import Accrue.Portal.Router

  accrue_portal("/billing", session_keys: [:user_token], login_path: "/users/log-in")
end

defmodule AccruePortal.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :accrue_portal

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Session,
    store: :cookie,
    key: "_accrue_portal_test_key",
    signing_salt: "test-signing-salt"
  )

  plug(AccruePortal.TestRouter)
end

defmodule AccruePortal.ConnCase do
  @moduledoc """
  ExUnit case template for portal router and LiveView tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import Plug.Conn

      @endpoint AccruePortal.TestEndpoint
    end
  end

  setup tags do
    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(AccruePortal.TestRepo, shared: not tags[:async])

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    :ok = Accrue.Auth.Mock.clear_current_user()
    :ok = Accrue.Actor.put_operation_id("portal-test-" <> Ecto.UUID.generate())

    conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})

    {:ok, conn: conn}
  end

  @doc """
  Stores a mock user in the current process and mirrors the session keys a host
  router would thread into the mounted portal session.
  """
  @spec sign_in_customer(Plug.Conn.t(), map(), String.t()) :: Plug.Conn.t()
  def sign_in_customer(conn, user, token \\ "customer-token") when is_map(user) do
    :ok = Accrue.Auth.Mock.put_current_user(user)
    Plug.Test.init_test_session(conn, %{"user_token" => token})
  end
end
