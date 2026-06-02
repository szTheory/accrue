defmodule AccrueHostWeb.LiveAcceptance do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    socket =
      assign_new(socket, :phoenix_ecto_sandbox, fn ->
        sandbox_metadata(socket)
      end)

    Phoenix.Ecto.SQL.Sandbox.allow(
      socket.assigns.phoenix_ecto_sandbox,
      Ecto.Adapters.SQL.Sandbox
    )

    {:cont, socket}
  end

  defp sandbox_metadata(socket) do
    sandbox_header =
      socket
      |> get_connect_info(:x_headers)
      |> List.wrap()
      |> List.keyfind("x-sandbox-id", 0)

    case sandbox_header do
      {"x-sandbox-id", metadata} -> metadata
      _ -> get_connect_info(socket, :user_agent)
    end
  end
end
