defmodule AccrueHost.OrdinarySeedBoundary do
  @moduledoc false

  @spec allowed?(atom(), String.t(), String.t(), String.t() | nil, String.t() | nil) :: boolean()
  def allowed?(:test, database, role, server_address, _expected_address) do
    Regex.match?(~r/^accrue_host_test\d*$/, database) and role == "postgres" and
      (loopback_address?(server_address) or ci_service_network_address?(server_address))
  end

  def allowed?(:dev, database, role, server_address, expected_address) do
    database == "accrue_host_dev" and role == "postgres" and
      is_binary(expected_address) and server_address == expected_address
  end

  def allowed?(_env, _database, _role, _server_address, _expected_address), do: false

  # A GitHub Actions Postgres service container is reached through a published port, so the
  # server sees its own address on the Docker bridge (172.16.0.0/12), never loopback. That
  # range is accepted only on a GitHub Actions runner, and the database-name and role checks
  # above still apply. Any other environment keeps the strict loopback-only rule.
  defp ci_service_network_address?(address) when is_binary(address) do
    System.get_env("GITHUB_ACTIONS") == "true" and
      match?(
        {:ok, {172, second, _, _}} when second in 16..31,
        :inet.parse_address(String.to_charlist(address))
      )
  end

  defp ci_service_network_address?(_), do: false

  defp loopback_address?(address) when is_binary(address) do
    case :inet.parse_address(String.to_charlist(address)) do
      {:ok, {127, _, _, _}} -> true
      {:ok, {0, 0, 0, 0, 0, 0, 0, 1}} -> true
      _ -> false
    end
  end

  defp loopback_address?(_), do: false
end
