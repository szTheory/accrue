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

  An allowlist check rejects any id containing traversal characters (`/`, `\\`,
  `.`, `%`) before building the redirect target (T-175-03-02 defence-in-depth).
  `raw_id` re-encodes the (already-decoded) param before using it to strip the
  suffix from `conn.request_path`, which retains percent-encoding in the raw
  path.
  """
  def charges_show(conn, %{"id" => id}) do
    if String.contains?(id, [".", "/", "\\", "%"]) do
      send_resp(conn, 400, "Bad request")
    else
      qs = if conn.query_string != "", do: "?" <> conn.query_string, else: ""
      raw_id = URI.encode(id, &URI.char_unreserved?/1)
      mount_path = String.replace_suffix(conn.request_path, "/charges/#{raw_id}", "")
      redirect(conn, to: mount_path <> "/payments/" <> raw_id <> qs)
    end
  end
end
