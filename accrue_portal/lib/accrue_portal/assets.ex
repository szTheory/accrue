defmodule AccruePortal.Assets do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @brand_file Application.app_dir(:accrue, "priv/static/brand.css")
  @css_file Application.app_dir(:accrue_portal, "priv/static/accrue_portal.css")
  @js_file Application.app_dir(:accrue_portal, "priv/static/accrue_portal.js")
  @phoenix_js_file Application.app_dir(:phoenix, "priv/static/phoenix.min.js")
  @live_view_js_file Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.min.js")

  @brand_body File.read!(@brand_file)
  @css_body File.read!(@css_file)
  @js_body File.read!(@js_file)
  @phoenix_js_body File.read!(@phoenix_js_file)
  @live_view_js_body File.read!(@live_view_js_file)

  @brand_hash :md5 |> :crypto.hash(@brand_body) |> Base.encode16(case: :lower)
  @css_hash :md5 |> :crypto.hash(@css_body) |> Base.encode16(case: :lower)
  @js_hash :md5 |> :crypto.hash(@js_body) |> Base.encode16(case: :lower)
  @phoenix_js_hash :md5 |> :crypto.hash(@phoenix_js_body) |> Base.encode16(case: :lower)
  @live_view_js_hash :md5 |> :crypto.hash(@live_view_js_body) |> Base.encode16(case: :lower)

  @type kind :: :brand | :css | :js | :phoenix | :live_view

  def brand_hash, do: @brand_hash
  def css_hash, do: @css_hash
  def js_hash, do: @js_hash
  def phoenix_hash, do: @phoenix_js_hash
  def live_view_hash, do: @live_view_js_hash

  def init(kind) when kind in [:brand, :css, :js, :phoenix, :live_view], do: kind

  def call(conn, kind) when kind in [:brand, :css, :js, :phoenix, :live_view] do
    {body, content_type, etag} = asset(kind)

    conn
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_resp_header("etag", ~s("#{etag}"))
    |> put_resp_content_type(content_type)
    |> send_resp(200, body)
  end

  def hashed_path(kind, mount_path) when kind in [:brand, :css, :js, :phoenix, :live_view] do
    suffix =
      case kind do
        :brand -> "brand-#{@brand_hash}"
        :css -> "css-#{@css_hash}"
        :js -> "js-#{@js_hash}"
        :phoenix -> "phoenix-#{@phoenix_js_hash}"
        :live_view -> "live-view-#{@live_view_js_hash}"
      end

    Accrue.Config.normalize_mount_path(mount_path) <> "/assets/" <> suffix
  end

  defp asset(:brand), do: {@brand_body, "text/css", @brand_hash}
  defp asset(:css), do: {@css_body, "text/css", @css_hash}
  defp asset(:js), do: {@js_body, "application/javascript", @js_hash}
  defp asset(:phoenix), do: {@phoenix_js_body, "application/javascript", @phoenix_js_hash}
  defp asset(:live_view), do: {@live_view_js_body, "application/javascript", @live_view_js_hash}
end
