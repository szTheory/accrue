defmodule AccrueAdmin.DataTableNav do
  @moduledoc """
  Shared `push_patch` navigation for the admin `DataTable` SPA filter contract.

  The `DataTable` LiveComponent renders the filter `<form>` with `phx-change`/
  `phx-submit="data_table_filter"` (parent-targeted — no `phx-target`). Each list
  LiveView delegates that event here, which merges the submitted filter params
  into the table's canonical path and `push_patch`es the result.

  ## Why merge instead of append

  `socket.assigns.table_path` already carries any pre-existing query string. In
  organization mode it is `"/billing/customers?org=acme"` (from each page's
  `scoped_path/3`). A naive `path <> "?" <> URI.encode_query(params)` would emit
  `"/billing/customers?org=acme?q=foo"` — a corrupting second `?` that drops the
  org param and breaks owner-scoping on every apply/change/clear.

  `patch_with_filters/3` instead decodes the existing query, merges the filter
  params over it (filter params win for keys they set), drops blank/nil values so
  cleared fields disappear from the URL, and re-encodes a SINGLE query string. The
  pre-existing `org` (and any other) query param survives every apply/change/clear.
  """

  alias Phoenix.LiveView

  @doc """
  Merges `params` into `path`'s existing query and `push_patch`es the socket.

  * decodes `path`'s existing query string (e.g. `org=acme`)
  * merges `params` over it (filter params win)
  * drops `nil`/`""` values so cleared fields leave the URL
  * re-encodes a single query string (no double `?`)
  * `push_patch`es to the resulting path (no trailing `?` when empty)
  """
  @spec patch_with_filters(LiveView.Socket.t(), String.t(), map()) :: LiveView.Socket.t()
  def patch_with_filters(socket, path, params) when is_binary(path) and is_map(params) do
    LiveView.push_patch(socket, to: merge_query(path, params))
  end

  @doc """
  Builds the merged path string without touching a socket.

  Exposed for unit testing the merge/no-double-?/blank-drop/org-only behavior.
  """
  @spec merge_query(String.t(), map()) :: String.t()
  def merge_query(path, params) when is_binary(path) and is_map(params) do
    uri = URI.parse(path)

    merged =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.merge(stringify(params))
      |> Enum.reject(fn {_key, value} -> blank?(value) end)
      |> Map.new()

    query = if merged == %{}, do: nil, else: URI.encode_query(merged)

    %{uri | query: query} |> URI.to_string()
  end

  defp stringify(params) do
    Map.new(params, fn {key, value} -> {to_string(key), value} end)
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false
end
