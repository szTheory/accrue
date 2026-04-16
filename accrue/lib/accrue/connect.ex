defmodule Accrue.Connect do
  @moduledoc """
  Phase 5 Connect domain facade (D5-01..D5-06).

  Wraps the `Accrue.Processor` Connect callbacks with:

    * `with_account/2` — pdict-scoped block that threads a
      `stripe_account` id through every nested processor call via the
      `:accrue_connected_account_id` key. This is the same key the
      Plan 05-01 `Accrue.Processor.Stripe.resolve_stripe_account/1`
      precedence chain reads, and the Plan 05-01 Oban middleware
      restores across the enqueue → perform boundary.
    * `create_account/2..list_accounts/1` dual bang/tuple facade
      (mirrors `Accrue.BillingPortal.Session`).
    * Local projection upsert via `Accrue.Connect.Projection.decompose/1`
      + `Accrue.Connect.Account.changeset/2`, wrapped in a single
      `Accrue.Repo.transact/1` block with `Accrue.Events.record_multi/3`
      so the state mutation + audit row commit atomically (D-14).

  Soft-delete semantics: `delete_account/2` tombstones the local row
  via `deauthorized_at` rather than hard-deleting it (D5-05 audit
  requirement).
  """

  alias Accrue.Billing.Charge
  alias Accrue.Connect.{Account, AccountLink, LoginLink, PlatformFee, Projection}
  alias Accrue.Money
  alias Accrue.Processor
  alias Accrue.Repo

  import Ecto.Query, only: [from: 2]

  @pdict_key :accrue_connected_account_id

  @account_link_schema [
    return_url: [type: :string, required: true],
    refresh_url: [type: :string, required: true],
    type: [type: {:in, ["account_onboarding", "account_update"]}, default: "account_onboarding"],
    collect: [type: {:in, ["currently_due", "eventually_due"]}, default: "currently_due"]
  ]

  @create_schema [
    type: [
      type: {:in, ["standard", "express", "custom", :standard, :express, :custom]},
      required: true
    ],
    country: [type: {:or, [:string, nil]}, default: nil],
    email: [type: {:or, [:string, nil]}, default: nil],
    capabilities: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    business_type: [type: {:or, [:string, nil]}, default: nil],
    tos_acceptance: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    metadata: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    owner_type: [type: {:or, [:string, nil]}, default: nil],
    owner_id: [type: {:or, [:any, nil]}, default: nil]
  ]

  # ---------------------------------------------------------------------------
  # Scope helpers (pdict writer side of the D5-01 precedence chain)
  # ---------------------------------------------------------------------------

  @doc """
  Runs `fun` with the connected-account scope set in the process
  dictionary, restoring the prior value (or clearing it) in an `after`
  block even if `fun` raises. Mirrors `Accrue.Stripe.with_api_version/2`.

  Accepts a stripe account id string, a `%Accrue.Connect.Account{}`
  struct, or `nil` (nil clears any existing scope for the block's
  lifetime — useful for temporarily stepping back to platform scope
  from inside a nested block).
  """
  @spec with_account(Account.t() | String.t() | nil, (-> result)) :: result when result: var
  def with_account(account_or_id, fun) when is_function(fun, 0) do
    new = resolve_account_id(account_or_id)
    old = Process.get(@pdict_key)

    if new do
      Process.put(@pdict_key, new)
    else
      Process.delete(@pdict_key)
    end

    try do
      fun.()
    after
      cond do
        old -> Process.put(@pdict_key, old)
        true -> Process.delete(@pdict_key)
      end
    end
  end

  @doc "Reads the currently-scoped connected account id from the pdict (or `nil`)."
  @spec current_account_id() :: String.t() | nil
  def current_account_id, do: Process.get(@pdict_key)

  @doc """
  Writes the connected-account scope to the process dictionary without
  restoring afterwards. Used by `Accrue.Plug.PutConnectedAccount` and
  the Plan 05-01 Oban middleware, where the scope lifetime matches the
  request/job lifetime rather than a lexical block.
  """
  @spec put_account_id(String.t() | nil) :: :ok
  def put_account_id(nil) do
    Process.delete(@pdict_key)
    :ok
  end

  def put_account_id(id) when is_binary(id) do
    Process.put(@pdict_key, id)
    :ok
  end

  @doc "Clears the connected-account scope from the process dictionary."
  @spec delete_account_id() :: :ok
  def delete_account_id do
    Process.delete(@pdict_key)
    :ok
  end

  @doc """
  Normalizes a caller-supplied account reference to a bare stripe account
  id string. Accepts `%Account{}`, a binary, or `nil` (returns `nil` —
  caller-side auth is out of scope; see T-05-02-02 in the plan threat model).
  """
  @spec resolve_account_id(Account.t() | String.t() | nil) :: String.t() | nil
  def resolve_account_id(%Account{stripe_account_id: id}), do: id
  def resolve_account_id(id) when is_binary(id), do: id
  def resolve_account_id(nil), do: nil

  # ---------------------------------------------------------------------------
  # CRUD — dual bang/tuple facade
  # ---------------------------------------------------------------------------

  @doc """
  Creates a new connected account through the configured processor,
  then upserts the local `accrue_connect_accounts` row and records an
  `"connect.account.created"` event in the same transaction.

  ## Options

  See `@create_schema` in the module source for the full NimbleOptions
  schema. `:type` is required (no default — host explicitly picks
  `:standard`/`:express`/`:custom`).
  """
  @spec create_account(map() | keyword(), keyword()) ::
          {:ok, Account.t()} | {:error, term()}
  def create_account(params, opts \\ [])

  def create_account(params, opts) when is_list(params), do: create_account(Map.new(params), opts)

  def create_account(params, opts) when is_map(params) and is_list(opts) do
    case validate_create_params(params) do
      {:ok, {stripe_params, req_opts, owner}} ->
        final_opts = Keyword.merge(req_opts, opts)

        case Processor.__impl__().create_account(stripe_params, final_opts) do
          {:ok, stripe} ->
            upsert_local(stripe, owner, :connect_account_created)

          {:error, err} ->
            {:error, err}
        end

      {:error, _} = err ->
        err
    end
  end

  @doc "Bang variant of `create_account/2`. Raises on failure."
  @spec create_account!(map() | keyword(), keyword()) :: Account.t()
  def create_account!(params, opts \\ []) do
    case create_account(params, opts) do
      {:ok, acct} -> acct
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.create_account/2 failed: #{inspect(other)}"
    end
  end

  @doc """
  Retrieves a connected account through the processor and upserts the
  local row (force_status_changeset path — out-of-order webhooks can
  arrive before first retrieve). Returns `{:ok, %Account{}}`.
  """
  @spec retrieve_account(String.t(), keyword()) :: {:ok, Account.t()} | {:error, term()}
  def retrieve_account(acct_id, opts \\ []) when is_binary(acct_id) and is_list(opts) do
    case Processor.__impl__().retrieve_account(acct_id, opts) do
      {:ok, stripe} -> upsert_local(stripe, nil, :connect_account_retrieved)
      {:error, err} -> {:error, err}
    end
  end

  @doc "Bang variant of `retrieve_account/2`."
  @spec retrieve_account!(String.t(), keyword()) :: Account.t()
  def retrieve_account!(acct_id, opts \\ []) do
    case retrieve_account(acct_id, opts) do
      {:ok, acct} -> acct
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.retrieve_account/2 failed: #{inspect(other)}"
    end
  end

  @doc """
  Updates a connected account through the processor. Nested params
  (`capabilities:`, `settings: %{payouts: %{schedule: ...}}`) are
  forwarded verbatim (CONN-08/09).
  """
  @spec update_account(String.t(), map(), keyword()) ::
          {:ok, Account.t()} | {:error, term()}
  def update_account(acct_id, params, opts \\ [])
      when is_binary(acct_id) and is_map(params) and is_list(opts) do
    case Processor.__impl__().update_account(acct_id, params, opts) do
      {:ok, stripe} -> upsert_local(stripe, nil, :connect_account_updated)
      {:error, err} -> {:error, err}
    end
  end

  @doc "Bang variant of `update_account/3`."
  @spec update_account!(String.t(), map(), keyword()) :: Account.t()
  def update_account!(acct_id, params, opts \\ []) do
    case update_account(acct_id, params, opts) do
      {:ok, acct} -> acct
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.update_account/3 failed: #{inspect(other)}"
    end
  end

  @doc """
  Deletes a connected account through the processor and tombstones the
  local row via `deauthorized_at` (soft delete per D5-05 — audit trail
  is never hard-deleted).
  """
  @spec delete_account(String.t(), keyword()) ::
          {:ok, Account.t()} | {:error, term()}
  def delete_account(acct_id, opts \\ []) when is_binary(acct_id) and is_list(opts) do
    case Processor.__impl__().delete_account(acct_id, opts) do
      {:ok, _stripe} ->
        tombstone_local(acct_id)

      {:error, err} ->
        {:error, err}
    end
  end

  @doc "Bang variant of `delete_account/2`."
  @spec delete_account!(String.t(), keyword()) :: Account.t()
  def delete_account!(acct_id, opts \\ []) do
    case delete_account(acct_id, opts) do
      {:ok, acct} -> acct
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.delete_account/2 failed: #{inspect(other)}"
    end
  end

  @doc """
  Rejects a connected account through the processor. `reason` is a
  bare string per the Stripe API (e.g. `"fraud"`, `"terms_of_service"`).
  """
  @spec reject_account(String.t(), String.t(), keyword()) ::
          {:ok, Account.t()} | {:error, term()}
  def reject_account(acct_id, reason, opts \\ [])
      when is_binary(acct_id) and is_binary(reason) and is_list(opts) do
    case Processor.__impl__().reject_account(acct_id, %{reason: reason}, opts) do
      {:ok, stripe} -> upsert_local(stripe, nil, :connect_account_rejected)
      {:error, err} -> {:error, err}
    end
  end

  @doc "Bang variant of `reject_account/3`."
  @spec reject_account!(String.t(), String.t(), keyword()) :: Account.t()
  def reject_account!(acct_id, reason, opts \\ []) do
    case reject_account(acct_id, reason, opts) do
      {:ok, acct} -> acct
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.reject_account/3 failed: #{inspect(other)}"
    end
  end

  @doc "Lists connected accounts through the processor (pass-through)."
  @spec list_accounts(keyword()) :: {:ok, map()} | {:error, term()}
  def list_accounts(opts \\ []) when is_list(opts) do
    Processor.__impl__().list_accounts(%{}, opts)
  end

  @doc """
  Local-first fetch: returns the persisted `%Account{}` row by stripe
  account id, falling back to `retrieve_account/2` on miss (which upserts
  the local row as a side-effect).
  """
  @spec fetch_account(String.t(), keyword()) :: {:ok, Account.t()} | {:error, term()}
  def fetch_account(acct_id, opts \\ []) when is_binary(acct_id) and is_list(opts) do
    case Repo.get_by(Account, stripe_account_id: acct_id) do
      %Account{} = acct -> {:ok, acct}
      nil -> retrieve_account(acct_id, opts)
    end
  end

  @doc "Bang variant of `fetch_account/2`."
  @spec fetch_account!(String.t(), keyword()) :: Account.t()
  def fetch_account!(acct_id, opts \\ []) do
    case fetch_account(acct_id, opts) do
      {:ok, acct} -> acct
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.fetch_account/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Account Link + Login Link (D5-06, CONN-02, CONN-07)
  # ---------------------------------------------------------------------------

  @doc """
  Creates a Stripe Connect Account Link for hosted onboarding or
  account-update flows.

  Accepts either an `%Account{}` struct, a bare `"acct_..."` binary,
  or a map with an `:account` key. `:return_url` and `:refresh_url`
  are required per `@account_link_schema`.

  Returns `{:ok, %Accrue.Connect.AccountLink{}}` on success. The
  returned struct masks its `:url` field in `Inspect` output — treat
  the URL as a short-lived bearer credential and redirect the user
  immediately.

  ## Options

  - `:return_url` (required) — where Stripe redirects on completion
  - `:refresh_url` (required) — where Stripe redirects if the link expires
  - `:type` — `"account_onboarding"` (default) or `"account_update"`
  - `:collect` — `"currently_due"` (default) or `"eventually_due"`
  """
  @spec create_account_link(Account.t() | String.t(), keyword()) ::
          {:ok, AccountLink.t()} | {:error, term()}
  def create_account_link(account, opts \\ []) when is_list(opts) do
    with {:ok, acct_id} <- require_account_id(account),
         {:ok, validated} <- NimbleOptions.validate(opts, @account_link_schema) do
      params = %{
        account: acct_id,
        return_url: validated[:return_url],
        refresh_url: validated[:refresh_url],
        type: validated[:type],
        collect: validated[:collect]
      }

      case Processor.__impl__().create_account_link(params, []) do
        {:ok, stripe} -> {:ok, AccountLink.from_stripe(stripe)}
        {:error, err} -> {:error, err}
      end
    end
  end

  @doc "Bang variant of `create_account_link/2`. Raises on failure."
  @spec create_account_link!(Account.t() | String.t(), keyword()) :: AccountLink.t()
  def create_account_link!(account, opts \\ []) do
    case create_account_link(account, opts) do
      {:ok, link} -> link
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.create_account_link/2 failed: #{inspect(other)}"
    end
  end

  @doc """
  Creates a Stripe Express dashboard Login Link for a connected account.

  **Only Express accounts are supported.** Standard and Custom
  accounts are rejected locally before reaching the processor to
  avoid leaking "acct_X is Standard" via a Stripe 400 error payload
  (T-05-03-02). The local row is consulted first; on a miss the
  account is retrieved from the processor.

  Returns `{:ok, %Accrue.Connect.LoginLink{}}` on success. The
  returned struct masks its `:url` field in `Inspect` output — treat
  the URL as a short-lived bearer credential and redirect the user
  immediately.
  """
  @spec create_login_link(Account.t() | String.t(), keyword()) ::
          {:ok, LoginLink.t()} | {:error, term()}
  def create_login_link(account, opts \\ []) when is_list(opts) do
    with {:ok, acct_id} <- require_account_id(account),
         {:ok, _row} <- require_express(acct_id) do
      case Processor.__impl__().create_login_link(acct_id, []) do
        {:ok, stripe} -> {:ok, LoginLink.from_stripe(stripe)}
        {:error, err} -> {:error, err}
      end
    end
  end

  @doc "Bang variant of `create_login_link/2`. Raises on failure."
  @spec create_login_link!(Account.t() | String.t(), keyword()) :: LoginLink.t()
  def create_login_link!(account, opts \\ []) do
    case create_login_link(account, opts) do
      {:ok, link} -> link
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.create_login_link/2 failed: #{inspect(other)}"
    end
  end

  defp require_account_id(%Account{stripe_account_id: id}) when is_binary(id), do: {:ok, id}
  defp require_account_id(id) when is_binary(id), do: {:ok, id}

  defp require_account_id(other) do
    {:error,
     %Accrue.ConfigError{
       key: :account,
       message:
         "expected %Accrue.Connect.Account{} or a binary stripe_account_id, got: " <>
           inspect(other)
     }}
  end

  defp require_express(acct_id) when is_binary(acct_id) do
    case fetch_account(acct_id) do
      {:ok, %Account{type: "express"} = row} ->
        {:ok, row}

      {:ok, %Account{type: type}} ->
        {:error,
         %Accrue.APIError{
           code: "invalid_request_error",
           http_status: 400,
           message:
             "Accrue.Connect.create_login_link/2 is only supported for Express " <>
               "connected accounts; got type=#{inspect(type)} for #{acct_id}"
         }}

      {:error, _} = err ->
        err
    end
  end

  # ---------------------------------------------------------------------------
  # Platform fee (D5-04, CONN-06) — pure Money math, caller-inject semantics
  # ---------------------------------------------------------------------------

  @doc """
  Computes a platform fee as a pure `Accrue.Money` value.

  **Caller-inject semantics.** This helper returns the computed fee; it
  does NOT auto-apply the value to any charge or transfer. Callers thread
  the result into `application_fee_amount:` on their own charge/transfer
  calls (Plan 05-05) so the fee line is always auditable at the call site.

  See `Accrue.Connect.PlatformFee` for the full computation order and
  clamp semantics. Defaults come from the `:platform_fee` sub-key of the
  `:connect` config (`Accrue.Config.get!(:connect)`), which ships with
  Stripe's standard 2.9% baseline and no fixed/min/max.

  ## Examples

      iex> {:ok, fee} = Accrue.Connect.platform_fee(
      ...>   Accrue.Money.new(10_000, :usd),
      ...>   percent: Decimal.new("2.9"),
      ...>   fixed: Accrue.Money.new(30, :usd)
      ...> )
      iex> fee
      %Accrue.Money{amount_minor: 320, currency: :usd}
  """
  @spec platform_fee(Accrue.Money.t(), keyword()) ::
          {:ok, Accrue.Money.t()} | {:error, Exception.t()}
  defdelegate platform_fee(gross, opts \\ []), to: PlatformFee, as: :compute

  @doc "Bang variant of `platform_fee/2`. Raises on validation failure."
  @spec platform_fee!(Accrue.Money.t(), keyword()) :: Accrue.Money.t()
  defdelegate platform_fee!(gross, opts \\ []), to: PlatformFee, as: :compute!

  # ---------------------------------------------------------------------------
  # Destination charges (D5-03, CONN-04)
  # ---------------------------------------------------------------------------

  @destination_charge_schema [
    amount: [type: {:struct, Money}, required: true],
    destination: [type: :any, required: true],
    customer: [type: :any, required: true],
    application_fee_amount: [type: {:or, [{:struct, Money}, nil]}, default: nil],
    description: [type: {:or, [:string, nil]}, default: nil],
    metadata: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    statement_descriptor: [type: {:or, [:string, nil]}, default: nil],
    payment_method: [type: {:or, [:string, nil]}, default: nil]
  ]

  @separate_charge_schema [
    amount: [type: {:struct, Money}, required: true],
    customer: [type: :any, required: true],
    destination: [type: :any, required: true],
    transfer_amount: [type: {:struct, Money}, required: true],
    description: [type: {:or, [:string, nil]}, default: nil],
    metadata: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    payment_method: [type: {:or, [:string, nil]}, default: nil]
  ]

  @transfer_schema [
    amount: [type: {:struct, Money}, required: true],
    destination: [type: :any, required: true],
    description: [type: {:or, [:string, nil]}, default: nil],
    metadata: [type: {:or, [{:map, :any, :any}, nil]}, default: nil],
    source_transaction: [type: {:or, [:string, nil]}, default: nil]
  ]

  @doc """
  Creates a Stripe Connect **destination charge** (D5-03, CONN-04).

  A destination charge is a single platform-scoped charge whose
  `transfer_data.destination` points at a connected account. Stripe
  handles the platform-to-connected-account settlement on your behalf;
  you do not need to issue a separate `Transfer`. An optional
  `:application_fee_amount` (pre-computed via
  `Accrue.Connect.platform_fee/2`) is forwarded to Stripe verbatim.

  **This call is always PLATFORM-scoped.** The `Stripe-Account` header
  is explicitly unset regardless of any `with_account/2` scope the
  caller may be inside — Pitfall 2 would otherwise cause Stripe to 400.

  ## Required parameters

    * `:amount` — `%Accrue.Money{}` gross charge amount
    * `:destination` — `%Accrue.Connect.Account{}` struct or
      `"acct_..."` binary
    * `:customer` — `%Accrue.Billing.Customer{}` struct

  ## Optional parameters

    * `:application_fee_amount` — `%Accrue.Money{}` platform fee.
      Compute via `Accrue.Connect.platform_fee/2` and pass through —
      fees are caller-injected per D5-04 (never auto-applied).
    * `:description`, `:metadata`, `:statement_descriptor`
    * `:payment_method` — processor payment method id

  Returns `{:ok, %Accrue.Billing.Charge{}}` on success. The local
  charge row is persisted and bundled with the resolved destination
  account via the charge's `data` jsonb field.

  ## Examples

      {:ok, fee} = Accrue.Connect.platform_fee(Accrue.Money.new(10_000, :usd))

      {:ok, %Accrue.Billing.Charge{} = charge} =
        Accrue.Connect.destination_charge(
          %{
            amount: Accrue.Money.new(10_000, :usd),
            destination: connected_account,
            customer: customer
          },
          application_fee_amount: fee,
          payment_method: "pm_..."
        )
  """
  @spec destination_charge(map() | keyword(), keyword()) ::
          {:ok, Charge.t()} | {:error, term()}
  def destination_charge(params, opts \\ [])

  def destination_charge(params, opts) when is_list(params),
    do: destination_charge(Map.new(params), opts)

  def destination_charge(params, opts) when is_map(params) and is_list(opts) do
    merged = params |> Map.to_list() |> Keyword.merge(opts)

    with {:ok, validated} <- NimbleOptions.validate(merged, @destination_charge_schema),
         {:ok, acct_id} <- require_account_id(validated[:destination]),
         {:ok, customer_id, customer_struct} <- resolve_customer(validated[:customer]) do
      %Money{} = gross = validated[:amount]
      fee = validated[:application_fee_amount]

      stripe_params =
        %{
          amount: gross.amount_minor,
          currency: Atom.to_string(gross.currency),
          customer: customer_id,
          transfer_data: %{destination: acct_id}
        }
        |> put_if_present(:application_fee_amount, fee_minor(fee))
        |> put_if_present(:description, validated[:description])
        |> put_if_present(:metadata, validated[:metadata])
        |> put_if_present(:statement_descriptor, validated[:statement_descriptor])
        |> put_if_present(:payment_method, validated[:payment_method])
        |> Map.put(:confirm, true)

      # Pitfall 2: force platform scope unconditionally.
      request_opts = Keyword.put([], :stripe_account, nil)

      Accrue.Telemetry.span(
        [:accrue, :connect, :destination_charge],
        %{destination: acct_id, amount_minor: gross.amount_minor, currency: gross.currency},
        fn ->
          case Processor.__impl__().create_charge(stripe_params, request_opts) do
            {:ok, stripe_ch} ->
              with {:ok, charge_row} <- persist_charge(stripe_ch, customer_struct, gross),
                   _ = record_connect_event("connect.destination_charge", charge_row, acct_id) do
                {:ok, charge_row}
              end

            {:error, _} = err ->
              err
          end
        end
      )
    end
  end

  @doc "Bang variant of `destination_charge/2`. Raises on failure."
  @spec destination_charge!(map() | keyword(), keyword()) :: Charge.t()
  def destination_charge!(params, opts \\ []) do
    case destination_charge(params, opts) do
      {:ok, charge} -> charge
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.destination_charge/2 failed: #{inspect(other)}"
    end
  end

  @doc """
  Creates a **separate charge and transfer** flow (D5-03, CONN-05).

  Two distinct API calls:

    1. `Processor.create_charge/2` on the PLATFORM (no `Stripe-Account`
       header, no `transfer_data`). Charges the customer against the
       platform balance.
    2. `Processor.create_transfer/2` to the connected account,
       `source_transaction` linked to the charge above, moving a
       caller-specified amount from the platform balance to the
       connected-account balance.

  Use this flow when the platform needs explicit control over the
  transfer step — e.g. delayed transfers, split destinations, or
  transfers that are not a fixed percentage of the gross.

  Returns `{:ok, %{charge: %Charge{}, transfer: map()}}` on success.

  If the transfer step fails after the charge succeeded, returns
  `{:error, {:transfer_failed, %Charge{}, error}}` so callers can
  reconcile — the charge row is persisted but no transfer exists.

  ## Required parameters

    * `:amount` — `%Money{}` gross charge amount
    * `:customer` — `%Accrue.Billing.Customer{}` struct
    * `:destination` — connected account
    * `:transfer_amount` — `%Money{}` amount to forward (platform keeps
      the difference as its fee; Accrue does NOT compute this for you —
      D5-04 caller-inject semantics)
  """
  @spec separate_charge_and_transfer(map() | keyword(), keyword()) ::
          {:ok, %{charge: Charge.t(), transfer: map()}}
          | {:error, term()}
  def separate_charge_and_transfer(params, opts \\ [])

  def separate_charge_and_transfer(params, opts) when is_list(params),
    do: separate_charge_and_transfer(Map.new(params), opts)

  def separate_charge_and_transfer(params, opts) when is_map(params) and is_list(opts) do
    merged = params |> Map.to_list() |> Keyword.merge(opts)

    with {:ok, validated} <- NimbleOptions.validate(merged, @separate_charge_schema),
         {:ok, acct_id} <- require_account_id(validated[:destination]),
         {:ok, customer_id, customer_struct} <- resolve_customer(validated[:customer]) do
      %Money{} = gross = validated[:amount]
      %Money{} = xfer = validated[:transfer_amount]

      charge_params =
        %{
          amount: gross.amount_minor,
          currency: Atom.to_string(gross.currency),
          customer: customer_id,
          confirm: true
        }
        |> put_if_present(:description, validated[:description])
        |> put_if_present(:metadata, validated[:metadata])
        |> put_if_present(:payment_method, validated[:payment_method])

      platform_opts = [stripe_account: nil]

      Accrue.Telemetry.span(
        [:accrue, :connect, :separate_charge_and_transfer],
        %{
          destination: acct_id,
          amount_minor: gross.amount_minor,
          transfer_minor: xfer.amount_minor
        },
        fn ->
          with {:ok, stripe_ch} <-
                 Processor.__impl__().create_charge(charge_params, platform_opts),
               {:ok, charge_row} <- persist_charge(stripe_ch, customer_struct, gross) do
            transfer_params = %{
              amount: xfer.amount_minor,
              currency: Atom.to_string(xfer.currency),
              destination: acct_id,
              source_transaction: charge_row.processor_id
            }

            case Processor.__impl__().create_transfer(transfer_params, platform_opts) do
              {:ok, transfer} ->
                _ = record_connect_event("connect.separate_charge_transfer", charge_row, acct_id)
                {:ok, %{charge: charge_row, transfer: transfer}}

              {:error, err} ->
                {:error, {:transfer_failed, charge_row, err}}
            end
          end
        end
      )
    end
  end

  @doc "Bang variant of `separate_charge_and_transfer/2`. Raises on failure."
  @spec separate_charge_and_transfer!(map() | keyword(), keyword()) ::
          %{charge: Charge.t(), transfer: map()}
  def separate_charge_and_transfer!(params, opts \\ []) do
    case separate_charge_and_transfer(params, opts) do
      {:ok, result} ->
        result

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "Accrue.Connect.separate_charge_and_transfer/2 failed: #{inspect(other)}"
    end
  end

  @doc """
  Creates a standalone **Transfer** from the platform balance to a
  connected account (D5-03, CONN-05).

  This is the bare Transfers API — a thin wrapper over
  `Processor.create_transfer/2`. Use when you need to manually move
  funds outside a charge flow (e.g. revenue share payouts from an
  accumulated platform balance).

  Phase 5 does NOT ship a dedicated `accrue_connect_transfers` schema
  (D5-05 events-ledger-only). Each successful call appends a
  `connect.transfer` row to `accrue_events` via `Accrue.Events.record/1`.

  Returns `{:ok, map()}` (the bare processor response).

  ## Required parameters

    * `:amount` — `%Money{}`
    * `:destination` — connected account
  """
  @spec transfer(map() | keyword(), keyword()) :: {:ok, map()} | {:error, term()}
  def transfer(params, opts \\ [])

  def transfer(params, opts) when is_list(params), do: transfer(Map.new(params), opts)

  def transfer(params, opts) when is_map(params) and is_list(opts) do
    merged = params |> Map.to_list() |> Keyword.merge(opts)

    with {:ok, validated} <- NimbleOptions.validate(merged, @transfer_schema),
         {:ok, acct_id} <- require_account_id(validated[:destination]) do
      %Money{} = amount = validated[:amount]

      stripe_params =
        %{
          amount: amount.amount_minor,
          currency: Atom.to_string(amount.currency),
          destination: acct_id
        }
        |> put_if_present(:description, validated[:description])
        |> put_if_present(:metadata, validated[:metadata])
        |> put_if_present(:source_transaction, validated[:source_transaction])

      platform_opts = [stripe_account: nil]

      Accrue.Telemetry.span(
        [:accrue, :connect, :transfer],
        %{destination: acct_id, amount_minor: amount.amount_minor, currency: amount.currency},
        fn ->
          case Processor.__impl__().create_transfer(stripe_params, platform_opts) do
            {:ok, transfer} ->
              _ =
                Accrue.Events.record(%{
                  type: "connect.transfer",
                  subject_type: "Accrue.Connect.Transfer",
                  subject_id: transfer[:id] || transfer["id"] || acct_id,
                  data: %{
                    "destination" => acct_id,
                    "amount_minor" => amount.amount_minor,
                    "currency" => Atom.to_string(amount.currency)
                  }
                })

              {:ok, transfer}

            {:error, _} = err ->
              err
          end
        end
      )
    end
  end

  @doc "Bang variant of `transfer/2`. Raises on failure."
  @spec transfer!(map() | keyword(), keyword()) :: map()
  def transfer!(params, opts \\ []) do
    case transfer(params, opts) do
      {:ok, t} -> t
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.transfer/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Internals — Plan 05-05 charges / transfers
  # ---------------------------------------------------------------------------

  defp resolve_customer(%Accrue.Billing.Customer{processor_id: pid} = c)
       when is_binary(pid),
       do: {:ok, pid, c}

  defp resolve_customer(id) when is_binary(id), do: {:ok, id, nil}

  defp resolve_customer(other) do
    {:error,
     %Accrue.ConfigError{
       key: :customer,
       message:
         "expected %Accrue.Billing.Customer{} or a binary processor_id, got: " <> inspect(other)
     }}
  end

  defp fee_minor(nil), do: nil
  defp fee_minor(%Money{amount_minor: m}), do: m

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp persist_charge(stripe_ch, nil, %Money{} = _amount) do
    # Caller passed a bare customer id string; we cannot persist a local
    # row without a %Customer{} (the FK is on customer_id). Return the
    # raw stripe shape wrapped as an error so the caller notices.
    {:error,
     %Accrue.ConfigError{
       key: :customer,
       message:
         "Accrue.Connect charge helpers require a %Accrue.Billing.Customer{} struct " <>
           "to persist the local projection (got raw id; stripe_charge=#{inspect(stripe_ch[:id] || stripe_ch["id"])})"
     }}
  end

  defp persist_charge(stripe_ch, %Accrue.Billing.Customer{} = customer, %Money{} = amount) do
    bt = get_field(stripe_ch, :balance_transaction) || %{}
    fee_minor = get_field(bt, :fee)
    fees_settled_at = if is_integer(fee_minor), do: Accrue.Clock.utc_now(), else: nil

    status =
      case get_field(stripe_ch, :status) do
        s when is_atom(s) and not is_nil(s) -> Atom.to_string(s)
        s when is_binary(s) -> s
        _ -> nil
      end

    attrs = %{
      customer_id: customer.id,
      processor: processor_name(),
      processor_id: get_field(stripe_ch, :id),
      amount_cents: amount.amount_minor,
      currency: Atom.to_string(amount.currency),
      status: status,
      stripe_fee_amount_minor: fee_minor,
      stripe_fee_currency: Atom.to_string(amount.currency),
      fees_settled_at: fees_settled_at,
      data: stringify_charge(stripe_ch),
      metadata: get_field(stripe_ch, :metadata) || %{}
    }

    %Charge{}
    |> Charge.changeset(attrs)
    |> Repo.insert()
  end

  defp record_connect_event(type, %Charge{} = charge, destination) do
    Accrue.Events.record(%{
      type: type,
      subject_type: "Accrue.Billing.Charge",
      subject_id: charge.id,
      data: %{
        "charge_id" => charge.id,
        "processor_id" => charge.processor_id,
        "destination" => destination
      }
    })
  end

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp get_field(%{} = m, key) when is_atom(key) do
    Map.get(m, key) || Map.get(m, Atom.to_string(key))
  end

  defp get_field(_, _), do: nil

  defp stringify_charge(value) when is_map(value) and not is_struct(value) do
    for {k, v} <- value, into: %{} do
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {key, stringify_charge(v)}
    end
  end

  defp stringify_charge(value) when is_list(value), do: Enum.map(value, &stringify_charge/1)
  defp stringify_charge(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  defp stringify_charge(value)
       when is_atom(value) and not is_nil(value) and not is_boolean(value),
       do: Atom.to_string(value)

  defp stringify_charge(value), do: value

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp validate_create_params(params) do
    kw = params |> Map.to_list() |> normalize_type_value()

    case NimbleOptions.validate(kw, @create_schema) do
      {:ok, opts} ->
        {owner, opts} = Keyword.split(opts, [:owner_type, :owner_id])

        stripe_params =
          opts
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> Map.new()
          |> normalize_type_string()

        {:ok, {stripe_params, [], Map.new(owner)}}

      {:error, nimble_err} ->
        {:error,
         %Accrue.ConfigError{
           key: :type,
           message:
             "Accrue.Connect.create_account/2 invalid params: " <> Exception.message(nimble_err)
         }}
    end
  end

  # Accept both atom and string forms for :type without the NimbleOptions
  # {:in, [...]} check tripping on atoms.
  defp normalize_type_value(kw) do
    Enum.map(kw, fn
      {:type, t} when is_atom(t) -> {:type, Atom.to_string(t)}
      {:type, t} when is_binary(t) -> {:type, t}
      other -> other
    end)
  end

  defp normalize_type_string(%{type: t} = params) when is_atom(t),
    do: Map.put(params, :type, Atom.to_string(t))

  defp normalize_type_string(params), do: params

  defp upsert_local(stripe_account, owner, event_type) do
    {:ok, decomposed} = Projection.decompose(stripe_account)

    stripe_id = decomposed.stripe_account_id

    Repo.transact(fn ->
      existing = Repo.get_by(Account, stripe_account_id: stripe_id)

      changeset =
        case existing do
          nil ->
            attrs = decomposed |> maybe_merge_owner(owner)
            Account.changeset(%Account{}, attrs)

          %Account{} = row ->
            Account.force_status_changeset(row, Map.drop(decomposed, [:stripe_account_id, :type]))
        end

      case upsert_insert_or_update(changeset, existing) do
        {:ok, row} ->
          _ =
            Accrue.Events.record(%{
              type: Atom.to_string(event_type) |> String.replace("_", "."),
              subject_type: "Accrue.Connect.Account",
              subject_id: row.stripe_account_id,
              data: %{"stripe_account_id" => row.stripe_account_id}
            })

          {:ok, row}

        {:error, cs} ->
          {:error, cs}
      end
    end)
  end

  defp upsert_insert_or_update(cs, nil), do: Repo.insert(cs)
  defp upsert_insert_or_update(cs, %Account{}), do: Repo.update(cs)

  defp maybe_merge_owner(attrs, nil), do: attrs
  defp maybe_merge_owner(attrs, owner) when is_map(owner) and map_size(owner) == 0, do: attrs

  defp maybe_merge_owner(attrs, owner) when is_map(owner) do
    # Stringify owner_id since the local column is :string (polymorphic).
    owner =
      case Map.get(owner, :owner_id) do
        nil -> owner
        id when is_binary(id) -> owner
        other -> Map.put(owner, :owner_id, to_string(other))
      end

    Map.merge(attrs, owner)
  end

  defp tombstone_local(acct_id) do
    case Repo.get_by(Account, stripe_account_id: acct_id) do
      nil ->
        {:error, :not_found}

      %Account{} = row ->
        cs =
          Account.force_status_changeset(row, %{deauthorized_at: DateTime.utc_now()})

        case Repo.update(cs) do
          {:ok, updated} ->
            _ =
              Accrue.Events.record(%{
                type: "connect.account.deauthorized",
                subject_type: "Accrue.Connect.Account",
                subject_id: updated.stripe_account_id,
                data: %{"stripe_account_id" => updated.stripe_account_id}
              })

            {:ok, updated}

          {:error, _} = err ->
            err
        end
    end
  end

  # Suppress unused warning for the `from` import if the compiler
  # decides the query below is unused after optimization.
  @doc false
  def __query_placeholder__, do: from(a in Account, select: a.id)
end
