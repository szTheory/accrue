defmodule AccrueAdmin.Layouts do
  @moduledoc """
  Minimal root layout for mounted admin LiveViews.
  """

  use Phoenix.Component

  attr(:inner_content, :any, required: true)
  attr(:page_title, :string, default: "Accrue Admin")
  attr(:assets_css_path, :string, default: nil)
  attr(:assets_js_path, :string, default: nil)

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="accrue-admin">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title><%= @page_title %></title>
        <link :if={@assets_css_path} rel="stylesheet" href={@assets_css_path} />
      </head>
      <body class="accrue-admin-shell">
        <%= @inner_content %>
        <script :if={@assets_js_path} defer src={@assets_js_path}></script>
      </body>
    </html>
    """
  end
end
