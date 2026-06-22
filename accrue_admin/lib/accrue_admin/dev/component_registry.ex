if Mix.env() != :prod do
  defmodule AccrueAdmin.Dev.ComponentRegistry do
    @moduledoc false

    @type entry :: %{
            family: String.t(),
            variant: String.t(),
            ax_class: String.t(),
            tokens: [String.t()],
            applicable_states: [String.t()] | nil,
            na_states: [%{state: String.t(), reason: String.t()}] | nil,
            specimens: [%{label: String.t(), props: map(), content: String.t() | nil}] | nil
          }

    @type group_contract :: %{
            name: String.t(),
            slug: String.t(),
            proof_id: String.t(),
            required_states: [String.t()],
            primary_components: [String.t()],
            locators: [String.t()],
            phase191_handoff_tags: [String.t()],
            behavior_contracts: [String.t()],
            hierarchy: [String.t()],
            representative_route_category: String.t(),
            decisions: [String.t()]
          }

    @doc """
    Returns the canonical Phase 190 component-group contracts.

    These mirror the frozen Phase 187 COMPONENT_GROUPS names and provide the
    `data-component-group` slugs later kitchen/probe plans consume.
    """
    @spec group_contracts() :: [group_contract()]
    def group_contracts do
      [
        %{
          name: "page-header/actions/breadcrumbs",
          slug: "page-header-actions-breadcrumbs",
          proof_id: "grp190-page-header-actions-breadcrumbs",
          required_states: ["long-content", "overflow", "mobile-wrap", "dark-mode"],
          primary_components: ["Breadcrumbs", "Button", "AppShell page header"],
          locators: group_locators("page-header-actions-breadcrumbs"),
          phase191_handoff_tags: ["liveview-patch-focus", "microcopy"],
          behavior_contracts: [
            "Breadcrumbs orient before the task heading.",
            "Primary action remains in the same visual band as the task.",
            "Mobile wraps actions below the title without separating context."
          ],
          hierarchy: [
            "orientation",
            "task heading",
            "supporting copy",
            "primary and secondary actions"
          ],
          representative_route_category: "admin page header",
          decisions: ["D-01", "D-02", "D-05", "D-16", "D-17", "D-20", "D-21"]
        },
        %{
          name: "toolbar/search/filter/sort",
          slug: "toolbar-search-filter-sort",
          proof_id: "grp190-toolbar-search-filter-sort",
          required_states: [
            "long-content",
            "overflow",
            "filtered-empty",
            "selected-filter-active",
            "mobile-wrap",
            "dark-mode"
          ],
          primary_components: [
            "DataTable filters",
            "FilterChipBar",
            "GlobalSearch",
            "DropdownMenu"
          ],
          locators: group_locators("toolbar-search-filter-sort"),
          phase191_handoff_tags: ["liveview-patch-focus", "fixture-gaps", "microcopy"],
          behavior_contracts: [
            "Filters sit with the table/list they constrain.",
            "Active filters remain visible as chips or selected controls.",
            "Search, filter, sort, apply, and clear actions stack below 768px."
          ],
          hierarchy: [
            "filter label",
            "search/filter/sort controls",
            "active constraints",
            "apply or clear action"
          ],
          representative_route_category: "list toolbar",
          decisions: ["D-01", "D-02", "D-06", "D-12", "D-13", "D-17", "D-23", "D-24"]
        },
        %{
          name: "table/empty/loading/error/pagination",
          slug: "table-empty-loading-error-pagination",
          proof_id: "grp190-table-empty-loading-error-pagination",
          required_states: [
            "long-content",
            "overflow",
            "empty",
            "filtered-empty",
            "loading",
            "error",
            "no-pagination",
            "has-pagination",
            "selected-filter-active",
            "mobile-card-list-degradation",
            "dark-mode"
          ],
          primary_components: ["DataTable", "EmptyState", "Spinner", "StatusBadge", "Button"],
          locators: group_locators("table-empty-loading-error-pagination"),
          phase191_handoff_tags: ["scroll-reachability", "fixture-gaps", "microcopy"],
          behavior_contracts: [
            "Entity queues use DataTable desktop table plus mobile cards.",
            "Only one responsive mode is accessible and focusable at a time.",
            "Load more appears only when a next cursor or equivalent exists."
          ],
          hierarchy: [
            "table caption or label",
            "column or card identity",
            "row facts and status",
            "row actions",
            "cursor-gated footer"
          ],
          representative_route_category: "list and table page",
          decisions: [
            "D-02",
            "D-06",
            "D-08",
            "D-10",
            "D-11",
            "D-12",
            "D-13",
            "D-14",
            "D-29"
          ]
        },
        %{
          name: "KPI/chart/table",
          slug: "kpi-chart-table",
          proof_id: "grp190-kpi-chart-table",
          required_states: [
            "long-content",
            "overflow",
            "empty",
            "loading",
            "error",
            "no-pagination",
            "has-pagination",
            "mobile-card-list-degradation",
            "dark-mode"
          ],
          primary_components: ["KpiCard", "FunnelChart", "AtRiskTable", "DataTable"],
          locators: group_locators("kpi-chart-table"),
          phase191_handoff_tags: ["fixture-gaps", "microcopy"],
          behavior_contracts: [
            "Summary KPIs precede trend or chart evidence.",
            "Trend or chart evidence precedes row-level drill-down.",
            "Specialized tables honor the shared data-display state contract."
          ],
          hierarchy: ["summary metrics", "trend evidence", "row evidence", "drill-down actions"],
          representative_route_category: "recovery analytics",
          decisions: ["D-06", "D-09", "D-15", "D-17", "D-18", "D-19", "D-21"]
        },
        %{
          name: "detail-header/metadata/actions",
          slug: "detail-header-metadata-actions",
          proof_id: "grp190-detail-header-metadata-actions",
          required_states: [
            "long-content",
            "overflow",
            "loading",
            "error",
            "mobile-wrap",
            "dark-mode"
          ],
          primary_components: ["Detail", "RelatedResources", "StatusBadge", "InlineId", "Button"],
          locators: group_locators("detail-header-metadata-actions"),
          phase191_handoff_tags: ["fixture-gaps", "microcopy"],
          behavior_contracts: [
            "Object identity appears before metadata and actions.",
            "Metadata wraps IDs and external identifiers intentionally.",
            "Actions stay adjacent to object identity across breakpoints."
          ],
          hierarchy: ["eyebrow", "title or ID", "status", "primary facts", "actions"],
          representative_route_category: "detail page",
          decisions: ["D-02", "D-03", "D-06", "D-16", "D-17", "D-18", "D-19", "D-21"]
        },
        %{
          name: "modal-confirm",
          slug: "modal-confirm",
          proof_id: "grp190-modal-confirm",
          required_states: [
            "long-content",
            "overflow",
            "loading",
            "error",
            "mobile-stack",
            "dark-mode"
          ],
          primary_components: ["StepUpAuthModal", "Button", "Icon"],
          locators: group_locators("modal-confirm"),
          phase191_handoff_tags: [
            "focus-trap",
            "focus-restore",
            "escape",
            "click-outside",
            "scroll-reachability",
            "overlay-position",
            "microcopy"
          ],
          behavior_contracts: [
            "Dialog exposes title and description IDs.",
            "Footer keeps cancel neutral and confirm visually unmistakable.",
            "Panel consumes modal layer tokens and mobile action stacking."
          ],
          hierarchy: [
            "title",
            "description",
            "object consequence",
            "cancel action",
            "confirm action"
          ],
          representative_route_category: "overlay confirmation",
          decisions: ["D-23", "D-24", "D-25", "D-26", "D-30"]
        },
        %{
          name: "drawer/form",
          slug: "drawer-form",
          proof_id: "grp190-drawer-form",
          required_states: [
            "long-content",
            "overflow",
            "loading",
            "error",
            "selected-filter-active",
            "mobile-fullscreen",
            "dark-mode"
          ],
          primary_components: ["DetailDrawer", "Input", "Select", "Textarea", "Button"],
          locators: group_locators("drawer-form"),
          phase191_handoff_tags: [
            "focus-trap",
            "focus-restore",
            "escape",
            "click-outside",
            "scroll-reachability",
            "overlay-position",
            "fixture-gaps",
            "microcopy"
          ],
          behavior_contracts: [
            "Drawer header, body, and footer keep visible action rhythm.",
            "Scrollable body cannot strand footer actions.",
            "Form errors sit directly below the field they describe."
          ],
          hierarchy: ["title", "description", "form body", "field errors", "footer actions"],
          representative_route_category: "drawer edit flow",
          decisions: ["D-20", "D-23", "D-24", "D-25", "D-26", "D-30"]
        },
        %{
          name: "tabs/subviews",
          slug: "tabs-subviews",
          proof_id: "grp190-tabs-subviews",
          required_states: [
            "long-content",
            "overflow",
            "selected-filter-active",
            "mobile-scroll",
            "dark-mode"
          ],
          primary_components: ["Tabs", "WindowSelector", "Breadcrumbs"],
          locators: group_locators("tabs-subviews"),
          phase191_handoff_tags: ["liveview-patch-focus", "microcopy"],
          behavior_contracts: [
            "Route and patch navigation use links with aria-current.",
            "Active tab uses text, border, and selected state.",
            "Long tab rows remain horizontally reachable without hiding active state."
          ],
          hierarchy: ["current route label", "tab labels", "counts", "active indicator"],
          representative_route_category: "route subnavigation",
          decisions: ["D-02", "D-06", "D-17", "D-23", "D-28", "D-30"]
        }
      ]
    end

    @doc "Ordered Phase 190 component-group slugs for data-component-group locators."
    @spec component_group_slugs() :: [String.t()]
    def component_group_slugs do
      Enum.map(group_contracts(), & &1.slug)
    end

    @doc "Looks up a group contract by its static Phase 190 slug."
    @spec group_contract_by_slug(String.t()) :: group_contract() | nil
    def group_contract_by_slug(slug) when is_binary(slug) do
      Enum.find(group_contracts(), &(&1.slug == slug))
    end

    @doc """
    Returns all curated component variant entries across the three DSY-03 families:
    button (4), status (5), card (6 = base + 5 delta tones), plus foundation entries.

    The `ax_class` field in each entry is the full class string as rendered in the HTML
    class attribute (e.g. `"ax-button ax-button-primary"`). Plan 04's drift test
    extracts rendered class attributes and compares them against these strings.

    Phase 189 additions: `button` and `status` families carry three new schema fields:
    - `applicable_states` — list of state names from the 11-state taxonomy
    - `na_states` — list of `%{state: string, reason: string}` maps for states that don't apply
    - `specimens` — list of `%{label: string, props: map, content: string | nil}` maps
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
          tokens: ["--ax-accent-strong", "--ax-accent-contrast", "--ax-transition-colors"],
          # Phase 189 — state-matrix schema additions
          applicable_states: [
            "default",
            "hover",
            "focus",
            "active",
            "pressed",
            "disabled",
            "loading",
            "overflow"
          ],
          na_states: [
            %{
              state: "selected",
              reason:
                "button has no selection state — use aria-pressed for toggle buttons separately"
            },
            %{state: "empty", reason: "button always has a label"},
            %{state: "error", reason: "button conveys intent via variant, not validation state"}
          ],
          specimens: [
            %{
              label: "Default",
              props: %{variant: "primary", type: "button"},
              content: "Save changes"
            },
            %{label: "Short", props: %{variant: "primary", type: "button"}, content: "Go"},
            %{
              label: "Long label (overflow)",
              props: %{variant: "primary", type: "button"},
              content: "Export all subscription events to CSV"
            },
            %{
              label: "Disabled",
              props: %{variant: "primary", type: "button", disabled: true},
              content: "Archived"
            },
            %{label: "Loading", props: %{variant: "primary", type: "button"}, content: "Saving…"}
          ]
        },
        %{
          family: "button",
          variant: "secondary",
          ax_class: "ax-button ax-button-secondary",
          tokens: ["--ax-border-strong", "--ax-elevated", "--ax-primary"],
          applicable_states: [
            "default",
            "hover",
            "focus",
            "active",
            "pressed",
            "disabled",
            "loading",
            "overflow"
          ],
          na_states: [
            %{
              state: "selected",
              reason:
                "button has no selection state — use aria-pressed for toggle buttons separately"
            },
            %{state: "empty", reason: "button always has a label"},
            %{state: "error", reason: "button conveys intent via variant, not validation state"}
          ],
          specimens: [
            %{
              label: "Default",
              props: %{variant: "secondary", type: "button"},
              content: "Cancel"
            },
            %{
              label: "Long label (overflow)",
              props: %{variant: "secondary", type: "button"},
              content: "Export all subscription events to CSV"
            },
            %{
              label: "Disabled",
              props: %{variant: "secondary", type: "button", disabled: true},
              content: "Archived"
            },
            %{
              label: "Loading",
              props: %{variant: "secondary", type: "button"},
              content: "Saving…"
            }
          ]
        },
        %{
          family: "button",
          variant: "ghost",
          ax_class: "ax-button ax-button-ghost",
          tokens: ["--ax-primary", "--ax-interactive-hover", "--ax-transition-colors"],
          applicable_states: [
            "default",
            "hover",
            "focus",
            "active",
            "pressed",
            "disabled",
            "loading",
            "overflow"
          ],
          na_states: [
            %{
              state: "selected",
              reason:
                "button has no selection state — use aria-pressed for toggle buttons separately"
            },
            %{state: "empty", reason: "button always has a label"},
            %{state: "error", reason: "button conveys intent via variant, not validation state"}
          ],
          specimens: [
            %{
              label: "Default",
              props: %{variant: "ghost", type: "button"},
              content: "View details"
            },
            %{
              label: "Long label (overflow)",
              props: %{variant: "ghost", type: "button"},
              content: "Export all subscription events to CSV"
            },
            %{
              label: "Disabled",
              props: %{variant: "ghost", type: "button", disabled: true},
              content: "Archived"
            },
            %{label: "Loading", props: %{variant: "ghost", type: "button"}, content: "Saving…"}
          ]
        },
        # danger is the essential variant: exists in button_variant_class/1 but was
        # absent from the kitchen before DSY-03. Registry must include it (RESEARCH #4).
        # Filled destructive control uses the status-danger-solid pair (AA-tuned per
        # theme); the old --ax-danger/--ax-base mapping rendered a white button in dark.
        %{
          family: "button",
          variant: "danger",
          ax_class: "ax-button ax-button-danger",
          tokens: [
            "--ax-status-danger-solid",
            "--ax-status-danger-on-solid",
            "--ax-transition-colors"
          ],
          applicable_states: [
            "default",
            "hover",
            "focus",
            "active",
            "pressed",
            "disabled",
            "loading",
            "overflow"
          ],
          na_states: [
            %{
              state: "selected",
              reason:
                "button has no selection state — use aria-pressed for toggle buttons separately"
            },
            %{state: "empty", reason: "button always has a label"},
            %{state: "error", reason: "button conveys intent via variant, not validation state"}
          ],
          specimens: [
            %{
              label: "Default",
              props: %{variant: "danger", type: "button"},
              content: "Delete subscription"
            },
            %{
              label: "Long label (overflow)",
              props: %{variant: "danger", type: "button"},
              content: "Export all subscription events to CSV"
            },
            %{
              label: "Disabled",
              props: %{variant: "danger", type: "button", disabled: true},
              content: "Archived"
            },
            %{label: "Loading", props: %{variant: "danger", type: "button"}, content: "Deleting…"}
          ]
        },

        # ── Input family — one entry (text variant is canonical; registry represents the family) ──
        # Rendered: class={["ax-field-control", error && "ax-field-control-error"]}
        # Outer wrapper: class="ax-field"
        # ax_class must have two space-separated tokens (test (a) contract).
        # "ax-field-control" is the second token; it appears in the rendered HTML from Input component.
        %{
          family: "input",
          variant: "text",
          ax_class: "ax-field ax-field-control",
          tokens: ["--ax-border", "--ax-base", "--ax-primary"],
          applicable_states: ["default", "focus", "error", "disabled", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "text input shows cursor change only via CSS — no background shift applies"
            },
            %{
              state: "active",
              reason:
                "text input has no active/pressed state — activation focus is covered by the focus state"
            },
            %{
              state: "loading",
              reason:
                "input is a form control — loading state belongs to the surrounding form or submit button"
            },
            %{
              state: "selected",
              reason:
                "selection in input is text-selection — not a component state in the registry taxonomy"
            },
            %{
              state: "empty",
              reason:
                "empty input is identical to default (placeholder shown) — no distinct visual state"
            },
            %{state: "pressed", reason: "input has no press-scale or pressed visual state"}
          ],
          specimens: [
            %{
              label: "Default (with placeholder)",
              props: %{
                id: "inp-default",
                name: "demo",
                label: "Email",
                placeholder: "name@example.com"
              },
              content: nil
            },
            %{
              label: "Filled (overflow ID)",
              props: %{
                id: "inp-overflow",
                name: "demo_overflow",
                label: "Customer ID",
                value: "cus_1234567890abcdefghijklmnopqrstuvwxyz"
              },
              content: nil
            },
            %{
              label: "Error state",
              props: %{
                id: "inp-error",
                name: "demo_error",
                label: "Email",
                errors: ["is not a valid email address"]
              },
              content: nil
            },
            %{
              label: "Disabled",
              props: %{
                id: "inp-disabled",
                name: "demo_disabled",
                label: "Email",
                disabled: true,
                value: "locked@example.com"
              },
              content: nil
            }
          ]
        },

        # ── Textarea family ────────────────────────────────────────────────────────
        # Textarea renders class={["ax-field-control", "ax-textarea", ...]} on the textarea element.
        # "ax-textarea" appears in rendered HTML → satisfies test (a).
        %{
          family: "textarea",
          variant: "default",
          ax_class: "ax-field ax-textarea",
          tokens: ["--ax-border", "--ax-base", "--ax-primary"],
          applicable_states: ["default", "focus", "error", "disabled", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "textarea shows cursor change only via CSS — no background shift applies"
            },
            %{state: "active", reason: "textarea has no active/pressed state"},
            %{
              state: "loading",
              reason:
                "loading state belongs to the surrounding form or submit button, not the textarea"
            },
            %{
              state: "selected",
              reason:
                "selection in textarea is text-selection — not a component state in the registry taxonomy"
            },
            %{
              state: "empty",
              reason:
                "empty textarea is identical to default (placeholder shown) — no distinct visual state"
            },
            %{state: "pressed", reason: "textarea has no press-scale or pressed visual state"}
          ],
          specimens: [
            %{
              label: "Default (with placeholder)",
              props: %{
                id: "ta-default",
                name: "notes",
                label: "Notes",
                placeholder: "Add notes here…"
              },
              content: nil
            },
            %{
              label: "Filled multiline",
              props: %{
                id: "ta-filled",
                name: "notes_filled",
                label: "Notes",
                value: "Line one of the note.\nLine two of the note.\nLine three of the note."
              },
              content: nil
            },
            %{
              label: "Error state",
              props: %{
                id: "ta-error",
                name: "notes_error",
                label: "Notes",
                errors: ["is too short (minimum is 10 characters)"]
              },
              content: nil
            },
            %{
              label: "Disabled",
              props: %{
                id: "ta-disabled",
                name: "notes_disabled",
                label: "Notes",
                disabled: true,
                value: "This field is locked."
              },
              content: nil
            }
          ]
        },

        # ── Checkbox family ────────────────────────────────────────────────────────
        # Checkbox renders inner input with class="ax-checkbox" → "ax-checkbox" appears in HTML.
        %{
          family: "checkbox",
          variant: "default",
          ax_class: "ax-field ax-checkbox",
          tokens: ["--ax-border", "--ax-interactive-selected", "--ax-accent-strong"],
          applicable_states: ["default", "selected", "focus", "disabled"],
          na_states: [
            %{
              state: "hover",
              reason:
                "checkbox hover is cursor change only via CSS — no distinct background shift in the registry taxonomy"
            },
            %{
              state: "active",
              reason:
                "checkbox active state is a brief CSS press — not a persistent rendered state in the lab"
            },
            %{
              state: "loading",
              reason:
                "checkbox is a boolean control — loading state belongs to surrounding form context"
            },
            %{
              state: "error",
              reason:
                "checkbox error is surfaced at the field-group level via form validation, not per-checkbox"
            },
            %{
              state: "empty",
              reason: "unchecked checkbox is the default state — no distinct empty visual"
            },
            %{
              state: "overflow",
              reason:
                "checkbox label truncates gracefully via CSS — overflow is a label-width concern, not a checkbox state"
            },
            %{
              state: "pressed",
              reason: "checkbox has no press-scale or pressed visual state separate from active"
            }
          ],
          specimens: [
            %{
              label: "Unchecked (default)",
              props: %{id: "cb-default", name: "accept", label: "Accept terms and conditions"},
              content: nil
            },
            %{
              label: "Checked (selected)",
              props: %{
                id: "cb-checked",
                name: "accept_checked",
                label: "Accept terms and conditions",
                checked: true
              },
              content: nil
            },
            %{
              label: "Disabled unchecked",
              props: %{
                id: "cb-disabled",
                name: "accept_disabled",
                label: "Accept terms and conditions",
                disabled: true
              },
              content: nil
            },
            %{
              label: "Long label (overflow)",
              props: %{
                id: "cb-overflow",
                name: "accept_overflow",
                label:
                  "I agree to the Accrue Terms of Service, Privacy Policy, and Data Processing Agreement"
              },
              content: nil
            }
          ]
        },

        # ── Radio family ────────────────────────────────────────────────────────────
        # Radio renders inner input with class="ax-radio" → "ax-radio" appears in HTML.
        %{
          family: "radio",
          variant: "default",
          ax_class: "ax-field ax-radio",
          tokens: ["--ax-border", "--ax-interactive-selected", "--ax-accent-strong"],
          applicable_states: ["default", "selected", "focus", "disabled"],
          na_states: [
            %{
              state: "hover",
              reason:
                "radio hover is cursor change only via CSS — no distinct background shift in the registry taxonomy"
            },
            %{
              state: "active",
              reason:
                "radio active state is a brief CSS press — not a persistent rendered state in the lab"
            },
            %{
              state: "loading",
              reason:
                "radio is a selection control — loading state belongs to surrounding form context"
            },
            %{
              state: "error",
              reason:
                "radio error is surfaced at the radio group level via form validation, not per-radio"
            },
            %{
              state: "empty",
              reason: "unselected radio is the default state — no distinct empty visual"
            },
            %{
              state: "overflow",
              reason:
                "radio label truncates gracefully via CSS — overflow is a label-width concern, not a radio state"
            },
            %{
              state: "pressed",
              reason: "radio has no press-scale or pressed visual state separate from active"
            }
          ],
          specimens: [
            %{
              label: "Unselected (default)",
              props: %{id: "rb-default", name: "plan", label: "Starter plan", value: "starter"},
              content: nil
            },
            %{
              label: "Selected",
              props: %{
                id: "rb-selected",
                name: "plan_selected",
                label: "Starter plan",
                value: "starter",
                checked: true
              },
              content: nil
            },
            %{
              label: "Disabled",
              props: %{
                id: "rb-disabled",
                name: "plan_disabled",
                label: "Enterprise plan (contact sales)",
                value: "enterprise",
                disabled: true
              },
              content: nil
            },
            %{
              label: "Long label (overflow)",
              props: %{
                id: "rb-overflow",
                name: "plan_overflow",
                label:
                  "Professional plan with advanced analytics, priority support, and unlimited team members",
                value: "pro"
              },
              content: nil
            }
          ]
        },

        # ── Toggle family ────────────────────────────────────────────────────────────
        # Toggle renders button with class="ax-toggle" → "ax-toggle" appears in HTML.
        # Outer label has class={["ax-field", "ax-field-inline", ...]}.
        %{
          family: "toggle",
          variant: "default",
          ax_class: "ax-field ax-toggle",
          tokens: ["--ax-border", "--ax-interactive-selected", "--ax-accent-strong"],
          applicable_states: ["default", "selected", "focus", "disabled"],
          na_states: [
            %{
              state: "hover",
              reason:
                "toggle hover is cursor change only via CSS — no distinct background shift in the registry taxonomy"
            },
            %{
              state: "active",
              reason:
                "toggle active state is a brief CSS press — not a persistent rendered state in the lab"
            },
            %{
              state: "loading",
              reason:
                "toggle is a boolean switch — loading state belongs to surrounding form or action context"
            },
            %{
              state: "error",
              reason:
                "toggle error is surfaced at the field-group level via form validation, not on the toggle itself"
            },
            %{
              state: "empty",
              reason: "off toggle is the default state — no distinct empty visual"
            },
            %{
              state: "overflow",
              reason:
                "toggle label truncates gracefully via CSS — overflow is a label-width concern, not a toggle state"
            },
            %{
              state: "pressed",
              reason: "toggle has no press-scale or pressed visual state separate from active"
            }
          ],
          specimens: [
            %{
              label: "Off (default)",
              props: %{id: "tg-default", name: "notifications", label: "Email notifications"},
              content: nil
            },
            %{
              label: "On (selected)",
              props: %{
                id: "tg-on",
                name: "notifications_on",
                label: "Email notifications",
                on: true
              },
              content: nil
            },
            %{
              label: "Disabled off",
              props: %{
                id: "tg-disabled",
                name: "notifications_disabled",
                label: "Email notifications",
                disabled: true
              },
              content: nil
            },
            %{
              label: "Long label (overflow)",
              props: %{
                id: "tg-overflow",
                name: "notifications_overflow",
                label:
                  "Notify me by email when a subscription renewal payment is processed or fails"
              },
              content: nil
            }
          ]
        },

        # ── Theme picker family ──────────────────────────────────────────────────────
        # Unified light/dark/system segmented control. "selected" demonstrates the
        # active "thumb" on a non-default segment.
        %{
          family: "theme-picker",
          variant: "segmented",
          ax_class: "ax-theme-picker ax-theme-picker-option",
          tokens: [
            "--ax-sunken",
            "--ax-elevated",
            "--ax-accent-border",
            "--ax-border",
            "--ax-primary",
            "--ax-muted",
            "--ax-focus-ring",
            "--ax-transition-colors"
          ],
          applicable_states: ["default", "selected"],
          na_states: [
            %{
              state: "hover",
              reason:
                "inactive-segment hover is a CSS background shift only — not a distinct rendered specimen"
            },
            %{
              state: "focus",
              reason:
                "focus ring shows on keyboard focus (roving tabindex) — a live state, not a forced static specimen"
            },
            %{state: "active", reason: "selection is instant — no persistent pressed visual"},
            %{state: "pressed", reason: "no press-scale state separate from the click"},
            %{state: "disabled", reason: "the theme picker is always enabled — no disabled state"},
            %{state: "loading", reason: "preference toggles instantly — no async loading state"},
            %{state: "error", reason: "no validation — the control cannot be in an error state"},
            %{state: "empty", reason: "one segment is always active — there is no empty state"},
            %{
              state: "overflow",
              reason:
                "labels collapse to icon-only below 768px via CSS — a responsive collapse, not overflow"
            }
          ],
          specimens: [
            %{label: "System (default)", props: %{theme: "system"}, content: nil},
            %{label: "Light active (selected)", props: %{theme: "light"}, content: nil}
          ]
        },

        # ── Segmented filter family ───────────────────────────────────────────────────
        # Reusable DataTable filter segmented control (e.g. All/Live/Test). Shares the
        # theme-picker visual language as new shared .ax-segmented* classes. The default
        # specimen MUST render the variant class `ax-segmented-option` (render-coverage
        # guardrail splits ax_class on space and asserts the variant class appears).
        %{
          family: "segmented",
          variant: "filter",
          ax_class: "ax-segmented ax-segmented-option",
          tokens: [
            "--ax-sunken",
            "--ax-elevated",
            "--ax-accent-border",
            "--ax-border",
            "--ax-primary",
            "--ax-muted",
            "--ax-focus-ring",
            "--ax-transition-colors"
          ],
          applicable_states: ["default", "active"],
          na_states: [
            %{
              state: "hover",
              reason:
                "inactive-segment hover is a CSS background shift only — not a distinct rendered specimen"
            },
            %{
              state: "focus",
              reason:
                "focus ring shows on keyboard focus (focus-within) — a live state, not a forced static specimen"
            },
            %{state: "selected", reason: "active is the selection state for a segmented radiogroup"},
            %{state: "pressed", reason: "selection is instant — no separate pressed visual"},
            %{state: "disabled", reason: "filter segments are always enabled"},
            %{state: "loading", reason: "filter toggles submit a GET form — no async loading state"},
            %{state: "error", reason: "no validation — a segment cannot be in an error state"},
            %{state: "empty", reason: "one segment is always active — there is no empty state"},
            %{
              state: "overflow",
              reason: "segment labels are short fixed words (All/Live/Test) — no overflow case"
            }
          ],
          specimens: [
            %{label: "All (default)", props: %{value: ""}, content: nil},
            %{label: "Live active", props: %{value: "true"}, content: nil}
          ]
        },

        # ── Stat strip family ─────────────────────────────────────────────────────────
        # Compact inline metric <dl> for list/index pages. The default specimen MUST
        # render the variant class `ax-stat-value` (render-coverage guardrail splits
        # ax_class on space and asserts the second class appears in the markup) — the
        # dedicated do_render_specimen("stat-strip", …) clause emits it.
        %{
          family: "stat-strip",
          variant: "inline",
          ax_class: "ax-stat-strip ax-stat-value",
          tokens: [
            "--ax-space-sm",
            "--ax-space-md",
            "--ax-space-lg",
            "--ax-space-xs",
            "--ax-border",
            "--ax-muted",
            "--ax-primary",
            "--ax-type-label-font",
            "--ax-type-lg",
            "--ax-leading-tight",
            "--ax-success-readable",
            "--ax-accent-readable",
            "--ax-warning-readable",
            "--ax-radius-2xs",
            "--ax-focus-ring"
          ],
          applicable_states: ["default"],
          na_states: [
            %{state: "hover", reason: "only linked stats have a hover underline — a CSS shift, not a distinct static specimen"},
            %{state: "focus", reason: "focus ring shows on keyboard focus of a linked stat — a live state, not a forced static specimen"},
            %{state: "selected", reason: "a read-only metric strip has no selection state"},
            %{state: "active", reason: "a read-only metric strip has no active/pressed state"},
            %{state: "pressed", reason: "metrics are not interactive controls — no pressed visual"},
            %{state: "disabled", reason: "a display-only strip is never disabled"},
            %{state: "loading", reason: "metrics are server-rendered with the page — no async loading state"},
            %{state: "error", reason: "no validation — a metric strip cannot be in an error state"},
            %{state: "empty", reason: "list pages always render at least one metric — no empty state"},
            %{state: "overflow", reason: "values are short counts; the strip wraps via flex-wrap rather than overflowing"}
          ],
          specimens: [
            %{label: "Default", props: %{}, content: nil}
          ]
        },

        # ── Timeline family ──────────────────────────────────────────────────────────
        # Threaded event feed. The default specimen MUST be non-empty so the rendered
        # HTML contains `ax-timeline-item` (render-coverage guardrail needs two tokens
        # AND that the variant token actually appears in the default specimen's markup).
        %{
          family: "timeline",
          variant: "threaded",
          ax_class: "ax-timeline ax-timeline-item",
          tokens: [
            "--ax-border-strong",
            "--ax-elevated",
            "--ax-success",
            "--ax-accent",
            "--ax-warning",
            "--ax-muted",
            "--ax-primary",
            "--ax-radius-lg",
            "--ax-space-lg",
            "--ax-transition-colors"
          ],
          applicable_states: ["default", "hover", "empty"],
          na_states: [
            %{
              state: "selected",
              reason: "a read-only event feed has no selectable row — nodes are not selectable"
            },
            %{
              state: "focus",
              reason:
                "details summary focus is a live keyboard state, not a static specimen"
            },
            %{
              state: "active",
              reason: "timeline rows are non-interactive — no active/press state applies"
            },
            %{state: "pressed", reason: "timeline rows have no press-scale or pressed visual"},
            %{
              state: "disabled",
              reason: "an event feed is always rendered — disabled does not apply"
            },
            %{
              state: "loading",
              reason: "loading belongs to the surrounding data context, not the feed itself"
            },
            %{
              state: "error",
              reason: "the feed renders whatever events it receives — no per-feed error state"
            },
            %{
              state: "overflow",
              reason: "long bodies wrap via overflow-wrap, not a distinct specimen"
            }
          ],
          specimens: [
            %{label: "Multi-tone feed", props: %{}, content: nil},
            %{label: "Empty", props: %{}, content: nil}
          ]
        },

        # ── Select family ────────────────────────────────────────────────────────────
        # Select renders class={["ax-field-control", "ax-select-control", ...]} → "ax-select-control" appears.
        %{
          family: "select",
          variant: "default",
          ax_class: "ax-field ax-select-control",
          tokens: ["--ax-border", "--ax-base", "--ax-primary"],
          applicable_states: ["default", "focus", "error", "disabled"],
          na_states: [
            %{
              state: "hover",
              reason:
                "select hover is cursor change only via CSS — no background shift applies in the registry taxonomy"
            },
            %{
              state: "active",
              reason: "select has no active/pressed state — it opens a native OS picker on click"
            },
            %{
              state: "loading",
              reason:
                "loading state belongs to the surrounding form or submit action, not the select control"
            },
            %{
              state: "selected",
              reason:
                "selected option is internal to the native select control, not a component-level state in the registry taxonomy"
            },
            %{
              state: "empty",
              reason:
                "empty select shows the prompt option — identical to default render; no distinct visual state"
            },
            %{
              state: "overflow",
              reason: "select value text truncates natively via OS; not a component-level state"
            },
            %{state: "pressed", reason: "select has no press-scale or pressed visual state"}
          ],
          specimens: [
            %{
              label: "Default (with prompt)",
              props: %{
                id: "sel-default",
                name: "country",
                label: "Country",
                prompt: "Select a country",
                options: [{"United States", "us"}, {"United Kingdom", "gb"}, {"Canada", "ca"}]
              },
              content: nil
            },
            %{
              label: "Error state",
              props: %{
                id: "sel-error",
                name: "country_error",
                label: "Country",
                errors: ["is required"],
                prompt: "Select a country",
                options: [{"United States", "us"}]
              },
              content: nil
            },
            %{
              label: "Disabled",
              props: %{
                id: "sel-disabled",
                name: "country_disabled",
                label: "Country",
                disabled: true,
                value: "us",
                options: [{"United States", "us"}]
              },
              content: nil
            }
          ]
        },

        # ── Form-field family — wrapper / labelled group ───────────────────────────
        # Represents the ax-field wrapper itself as a family (fieldset / group role)
        %{
          family: "form-field",
          variant: "wrapper",
          ax_class: "ax-field ax-form-field",
          tokens: ["--ax-border", "--ax-status-danger-border", "--ax-muted"],
          applicable_states: ["default", "error"],
          na_states: [
            %{
              state: "hover",
              reason:
                "form-field wrapper is non-interactive — only its child controls are interactive"
            },
            %{
              state: "focus",
              reason:
                "form-field wrapper is non-interactive — focus applies to the child control, not the wrapper"
            },
            %{state: "active", reason: "form-field wrapper has no active state"},
            %{state: "pressed", reason: "form-field wrapper has no press state"},
            %{
              state: "disabled",
              reason:
                "disabled state is applied to the child control, not the wrapper (wrapper remains visible)"
            },
            %{
              state: "loading",
              reason:
                "form-field wrapper has no loading state — loading belongs to submit context"
            },
            %{state: "selected", reason: "form-field wrapper has no selected state"},
            %{
              state: "empty",
              reason: "form-field wrapper renders regardless of whether child control is empty"
            },
            %{
              state: "overflow",
              reason:
                "form-field wrapper expands to contain its child — overflow is a child-control concern"
            }
          ],
          specimens: [
            %{
              label: "Default wrapper",
              props: %{},
              content: "ax-field wrapper around a labeled input control"
            },
            %{
              label: "Error wrapper (danger border + error text visible)",
              props: %{},
              content:
                "ax-field wrapper in error state with validation message shown below the control"
            }
          ]
        },

        # ── StatusBadge family — 5 tone variants from status_tone/1 ────────────────
        # Rendered: class={["ax-status-badge", "ax-status-badge-" <> tone]}
        # → "ax-status-badge ax-status-badge-{tone}"
        %{
          family: "status",
          variant: "moss",
          ax_class: "ax-status-badge ax-status-badge-moss",
          tokens: ["--ax-success", "--ax-success-readable", "--ax-elevated"],
          # Phase 189 — state-matrix schema additions
          # StatusBadge is non-interactive: only default and overflow apply.
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "focus",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "active",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "pressed",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "disabled",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "loading",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "selected",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "empty",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "error",
              reason: "non-interactive display element — no interactive state applies"
            }
          ],
          specimens: [
            %{label: "Active", props: %{tone: "moss"}, content: "Active"},
            %{
              label: "Long label (overflow)",
              props: %{tone: "moss"},
              content: "Requires additional customer authentication step"
            }
          ]
        },
        %{
          family: "status",
          variant: "cobalt",
          ax_class: "ax-status-badge ax-status-badge-cobalt",
          tokens: ["--ax-accent", "--ax-accent-readable", "--ax-elevated"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "focus",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "active",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "pressed",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "disabled",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "loading",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "selected",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "empty",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "error",
              reason: "non-interactive display element — no interactive state applies"
            }
          ],
          specimens: [
            %{label: "Processing", props: %{tone: "cobalt"}, content: "Processing"},
            %{
              label: "Long label (overflow)",
              props: %{tone: "cobalt"},
              content: "Requires additional customer authentication step"
            }
          ]
        },
        %{
          family: "status",
          variant: "amber",
          ax_class: "ax-status-badge ax-status-badge-amber",
          tokens: ["--ax-warning", "--ax-warning-readable", "--ax-elevated"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "focus",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "active",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "pressed",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "disabled",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "loading",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "selected",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "empty",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "error",
              reason: "non-interactive display element — no interactive state applies"
            }
          ],
          specimens: [
            %{label: "Past due", props: %{tone: "amber"}, content: "Past due"},
            %{
              label: "Long label (overflow)",
              props: %{tone: "amber"},
              content: "Requires additional customer authentication step"
            }
          ]
        },
        %{
          family: "status",
          variant: "slate",
          ax_class: "ax-status-badge ax-status-badge-slate",
          tokens: ["--ax-border", "--ax-muted", "--ax-elevated"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "focus",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "active",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "pressed",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "disabled",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "loading",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "selected",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "empty",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "error",
              reason: "non-interactive display element — no interactive state applies"
            }
          ],
          specimens: [
            %{label: "Canceled", props: %{tone: "slate"}, content: "Canceled"},
            %{
              label: "Long label (overflow)",
              props: %{tone: "slate"},
              content: "Requires additional customer authentication step"
            }
          ]
        },
        %{
          family: "status",
          variant: "ink",
          ax_class: "ax-status-badge ax-status-badge-ink",
          tokens: ["--ax-primary", "--ax-elevated"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "focus",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "active",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "pressed",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "disabled",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "loading",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "selected",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "empty",
              reason: "non-interactive display element — no interactive state applies"
            },
            %{
              state: "error",
              reason: "non-interactive display element — no interactive state applies"
            }
          ],
          specimens: [
            %{label: "Unknown", props: %{tone: "ink"}, content: "Unknown"},
            %{
              label: "Long label (overflow)",
              props: %{tone: "ink"},
              content: "Requires additional customer authentication step"
            }
          ]
        },

        # ── Icon family ───────────────────────────────────────────────────────────
        # Rendered: class={["ax-icon", "ax-icon-#{size}", class]}
        %{
          family: "icon",
          variant: "md",
          ax_class: "ax-icon ax-icon-md",
          tokens: ["--ax-primary", "--ax-muted"],
          applicable_states: ["default"],
          na_states: [
            %{state: "hover", reason: "non-interactive display primitive — no hover state"},
            %{
              state: "focus",
              reason: "non-interactive display primitive — not focusable without a wrapper button"
            },
            %{state: "active", reason: "non-interactive display primitive — no active state"},
            %{state: "pressed", reason: "non-interactive display primitive — no press state"},
            %{
              state: "disabled",
              reason:
                "non-interactive display primitive — icons are always rendered, not disabled"
            },
            %{
              state: "loading",
              reason: "non-interactive display primitive — icons do not have a loading state"
            },
            %{
              state: "selected",
              reason: "non-interactive display primitive — icons do not have a selected state"
            },
            %{
              state: "empty",
              reason: "non-interactive display primitive — icons always render a glyph"
            },
            %{
              state: "error",
              reason:
                "non-interactive display primitive — icons signal context but are not themselves in error"
            },
            %{
              state: "overflow",
              reason:
                "non-interactive display primitive — icons are fixed-size SVGs, no overflow applies"
            }
          ],
          specimens: [
            %{label: "Default glyph", props: %{name: :invoices, size: "md"}, content: nil},
            %{
              label: "Muted glyph (inline)",
              props: %{name: :users, size: "md", class: "ax-muted"},
              content: nil
            }
          ]
        },

        # ── MoneyFormatter family ─────────────────────────────────────────────────
        # Rendered: class={["ax-money", class]}
        %{
          family: "money",
          variant: "display",
          ax_class: "ax-money ax-money-display",
          tokens: ["--ax-primary", "--ax-muted"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{state: "hover", reason: "non-interactive display primitive — no hover state"},
            %{state: "focus", reason: "non-interactive display primitive — not focusable"},
            %{state: "active", reason: "non-interactive display primitive — no active state"},
            %{state: "pressed", reason: "non-interactive display primitive — no press state"},
            %{
              state: "disabled",
              reason: "non-interactive display primitive — money amounts are always rendered"
            },
            %{
              state: "loading",
              reason:
                "non-interactive display primitive — loading state belongs to the surrounding data context"
            },
            %{state: "selected", reason: "non-interactive display primitive — no selected state"},
            %{
              state: "empty",
              reason:
                "money formatter renders '--' when no value is provided — indistinct from default"
            },
            %{
              state: "error",
              reason:
                "non-interactive display primitive — formatting errors render '--', not a distinct component error state"
            }
          ],
          specimens: [
            %{
              label: "Default amount",
              props: %{amount_minor: 4200, currency: :usd},
              content: nil
            },
            %{
              label: "Large amount (overflow)",
              props: %{amount_minor: 99_999_999_999, currency: :usd},
              content: nil
            }
          ]
        },

        # ── JsonViewer family ─────────────────────────────────────────────────────
        # Rendered: class="ax-card ax-json-viewer" (outer section)
        %{
          family: "json-viewer",
          variant: "tree",
          ax_class: "ax-json-viewer ax-json-tree",
          tokens: ["--ax-elevated", "--ax-border", "--ax-muted"],
          applicable_states: ["default", "empty", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason:
                "json-viewer is a non-interactive tree display — individual nodes have cursor but the component itself has no hover state"
            },
            %{
              state: "focus",
              reason:
                "json-viewer tree interaction is via keyboard on detail/summary elements — no component-level focus state"
            },
            %{state: "active", reason: "non-interactive display component — no active state"},
            %{state: "pressed", reason: "non-interactive display component — no press state"},
            %{state: "disabled", reason: "non-interactive display component — always rendered"},
            %{
              state: "loading",
              reason:
                "json-viewer renders what it receives — loading state belongs to surrounding data context"
            },
            %{state: "selected", reason: "non-interactive display component — no selected state"},
            %{
              state: "error",
              reason:
                "json-viewer normalizes unknown structs gracefully — no explicit error state"
            }
          ],
          specimens: [
            %{
              label: "Default (populated)",
              props: %{
                id: "jv-default",
                payload: %{
                  "id" => "evt_1234",
                  "type" => "payment_intent.succeeded",
                  "amount" => 4200,
                  "currency" => "usd"
                },
                label: "Webhook payload"
              },
              content: nil
            },
            %{
              label: "Empty payload",
              props: %{id: "jv-empty", payload: %{}, label: "Empty payload"},
              content: nil
            },
            %{
              label: "Deep nested (overflow)",
              props: %{
                id: "jv-overflow",
                payload: %{
                  "subscription" => %{
                    "id" => "sub_1234567890abcdefghijklmnopqrstuvwxyz",
                    "customer" => %{
                      "id" => "cus_1234567890abcdefghijklmnopqrstuvwxyz",
                      "email" =>
                        "customer.with.very.long.email.address@example-domain-that-is-quite-long.com"
                    }
                  }
                },
                label: "Nested payload"
              },
              content: nil
            }
          ]
        },

        # ── Spinner family ─────────────────────────────────────────────────────────
        # Rendered: class={["ax-spinner", "ax-spinner-#{size}", class]}
        %{
          family: "spinner",
          variant: "sm",
          ax_class: "ax-spinner ax-spinner-sm",
          tokens: ["--ax-accent-strong", "--ax-border"],
          applicable_states: ["loading"],
          na_states: [
            %{
              state: "default",
              reason:
                "spinner only exists in loading state — it is not rendered in a non-loading context"
            },
            %{state: "hover", reason: "non-interactive display primitive — no hover state"},
            %{state: "focus", reason: "non-interactive display primitive — not focusable"},
            %{state: "active", reason: "non-interactive display primitive — no active state"},
            %{state: "pressed", reason: "non-interactive display primitive — no press state"},
            %{
              state: "disabled",
              reason: "spinner only exists in loading state — disabled does not apply"
            },
            %{
              state: "selected",
              reason: "spinner only exists in loading state — selected does not apply"
            },
            %{
              state: "empty",
              reason: "spinner only exists in loading state — empty does not apply"
            },
            %{
              state: "error",
              reason: "spinner only exists in loading state — error does not apply"
            },
            %{
              state: "overflow",
              reason: "spinner is a fixed-size circular animation — overflow does not apply"
            }
          ],
          specimens: [
            %{
              label: "Loading (sm)",
              props: %{size: "sm", label: "Loading subscription data…"},
              content: nil
            },
            %{
              label: "Loading (md)",
              props: %{size: "md", label: "Processing payment for the current billing period…"},
              content: nil
            }
          ]
        },

        # ── Tooltip family ─────────────────────────────────────────────────────────
        # Rendered: class={["ax-tooltip-wrapper", "ax-tooltip-#{position}", class]}
        %{
          family: "tooltip",
          variant: "above",
          ax_class: "ax-tooltip-wrapper ax-tooltip-above",
          tokens: ["--ax-primary", "--ax-elevated", "--ax-z-popover"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason:
                "tooltip is revealed by hover on the trigger — hover is a trigger behavior, not a tooltip component state"
            },
            %{
              state: "focus",
              reason:
                "tooltip is revealed by focus-within on the wrapper — focus is a trigger behavior, not a tooltip component state"
            },
            %{state: "active", reason: "tooltip wrapper has no active/press state"},
            %{state: "pressed", reason: "tooltip wrapper has no press state"},
            %{
              state: "disabled",
              reason:
                "tooltip wrapper is always rendered — the trigger element may be disabled separately"
            },
            %{state: "loading", reason: "tooltip wrapper has no loading state"},
            %{state: "selected", reason: "tooltip wrapper has no selected state"},
            %{state: "error", reason: "tooltip wrapper has no error state"},
            %{
              state: "empty",
              reason: "tooltip always has content (required attr) — no empty state"
            }
          ],
          specimens: [
            %{
              label: "Default tooltip above",
              props: %{content: "Copy to clipboard", position: "above"},
              content: "Trigger button"
            },
            %{
              label: "Long content tooltip (overflow)",
              props: %{
                content:
                  "This action will permanently delete the subscription and all associated invoice history from the billing record",
                position: "above"
              },
              content: "Delete"
            }
          ]
        },

        # ── InlineId family ───────────────────────────────────────────────────────
        # Rendered: class={["ax-inline-id", class]}
        %{
          family: "inline-id",
          variant: "short",
          ax_class: "ax-inline-id ax-inline-id-short",
          tokens: ["--ax-primary", "--ax-muted"],
          applicable_states: ["default", "overflow"],
          na_states: [
            %{
              state: "hover",
              reason:
                "non-interactive display primitive — no hover state (title attr provides full text on pointer hover natively)"
            },
            %{
              state: "focus",
              reason: "non-interactive display primitive — code element is not focusable"
            },
            %{state: "active", reason: "non-interactive display primitive — no active state"},
            %{state: "pressed", reason: "non-interactive display primitive — no press state"},
            %{
              state: "disabled",
              reason: "non-interactive display primitive — inline IDs are always rendered"
            },
            %{
              state: "loading",
              reason:
                "non-interactive display primitive — loading state belongs to surrounding data context"
            },
            %{
              state: "selected",
              reason:
                "non-interactive display primitive — text selection is a browser behavior, not a component state"
            },
            %{
              state: "error",
              reason: "non-interactive display primitive — inline ID renders what it receives"
            },
            %{
              state: "empty",
              reason:
                "non-interactive display primitive — id_value is required; empty is not a valid component state"
            }
          ],
          specimens: [
            %{label: "Short Stripe ID", props: %{id_value: "cus_ABC123"}, content: nil},
            %{
              label: "Full Stripe ID (overflow, truncates)",
              props: %{id_value: "cus_1234567890abcdefghijklmnopqrstuvwxyz"},
              content: nil
            }
          ]
        },

        # ── IdBadge family ─────────────────────────────────────────────────────────
        # Interactive click-to-copy ID chip (sibling of inline-id). Rendered:
        # class={["ax-id-badge", "ax-id-badge-default", class]}. The default specimen
        # MUST render the variant class `ax-id-badge-default` (render-coverage guardrail
        # splits ax_class and asserts the variant class appears in the page HTML).
        %{
          family: "id-badge",
          variant: "default",
          ax_class: "ax-id-badge ax-id-badge-default",
          tokens: [
            "--ax-font-mono",
            "--ax-type-code-xs-font",
            "--ax-border",
            "--ax-border-strong",
            "--ax-sunken",
            "--ax-interactive-hover",
            "--ax-success",
            "--ax-transition-colors"
          ],
          # Click-to-copy control; copy success is a transient JS state (the hook sets
          # data-copied). Only the resting default is a forced static specimen.
          applicable_states: ["default"],
          na_states: [
            %{
              state: "hover",
              reason:
                "hover is a CSS background shift on the chip — a live pointer state, not a forced static specimen"
            },
            %{
              state: "focus",
              reason: "focus ring shows on keyboard focus — a live state, not a static specimen"
            },
            %{
              state: "active",
              reason: "copy fires instantly on click — no persistent pressed visual"
            },
            %{state: "pressed", reason: "no press-scale state separate from the click"},
            %{
              state: "selected",
              reason: "copy success (data-copied) is a transient JS feedback, not a selection state"
            },
            %{state: "disabled", reason: "the copy chip is always enabled"},
            %{state: "loading", reason: "clipboard write is synchronous-feeling — no loading state"},
            %{state: "error", reason: "no validation — the chip cannot be in an error state"},
            %{
              state: "empty",
              reason: "id_value is required — an empty chip is not a valid component state"
            },
            %{
              state: "overflow",
              reason: "long ids truncate within the chip max-width via ellipsis — not a distinct specimen"
            }
          ],
          specimens: [
            %{label: "Default ID chip", props: %{id_value: "cus_phase191_host_1"}, content: nil}
          ]
        },

        # ── EmptyState family ──────────────────────────────────────────────────────
        # Rendered: class={["ax-empty", class]}
        %{
          family: "empty-state",
          variant: "no-data",
          ax_class: "ax-empty ax-empty-no-data",
          tokens: ["--ax-muted", "--ax-sunken", "--ax-border"],
          applicable_states: ["empty"],
          na_states: [
            %{
              state: "default",
              reason:
                "empty-state hero only exists in the empty context — it is not rendered when data is present"
            },
            %{
              state: "hover",
              reason: "empty-state hero is non-interactive — cursor: default; no hover affordance"
            },
            %{
              state: "focus",
              reason:
                "empty-state wrapper is non-interactive — focus applies only to the CTA button in the actions slot"
            },
            %{state: "active", reason: "empty-state hero wrapper has no active/press state"},
            %{state: "pressed", reason: "empty-state hero wrapper has no press state"},
            %{
              state: "disabled",
              reason: "empty-state hero is a static display — disabled does not apply"
            },
            %{
              state: "loading",
              reason:
                "empty-state hero has no loading state — loading belongs to the surrounding page context"
            },
            %{state: "selected", reason: "empty-state hero has no selected state"},
            %{
              state: "error",
              reason:
                "empty-state hero has no error state — it communicates the absence of data, not an error"
            },
            %{
              state: "overflow",
              reason:
                "empty-state hero expands to fill its container — overflow does not apply to the hero wrapper"
            }
          ],
          specimens: [
            %{
              label: "Empty state hero (no data)",
              props: %{
                icon: :inbox,
                title: "No subscriptions yet",
                body: "Create a subscription to start billing your customers."
              },
              content: nil
            },
            %{
              label: "Empty state with long body copy (overflow test)",
              props: %{
                icon: :invoices,
                title: "No invoices found",
                body:
                  "There are no invoices matching your current filter criteria. Try adjusting the date range, status filter, or search query to find what you are looking for."
              },
              content: nil
            }
          ]
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

    defp group_locators(slug) do
      [
        ~s([data-component-group="#{slug}"]),
        "#grp190-#{slug}",
        "/billing/dev/components?group=#{slug}"
      ]
    end
  end
end
