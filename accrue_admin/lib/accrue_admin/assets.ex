defmodule AccrueAdmin.Assets do
  @moduledoc """
  Serves the committed admin CSS and JS bundles from package-owned routes.
  """

  @behaviour Plug

  import Plug.Conn

  @css_file Application.app_dir(:accrue_admin, "priv/static/accrue_admin.css")
  @js_file Application.app_dir(:accrue_admin, "priv/static/accrue_admin.js")

  @external_resource @css_file
  @external_resource @js_file

  @css_body File.read!(@css_file)
  @js_body File.read!(@js_file)

  @css_hash :md5 |> :crypto.hash(@css_body) |> Base.encode16(case: :lower)
  @js_hash :md5 |> :crypto.hash(@js_body) |> Base.encode16(case: :lower)

  @type kind :: :css | :js

  @spec init(kind()) :: kind()
  def init(kind) when kind in [:css, :js], do: kind

  @spec call(Plug.Conn.t(), kind()) :: Plug.Conn.t()
  def call(conn, kind) when kind in [:css, :js] do
    {body, content_type, etag} = asset(kind)

    conn
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_resp_header("etag", ~s("#{etag}"))
    |> put_resp_content_type(content_type)
    |> send_resp(200, body)
  end

  @spec css_hash() :: String.t()
  def css_hash, do: @css_hash

  @spec js_hash() :: String.t()
  def js_hash, do: @js_hash

  @spec hashed_path(kind()) :: String.t()
  def hashed_path(kind), do: hashed_path(kind, "")

  @spec hashed_path(kind(), String.t()) :: String.t()
  def hashed_path(kind, mount_path) when kind in [:css, :js] and is_binary(mount_path) do
    normalized_mount = normalize_mount_path(mount_path)
    suffix = if kind == :css, do: "css-#{@css_hash}", else: "js-#{@js_hash}"
    normalized_mount <> "/assets/" <> suffix
  end

  @spec normalize_mount_path(String.t()) :: String.t()
  def normalize_mount_path(path) when is_binary(path) do
    path
    |> String.trim()
    |> case do
      "" -> "/"
      "/" -> "/"
      value -> "/" <> String.trim_leading(value, "/")
    end
    |> String.trim_trailing("/")
    |> case do
      "" -> "/"
      value -> value
    end
  end

  @spec asset(kind()) :: {binary(), binary(), String.t()}
  def asset(:css), do: {@css_body, "text/css", @css_hash}
  def asset(:js), do: {@js_body, "application/javascript", @js_hash}
end
