if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.Storybook do
    @moduledoc false

    # D-17 spike C recorded decision: inert attribute chosen as background-suppression
    # mechanism over aria-hidden+focusguard. The `inert` attribute is the most correct
    # and lowest-overhead mechanism for suppressing background interaction when an overlay
    # is open. Browser floor (Chrome 102+, Firefox 112+, Safari 15.5+) is satisfied by
    # accrue_admin's target audience (SaaS operators on modern tooling). The
    # aria-hidden+focusguard fallback would require a JS polyfill and a more complex
    # focus-management contract. Phase 199 enforces inert usage across all overlay surfaces.

    use PhoenixStorybook,
      otp_app: :accrue_admin,
      content_path: Path.expand("../../../../storybook", __DIR__),
      css_path: AccrueAdmin.Assets.hashed_path(:storybook_css, "/dev/storybook"),
      js_path: AccrueAdmin.Assets.hashed_path(:storybook_js, "/dev/storybook"),
      sandbox_class: "accrue-admin",
      color_mode_sandbox_dark_class: "ax-theme-dark-shim"
  end
end
