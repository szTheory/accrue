defmodule AccruePortal.Assets do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @brand_file Application.app_dir(:accrue, "priv/static/brand.css")
  @css_file Application.app_dir(:accrue_portal, "priv/static/accrue_portal.css")
  @js_file Application.app_dir(:accrue_portal, "priv/static/accrue_portal.js")

  @brand_body File.read!(@brand_file)
  @css_body File.read!(@css_file)
  @js_body File.read!(@js_file)

  @brand_hash :md5 |> :crypto.hash(@brand_body) |> Base.encode16(case: :lower)
  @css_hash :md5 |> :crypto.hash(@css_body) |> Base.encode16(case: :lower)
  @js_hash :md5 |> :crypto.hash(@js_body) |> Base.encode16(case: :lower)

  @type kind :: :brand | :css | :js

  def init(kind) when kind in [:brand, :css, :js], do: kind

  def call(conn, kind) when kind in [:brand, :css, :js] do
    {body, content_type, etag} = asset(kind)

    conn
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_resp_header("etag", ~s("#{etag}"))
    |> put_resp_content_type(content_type)
    |> send_resp(200, body)
  end

  def hashed_path(kind, mount_path) when kind in [:brand, :css, :js] do
    suffix =
      case kind do
        :brand -> "brand-#{@brand_hash}"
        :css -> "css-#{@css_hash}"
        :js -> "js-#{@js_hash}"
      end

    Accrue.Config.normalize_mount_path(mount_path) <> "/assets/" <> suffix
  end

  defp asset(:brand), do: {@brand_body, "text/css", @brand_hash}
  defp asset(:css), do: {@css_body, "text/css", @css_hash}
  defp asset(:js), do: {@js_body, "application/javascript", @js_hash}
end
