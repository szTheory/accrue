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

  # --- internals --------------------------------------------------------

  @spec default_for(atom()) :: term()
  defp default_for(key) do
    case Keyword.fetch(@schema, key) do
      {:ok, spec} -> Keyword.get(spec, :default)
      :error -> nil
    end
  end
end
