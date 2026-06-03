defmodule AccrueAdmin.Components.Icon do
  @moduledoc """
  Inline SVG icon primitive for the admin UI.

  Renders [Heroicons](https://heroicons.com) (MIT-licensed) outline glyphs as inline
  SVG — no sprite file, no runtime JS, CSP-clean. Icons inherit color via
  `currentColor` and are sized by the `--ax-icon-*` design tokens (`size` attr).

      <Icon.icon name={:bolt} />
      <Icon.icon name={:arrow_right} size="sm" class="text-accent" />

  Decorative by default (`aria-hidden`). Pass `label` to expose an accessible name
  for an icon that carries meaning on its own (e.g. an icon-only button/link).
  """

  use Phoenix.Component

  @names ~w(home users subscriptions invoices payments recovery webhooks events
            coupons promotions connect search arrow_right arrow_long_right
            chevron_right chevron_down chevron_up_down x_mark check check_circle
            exclamation_triangle information_circle external clock banknotes
            replay funnel plus building dots_vertical inbox)a

  @doc """
  Renders an inline icon.

  ## Attributes
    * `name` — required, one of `#{inspect(@names)}`
    * `size` — `"sm"` (16px) | `"md"` (20px, default) | `"lg"` (24px)
    * `class` — extra classes merged onto the `<svg>`
    * `label` — accessible name; when set the icon is exposed to AT (not hidden)
  """
  attr(:name, :atom, required: true, values: @names)
  attr(:size, :string, default: "md", values: ~w(sm md lg))
  attr(:class, :any, default: nil)
  attr(:label, :string, default: nil)
  attr(:rest, :global)

  def icon(assigns) do
    ~H"""
    <svg
      class={["ax-icon", "ax-icon-#{@size}", @class]}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden={if @label, do: "false", else: "true"}
      role={if @label, do: "img"}
      aria-label={@label}
      {@rest}
    >
      <title :if={@label}><%= @label %></title>
      <%= Phoenix.HTML.raw(paths(@name)) %>
    </svg>
    """
  end

  @doc "All icon names this component can render."
  @spec names() :: [atom()]
  def names, do: @names

  # Heroicons v2 outline path data (24x24). Static literals — `raw/1` is safe.
  defp paths(:home),
    do:
      ~s(<path d="M2.25 12 11.2 3.045a1.125 1.125 0 0 1 1.6 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75"/><path d="M8.25 21h8.25"/>)

  defp paths(:users),
    do:
      ~s(<path d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"/>)

  defp paths(:subscriptions),
    do:
      ~s(<path d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"/>)

  defp paths(:invoices),
    do:
      ~s(<path d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>)

  defp paths(:payments),
    do:
      ~s(<path d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 0 0 2.25-2.25V6.75A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25v10.5A2.25 2.25 0 0 0 4.5 19.5Z"/>)

  defp paths(:recovery),
    do:
      ~s(<path d="M2.25 18 9 11.25l4.306 4.307a11.95 11.95 0 0 1 5.814-5.519l2.74-1.22m0 0-5.94-2.28m5.94 2.28-2.28 5.941"/>)

  defp paths(:webhooks),
    do: ~s(<path d="M3.75 13.5 14.25 2.25 12 10.5h8.25L9.75 21.75 12 13.5H3.75Z"/>)

  defp paths(:events),
    do: ~s(<path d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"/>)

  defp paths(:coupons),
    do:
      ~s(<path d="M16.5 6v.75m0 3v.75m0 3v.75m0 3V18m-9-5.25h5.25M7.5 15h3M3.375 5.25c-.621 0-1.125.504-1.125 1.125v3.026a2.999 2.999 0 0 1 0 5.198v3.026c0 .621.504 1.125 1.125 1.125h17.25c.621 0 1.125-.504 1.125-1.125v-3.026a2.999 2.999 0 0 1 0-5.198V6.375c0-.621-.504-1.125-1.125-1.125H3.375Z"/>)

  defp paths(:promotions),
    do:
      ~s(<path d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z"/><path d="M6 6h.008v.008H6V6Z"/>)

  defp paths(:connect),
    do:
      ~s(<path d="M13.19 8.688a4.5 4.5 0 0 1 1.242 7.244l-4.5 4.5a4.5 4.5 0 0 1-6.364-6.364l1.757-1.757m13.35-.622 1.757-1.757a4.5 4.5 0 0 0-6.364-6.364l-4.5 4.5a4.5 4.5 0 0 0 1.242 7.244"/>)

  defp paths(:search),
    do:
      ~s(<path d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"/>)

  defp paths(:arrow_right), do: ~s(<path d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/>)

  defp paths(:arrow_long_right), do: ~s(<path d="M17.25 8.25 21 12m0 0-3.75 3.75M21 12H3"/>)

  defp paths(:chevron_right), do: ~s(<path d="m8.25 4.5 7.5 7.5-7.5 7.5"/>)

  defp paths(:chevron_down), do: ~s(<path d="m19.5 8.25-7.5 7.5-7.5-7.5"/>)

  defp paths(:chevron_up_down),
    do: ~s(<path d="M8.25 15 12 18.75 15.75 15m-7.5-6L12 5.25 15.75 9"/>)

  defp paths(:x_mark), do: ~s(<path d="M6 18 18 6M6 6l12 12"/>)

  defp paths(:check), do: ~s(<path d="m4.5 12.75 6 6 9-13.5"/>)

  defp paths(:check_circle),
    do: ~s(<path d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>)

  defp paths(:exclamation_triangle),
    do:
      ~s(<path d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/>)

  defp paths(:information_circle),
    do:
      ~s(<path d="M11.25 11.25l.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"/>)

  defp paths(:external),
    do:
      ~s(<path d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"/>)

  defp paths(:clock),
    do: ~s(<path d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>)

  defp paths(:banknotes),
    do:
      ~s(<path d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z"/>)

  defp paths(:replay),
    do: ~s(<path d="M9 15 3 9m0 0 6-6M3 9h12a6 6 0 0 1 0 12h-3"/>)

  defp paths(:funnel),
    do:
      ~s(<path d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25 2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0 1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0 0-.659-1.591L3.659 7.409A2.25 2.25 0 0 1 3 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0 1 12 3Z"/>)

  defp paths(:plus), do: ~s(<path d="M12 4.5v15m7.5-7.5h-15"/>)

  defp paths(:building),
    do:
      ~s(<path d="M3.75 21h16.5M4.5 3h15M5.25 3v18m13.5-18v18M9 6.75h1.5m-1.5 3h1.5m-1.5 3h1.5m3-6H15m-1.5 3H15m-1.5 3H15M9 21v-3.375c0-.621.504-1.125 1.125-1.125h3.75c.621 0 1.125.504 1.125 1.125V21"/>)

  defp paths(:dots_vertical),
    do:
      ~s(<path d="M12 6.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 12.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 18.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5Z"/>)

  defp paths(:inbox),
    do:
      ~s(<path d="M2.25 13.5h3.86a2.25 2.25 0 0 1 2.012 1.244l.256.512a2.25 2.25 0 0 0 2.013 1.244h3.218a2.25 2.25 0 0 0 2.013-1.244l.256-.512a2.25 2.25 0 0 1 2.013-1.244h3.859m-19.5.338V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18v-4.162c0-.224-.034-.447-.1-.661L19.24 5.338a2.25 2.25 0 0 0-2.15-1.588H6.911a2.25 2.25 0 0 0-2.15 1.588L2.35 13.177a2.25 2.25 0 0 0-.1.661Z"/>)
end
