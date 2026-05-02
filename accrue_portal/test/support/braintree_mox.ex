defmodule AccruePortal.BraintreeMox do
  @moduledoc false

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{client_token: "portal-client-token"} end, name: __MODULE__)
  end

  def reset(client_token \\ "portal-client-token") when is_binary(client_token) do
    ensure_started()
    Agent.update(__MODULE__, fn _ -> %{client_token: client_token} end)
  end

  def stub_client_token(client_token) when is_binary(client_token) do
    Application.put_env(:accrue, :braintree_client_token_generator, __MODULE__.Generator)
    reset(client_token)
  end

  def client_token, do: Agent.get(__MODULE__, & &1.client_token)

  defmodule Generator do
    @moduledoc false

    def generate(%{customer_id: _customer_id}) do
      {:ok, AccruePortal.BraintreeMox.client_token()}
    end
  end

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil ->
        {:ok, _pid} = start_link([])
        :ok

      _pid ->
        :ok
    end
  end
end
