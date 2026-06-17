if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
    @moduledoc false

    @type entry :: %{
            family: String.t(),
            variant: String.t(),
            ax_class: String.t(),
            tokens: [String.t()]
          }

    @doc """
    Returns all curated component variant entries across the three DSY-03 families:
    button (4), status (5), card (6 = base + 5 delta tones).

    The `ax_class` field in each entry is the full class string as rendered in the HTML
    class attribute (e.g. `"ax-button ax-button-primary"`). Plan 04's drift test
    extracts rendered class attributes and compares them against these strings.
    """
    @spec entries() :: [entry()]
    def entries do
      [
        # ── Button family — 4 variants from button_variant_class/1 ──────────────────
        # button_variant_class("secondary") → "ax-button-secondary"
        # button_variant_class("ghost")     → "ax-button-ghost"
        # button_variant_class("danger")    → "ax-button-danger"
        # button_variant_class(_)           → "ax-button-primary"
        # Rendered class list: ["ax-button", button_variant_class(variant), nil]
        # Phoenix joins the list → "ax-button ax-button-primary" (nil is dropped)
        %{
          family: "button",
          variant: "primary",
          ax_class: "ax-button ax-button-primary",
          tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"]
        },
        %{
          family: "button",
          variant: "secondary",
          ax_class: "ax-button ax-button-secondary",
          tokens: ["--ax-border-strong", "--ax-elevated", "--ax-primary"]
        },
        %{
          family: "button",
          variant: "ghost",
          ax_class: "ax-button ax-button-ghost",
          tokens: ["--ax-primary", "--ax-interactive-hover", "--ax-transition-colors"]
        },
        # danger is the essential variant: exists in button_variant_class/1 but was
        # absent from the kitchen before DSY-03. Registry must include it (RESEARCH #4).
        # Filled destructive control uses the status-danger-solid pair (AA-tuned per
        # theme); the old --ax-danger/--ax-base mapping rendered a white button in dark.
        %{
          family: "button",
          variant: "danger",
          ax_class: "ax-button ax-button-danger",
          tokens: ["--ax-status-danger-solid", "--ax-status-danger-on-solid", "--ax-transition-colors"]
        },

        # ── StatusBadge family — 5 tone variants from status_tone/1 ────────────────
        # Rendered: class={["ax-status-badge", "ax-status-badge-" <> tone]}
        # → "ax-status-badge ax-status-badge-{tone}"
        %{
          family: "status",
          variant: "moss",
          ax_class: "ax-status-badge ax-status-badge-moss",
          tokens: ["--ax-success", "--ax-success-readable", "--ax-elevated"]
        },
        %{
          family: "status",
          variant: "cobalt",
          ax_class: "ax-status-badge ax-status-badge-cobalt",
          tokens: ["--ax-accent", "--ax-accent-readable", "--ax-elevated"]
        },
        %{
          family: "status",
          variant: "amber",
          ax_class: "ax-status-badge ax-status-badge-amber",
          tokens: ["--ax-warning", "--ax-warning-readable", "--ax-elevated"]
        },
        %{
          family: "status",
          variant: "slate",
          ax_class: "ax-status-badge ax-status-badge-slate",
          tokens: ["--ax-border", "--ax-muted", "--ax-elevated"]
        },
        %{
          family: "status",
          variant: "ink",
          ax_class: "ax-status-badge ax-status-badge-ink",
          tokens: ["--ax-primary", "--ax-elevated"]
        },

        # ── Card family — base + 5 delta tones from normalize_tone/1 ───────────────
        # Base KPI card: class={["ax-card ax-kpi-card", @class]} → "ax-card ax-kpi-card"
        # Delta span:    class={["ax-kpi-delta", "ax-kpi-delta-" <> normalize_tone(tone)]}
        #                → "ax-kpi-delta ax-kpi-delta-{tone}"
        %{
          family: "card",
          variant: "base",
          ax_class: "ax-card ax-kpi-card",
          tokens: ["--ax-elevated", "--ax-shadow-sm", "--ax-border"]
        },
        %{
          family: "card",
          variant: "moss",
          ax_class: "ax-kpi-delta ax-kpi-delta-moss",
          tokens: ["--ax-success", "--ax-transition-colors"]
        },
        %{
          family: "card",
          variant: "cobalt",
          ax_class: "ax-kpi-delta ax-kpi-delta-cobalt",
          tokens: ["--ax-accent", "--ax-accent-readable", "--ax-transition-colors"]
        },
        %{
          family: "card",
          variant: "amber",
          ax_class: "ax-kpi-delta ax-kpi-delta-amber",
          tokens: ["--ax-warning", "--ax-transition-colors"]
        },
        %{
          family: "card",
          variant: "slate",
          ax_class: "ax-kpi-delta ax-kpi-delta-slate",
          tokens: ["--ax-primary", "--ax-muted", "--ax-transition-colors"]
        },
        %{
          family: "card",
          variant: "ink",
          ax_class: "ax-kpi-delta ax-kpi-delta-ink",
          tokens: ["--ax-primary", "--ax-muted", "--ax-transition-colors"]
        },

        # ── Phase 188 foundation specimens ────────────────────────────────────────
        %{
          family: "foundation-type",
          variant: "roles",
          ax_class: "ax-foundation ax-foundation-type",
          tokens: ["--ax-type-body-font", "--ax-type-display-font", "--ax-type-body-tracking"]
        },
        %{
          family: "foundation-measure",
          variant: "prose",
          ax_class: "ax-foundation ax-foundation-measure",
          tokens: ["--ax-measure"]
        },
        %{
          family: "foundation-layer",
          variant: "stack",
          ax_class: "ax-foundation ax-foundation-layer",
          tokens: [
            "--ax-z-sticky",
            "--ax-z-dropdown",
            "--ax-z-popover",
            "--ax-z-drawer",
            "--ax-z-modal",
            "--ax-z-toast"
          ]
        },
        %{
          family: "foundation-focus",
          variant: "control",
          ax_class: "ax-foundation ax-foundation-focus",
          tokens: ["--ax-focus-ring", "--ax-focus-ring-offset", "--ax-focus-shadow"]
        },
        %{
          family: "foundation-disabled-readonly",
          variant: "states",
          ax_class: "ax-foundation ax-foundation-disabled-readonly",
          tokens: [
            "--ax-disabled-bg",
            "--ax-disabled-text",
            "--ax-readonly-bg",
            "--ax-readonly-text"
          ]
        },
        %{
          family: "foundation-interactive",
          variant: "states",
          ax_class: "ax-foundation ax-foundation-interactive",
          tokens: [
            "--ax-interactive-hover",
            "--ax-interactive-active",
            "--ax-interactive-selected"
          ]
        },
        %{
          family: "foundation-scrollbar",
          variant: "root",
          ax_class: "ax-foundation ax-foundation-scrollbar",
          tokens: ["--ax-scrollbar-thumb", "--ax-scrollbar-track", "--ax-scrollbar-thumb-hover"]
        },
        %{
          family: "foundation-status",
          variant: "roles",
          ax_class: "ax-foundation ax-foundation-status",
          tokens: [
            "--ax-status-success-bg",
            "--ax-status-warning-bg",
            "--ax-status-danger-bg",
            "--ax-status-info-bg",
            "--ax-status-neutral-bg"
          ]
        }
      ]
    end

    @doc "All entries for a given family string."
    @spec variants_for(String.t()) :: [entry()]
    def variants_for(family) do
      Enum.filter(entries(), &(&1.family == family))
    end
  end
end
