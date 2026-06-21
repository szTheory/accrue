defmodule AccrueAdmin.Components.IdBadge do
  @moduledoc """
  Interactive click-to-copy monospace ID chip.

  Distinct from the display-only `InlineId` (`ax-inline-id`): `IdBadge` is a
  clickable control that copies its `id_value` to the clipboard via the registered
  `Clipboard` LiveView hook. Because the hook mounts per-element, copy keeps working
  on rows appended by infinite-scroll and rows re-rendered on filter `push_patch`.

      <IdBadge.id_badge id="ax-id-badge-cus_1" id_value="cus_phase191_host_1" />

  `phx-hook` requires a unique DOM id. Callers rendering a chip per list row MUST
  pass a row-derived `id` (e.g. `id={"ax-id-badge-" <> to_string(row.id)}`). When no
  `id` is supplied it derives a stable one from `id_value`.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon

  attr(:id, :string, default: nil)
  attr(:id_value, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  def id_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:dom_id, fn -> assigns.id || "ax-id-badge-" <> to_string(assigns.id_value) end)
      |> assign_new(:aria_label, fn -> assigns.label || "Copy " <> to_string(assigns.id_value) end)

    ~H"""
    <button
      id={@dom_id}
      type="button"
      class={["ax-id-badge", "ax-id-badge-default", @class]}
      phx-hook="Clipboard"
      data-clipboard-text={@id_value}
      title={@id_value}
      aria-label={@aria_label}
      {@rest}
    >
      <span class="ax-id-badge-text"><%= @id_value %></span>
      <Icon.icon name={:copy} size="sm" />
    </button>
    """
  end
end
