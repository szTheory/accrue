defmodule AccrueHostWeb.SandboxController do
  use AccrueHostWeb, :controller

  def create(conn, _params) do
    # Start a new sandbox for this process. We share it so other processes can use it.
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(AccrueHost.Repo, shared: false)
    # The sandbox gives us a metadata string that clients can send in future requests
    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(AccrueHost.Repo, owner)
    
    conn
    |> put_status(:created)
    |> text(metadata)
  end

  def delete(conn, _params) do
    # When stopping, we just stop the owner of the sandbox in this process
    Ecto.Adapters.SQL.Sandbox.stop_owner(AccrueHost.Repo)
    send_resp(conn, :no_content, "")
  end
end
