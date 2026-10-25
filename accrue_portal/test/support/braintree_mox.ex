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

  # Started unlinked so the stub outlives the test that first touched it. A
  # linked start ties the Agent to that test process; ExUnit does not wait for
  # a finished test process to exit, so the next test's setup could see the
  # dying Agent and fail in Agent.update/2 with :noproc.
  defp ensure_started do
    case Agent.start(fn -> %{client_token: "portal-client-token"} end, name: __MODULE__) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end
end
