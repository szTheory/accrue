defmodule Accrue.Config do
  alias Accrue.Entitlements.Source.Registry

  @product_environments [:production, :sandbox]
  # --- Dunning campaign cadence (DUN-01, D-01/D-04/D-07) -----------------
  # Per-step NimbleOptions schema for a dunning campaign step. `template`
  # is `:atom` because module names ARE atoms — no `{:in, ...}` needed; the
  # host owns the value (trusted compile-time-ish config, not webhook/DB
  # input, so there is no atom-table exhaustion surface — threat T-128-02).
  @step_schema [
    after_days: [type: :non_neg_integer, required: true],
    key: [type: :atom, required: true],
    template: [type: :atom, required: true]
  ]

  # The default multi-step dunning journey (D-01). Absolute day offsets from
  # campaign start: `[0, 5, 12]`. Last step (12) sits two days inside the
  # default `grace_days` (14) so the final notice always precedes the
  # sweeper's terminal action (the cross-field invariant enforced at boot by
  # `validate_dunning_campaign_grace!/1`). Ships ON by default (opt-out).
  @default_dunning_steps [
    [after_days: 0, key: :reminder, template: Accrue.Emails.InvoicePaymentFailed],
    [after_days: 5, key: :action_required, template: Accrue.Emails.DunningActionRequired],
    [after_days: 12, key: :final_notice, template: Accrue.Emails.DunningFinalNotice]
  ]

  # WR-01: single source of truth for the `:dunning` `:grace_days` default and
  # the default `:campaign` journey. Both the `@schema` defaults AND the boot
  # guards (`validate_dunning_campaign_grace!/1`) and the `dunning_campaign/0`
  # accessor read these — so the boot guard can never validate against a stale
  # default that drifted from the schema (it previously inlined `14` and the
  # default journey as literals in three places).
  @default_grace_days 14
  @default_dunning_campaign [enabled: true, steps: @default_dunning_steps]

  @schema [
    # --- Repo + adapters --------------------------------------------------
    repo: [
      type: :atom,
      required: true,
      doc:
        "Host `Ecto.Repo` module that Accrue writes to (event ledger, webhook events, billing tables)."
    ],
    billing_schema: [
      type: {:custom, __MODULE__, :validate_billing_schema, []},
      default: "billing",
      doc:
        "PostgreSQL schema where Accrue-owned billing tables are stored. Defaults to `billing`; set to `public` explicitly to keep Accrue tables in the default schema. This is compile-time configuration for Ecto schemas and migration generation."
    ],
    processor: [
      type: :atom,
      default: Accrue.Processor.Fake,
      doc: "Processor adapter implementing `Accrue.Processor` behaviour."
    ],
    rails: [
      type: :keyword_list,
      default: [],
      keys: [
        *: [
          type: :keyword_list,
          keys: [
            source: [type: :atom, required: true],
            processor: [type: {:or, [:atom, nil]}, default: nil],
            environments: [type: {:list, :atom}, default: []],
            default_environment: [type: {:or, [:atom, nil]}, default: nil]
          ]
        ]
      ],
      doc:
        "Additive entitlement rail registrations. Omit to retain legacy single-processor behaviour."
    ],
    default_rail: [
      type: {:or, [:atom, nil]},
      default: nil,
      doc: "The registered controllable rail that agrees with the legacy :processor alias."
    ],
    mailer: [
      type: :atom,
      default: Accrue.Mailer.Default,
      doc: "Mailer pipeline module implementing `Accrue.Mailer` behaviour."
    ],
    mailer_adapter: [
      type: :atom,
      default: Accrue.Mailer.Swoosh,
      doc: "Swoosh-backed mailer delivery module."
    ],
    invoice_pdf_adapter: [
      type: :atom,
      default: Accrue.InvoiceRenderer.Rendro,
      doc:
        "Invoice PDF adapter implementing `Accrue.InvoiceRenderer` behaviour. " <>
          "Defaults to the native Rendro-backed invoice renderer."
    ],
    pdf_adapter: [
      type: :atom,
      default: Accrue.PDF.ChromicPDF,
      doc:
        "Legacy HTML-to-PDF adapter implementing `Accrue.PDF` behaviour. " <>
          "Used by the Chromic invoice renderer path and by custom HTML callers."
    ],
    auth_adapter: [
      type: :atom,
      default: Accrue.Auth.Default,
      doc: "Auth adapter implementing `Accrue.Auth` behaviour."
    ],
    plan_resolver: [
      type: {:or, [:atom, nil]},
      default: nil,
      doc:
        "Optional host-owned resolver module implementing `Accrue.PlanResolver`. " <>
          "Required when a processor needs more than a bare `price_id` to perform " <>
          "plan changes through the shared facade (for example Braintree swap-plan flows)."
    ],
    storage_adapter: [
      type: :atom,
      default: Accrue.Storage.Null,
      doc:
        "Storage adapter implementing `Accrue.Storage` behaviour. v1.0 ships " <>
          "`Accrue.Storage.Null` only; hosts supply a custom adapter (e.g., S3) to enable " <>
          "persisted asset storage. `Accrue.Storage.Filesystem` ships in v1.1."
    ],

    # --- Stripe (runtime only — NEVER compile_env) -----------------------
    stripe_secret_key: [
      type: :string,
      required: false,
      doc:
        "Runtime Stripe secret key. MUST be read at runtime only; never via `Application.compile_env!/2`. " <>
          "Validated at boot when `processor == Accrue.Processor.Stripe`."
    ],
    stripe_api_version: [
      type: :string,
      default: "2026-03-25.dahlia",
      doc: "Stripe API version pinned by the `:lattice_stripe` wrapper."
    ],

    # --- Email pipeline ----------------------------------------------------
    emails: [
      type: :keyword_list,
      default: [],
      doc:
        "Per-email-type switches. Keys are email type atoms; values are `boolean` or `{Mod, :fun, args}` MFA callbacks."
    ],
    email_overrides: [
      type: :keyword_list,
      default: [],
      doc:
        "Per-email-type template module overrides (third rung of the override ladder; see `guides/email.md`). " <>
          "Keys are email type atoms; values are module names."
    ],
    attach_invoice_pdf: [
      type: :boolean,
      default: true,
      doc: "Auto-attach invoice PDF to the receipt email."
    ],

    # --- Event ledger ------------------------------------------------------
    enforce_immutability: [
      type: :boolean,
      default: false,
      doc:
        "When true, `Accrue.Application` boot raises if the current PG role has UPDATE/DELETE on `accrue_events`."
    ],

    # --- Brand config (top-level legacy keys; prefer nested :branding) ---
    business_name: [
      type: :string,
      default: "Accrue",
      doc: "Business name shown in email headers, PDFs, and admin UI."
    ],
    business_address: [
      type: :string,
      default: "",
      doc: "Business postal address shown in invoice footers."
    ],
    logo_url: [
      type: :string,
      default: "",
      doc: "Absolute URL to the brand logo used in email + PDF headers."
    ],
    support_email: [
      type: :string,
      default: "support@example.com",
      doc: "Reply-to support email address for transactional mail."
    ],
    from_email: [
      type: :string,
      default: "noreply@example.com",
      doc: "Default From: address for transactional mail."
    ],
    from_name: [
      type: :string,
      default: "Accrue",
      doc: "Default From: name for transactional mail."
    ],
    default_currency: [
      type: :atom,
      default: :usd,
      doc: "Default currency when one is not explicitly supplied."
    ],

    # --- Webhook pipeline --------------------------------------------------
    webhook_signing_secrets: [
      type: :any,
      default: %{},
      doc:
        "Map of processor atom to signing secret(s). Each value is a string " <>
          "or list of strings for rotation. Example: " <>
          "`%{stripe: [\"whsec_old\", \"whsec_new\"]}`."
    ],

    # --- Webhook retention -------------------------------------------------
    succeeded_retention_days: [
      type: {:or, [:pos_integer, {:in, [:infinity]}]},
      default: 14,
      doc:
        "Number of days to retain `:succeeded` webhook events before the " <>
          "Pruner deletes them. Set to `:infinity` to disable pruning. Default: 14."
    ],
    dead_retention_days: [
      type: {:or, [:pos_integer, {:in, [:infinity]}]},
      default: 90,
      doc:
        "Number of days to retain `:dead` webhook events before the " <>
          "Pruner deletes them. Set to `:infinity` to disable pruning. Default: 90."
    ],
    webhook_handlers: [
      type: {:list, :atom},
      default: [],
      doc:
        "List of modules implementing `Accrue.Webhook.Handler` behaviour. " <>
          "Called sequentially after the default handler on each webhook event. " <>
          "Example: `[MyApp.BillingHandler, MyApp.AnalyticsHandler]`."
    ],

    # --- Customer portal / local checkout ----------------------------------
    portal_mount_path: [
      type: :string,
      default: "/billing",
      doc:
        "Mount path for the first-party `Accrue.Portal` routes when a processor " <>
          "uses local portal semantics. Returned checkout / billing-portal URLs " <>
          "append to this normalized path after `:portal_base_url` supplies the absolute host."
    ],
    portal_base_url: [
      type: {:or, [:string, nil]},
      default: nil,
      doc:
        "Absolute base URL (for example `https://app.example.com`) used to " <>
          "generate returned local portal checkout and billing-portal URLs. " <>
          "Leave unset only when those local portal URLs are not in use; " <>
          "`portal_url/1` raises instead of falling back to a relative path."
    ],
    braintree_client_token_generator: [
      type: :atom,
      default: Braintree.ClientToken,
      doc:
        "Module used to generate Braintree client tokens for Hosted Fields. " <>
          "Must export `generate/1`."
    ],

    # --- Subscription lifecycle --------------------------------------------
    expiring_card_thresholds: [
      type: {:custom, __MODULE__, :validate_descending, []},
      default: [30, 7, 1],
      doc:
        "Strictly-descending list of day thresholds at which the expiring-card " <>
          "reminder email fires ahead of a stored card's expiration. " <>
          "Default: `[30, 7, 1]` — 30, 7, and 1 days out."
    ],
    idempotency_mode: [
      type: {:in, [:warn, :strict]},
      default: :warn,
      doc:
        "How `Accrue.Actor.current_operation_id!/0` behaves when the process " <>
          "dict has no operation_id. `:strict` raises `Accrue.ConfigError`; " <>
          "`:warn` (the default) generates a random UUID and logs a warning. " <>
          "Set to `:strict` in production to ensure every outbound processor " <>
          "call carries a deterministic idempotency key."
    ],
    succeeded_refund_retention_days: [
      type: :pos_integer,
      default: 90,
      doc:
        "Number of days to retain `:succeeded` refund records before pruning " <>
          "Default: 90."
    ],

    # --- Dunning + multi-endpoint webhooks + DLQ replay -------------------
    dunning: [
      type: :keyword_list,
      default: [
        mode: :stripe_smart_retries,
        grace_days: @default_grace_days,
        terminal_action: :unpaid,
        telemetry_prefix: [:accrue, :ops],
        campaign: @default_dunning_campaign,
        engine: Accrue.Dunning.Engine.Oban
      ],
      keys: [
        mode: [type: {:in, [:stripe_smart_retries, :disabled]}, default: :stripe_smart_retries],
        grace_days: [type: :pos_integer, default: @default_grace_days],
        terminal_action: [type: {:in, [:unpaid, :canceled]}, default: :unpaid],
        telemetry_prefix: [type: {:list, :atom}, default: [:accrue, :ops]],
        campaign: [
          type: {:custom, __MODULE__, :validate_dunning_campaign, []},
          default: @default_dunning_campaign,
          doc:
            "Multi-step dunning cadence (D-04). A keyword list of " <>
              "`[enabled: boolean, steps: [...]]` where each step is " <>
              "`[after_days: non_neg_integer, key: atom, template: atom]`. " <>
              "`after_days` is ABSOLUTE from campaign start, strictly " <>
              "increasing and unique across the list; `key` is required and " <>
              "unique (it becomes the Oban-unique step identity). Ships a " <>
              "default journey ON by default (offsets `[0, 5, 12]`); set " <>
              "`campaign: false` (normalized to `[enabled: false, steps: []]`) " <>
              "to opt out. `steps: []` while `enabled: true` is a loud error. " <>
              "The last step's `after_days` MUST be `<= grace_days` (validated " <>
              "loud at boot) so the final notice precedes the sweeper's " <>
              "terminal action."
        ],
        engine: [
          type: :atom,
          default: Accrue.Dunning.Engine.Oban,
          doc:
            "Module implementing `Accrue.Dunning.Engine`. Default: " <>
              "`Accrue.Dunning.Engine.Oban` (built-in Oban campaign). " <>
              "Set to `Accrue.Integrations.Chimeway` to delegate orchestration " <>
              "to Chimeway."
        ]
      ],
      doc:
        "Dunning grace-period overlay config. `:mode` is " <>
          "`:stripe_smart_retries` or `:disabled`; `:terminal_action` is " <>
          "`:unpaid` or `:canceled`; `:grace_days` adds N days past Stripe's " <>
          "last retry before Accrue asks the processor facade to move the " <>
          "subscription to the terminal action. `:campaign` is the multi-step " <>
          "dunning cadence (see its own doc)."
    ],
    webhook_endpoints: [
      type: :keyword_list,
      default: [],
      doc:
        "Map of endpoint name to `[secret:, mode:]` for multi-endpoint " <>
          "webhooks. Example: `[primary: [secret: \"whsec_...\"], " <>
          "connect: [secret: \"whsec_...\", mode: :connect]]`."
    ],
    dlq_replay_batch_size: [
      type: :pos_integer,
      default: 100,
      doc: "Number of rows per chunk in `Accrue.Webhooks.DLQ.requeue_where/2` bulk replay."
    ],
    dlq_replay_stagger_ms: [
      type: :non_neg_integer,
      default: 1_000,
      doc:
        "Milliseconds to sleep between chunks during DLQ bulk replay " <>
          "(protects downstream). Default: 1_000."
    ],
    dlq_replay_max_rows: [
      type: :pos_integer,
      default: 10_000,
      doc:
        "Hard cap on bulk replay. Returns `{:error, :replay_too_large}` " <>
          "unless `force: true` is passed. Default: 10_000."
    ],

    # --- Branding ----------------------------------------------------------
    branding: [
      type: :keyword_list,
      required: false,
      default: [],
      keys: [
        business_name: [type: :string, default: "Accrue"],
        from_name: [type: :string, default: "Accrue"],
        from_email: [type: :string, required: true],
        support_email: [type: :string, required: true],
        reply_to_email: [type: {:or, [:string, nil]}, default: nil],
        logo_url: [type: {:or, [:string, nil]}, default: nil],
        logo_dark_url: [type: {:or, [:string, nil]}, default: nil],
        accent_color: [
          type: {:custom, __MODULE__, :validate_hex, []},
          default: "#1F6FEB"
        ],
        secondary_color: [
          type: {:custom, __MODULE__, :validate_hex, []},
          default: "#6B7280"
        ],
        font_stack: [
          type: :string,
          default: ~s(-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif)
        ],
        company_address: [type: {:or, [:string, nil]}, default: nil],
        support_url: [type: {:or, [:string, nil]}, default: nil],
        social_links: [type: :keyword_list, default: []],
        list_unsubscribe_url: [type: {:or, [:string, nil]}, default: nil],
        theme: [
          type: {:in, [:system, :light, :dark]},
          default: :system,
          doc:
            "Customer portal color-mode policy. `:system` (default) offers light + dark with a picker " <>
              "(follows the OS, user-switchable via the `accrue_theme` cookie). `:light` or `:dark` locks " <>
              "the portal to that mode and hides the picker."
        ]
      ],
      doc:
        "Branding config. Single source of truth for email + PDF brand. " <>
          "`:from_email` and `:support_email` are required for any real deploy. " <>
          "See guides/branding.md."
    ],
    admin_branding: [
      type: :keyword_list,
      required: false,
      default: [],
      keys: [
        app_name: [type: :string, default: "Billing"],
        logo_url: [type: {:or, [:string, nil]}, default: nil],
        accent_color: [
          type: {:custom, __MODULE__, :validate_hex, []},
          default: "#5D79F6"
        ]
      ],
      doc:
        "Optional Accrue Admin chrome branding. When unset, admin chrome keeps the " <>
          "legacy behavior and derives its app name, logo, and accent from " <>
          "`:branding`. Set this when customer-facing billing should use one brand " <>
          "while the mounted operator UI keeps an Accrue/admin identity."
    ],

    # --- Locale / timezone defaults (enrich/2 precedence) ----------------
    default_locale: [
      type: :string,
      default: "en",
      doc:
        "Application-wide default locale for email + PDF rendering. " <>
          "Third rung of the locale precedence ladder (after assigns[:locale] " <>
          "and customer.preferred_locale). Bad locales fall back to \"en\"."
    ],
    default_timezone: [
      type: :string,
      default: "Etc/UTC",
      doc:
        "Application-wide default IANA timezone for datetime rendering. " <>
          "Third rung of the timezone precedence ladder (after assigns[:timezone] " <>
          "and customer.preferred_timezone). Bad zones fall back to \"Etc/UTC\"."
    ],
    cldr_backend: [
      type: :atom,
      default: Accrue.Cldr,
      doc:
        "Cldr backend module used by `Accrue.Workers.Mailer.enrich/2` " <>
          "to validate locale strings. Defaults to `Accrue.Cldr`."
    ],

    # --- Stripe Connect ----------------------------------------------------
    connect: [
      type: :keyword_list,
      default: [
        default_stripe_account: nil,
        platform_fee: [
          percent: Decimal.new("2.9"),
          fixed: nil,
          min: nil,
          max: nil
        ]
      ],
      doc:
        "Stripe Connect configuration. `:default_stripe_account` is the " <>
          "fallback connected account id used when no per-call override " <>
          "or pdict scope is active (three-level precedence chain). " <>
          "`:platform_fee` configures the default flat-rate fee consumed " <>
          "by `Accrue.Connect.platform_fee/2`: `:percent` is a `Decimal` " <>
          "percentage (e.g. `Decimal.new(\"2.9\")` for 2.9%), `:fixed` is " <>
          "an `Accrue.Money` fee in minor units added after the percentage, " <>
          "and `:min`/`:max` optionally clamp the result."
    ],

    # --- Entitlements / plan-gating (ENT-01) ------------------------------
    entitlements: [
      type: :keyword_list,
      default: [],
      keys: [
        plans: [
          type: :keyword_list,
          default: [],
          keys: [
            *: [
              type: :keyword_list,
              keys: [
                features: [type: {:list, :atom}, default: []],
                limits: [
                  # `[atom: pos_integer]` quota caps (D-02). NimbleOptions has
                  # no `{:keyword_list, value_type}` form, so constrain every
                  # value via the wildcard-key `*` typed entry — same intent,
                  # valid 1.1 syntax.
                  type: :keyword_list,
                  default: [],
                  keys: [*: [type: :pos_integer]]
                ],
                price_ids: [type: {:list, :string}, default: []],
                products: [
                  type: :keyword_list,
                  default: [],
                  keys: [
                    *: [
                      type: :keyword_list,
                      default: [],
                      keys: [*: [type: {:list, :string}, default: []]]
                    ]
                  ]
                ]
              ]
            ]
          ],
          doc: "Logical plan name (atom) -> entitlement entry (features/limits/price_ids)"
        ],
        resolver: [
          type: :atom,
          default: Accrue.Entitlements.Resolver.LocalMap,
          doc: "Resolver module (Accrue.Entitlements.Resolver behaviour). Default LocalMap."
        ],
        unmapped_action: [
          type: {:in, [:deny, :raise]},
          default: :deny,
          doc:
            "Behaviour when an active price_id is unmapped. :deny fails closed; never silent-allow."
        ],
        # --- Phase 124 (ENT-06/07): guard config ---
        billable: [
          type: {:or, [nil, {:fun, 1}]},
          default: nil,
          doc:
            "Global billable resolver: a 1-arity fn `(conn | socket -> billable | nil)`. " <>
              "When unset, the default probes `current_scope.user -> current_user -> nil`. " <>
              "Must never raise — fail closed (resolve to nil) on any miss."
        ],
        on_deny: [
          type: {:custom, __MODULE__, :validate_on_deny, []},
          default: :forbidden,
          doc:
            "Global deny handler. Default is a content-negotiated opaque 403. " <>
              "Accepts `:forbidden | {:redirect, path} | {status, body} | fun/2 | {m,f,a}`. " <>
              "A per-guard `on_deny:` opt overrides this; this overrides the built-in 403. " <>
              "A malformed value fails loud at boot (never silently fails open)."
        ],
        deny_path: [
          type: :string,
          default: "/",
          doc: "LiveView fallback redirect target for `:forbidden` / non-redirectable denies."
        ],
        # --- Phase 125 (ENT-09): past-due grace knob ---
        past_due_grace: [
          type: {:or, [{:in, [:dunning, :none]}, :pos_integer]},
          default: :none,
          doc:
            "Entitlement access for :past_due subscriptions. :none (default) fails closed " <>
              "immediately. :dunning honors the dunning grace window (reuses " <>
              "Accrue.Config.dunning()[:grace_days]). A positive integer N honors an " <>
              "entitlement-specific N-day window. Grace grants are affirmative, resolved, " <>
              "configured decisions — never a fail-open."
        ],
        # --- Phase 127 (ENT-10): optional Stripe-native entitlement sync ---
        stripe_native_sync: [
          type: {:in, [:disabled, :advisory]},
          default: :disabled,
          doc:
            "Optional Stripe-native entitlement-summary sync. :disabled (default) is " <>
              "fully inert — no webhook reducer runs, no cache table is read or written. " <>
              ":advisory records Stripe entitlement summaries to an advisory cache for " <>
              "audit / telemetry / the admin read-seam; it does NOT change " <>
              "entitled?/has_active_plan? decisions in v1.x (local mapping stays " <>
              "canonical). The enum (not a boolean) reserves room for future additive " <>
              "modes without a breaking config change."
        ],
        multi_rail: [
          type: :keyword_list,
          default: [],
          keys: [
            mode: [type: {:in, [:disabled, :shadow, :enabled]}, default: :disabled],
            cohort: [type: :any, default: nil],
            clean_window: [type: :any, default: nil]
          ],
          doc:
            "Compatibility authority lane for canonical entitlement projection. " <>
              "Omit it (or use :disabled) to retain LocalMap authority; :shadow and " <>
              ":enabled require an explicit approved-account/MFA cohort."
        ]
      ],
      doc:
        "Plan->feature/quota entitlement catalog (host-owned, runtime). " <>
          "Boot-validated and the same `price_id` may not map to two plans " <>
          "(raises `Accrue.ConfigError` at boot). See guides/entitlements.md."
    ]
  ]

  @moduledoc """
  Runtime configuration schema for Accrue, backed by `NimbleOptions`.

  This module is the **single source of truth** for supported `:accrue`
  application keys. Host code reads validated values via `get!/1` or
  `Application.get_env/3`; extend behaviour through adapters, not by editing
  this schema from application code.

  ## Compile-time vs runtime

  Adapter atoms (`:processor`, `:mailer`, `:mailer_adapter`,
  `:invoice_pdf_adapter`, `:pdf_adapter`, `:auth_adapter`) are stable per-deploy and fine at compile time via
  `Application.compile_env!/2`.

  Secrets (`:stripe_secret_key`) and host-owned fields (`:default_currency`,
  `:from_email`, brand colors) MUST be read at runtime. See CLAUDE.md
  §Config Boundaries.

  ## Options

  #{NimbleOptions.docs(@schema)}
  """

  @doc """
  Validates a keyword list against the Accrue config schema and returns the
  normalized form. Raises `NimbleOptions.ValidationError` on failure.
  """
  @spec validate!(keyword()) :: keyword()
  def validate!(opts) when is_list(opts) do
    NimbleOptions.validate!(opts, @schema)
  end

  @doc """
  Reads a config key from `Application.get_env/3`, falling back to the
  schema default. Raises `Accrue.ConfigError` if the key is not in the
  schema at all (prevents silent typos in downstream code).
  """
  @spec get!(atom()) :: term()
  def get!(key) when is_atom(key) do
    unless Keyword.has_key?(@schema, key) do
      raise Accrue.ConfigError,
        key: key,
        message: "unknown accrue config key: #{inspect(key)}"
    end

    case Application.get_env(:accrue, key, :__accrue_unset__) do
      :__accrue_unset__ -> default_for(key)
      value -> value
    end
  end

  @doc """
  Returns the NimbleOptions schema keyword list. Used by boot-time
  validation to iterate keys.
  """
  @spec schema() :: keyword()
  def schema, do: @schema

  @doc """
  Compile-time billing schema prefix used by Accrue Ecto schemas.
  """
  @spec compile_time_billing_schema() :: String.t()
  def compile_time_billing_schema do
    :accrue
    |> Application.get_env(:billing_schema, "billing")
    |> validate_billing_schema!()
  end

  @doc """
  Runtime billing schema prefix used by migration and raw SQL helpers.
  """
  @spec billing_schema() :: String.t()
  def billing_schema do
    :accrue
    |> Application.get_env(:billing_schema, "billing")
    |> validate_billing_schema!()
  end

  @doc """
  Reads the current `:accrue` application env at boot time, filters it to
  the schema-known keys, and validates via `NimbleOptions.validate!/2`.

  Called by `Accrue.Application.start/2` before the supervision tree
  starts. Raises `NimbleOptions.ValidationError` on misconfig — fail loud
  rather than limp into production with silently-broken config.

  Only schema-known keys are validated. Extra keys in the `:accrue` env
  (e.g., per-module adapter configs like `Accrue.Mailer.Swoosh`) are
  ignored here — they belong to their own libraries and would otherwise
  produce spurious `unknown option` errors.
  """
  @spec validate_at_boot!() :: :ok
  def validate_at_boot! do
    known_keys = Keyword.keys(@schema)

    opts =
      :accrue
      |> Application.get_all_env()
      |> Keyword.take(known_keys)

    normalized_opts = NimbleOptions.validate!(opts, @schema)
    _ = maybe_validate_boot_setup!(normalized_opts)
    :ok
  end

  # --- webhook helpers --------------------------------------------------

  @doc """
  Returns the signing secret(s) for the given processor.

  Looks up `webhook_signing_secrets` in the `:accrue` application env
  and extracts the value for the given processor atom. Returns a list
  of strings (for multi-secret rotation support). Raises
  `Accrue.ConfigError` if no secrets are configured for the processor.
  """
  @spec webhook_signing_secrets(atom()) :: String.t() | [String.t()]
  def webhook_signing_secrets(processor) when is_atom(processor) do
    secrets_map = get!(:webhook_signing_secrets)

    case Map.fetch(secrets_map, processor) do
      {:ok, secrets} when is_list(secrets) and secrets != [] ->
        secrets

      {:ok, secret} when is_binary(secret) and secret != "" ->
        secret

      _ ->
        diagnostic =
          Accrue.SetupDiagnostic.webhook_secret_missing(
            details: "processor=#{inspect(processor)} signing secret missing"
          )

        raise Accrue.ConfigError, key: :webhook_signing_secrets, diagnostic: diagnostic
    end
  end

  @doc false
  @spec ensure_oban_configured!(keyword() | nil) :: :ok
  def ensure_oban_configured!(oban_config \\ Application.get_env(:accrue, Oban)) do
    queues =
      case oban_config do
        opts when is_list(opts) -> Keyword.get(opts, :queues, [])
        _ -> nil
      end

    cond do
      not is_list(oban_config) ->
        raise_oban_not_configured!("missing `config :accrue, Oban, ...`")

      not queue_present?(queues, :accrue_webhooks) ->
        raise_oban_not_configured!("missing `:accrue_webhooks` queue")

      not queue_present?(queues, :accrue_mailers) ->
        raise_oban_not_configured!("missing `:accrue_mailers` queue")

      true ->
        :ok
    end
  end

  @doc false
  @spec ensure_oban_supervised!((-> pid() | nil)) :: :ok
  def ensure_oban_supervised!(resolver \\ fn -> Process.whereis(Oban) end)
      when is_function(resolver, 0) do
    if resolver.() do
      :ok
    else
      diagnostic =
        Accrue.SetupDiagnostic.oban_not_supervised(details: "No running Oban process found")

      raise Accrue.ConfigError, key: Oban, diagnostic: diagnostic
    end
  end

  @doc false
  @spec ensure_migrations_current!(list() | nil | (-> term())) :: :ok
  def ensure_migrations_current!(migrations \\ nil)

  def ensure_migrations_current!(migrations) when is_list(migrations) do
    pending =
      Enum.filter(migrations, fn
        {:up, _, _} -> false
        {:up, _, _, _} -> false
        %{status: :up} -> false
        _ -> true
      end)

    if pending == [] do
      :ok
    else
      diagnostic =
        Accrue.SetupDiagnostic.migrations_pending(
          details: "pending=#{inspect(Enum.take(pending, 3))}"
        )

      raise Accrue.ConfigError, key: :repo, diagnostic: diagnostic
    end
  end

  def ensure_migrations_current!(fetch_migrations) when is_function(fetch_migrations, 0) do
    fetch_migrations.()
    |> ensure_migrations_current!()
  rescue
    error in [DBConnection.ConnectionError, Postgrex.Error, ArgumentError, UndefinedFunctionError] ->
      raise_migration_lookup_failed!(error)

    error in RuntimeError ->
      if expected_migration_runtime_error?(error) do
        raise_migration_lookup_failed!(error)
      else
        reraise error, __STACKTRACE__
      end
  end

  def ensure_migrations_current!(nil) do
    repo = Accrue.Repo.repo()

    ensure_migrations_current!(fn ->
      {:ok, migrations, _apps} =
        Ecto.Migrator.with_repo(repo, fn started_repo ->
          Ecto.Migrator.migrations(started_repo)
        end)

      migrations
    end)
  end

  @spec portal_mount_path() :: String.t()
  def portal_mount_path do
    :accrue
    |> Application.get_env(:portal_mount_path, "/billing")
    |> normalize_mount_path()
  end

  @spec plan_resolver() :: module() | nil
  def plan_resolver do
    case Application.get_env(:accrue, :plan_resolver) do
      resolver when is_atom(resolver) -> resolver
      _ -> nil
    end
  end

  @spec portal_base_url() :: String.t() | nil
  def portal_base_url do
    case Application.get_env(:accrue, :portal_base_url) do
      value when is_binary(value) ->
        value
        |> String.trim()
        |> String.trim_trailing("/")
        |> case do
          "" -> nil
          normalized -> validate_portal_base_url!(normalized)
        end

      _ ->
        nil
    end
  end

  @spec portal_url(String.t()) :: String.t()
  def portal_url(path) when is_binary(path) do
    normalized_path =
      path
      |> String.trim()
      |> case do
        "" -> "/"
        value -> "/" <> String.trim_leading(value, "/")
      end

    case portal_base_url() do
      nil ->
        raise Accrue.ConfigError,
          key: :portal_base_url,
          message:
            "missing accrue config key: :portal_base_url (set an absolute base URL before returning local portal checkout or billing portal URLs)"

      base ->
        base <> normalized_path
    end
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

  defp validate_portal_base_url!(value) do
    case URI.parse(value) do
      %URI{scheme: scheme, host: host}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        value

      _ ->
        raise Accrue.ConfigError,
          key: :portal_base_url,
          message:
            "invalid accrue config key: :portal_base_url (expected an absolute http(s) URL such as https://app.example.com)"
    end
  end

  @doc """
  Returns the number of days to retain `:succeeded` webhook events.
  """
  @spec succeeded_retention_days() :: pos_integer() | :infinity
  def succeeded_retention_days, do: get!(:succeeded_retention_days)

  @doc """
  Returns the number of days to retain `:dead` webhook events.
  """
  @spec dead_retention_days() :: pos_integer() | :infinity
  def dead_retention_days, do: get!(:dead_retention_days)

  @doc """
  Returns the list of user-registered webhook handler modules.
  """
  @spec webhook_handlers() :: [module()]
  def webhook_handlers, do: get!(:webhook_handlers)

  @doc """
  Returns the configured Stripe API version string.
  """
  @spec stripe_api_version() :: String.t()
  def stripe_api_version, do: get!(:stripe_api_version)

  @doc """
  Returns the dunning grace-period overlay config.
  """
  @spec dunning() :: keyword()
  def dunning, do: get!(:dunning)

  @doc """
  Returns the dunning campaign cadence config (D-07).

  Raw read with its own nested default — `dunning/0` does not normalize the
  nested `:campaign` key (identical constraint to `past_due_grace/0`), so
  the default journey is supplied here when a host overrides `:dunning`
  without re-stating `:campaign`. Ships ON by default.
  """
  @spec dunning_campaign() :: keyword()
  def dunning_campaign do
    case dunning() |> Keyword.get(:campaign, @default_dunning_campaign) do
      # `campaign: false` opt-out shorthand — normalize to the keyword shape
      # so the predicate/steps accessors always operate on a keyword list
      # (the `{:custom}` validator does the same normalization at boot).
      false -> [enabled: false, steps: []]
      campaign -> campaign
    end
  end

  @doc """
  Returns whether the multi-step dunning campaign is enabled (D-07).

  `false` when the campaign is opted out (`campaign: false` /
  `enabled: false`). Fail-closed: an absent `:enabled` key reads as `false`.
  """
  @spec dunning_campaign_enabled?() :: boolean()
  def dunning_campaign_enabled?, do: Keyword.get(dunning_campaign(), :enabled, false)

  @doc """
  Returns the configured dunning campaign steps (D-07).

  Returns `[]` when the campaign is disabled (so downstream consumers never
  fire steps for an opted-out host), else the configured step list.
  """
  @spec dunning_campaign_steps() :: [keyword()]
  def dunning_campaign_steps do
    if dunning_campaign_enabled?() do
      Keyword.get(dunning_campaign(), :steps, [])
    else
      []
    end
  end

  @doc """
  Returns the configured dunning engine module (D-03).

  Defaults to `Accrue.Dunning.Engine.Oban` (built-in Oban campaign).
  Set `dunning: [engine: Accrue.Integrations.Chimeway]` to opt into
  Chimeway orchestration.

  The atom is returned as-is without loading the module — resolution happens
  at dispatch time in the calling code.
  """
  @spec dunning_engine() :: module()
  def dunning_engine do
    Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)
  end

  @doc """
  Returns the past-due entitlement grace policy: `:none` (default,
  fail-closed), `:dunning` (reuse the dunning grace window), or a positive
  integer of days.

  The `:none` default is applied here because `entitlements/0` does a raw
  read without normalizing nested `:entitlements` defaults. The
  `:dunning` -> `grace_days` resolution is done by the resolver when it
  widens the fold, not by this accessor.
  """
  @spec past_due_grace() :: :none | :dunning | pos_integer()
  def past_due_grace, do: entitlements() |> Keyword.get(:past_due_grace, :none)

  @doc """
  Returns the optional Stripe-native entitlement-sync mode: `:disabled`
  (default, fully inert) or `:advisory` (record summaries to the advisory
  cache for audit / telemetry / the admin read-seam — does NOT change
  `entitled?`/`has_active_plan?` decisions; local mapping stays canonical).

  The `:disabled` default is supplied here because `entitlements/0` does a
  raw read without normalizing nested `:entitlements` defaults (identical
  constraint to `past_due_grace/0`).
  """
  @spec stripe_native_sync() :: :disabled | :advisory
  def stripe_native_sync, do: entitlements() |> Keyword.get(:stripe_native_sync, :disabled)

  @doc """
  Ergonomic predicate for the Stripe-native sync gate: `true` when sync is
  enabled in any non-`:disabled` mode, `false` otherwise. The webhook
  reducer dispatch checks this FIRST so the off lane early-returns before
  any `Repo` call.
  """
  @spec stripe_native_sync?() :: boolean()
  def stripe_native_sync?, do: stripe_native_sync() != :disabled

  @doc """
  Returns the branding config keyword list.

  Reads the nested `:branding` keyword list from app env, merging any
  unset keys with their schema defaults so callers can `Keyword.fetch!`
  any valid key without re-running the full NimbleOptions validator on
  every call site.
  """
  @spec branding() :: keyword()
  def branding do
    raw = get!(:branding)

    cond do
      is_list(raw) and raw == [] ->
        branding_defaults()

      is_list(raw) ->
        merge_with_defaults(raw)

      true ->
        raise Accrue.ConfigError,
          key: :branding,
          message: "expected :branding to be a keyword list, got: #{inspect(raw)}"
    end
  end

  # Merge a partially-populated user branding keyword list with the
  # schema defaults so `branding/1` can `Keyword.fetch!` any valid key.
  # Mirrors the shape NimbleOptions would return after validation but
  # without re-running the (expensive) full schema validator on every
  # call site.
  defp merge_with_defaults(user_kw) do
    Enum.reduce(branding_defaults(), user_kw, fn {k, default}, acc ->
      case Keyword.fetch(acc, k) do
        :error -> Keyword.put(acc, k, default)
        {:ok, _} -> acc
      end
    end)
  end

  @doc """
  Returns a single branding key. Raises if the key is unknown.
  """
  @spec branding(atom()) :: term()
  def branding(key) when is_atom(key), do: Keyword.fetch!(branding(), key)

  @doc """
  Returns branding for the mounted Accrue Admin operator chrome.

  Backwards compatible default: when `:admin_branding` is unset, derive the
  admin label, logo, and accent from the customer billing `:branding` config.
  Hosts that need a split identity can set `:admin_branding` explicitly.
  """
  @spec admin_branding() :: keyword()
  def admin_branding do
    case get!(:admin_branding) do
      [] ->
        customer_branding = branding()

        [
          app_name: Keyword.get(customer_branding, :business_name, "Billing"),
          logo_url: Keyword.get(customer_branding, :logo_url),
          accent_color: Keyword.get(customer_branding, :accent_color, "#5D79F6")
        ]

      raw when is_list(raw) ->
        merge_admin_branding_defaults(raw)

      other ->
        raise Accrue.ConfigError,
          key: :admin_branding,
          message: "expected :admin_branding to be a keyword list, got: #{inspect(other)}"
    end
  end

  @doc """
  Returns a single admin branding key. Raises if the key is unknown.
  """
  @spec admin_branding(atom()) :: term()
  def admin_branding(key) when is_atom(key), do: Keyword.fetch!(admin_branding(), key)

  defp branding_defaults do
    # Pull the nested :branding schema's inner :keys list and extract
    # `{atom, default}` pairs so callers get a fully-populated keyword
    # list with the same shape the validated schema would yield.
    @schema
    |> Keyword.fetch!(:branding)
    |> Keyword.fetch!(:keys)
    |> Enum.map(fn {k, spec} -> {k, Keyword.get(spec, :default)} end)
  end

  defp merge_admin_branding_defaults(user_kw) do
    Enum.reduce(admin_branding_defaults(), user_kw, fn {k, default}, acc ->
      case Keyword.fetch(acc, k) do
        :error -> Keyword.put(acc, k, default)
        {:ok, _} -> acc
      end
    end)
  end

  defp admin_branding_defaults do
    @schema
    |> Keyword.fetch!(:admin_branding)
    |> Keyword.fetch!(:keys)
    |> Enum.map(fn {k, spec} -> {k, Keyword.get(spec, :default)} end)
  end

  @doc """
  Returns the Connect config keyword list.

  Shape: `[default_stripe_account: String.t() | nil,
            platform_fee: [percent: Decimal.t(), fixed: Accrue.Money.t() | nil,
                           min: Accrue.Money.t() | nil, max: Accrue.Money.t() | nil]]`.
  """
  @spec connect() :: keyword()
  def connect, do: get!(:connect)

  @doc """
  Returns the multi-endpoint webhook config.
  """
  @spec webhook_endpoints() :: keyword()
  def webhook_endpoints, do: get!(:webhook_endpoints)

  @doc """
  Returns the DLQ bulk-replay chunk size.
  """
  @spec dlq_replay_batch_size() :: pos_integer()
  def dlq_replay_batch_size, do: get!(:dlq_replay_batch_size)

  @doc """
  Returns the DLQ bulk-replay inter-chunk stagger in milliseconds.
  """
  @spec dlq_replay_stagger_ms() :: non_neg_integer()
  def dlq_replay_stagger_ms, do: get!(:dlq_replay_stagger_ms)

  @doc """
  Returns the hard cap on DLQ bulk-replay rows.
  """
  @spec dlq_replay_max_rows() :: pos_integer()
  def dlq_replay_max_rows, do: get!(:dlq_replay_max_rows)

  @doc """
  Returns the application default locale string.
  """
  @spec default_locale() :: String.t()
  def default_locale, do: get!(:default_locale)

  @doc """
  Returns the application default IANA timezone string.
  """
  @spec default_timezone() :: String.t()
  def default_timezone, do: get!(:default_timezone)

  @doc """
  Returns the configured Cldr backend module used by
  `Accrue.Workers.Mailer.enrich/2` to validate locale strings.
  """
  @spec cldr_backend() :: module()
  def cldr_backend, do: get!(:cldr_backend)

  @doc """
  Returns the runtime `:entitlements` config keyword list (the plan->feature/
  quota catalog), or the schema default `[]` when unset.

  This is a thin runtime accessor (`get!/1`, NOT `compile_env!`) because
  `:entitlements` is host-owned catalog data that legitimately differs per
  environment (e.g. test-mode vs live-mode `price_ids`), like `:branding` and
  `:dunning`. Unlike `branding/0` (which merges schema defaults), this is a
  **raw** runtime read — it does NOT apply the nested per-plan defaults
  (`features: []`, `limits: []`, `price_ids: []`). `validate_at_boot!/0`
  validates the config but discards the normalized result and never writes it
  back to app env. The resolver tolerates missing nested keys via
  `Keyword.get/3` defaults, so it reads this raw value without re-running the
  full validator.
  """
  @spec entitlements() :: keyword()
  def entitlements do
    # Raw runtime read of the host catalog (no nested per-plan defaults — the
    # resolver tolerates missing `:plans` inner keys). The three Phase 124
    # guard keys (`:billable`/`:on_deny`/`:deny_path`) ARE surfaced with their
    # schema defaults via `Keyword.put_new/3` so guard surfaces (Plan 02) can
    # read a usable value whether or not the host overrode them — without
    # re-running the full validator or applying the `:plans` nested defaults.
    :entitlements
    |> get!()
    |> Keyword.put_new(:billable, nil)
    |> Keyword.put_new(:on_deny, :forbidden)
    |> Keyword.put_new(:deny_path, "/")
  end

  @doc "Returns the validated compatibility authority configuration."
  @spec multi_rail() :: keyword()
  def multi_rail do
    entitlements()
    |> Keyword.get(:multi_rail, [])
    |> normalize_multi_rail!()
  end

  @doc "Returns configured entitlement rails, or [] when a host uses the legacy processor path."
  @spec rails() :: keyword()
  def rails, do: get!(:rails)

  @doc "Returns the configured controllable entitlement rail, when rails are configured."
  @spec default_rail() :: atom() | nil
  def default_rail, do: get!(:default_rail)

  @doc "Returns logical plans indexed by `{rail, environment, product_id}`."
  @spec entitlement_product_catalog() :: %{optional({atom(), atom(), String.t()}) => atom()}
  def entitlement_product_catalog do
    normalized_entitlement_product_catalog(entitlements(), rails(), default_rail())
  end

  defp maybe_validate_boot_setup!(opts) do
    _ = Keyword.fetch!(opts, :repo)

    if safe_mix_env() != :test do
      _ = ensure_migrations_current!()
    end

    if Keyword.get(opts, :processor, Accrue.Processor.Fake) == Accrue.Processor.Stripe do
      _ = webhook_signing_secrets(:stripe)
    end

    _ = validate_entitlements_price_ids!(opts)
    _ = validate_rails!(opts)
    _ = validate_entitlement_product_catalog!(opts)

    _ =
      opts
      |> Keyword.get(:entitlements, [])
      |> Keyword.get(:multi_rail, [])
      |> normalize_multi_rail!()

    _ = validate_dunning_campaign_grace!(opts)

    :ok
  end

  @doc false
  def normalize_multi_rail!(config) when is_list(config) do
    mode = Keyword.get(config, :mode, :disabled)
    cohort = Keyword.get(config, :cohort)
    clean_window = Keyword.get(config, :clean_window)

    unless mode in [:disabled, :shadow, :enabled] do
      raise Accrue.ConfigError,
        key: :multi_rail,
        message: "mode must be :disabled, :shadow, or :enabled"
    end

    if mode in [:shadow, :enabled] and is_nil(cohort) do
      raise Accrue.ConfigError, key: :multi_rail, message: "#{mode} requires an explicit cohort"
    end

    validate_multi_rail_cohort!(cohort)
    %{mode: mode, cohort: normalize_multi_rail_cohort(cohort), clean_window: clean_window}
  end

  defp validate_multi_rail_cohort!(nil), do: :ok

  defp validate_multi_rail_cohort!({:accounts, accounts})
       when is_list(accounts) and accounts != [], do: :ok

  defp validate_multi_rail_cohort!({module, function, extra_args})
       when is_atom(module) and is_atom(function) and is_list(extra_args), do: :ok

  defp validate_multi_rail_cohort!(_cohort) do
    raise Accrue.ConfigError,
      key: :multi_rail,
      message: "cohort must be {:accounts, [opaque_account_id]} or {module, function, extra_args}"
  end

  defp normalize_multi_rail_cohort({:accounts, accounts}),
    do: {:accounts, accounts |> Enum.uniq() |> Enum.sort()}

  defp normalize_multi_rail_cohort(cohort), do: cohort

  defp validate_rails!(opts) do
    rails = Keyword.get(opts, :rails, [])
    default_rail = Keyword.get(opts, :default_rail)

    case rails do
      [] when is_nil(default_rail) ->
        :ok

      [] ->
        raise Accrue.ConfigError,
          key: :default_rail,
          message: "default_rail #{inspect(default_rail)} requires a registered rail"

      _ ->
        validate_registered_rail_sources!(rails)
        Enum.each(rails, &validate_rail!/1)
        validate_default_rail!(rails, default_rail, Keyword.fetch!(opts, :processor))
    end
  end

  defp validate_registered_rail_sources!(rails) do
    case Registry.validate(
           Enum.map(rails, fn {_rail, config} -> Keyword.fetch!(config, :source) end)
         ) do
      {:ok, _sources} ->
        :ok

      {:error, _error} ->
        raise Accrue.ConfigError,
          key: :rails,
          message:
            "rails must use distinct sources registered by Accrue.Entitlements.Source.Registry"
    end
  end

  defp validate_rail!({rail, config}) do
    source = Keyword.fetch!(config, :source)
    environments = Keyword.get(config, :environments, [])
    default_environment = Keyword.get(config, :default_environment)

    if rail != source do
      raise Accrue.ConfigError,
        key: :rails,
        message: "rail #{inspect(rail)} must use matching registered source #{inspect(source)}"
    end

    if source == :host_fake and safe_mix_env() != :test do
      raise Accrue.ConfigError,
        key: :rails,
        message: "host_fake is available only for deterministic test/proof rail configuration"
    end

    if source == :apple and Keyword.get(config, :processor) do
      raise Accrue.ConfigError,
        key: :rails,
        message: "Apple is an observer rail and must not configure a processor adapter"
    end

    unless Enum.all?(environments, &(&1 in @product_environments)) do
      raise Accrue.ConfigError,
        key: :rails,
        message:
          "rail #{inspect(rail)} environments must be one of #{inspect(@product_environments)}"
    end

    if default_environment && default_environment not in environments do
      raise Accrue.ConfigError,
        key: :rails,
        message: "rail #{inspect(rail)} default_environment must be a configured environment"
    end
  end

  defp validate_default_rail!(rails, default_rail, processor) do
    rail = Keyword.get(rails, default_rail)

    unless rail && controllable_rail?(Keyword.get(rail, :source)) &&
             Keyword.get(rail, :processor) == processor do
      raise Accrue.ConfigError,
        key: :default_rail,
        message:
          "default_rail #{inspect(default_rail)} must be a registered controllable rail matching :processor"
    end
  end

  # Stripe is the only production gateway rail. The existing host-fake source
  # remains available to deterministic test/proof runs without promoting it to
  # a production rail or treating Apple as an Accrue.Processor implementation.
  defp controllable_rail?(:stripe), do: true
  defp controllable_rail?(:host_fake), do: safe_mix_env() == :test
  defp controllable_rail?(_source), do: false

  defp validate_entitlement_product_catalog!(opts) do
    _ =
      normalized_entitlement_product_catalog(
        opts |> Keyword.get(:entitlements, []),
        Keyword.get(opts, :rails, []),
        Keyword.get(opts, :default_rail)
      )

    :ok
  end

  defp normalized_entitlement_product_catalog(entitlements, rails, default_rail) do
    plans = Keyword.get(entitlements, :plans, [])

    Enum.reduce(plans, %{}, fn {plan, entry}, catalog ->
      catalog
      |> add_qualified_products!(plan, Keyword.get(entry, :products, []), rails)
      |> add_default_rail_price_ids!(
        plan,
        Keyword.get(entry, :price_ids, []),
        rails,
        default_rail
      )
    end)
  end

  defp add_qualified_products!(catalog, plan, products, rails) do
    Enum.reduce(products, catalog, fn {rail, environments}, catalog ->
      rail_config = Keyword.get(rails, rail)

      unless rail_config do
        raise Accrue.ConfigError,
          key: :entitlements,
          message: "products for #{inspect(plan)} reference unregistered rail #{inspect(rail)}"
      end

      Enum.reduce(environments, catalog, fn {environment, product_ids}, catalog ->
        unless environment in @product_environments and
                 environment in Keyword.get(rail_config, :environments, []) do
          raise Accrue.ConfigError,
            key: :entitlements,
            message:
              "products for #{inspect(plan)} reference unconfigured #{inspect({rail, environment})}"
        end

        Enum.reduce(product_ids, catalog, fn product_id, catalog ->
          put_catalog_entry!(catalog, {rail, environment, product_id}, plan)
        end)
      end)
    end)
  end

  defp add_default_rail_price_ids!(catalog, _plan, [], _rails, _default_rail), do: catalog

  defp add_default_rail_price_ids!(catalog, _plan, _price_ids, [], nil), do: catalog

  defp add_default_rail_price_ids!(catalog, plan, price_ids, rails, default_rail) do
    rail_config = Keyword.get(rails, default_rail)
    environment = rail_config && Keyword.get(rail_config, :default_environment)

    unless environment do
      raise Accrue.ConfigError,
        key: :entitlements,
        message:
          "price_ids for #{inspect(plan)} require a configured default rail and environment"
    end

    Enum.reduce(price_ids, catalog, fn price_id, catalog ->
      put_catalog_entry!(catalog, {default_rail, environment, price_id}, plan)
    end)
  end

  defp put_catalog_entry!(catalog, key, plan) do
    case Map.fetch(catalog, key) do
      {:ok, ^plan} ->
        catalog

      {:ok, other_plan} ->
        raise Accrue.ConfigError,
          key: :entitlements,
          message:
            "qualified product #{inspect(key)} mapped to both #{inspect(other_plan)} and #{inspect(plan)}"

      :error ->
        Map.put(catalog, key, plan)
    end
  end

  # Cross-plan boot guard (D-04 / T-123-01): a single `price_id` mapped under
  # two different plans is a silent mis-resolution hazard, so we fail loud at
  # boot. This MUST live here (not as a per-field `{:custom, ...}` validator)
  # because a custom validator only sees one plan entry's value at a time and
  # cannot detect a collision ACROSS plans (RESEARCH § Pattern 3).
  defp validate_entitlements_price_ids!(opts) do
    # Legacy-only hosts retain the raw `price_id -> plan` guard because their
    # LocalMap resolver consumes those bare identifiers directly. Once either
    # additive rail key is configured, D-05 gives every alias a concrete
    # default rail/environment; defer to the qualified tuple reducer so both
    # collision detection and error reporting use the public identity.
    if Keyword.get(opts, :rails, []) == [] and is_nil(Keyword.get(opts, :default_rail)) do
      validate_legacy_entitlements_price_ids!(opts)
    else
      :ok
    end
  end

  defp validate_legacy_entitlements_price_ids!(opts) do
    plans =
      opts
      |> Keyword.get(:entitlements, [])
      |> Keyword.get(:plans, [])

    Enum.reduce(plans, %{}, fn {plan, entry}, seen ->
      entry
      |> Keyword.get(:price_ids, [])
      |> Enum.reduce(seen, fn price_id, acc ->
        case Map.fetch(acc, price_id) do
          {:ok, ^plan} ->
            # Same price_id repeated within the SAME plan is harmless.
            acc

          {:ok, other_plan} ->
            raise Accrue.ConfigError,
              key: :entitlements,
              message:
                "price_id #{inspect(price_id)} mapped to both " <>
                  "#{inspect(other_plan)} and #{inspect(plan)} " <>
                  "(a price_id may belong to at most one plan)"

          :error ->
            Map.put(acc, price_id, plan)
        end
      end)
    end)

    :ok
  end

  # Cross-field boot guard (D-06 / T-128-01): the campaign's final notice
  # MUST fire BEFORE the dunning sweeper moves the subscription to its
  # terminal action — i.e. `last_step.after_days <= grace_days`. This MUST
  # live here (not as a per-field `{:custom, ...}` validator on `:campaign`)
  # because a custom validator only sees the `:campaign` value and cannot
  # read the SIBLING `:grace_days` key on the same `:dunning` map to
  # cross-validate (same NimbleOptions constraint that forces the
  # entitlements price-id guard out of `{:custom}`). A violation here would
  # silently mis-fire (final notice arrives after the account is already
  # terminal), so we fail LOUD at boot.
  defp validate_dunning_campaign_grace!(opts) do
    dunning = Keyword.get(opts, :dunning, [])
    grace_days = Keyword.get(dunning, :grace_days, @default_grace_days)
    raw_campaign = Keyword.get(dunning, :campaign, @default_dunning_campaign)

    # `validate_at_boot!/0` passes the RAW (un-normalized) opts here, so the
    # campaign may still be the `false` opt-out shorthand (the `{:custom}`
    # normalization to `[enabled: false, steps: []]` happens on the discarded
    # validated copy). Treat `false` as disabled — nothing to cross-check.
    campaign = if raw_campaign == false, do: [enabled: false, steps: []], else: raw_campaign

    with true <- Keyword.get(campaign, :enabled, false),
         [_ | _] = steps <- Keyword.get(campaign, :steps, []),
         last_step = List.last(steps),
         last_after_days when is_integer(last_after_days) <- Keyword.get(last_step, :after_days) do
      if last_after_days > grace_days do
        raise Accrue.ConfigError,
          key: :dunning,
          message:
            "dunning campaign last step after_days (#{last_after_days}) must be " <>
              "<= grace_days (#{grace_days}) so the final notice precedes the " <>
              "sweeper's terminal action; got last step after_days=" <>
              "#{last_after_days}, grace_days=#{grace_days}"
      end
    end

    :ok
  end

  defp queue_present?(queues, queue_name) do
    Enum.any?(queues, fn
      {^queue_name, _value} -> true
      _ -> false
    end)
  end

  defp raise_oban_not_configured!(details) do
    diagnostic = Accrue.SetupDiagnostic.oban_not_configured(details: details)
    raise Accrue.ConfigError, key: Oban, diagnostic: diagnostic
  end

  defp raise_migration_lookup_failed!(error) do
    diagnostic =
      Accrue.SetupDiagnostic.migrations_pending(
        details: "migration inspection failed: #{Exception.message(error)}"
      )

    raise Accrue.ConfigError, key: :repo, diagnostic: diagnostic
  end

  defp expected_migration_runtime_error?(error) do
    message = Exception.message(error)

    String.contains?(message, "could not lookup Ecto repo") or
      String.contains?(message, "could not find migrations directory") or
      String.contains?(message, "could not start migration")
  end

  defp safe_mix_env do
    try do
      Mix.env()
    rescue
      _ -> :prod
    end
  end

  # --- custom validators (referenced by @schema) -----------------------

  @doc """
  NimbleOptions `:custom` validator for `:expiring_card_thresholds`.

  Accepts a non-empty list of positive integers that is strictly
  descending (each element strictly less than the previous). Returns
  `{:ok, list}` on success, `{:error, message}` on failure.
  """
  @spec validate_descending(term()) :: {:ok, [pos_integer()]} | {:error, String.t()}
  def validate_descending(list) when is_list(list) and list != [] do
    cond do
      not Enum.all?(list, &(is_integer(&1) and &1 > 0)) ->
        {:error, "expected a list of positive integers, got: #{inspect(list)}"}

      not strictly_descending?(list) ->
        {:error,
         "expected a strictly descending list of positive integers, got: #{inspect(list)}"}

      true ->
        {:ok, list}
    end
  end

  def validate_descending(other) do
    {:error, "expected a non-empty list of positive integers, got: #{inspect(other)}"}
  end

  @doc """
  NimbleOptions `:custom` validator for the `:dunning.campaign` cadence
  (DUN-01, D-04/D-05).

  Accepts:

    * `false` — normalized to `[enabled: false, steps: []]` (opt-out, D-05).
    * a keyword list `[enabled: boolean, steps: [...]]` where each step is a
      keyword list `[after_days: non_neg_integer, key: atom, template: atom]`
      validated against `@step_schema`.

  Intra-list invariants (the cross-field `last_step.after_days <= grace_days`
  invariant is checked separately at boot by
  `validate_dunning_campaign_grace!/1`, since a `{:custom}` validator cannot
  read the sibling `:grace_days` key):

    * `after_days` strictly increasing AND unique across the list.
    * `key` unique across the list.
    * when `enabled: true`, `steps` MUST be non-empty — `steps: []` while
      enabled is a LOUD `{:error, _}` (never a silent disable, D-05).

  Returns `{:ok, normalized_keyword}` on success, `{:error, message}` on
  failure (so boot validation fails loud rather than silently mis-firing).
  """
  @spec validate_dunning_campaign(term()) :: {:ok, keyword()} | {:error, String.t()}
  def validate_dunning_campaign(false), do: {:ok, [enabled: false, steps: []]}

  def validate_dunning_campaign(campaign) when is_list(campaign) do
    enabled = Keyword.get(campaign, :enabled, false)
    steps = Keyword.get(campaign, :steps, [])

    cond do
      not is_boolean(enabled) ->
        {:error, "expected :enabled to be a boolean, got: #{inspect(enabled)}"}

      not is_list(steps) ->
        {:error, "expected :steps to be a list of keyword lists, got: #{inspect(steps)}"}

      enabled and steps == [] ->
        {:error,
         "dunning campaign is enabled but :steps is empty; set `campaign: false` " <>
           "to opt out, or supply at least one step (an empty enabled cadence " <>
           "would silently never fire)"}

      true ->
        validate_dunning_campaign_steps(enabled, steps)
    end
  end

  def validate_dunning_campaign(other) do
    {:error,
     "expected `false` or a keyword list `[enabled: boolean, steps: [...]]`, " <>
       "got: #{inspect(other)}"}
  end

  defp validate_dunning_campaign_steps(enabled, steps) do
    with {:ok, validated} <- validate_each_step(steps),
         :ok <- validate_steps_after_days(validated),
         :ok <- validate_steps_keys_unique(validated) do
      {:ok, [enabled: enabled, steps: validated]}
    end
  end

  defp validate_each_step(steps) do
    Enum.reduce_while(steps, {:ok, []}, fn step, {:ok, acc} ->
      case NimbleOptions.validate(step, @step_schema) do
        {:ok, normalized} ->
          {:cont, {:ok, [normalized | acc]}}

        {:error, %NimbleOptions.ValidationError{} = err} ->
          {:halt, {:error, Exception.message(err)}}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      {:error, _} = err -> err
    end
  end

  defp validate_steps_after_days(steps) do
    after_days = Enum.map(steps, &Keyword.fetch!(&1, :after_days))

    cond do
      length(Enum.uniq(after_days)) != length(after_days) ->
        {:error,
         "expected strictly-increasing unique :after_days across steps, got " <>
           "duplicates in: #{inspect(after_days)}"}

      not strictly_increasing?(after_days) ->
        {:error,
         "expected a strictly increasing list of :after_days across steps, " <>
           "got: #{inspect(after_days)}"}

      true ->
        :ok
    end
  end

  defp validate_steps_keys_unique(steps) do
    keys = Enum.map(steps, &Keyword.fetch!(&1, :key))

    if length(Enum.uniq(keys)) == length(keys) do
      :ok
    else
      {:error, "expected unique step :key values across steps, got: #{inspect(keys)}"}
    end
  end

  @doc """
  NimbleOptions `:custom` validator for the global `:entitlements`
  `on_deny` handler (Phase 124, ENT-06).

  Accepts any of the supported deny-handler shapes and returns
  `{:ok, value}`; a malformed value returns `{:error, message}` so boot
  validation (`validate_at_boot!/0`) fails loud rather than letting a
  broken deny path silently fail open (T-124-01).

  Supported shapes:

    * `:forbidden` — built-in opaque 403 / LiveView redirect to `deny_path`.
    * `{:redirect, path}` when `path` is a binary.
    * `{status, body}` when `status` is an integer and `body` is a binary.
    * a 2-arity `fun` `(container, ctx -> result)`.
    * an MFA `{m, f, a}` when `m`/`f` are atoms and `a` is a list.
  """
  @spec validate_on_deny(term()) :: {:ok, term()} | {:error, String.t()}
  def validate_on_deny(:forbidden), do: {:ok, :forbidden}

  def validate_on_deny({:redirect, path} = value) when is_binary(path), do: {:ok, value}

  def validate_on_deny({status, body} = value) when is_integer(status) and is_binary(body),
    do: {:ok, value}

  def validate_on_deny(fun) when is_function(fun, 2), do: {:ok, fun}

  def validate_on_deny({m, f, a} = value) when is_atom(m) and is_atom(f) and is_list(a),
    do: {:ok, value}

  def validate_on_deny(other) do
    {:error,
     "expected :forbidden | {:redirect, path} | {status, body} | fun/2 | {m,f,a}, " <>
       "got: #{inspect(other)}"}
  end

  @doc """
  NimbleOptions `:custom` validator for `:branding.accent_color` /
  `:branding.secondary_color`. Accepts `#rgb`, `#rrggbb`, and
  `#rrggbbaa` hex color strings; rejects anything else.
  """
  @spec validate_hex(term()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_hex("#" <> rest = full) when byte_size(rest) in [3, 6, 8] do
    if rest =~ ~r/\A[0-9a-fA-F]+\z/ do
      {:ok, full}
    else
      {:error, "expected a hex color (#rgb, #rrggbb, or #rrggbbaa), got: #{inspect(full)}"}
    end
  end

  def validate_hex(other) do
    {:error, "expected a hex color string (#rgb, #rrggbb, or #rrggbbaa), got: #{inspect(other)}"}
  end

  @doc false
  def validate_billing_schema!(schema) when is_binary(schema) do
    if Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*$/, schema) do
      schema
    else
      raise Accrue.ConfigError,
        key: :billing_schema,
        message:
          "invalid accrue config key: :billing_schema " <>
            "(expected a PostgreSQL identifier such as \"billing\" or \"public\")"
    end
  end

  def validate_billing_schema!(schema) do
    raise Accrue.ConfigError,
      key: :billing_schema,
      message:
        "invalid accrue config key: :billing_schema " <>
          "(expected a string such as \"billing\" or \"public\", got: #{inspect(schema)})"
  end

  @doc false
  @spec validate_billing_schema(term()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_billing_schema(schema) when is_binary(schema) do
    if Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*$/, schema) do
      {:ok, schema}
    else
      {:error, "expected a PostgreSQL identifier such as \"billing\" or \"public\""}
    end
  end

  def validate_billing_schema(schema) do
    {:error, "expected a string such as \"billing\" or \"public\", got: #{inspect(schema)}"}
  end

  defp strictly_descending?([_]), do: true

  defp strictly_descending?([a, b | rest]) when a > b, do: strictly_descending?([b | rest])

  defp strictly_descending?(_), do: false

  defp strictly_increasing?([]), do: true

  defp strictly_increasing?([_]), do: true

  defp strictly_increasing?([a, b | rest]) when a < b, do: strictly_increasing?([b | rest])

  defp strictly_increasing?(_), do: false

  # --- internals --------------------------------------------------------

  @spec default_for(atom()) :: term()
  defp default_for(key) do
    case Keyword.fetch(@schema, key) do
      {:ok, spec} -> Keyword.get(spec, :default)
      :error -> nil
    end
  end
end
