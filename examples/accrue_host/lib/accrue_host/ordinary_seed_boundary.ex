defmodule AccrueHost.OrdinarySeedBoundary do
  @moduledoc false

  @spec allowed?(atom(), String.t(), String.t(), String.t() | nil, String.t() | nil) :: boolean()
  def allowed?(:test, database, role, server_address, _expected_address) do
    Regex.match?(~r/^accrue_host_test\d*$/, database) and role == "postgres" and
      loopback_address?(server_address)
  end

  def allowed?(:dev, database, role, server_address, expected_address) do
    database == "accrue_host_dev" and role == "postgres" and
      is_binary(expected_address) and server_address == expected_address
  end

  def allowed?(_env, _database, _role, _server_address, _expected_address), do: false

  defp loopback_address?(address) when is_binary(address) do
    case :inet.parse_address(String.to_charlist(address)) do
      {:ok, {127, _, _, _}} -> true
      {:ok, {0, 0, 0, 0, 0, 0, 0, 1}} -> true
      _ -> false
    end
  end

  defp loopback_address?(_), do: false
end
