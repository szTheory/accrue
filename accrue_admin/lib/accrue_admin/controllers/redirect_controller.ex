defmodule AccrueAdmin.RedirectController do
  @moduledoc false

  use Phoenix.Controller, formats: []

  @doc """
  Redirects GET /charges to /payments, preserving mount path and query string.

  The mount path is derived from the request path by stripping the /charges suffix,
  so this works regardless of which path the admin is mounted at.
  """
  def charges_index(conn, _params) do
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    mount_path = String.replace_suffix(conn.request_path, "/charges", "")
    redirect(conn, to: mount_path <> "/payments" <> qs)
  end

  @doc """
  Redirects GET /charges/:id to /payments/:id, preserving mount path and query string.

  URI.encode/1 is applied to the :id segment to prevent open-redirect via
  path traversal (T-175-03-02 in the threat model).
  """
  def charges_show(conn, %{"id" => id}) do
    qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
    safe_id = URI.encode(id)
    mount_path = String.replace_suffix(conn.request_path, "/charges/#{id}", "")
    redirect(conn, to: mount_path <> "/payments/" <> safe_id <> qs)
  end
end
