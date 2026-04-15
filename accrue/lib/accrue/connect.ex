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

  alias Accrue.Connect.{Account, AccountLink, LoginLink, Projection}
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
           message: "Accrue.Connect.create_account/2 invalid params: " <> Exception.message(nimble_err)
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
