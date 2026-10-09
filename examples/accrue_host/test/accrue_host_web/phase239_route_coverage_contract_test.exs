defmodule AccrueHostWeb.Phase239RouteCoverageContractTest do
  use ExUnit.Case, async: true

  alias AccrueHostWeb.Router

  @ledger Path.expand(
            "../../../../.planning/milestones/v1.63-phases/239-integrated-quality-handoff/239-COVERAGE.md",
            __DIR__
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
        |> Enum.map(fn {_mount, path} -> current_asset_path(path, mount, routes) end)
        |> MapSet.new()

      assert compiled_paths == ledger_paths,
             "#{mount} route ledger drift; missing rows: #{inspect(MapSet.difference(compiled_paths, ledger_paths) |> MapSet.to_list() |> Enum.sort())}; stale rows: #{inspect(MapSet.difference(ledger_paths, compiled_paths) |> MapSet.to_list() |> Enum.sort())}"
    end

    ledger_mounts = ledger_routes |> Enum.map(&elem(&1, 0)) |> MapSet.new()

    assert ledger_mounts == package_mounts,
           "package_route rows must cover exactly the compiled package mounts"
  end

  # The archived ledger records route identities and the assets at its acceptance
  # commit. Resolve only its known content-addressed asset slots against today's
  # package authority; compiled routes must still match those exact current hashes.
  # Current served bytes are checked by the mounted Phase 237 provenance owner.
  defp current_asset_path(path, mount, routes) do
    case Regex.run(~r/^(.+)\/assets\/(brand|css|js|phoenix|live-view)-[a-f0-9]{32}$/, path) do
      [_, ^mount, kind] ->
        asset_route =
          Enum.find(
            routes,
            &(is_binary(&1.helper) and String.ends_with?(&1.helper, "_assets") and
                String.starts_with?(&1.path, mount <> "/assets/"))
          )

        module =
          if String.starts_with?(asset_route.helper, "accrue_admin_"),
            do: AccrueAdmin.Assets,
            else: AccruePortal.Assets

        kind = if kind == "live-view", do: :live_view, else: String.to_existing_atom(kind)
        module.hashed_path(kind, mount)

      _ ->
        path
    end
  end
end
