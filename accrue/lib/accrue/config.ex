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
    pdf_adapter: [
      type: :atom,
      default: Accrue.PDF.ChromicPDF,
      doc: "PDF adapter implementing `Accrue.PDF` behaviour."
    ],
    auth_adapter: [
      type: :atom,
      default: Accrue.Auth.Default,
      doc: "Auth adapter implementing `Accrue.Auth` behaviour."
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

    # --- Brand config (flat keys; prefer nested :branding) ---------------
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
      doc:
        "Number of rows per chunk in `Accrue.Webhooks.DLQ.requeue_where/2` bulk replay."
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
    ]
  ]

  @moduledoc """
  Runtime configuration schema for Accrue, backed by `NimbleOptions`.

  This module is the **single source of truth** for supported `:accrue`
  application keys. Host code reads validated values via `get!/1` or
  `Application.get_env/3`; extend behaviour through adapters, not by editing
  this schema from application code.

  ## Compile-time vs runtime

  Adapter atoms (`:processor`, `:mailer`, `:mailer_adapter`, `:pdf_adapter`,
  `:auth_adapter`) are stable per-deploy and fine at compile time via
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
  Returns the branding config keyword list.

  Falls back to building a keyword list from deprecated top-level flat
  branding keys (`:business_name`, `:logo_url`, `:from_email`,
  `:from_name`, `:support_email`, `:business_address`) when the nested
  `:branding` key is unset or empty. Nested `:branding` always takes
  precedence. See `Accrue.Application.warn_deprecated_branding/0` for the
  boot-time `Logger.warning` when flat keys are still in use.
  """
  @spec branding() :: keyword()
  def branding do
    raw = get!(:branding)

    cond do
      is_list(raw) and raw == [] ->
        branding_from_flat_keys()

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
  Returns the list of deprecated flat branding keys.
  Consumed by `Accrue.Application.warn_deprecated_branding/0` and by the
  internal flat-key shim in `branding/0`.
  """
  @spec deprecated_flat_branding_keys() :: [atom()]
  def deprecated_flat_branding_keys do
    [:business_name, :logo_url, :from_email, :from_name, :support_email, :business_address]
  end

  # Build a branding keyword list from the deprecated top-level flat keys.
  # Only keys the host has actually set are copied; remaining slots come
  # from the nested :branding schema defaults.
  defp branding_from_flat_keys do
    flat = deprecated_flat_branding_keys()
    any_set? = Enum.any?(flat, fn k -> Application.get_env(:accrue, k) != nil end)

    if any_set? do
      base = branding_defaults()

      Enum.reduce(flat, base, fn key, acc ->
        case Application.get_env(:accrue, key) do
          nil ->
            acc

          value ->
            target_key = flat_key_to_nested(key)
            Keyword.put(acc, target_key, value)
        end
      end)
    else
      branding_defaults()
    end
  end

  defp flat_key_to_nested(:business_address), do: :company_address
  defp flat_key_to_nested(other), do: other

  defp branding_defaults do
    # Pull the nested :branding schema's inner :keys list and extract
    # `{atom, default}` pairs so the shim returns a fully-populated kw
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

  defp maybe_validate_boot_setup!(opts) do
    _ = Keyword.fetch!(opts, :repo)

    if safe_mix_env() != :test do
      _ = ensure_migrations_current!()
    end

    if Keyword.get(opts, :processor, Accrue.Processor.Fake) == Accrue.Processor.Stripe do
      _ = webhook_signing_secrets(:stripe)
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
