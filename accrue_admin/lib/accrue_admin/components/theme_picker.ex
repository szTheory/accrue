defmodule AccrueAdmin.Components.ThemePicker do
  @moduledoc """
  Color-theme picker — a unified segmented control for light / dark / system.

  One recessed track holding three segments (icon + label); the active segment
  renders as a contained, raised "thumb" with a subtle accent ring. The control
  is purely presentational: persistence and the live `data-theme` swap are owned
  by the `accrue_theme` JS hook (delegated click + arrow-key nav), keyed off the
  stable `data-theme-target` attribute. Server-rendered `@theme` sets the initial
  active segment so there is no flash before the hook syncs.

      <ThemePicker.theme_picker theme={@theme} />

  Accessibility: `role="radiogroup"` with `role="radio"` segments, roving
  `tabindex`, and a per-segment `aria-label` so the control keeps an accessible
  name when labels collapse to icon-only on narrow viewports.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon

  @options [
    {"light", "Light", :sun},
    {"dark", "Dark", :moon},
    {"system", "System", :computer_desktop}
  ]

  attr(:theme, :string, default: "system", values: ~w(light dark system))
  attr(:class, :any, default: nil)

  def theme_picker(assigns) do
    assigns = assign(assigns, :options, @options)

    ~H"""
    <div class={["ax-theme-picker", @class]} role="radiogroup" aria-label="Color theme">
      <button
        :for={{value, label, icon} <- @options}
        type="button"
        role="radio"
        aria-checked={to_string(@theme == value)}
        aria-label={label}
        title={label}
        tabindex={if @theme == value, do: "0", else: "-1"}
        data-theme-target={value}
        class={["ax-theme-picker-option", @theme == value && "ax-theme-picker-option-active"]}
      >
        <Icon.icon name={icon} size="sm" />
        <span class="ax-theme-picker-label"><%= label %></span>
      </button>
    </div>
    """
  end
end
