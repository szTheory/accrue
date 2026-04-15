defmodule AccrueAdmin.TestRouter do
  use Phoenix.Router

  import AccrueAdmin.Router

  accrue_admin("/billing", session_keys: [:admin_token], allow_live_reload: true)
end

defmodule AccrueAdmin.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :accrue_admin

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Session,
    store: :cookie,
    key: "_accrue_admin_test_key",
    signing_salt: "test-signing-salt"
  )

  plug(AccrueAdmin.TestRouter)
end

defmodule AccrueAdmin.LiveCase do
  @moduledoc """
  ExUnit case template for future admin LiveView tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.LiveViewTest
      import Plug.Conn
      import Phoenix.ConnTest

      @endpoint AccrueAdmin.TestEndpoint
    end
  end

  setup _tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(AccrueAdmin.TestRepo, shared: true)

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    :ok = Accrue.Actor.put_operation_id("admin-test-" <> Ecto.UUID.generate())

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
