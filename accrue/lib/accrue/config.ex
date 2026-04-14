defmodule Accrue.Config do
  @schema [
    # --- Repo + adapters --------------------------------------------------
    repo: [
      type: :atom,
      required: true,
      doc: "Host `Ecto.Repo` module that Accrue writes to (event ledger, webhook events, billing tables)."
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

    # --- Email pipeline (Plan 05 reads these) ----------------------------
    emails: [
      type: :keyword_list,
      default: [],
      doc:
        "Per-email-type switches (D-25). Keys are email type atoms; values are `boolean` or `{Mod, :fun, args}` MFA callbacks."
    ],
    email_overrides: [
      type: :keyword_list,
      default: [],
      doc:
        "Per-email-type template module overrides (D-23 rung 3). Keys are email type atoms; values are module names."
    ],
    attach_invoice_pdf: [
      type: :boolean,
      default: true,
      doc: "Auto-attach invoice PDF to the receipt email (D-39)."
    ],

    # --- Event ledger (Plan 03/06 read this) -----------------------------
    enforce_immutability: [
      type: :boolean,
      default: false,
      doc:
        "When true, `Accrue.Application` boot raises if the current PG role has UPDATE/DELETE on `accrue_events` (D-10)."
    ],

    # --- Brand config (Plan 05 reads these for email defaults — D-24) ----
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

    # --- Webhook pipeline (Plan 03 reads these) ----------------------------
    webhook_signing_secrets: [
      type: :any,
      default: %{},
      doc:
        "Map of processor atom to signing secret(s). Each value is a string " <>
          "or list of strings for rotation (D2-05). Example: " <>
          "`%{stripe: [\"whsec_old\", \"whsec_new\"]}`."
    ],

    # --- Webhook retention (Plan 04, D2-34) --------------------------------
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
          "Called sequentially after the default handler on each webhook event (D2-31). " <>
          "Example: `[MyApp.BillingHandler, MyApp.AnalyticsHandler]`."
    ],

    # --- Phase 3 subscription lifecycle ----------------------------------
    expiring_card_thresholds: [
      type: {:custom, __MODULE__, :validate_descending, []},
      default: [30, 7, 1],
      doc:
        "Strictly-descending list of day thresholds at which the expiring-card " <>
          "reminder email fires ahead of a stored card's expiration (D3-11). " <>
          "Default: `[30, 7, 1]` — 30, 7, and 1 days out."
    ],
    idempotency_mode: [
      type: {:in, [:warn, :strict]},
      default: :warn,
      doc:
        "How `Accrue.Actor.current_operation_id!/0` behaves when the process " <>
          "dict has no operation_id (D3-63). `:strict` raises `Accrue.ConfigError`; " <>
          "`:warn` (the default) generates a random UUID and logs a warning. " <>
          "Set to `:strict` in production to ensure every outbound processor " <>
          "call carries a deterministic idempotency key."
    ],
    succeeded_refund_retention_days: [
      type: :pos_integer,
      default: 90,
      doc:
        "Number of days to retain `:succeeded` refund records before pruning " <>
          "(D3-34). Default: 90."
    ],

    # --- Phase 4: advanced billing + webhook hardening -------------------
    dunning: [
      type: :keyword_list,
      default: [
        mode: :stripe_smart_retries,
        grace_days: 14,
        terminal_action: :unpaid,
        telemetry_prefix: [:accrue, :ops]
      ],
      doc:
        "Dunning grace-period overlay config (D4-02). `:mode` is " <>
          "`:stripe_smart_retries` or `:disabled`; `:terminal_action` is " <>
          "`:unpaid` or `:canceled`; `:grace_days` adds N days past Stripe's " <>
          "last retry before Accrue calls " <>
          "`LatticeStripe.Subscription.update(id, status: terminal_action)`."
    ],
    webhook_endpoints: [
      type: :keyword_list,
      default: [],
      doc:
        "Map of endpoint name to `[secret:, mode:]` for multi-endpoint " <>
          "webhooks (WH-13). Example: `[primary: [secret: \"whsec_...\"], " <>
          "connect: [secret: \"whsec_...\", mode: :connect]]`."
    ],
    dlq_replay_batch_size: [
      type: :pos_integer,
      default: 100,
      doc: "Number of rows per chunk in `Accrue.Webhooks.DLQ.requeue_where/2` bulk replay (D4-04)."
    ],
    dlq_replay_stagger_ms: [
      type: :non_neg_integer,
      default: 1_000,
      doc:
        "Milliseconds to sleep between chunks during DLQ bulk replay " <>
          "(protects downstream). Default: 1_000 (D4-04)."
    ],
    dlq_replay_max_rows: [
      type: :pos_integer,
      default: 10_000,
      doc:
        "Hard cap on bulk replay. Returns `{:error, :replay_too_large}` " <>
          "unless `force: true` is passed. Default: 10_000 (D4-04)."
    ]
  ]

  @moduledoc """
  Runtime configuration schema for Accrue, backed by `NimbleOptions`.

  This module is the **single source of truth** for every Phase 1 config
  key. Downstream plans (03/04/05/06) READ via `get!/1` or
  `Application.get_env/3` but never edit this schema. Plan 02 intentionally
  front-loads the full keyset so Wave 2 plans never collide on this file.

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
  Validates a keyword list against the Phase 1 schema and returns the
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
  Returns the NimbleOptions schema keyword list. Used by Plan 06's
  `validate_at_boot!/0` to iterate keys.
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
      {:ok, secrets} when is_list(secrets) and secrets != [] -> secrets
      {:ok, secret} when is_binary(secret) and secret != "" -> secret
      _ ->
        raise Accrue.ConfigError,
          key: :webhook_signing_secrets,
          message: "no webhook signing secrets configured for processor #{inspect(processor)}"
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
  Returns the list of user-registered webhook handler modules (D2-31).
  """
  @spec webhook_handlers() :: [module()]
  def webhook_handlers, do: get!(:webhook_handlers)

  @doc """
  Returns the configured Stripe API version string (D2-14).
  """
  @spec stripe_api_version() :: String.t()
  def stripe_api_version, do: get!(:stripe_api_version)

  # --- Phase 4 helpers --------------------------------------------------

  @doc """
  Returns the dunning grace-period overlay config (D4-02).
  """
  @spec dunning() :: keyword()
  def dunning, do: get!(:dunning)

  @doc """
  Returns the multi-endpoint webhook config (WH-13).
  """
  @spec webhook_endpoints() :: keyword()
  def webhook_endpoints, do: get!(:webhook_endpoints)

  @doc """
  Returns the DLQ bulk-replay chunk size (D4-04).
  """
  @spec dlq_replay_batch_size() :: pos_integer()
  def dlq_replay_batch_size, do: get!(:dlq_replay_batch_size)

  @doc """
  Returns the DLQ bulk-replay inter-chunk stagger in milliseconds (D4-04).
  """
  @spec dlq_replay_stagger_ms() :: non_neg_integer()
  def dlq_replay_stagger_ms, do: get!(:dlq_replay_stagger_ms)

  @doc """
  Returns the hard cap on DLQ bulk-replay rows (D4-04).
  """
  @spec dlq_replay_max_rows() :: pos_integer()
  def dlq_replay_max_rows, do: get!(:dlq_replay_max_rows)

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
        {:error,
         "expected a list of positive integers, got: #{inspect(list)}"}

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
