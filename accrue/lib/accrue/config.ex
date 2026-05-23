defmodule Accrue.Config do
  @schema [
    # --- Repo + adapters --------------------------------------------------
    repo: [
      type: :atom,
      required: true,
      doc:
        "Host `Ecto.Repo` module that Accrue writes to (event ledger, webhook events, billing tables)."
    ],
    processor: [
      type: :atom,
      default: Accrue.Processor.Fake,
      doc: "Processor adapter implementing `Accrue.Processor` behaviour."
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
        grace_days: 14,
        terminal_action: :unpaid,
        telemetry_prefix: [:accrue, :ops]
      ],
      doc:
        "Dunning grace-period overlay config. `:mode` is " <>
          "`:stripe_smart_retries` or `:disabled`; `:terminal_action` is " <>
          "`:unpaid` or `:canceled`; `:grace_days` adds N days past Stripe's " <>
          "last retry before Accrue asks the processor facade to move the " <>
          "subscription to the terminal action."
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
        list_unsubscribe_url: [type: {:or, [:string, nil]}, default: nil]
      ],
      doc:
        "Branding config. Single source of truth for email + PDF brand. " <>
          "`:from_email` and `:support_email` are required for any real deploy. " <>
          "See guides/branding.md."
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
                price_ids: [type: {:list, :string}, default: []]
              ]
            ]
          ],
          doc:
            "Logical plan name (atom) -> entitlement entry (features/limits/price_ids)"
        ],
        resolver: [
          type: :atom,
          default: Accrue.Entitlements.Resolver.LocalMap,
          doc:
            "Resolver module (Accrue.Entitlements.Resolver behaviour). Default LocalMap."
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
          doc:
            "LiveView fallback redirect target for `:forbidden` / non-redirectable denies."
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

    _ = NimbleOptions.validate!(opts, @schema)
    _ = maybe_validate_boot_setup!(opts)
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

  defp branding_defaults do
    # Pull the nested :branding schema's inner :keys list and extract
    # `{atom, default}` pairs so callers get a fully-populated keyword
    # list with the same shape the validated schema would yield.
    @schema
    |> Keyword.fetch!(:branding)
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

  defp maybe_validate_boot_setup!(opts) do
    _ = Keyword.fetch!(opts, :repo)

    if safe_mix_env() != :test do
      _ = ensure_migrations_current!()
    end

    if Keyword.get(opts, :processor, Accrue.Processor.Fake) == Accrue.Processor.Stripe do
      _ = webhook_signing_secrets(:stripe)
    end

    _ = validate_entitlements_price_ids!(opts)

    :ok
  end

  # Cross-plan boot guard (D-04 / T-123-01): a single `price_id` mapped under
  # two different plans is a silent mis-resolution hazard, so we fail loud at
  # boot. This MUST live here (not as a per-field `{:custom, ...}` validator)
  # because a custom validator only sees one plan entry's value at a time and
  # cannot detect a collision ACROSS plans (RESEARCH § Pattern 3).
  defp validate_entitlements_price_ids!(opts) do
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

  defp strictly_descending?([_]), do: true

  defp strictly_descending?([a, b | rest]) when a > b, do: strictly_descending?([b | rest])

  defp strictly_descending?(_), do: false

  # --- internals --------------------------------------------------------

  @spec default_for(atom()) :: term()
  defp default_for(key) do
    case Keyword.fetch(@schema, key) do
      {:ok, spec} -> Keyword.get(spec, :default)
      :error -> nil
    end
  end
end
