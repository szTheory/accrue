defmodule AccrueHostWeb.Phase239RouteCoverageContractTest do
  use ExUnit.Case, async: true

  alias AccrueHostWeb.Router

  @ledger Path.expand(
            "../../.planning/phases/239-integrated-quality-handoff/239-COVERAGE.md",
            File.cwd!()
          )

  test "every compiled Admin and Portal package route has an exact ledger disposition" do
    routes = Router.__routes__()
    ledger = File.read!(@ledger)

    ledger_routes =
      Regex.scan(~r/^\| package_route \| ([^|]+) \| ([^|]+) \|/m, ledger)
      |> Enum.map(fn [_, mount, path] -> {String.trim(mount), String.trim(path)} end)
      |> MapSet.new()

    ordered_ledger_routes =
      Regex.scan(~r/^\| package_route \| ([^|]+) \| ([^|]+) \|/m, ledger)
      |> Enum.map(fn [_, mount, path] -> {String.trim(mount), String.trim(path)} end)

    assert ordered_ledger_routes ==
             Enum.sort_by(ordered_ledger_routes, fn {mount, path} -> {mount, path} end),
           "package_route rows must remain ordered by mount then route path"

    package_mounts =
      routes
      |> Enum.filter(fn route ->
        is_binary(route.helper) and
          (String.starts_with?(route.helper, "accrue_admin_") or
             String.starts_with?(route.helper, "accrue_portal_")) and
          String.ends_with?(route.helper, "_assets") and String.contains?(route.path, "/assets/")
      end)
      |> Enum.map(fn route ->
        [mount | _] = String.split(route.path, "/assets/", parts: 2)
        mount
      end)
      |> MapSet.new()

    assert MapSet.size(package_mounts) > 0,
           "expected package asset route helpers to derive mounts"

    for mount <- package_mounts do
      compiled_paths =
        routes
        |> Enum.filter(&(&1.path == mount or String.starts_with?(&1.path, mount <> "/")))
        |> Enum.map(& &1.path)
        |> MapSet.new()

      ledger_paths =
        ledger_routes
        |> Enum.filter(fn {row_mount, _path} -> row_mount == mount end)
        |> Enum.map(&elem(&1, 1))
        |> MapSet.new()

      assert compiled_paths == ledger_paths,
             "#{mount} route ledger drift; missing rows: #{inspect(MapSet.difference(compiled_paths, ledger_paths) |> MapSet.to_list() |> Enum.sort())}; stale rows: #{inspect(MapSet.difference(ledger_paths, compiled_paths) |> MapSet.to_list() |> Enum.sort())}"
    end

    ledger_mounts = ledger_routes |> Enum.map(&elem(&1, 0)) |> MapSet.new()

    assert ledger_mounts == package_mounts,
           "package_route rows must cover exactly the compiled package mounts"
  end
end
