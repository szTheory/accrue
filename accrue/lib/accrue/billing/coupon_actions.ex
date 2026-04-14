defmodule Accrue.Billing.CouponActions do
  @moduledoc """
  Phase 4 Plan 05 coupon + promotion-code write surface (BILL-27, BILL-28).

  Thin wrappers around the processor's coupon + promotion-code
  endpoints. Per D4-01 / Claude's Discretion: the local
  `accrue_coupons` + `accrue_promotion_codes` tables are a thin
  projection — the processor is canonical and Accrue mirrors only the
  fields the admin LiveView needs.

  ## Functions

    * `create_coupon/2` — creates a coupon via the processor, persists
      a local row, records a `"coupon.created"` event.
    * `create_promotion_code/2` — creates a promotion code via the
      processor, persists a local row FK'd to the coupon, records a
      `"promotion_code.created"` event.
    * `apply_promotion_code/3` — looks up a local promotion code by
      its customer-facing `code`, validates `active` / `expires_at` /
      `max_redemptions`, then calls
      `Processor.update_subscription(sub_id, %{coupon: coupon_id})`.
      Records a `"coupon.applied"` event on success.

  All public functions follow the dual-API `foo/n` + `foo!/n` pattern
  (D-05). Processor calls run inside `Repo.transact/2` here because
  coupon create is not SCA-capable — there's no asynchronous 3DS leg
  to keep outside the transaction.
  """

  require Logger

  alias Accrue.Actor

  alias Accrue.Billing.{
    Coupon,
    PromotionCode,
    PromotionCodeProjection,
    Subscription
  }

  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  # ---------------------------------------------------------------------
  # create_coupon/1..2
  # ---------------------------------------------------------------------

  @doc """
  Creates a coupon through the configured processor and persists a
  local `%Coupon{}` row plus a `"coupon.created"` event.

  `params` is a map of processor-shape attrs. Supply a caller-chosen
  `:id` to pin a deterministic coupon id (required for the comp flow's
  `"accrue_comp_100_forever"` seed coupon).
  """
  @spec create_coupon(map(), keyword()) :: {:ok, Coupon.t()} | {:error, term()}
  def create_coupon(params, opts \\ []) when is_map(params) and is_list(opts) do
    op_id = resolve_operation_id(opts)
    subject = to_string(params[:id] || params["id"] || params[:name] || "coupon_new")
    idem_key = Idempotency.key(:create_coupon, subject, op_id)

    Repo.transact(fn ->
      with {:ok, processor_result} <-
             Processor.__impl__().coupon_create(
               params,
               Keyword.put(opts, :idempotency_key, idem_key)
             ),
           attrs <- project_coupon(processor_result),
           {:ok, coupon} <- upsert_coupon(attrs),
           {:ok, _event} <-
             Events.record(%{
               type: "coupon.created",
               subject_type: "Coupon",
               subject_id: coupon.id,
               data: %{processor_id: coupon.processor_id}
             }) do
        {:ok, coupon}
      end
    end)
  end

  @doc "Raising variant of `create_coupon/2`."
  @spec create_coupon!(map(), keyword()) :: Coupon.t()
  def create_coupon!(params, opts \\ []) do
    case create_coupon(params, opts) do
      {:ok, coupon} -> coupon
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "create_coupon!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # create_promotion_code/1..2
  # ---------------------------------------------------------------------

  @doc """
  Creates a promotion code through the configured processor and
  persists a local `%PromotionCode{}` row FK'd to the underlying
  coupon. Records a `"promotion_code.created"` event.

  `params[:coupon]` MUST be the processor-side coupon id (e.g.
  `"accrue_comp_100_forever"` or `"SUMMER25"`).
  """
  @spec create_promotion_code(map(), keyword()) ::
          {:ok, PromotionCode.t()} | {:error, term()}
  def create_promotion_code(params, opts \\ []) when is_map(params) and is_list(opts) do
    op_id = resolve_operation_id(opts)
    subject = to_string(params[:code] || params["code"] || "promo_new")
    idem_key = Idempotency.key(:create_promotion_code, subject, op_id)

    Repo.transact(fn ->
      with {:ok, processor_result} <-
             Processor.__impl__().promotion_code_create(
               params,
               Keyword.put(opts, :idempotency_key, idem_key)
             ),
           {:ok, attrs, coupon_processor_id} <- PromotionCodeProjection.decompose(processor_result),
           {:ok, coupon_id} <- resolve_coupon_fk(coupon_processor_id),
           row_attrs <-
             attrs
             |> Map.put(:processor, processor_name())
             |> Map.put(:coupon_id, coupon_id),
           {:ok, promo} <-
             %PromotionCode{} |> PromotionCode.changeset(row_attrs) |> Repo.insert(),
           {:ok, _event} <-
             Events.record(%{
               type: "promotion_code.created",
               subject_type: "PromotionCode",
               subject_id: promo.id,
               data: %{code: promo.code, coupon_processor_id: coupon_processor_id}
             }) do
        {:ok, promo}
      end
    end)
  end

  @doc "Raising variant of `create_promotion_code/2`."
  @spec create_promotion_code!(map(), keyword()) :: PromotionCode.t()
  def create_promotion_code!(params, opts \\ []) do
    case create_promotion_code(params, opts) do
      {:ok, promo} -> promo
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "create_promotion_code!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # apply_promotion_code/2..3
  # ---------------------------------------------------------------------

  @type apply_error ::
          :not_found
          | :inactive
          | :expired
          | :max_redemptions_reached
          | :coupon_missing
          | term()

  @doc """
  Attaches a promotion code to a subscription by looking up the local
  `%PromotionCode{}` row by customer-facing `code`, validating
  applicability, then calling the processor's `update_subscription`
  with `%{coupon: coupon_processor_id}`.

  Returns `{:ok, %Subscription{}}` on success. On validation failure
  returns `{:error, :not_found | :inactive | :expired |
  :max_redemptions_reached}` BEFORE making any processor call
  (T-04-05-02 mitigation).

  A `"coupon.applied"` event is recorded inside the same
  `Repo.transact/2` as the processor call on success.
  """
  @spec apply_promotion_code(Subscription.t(), String.t(), keyword()) ::
          {:ok, Subscription.t()} | {:error, apply_error()}
  def apply_promotion_code(%Subscription{} = sub, code, opts \\ []) when is_binary(code) do
    with {:ok, promo} <- fetch_applicable(code),
         {:ok, coupon} <- fetch_coupon(promo.coupon_id) do
      op_id = resolve_operation_id(opts)
      idem_key = Idempotency.key(:apply_promotion_code, sub.id, op_id)

      Repo.transact(fn ->
        with {:ok, _stripe_sub} <-
               Processor.__impl__().update_subscription(
                 sub.processor_id,
                 %{coupon: coupon.processor_id},
                 Keyword.put(opts, :idempotency_key, idem_key)
               ),
             {:ok, _event} <-
               Events.record(%{
                 type: "coupon.applied",
                 subject_type: "Subscription",
                 subject_id: sub.id,
                 data: %{
                   coupon_processor_id: coupon.processor_id,
                   promotion_code: promo.code
                 }
               }) do
          {:ok, sub}
        end
      end)
    end
  end

  @doc "Raising variant of `apply_promotion_code/3`."
  @spec apply_promotion_code!(Subscription.t(), String.t(), keyword()) :: Subscription.t()
  def apply_promotion_code!(%Subscription{} = sub, code, opts \\ []) when is_binary(code) do
    case apply_promotion_code(sub, code, opts) do
      {:ok, updated} -> updated
      {:error, err} when is_exception(err) -> raise err
      {:error, reason} -> raise "apply_promotion_code!/3 failed: #{inspect(reason)}"
    end
  end

  # ---------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------

  defp fetch_applicable(code) do
    now = Accrue.Clock.utc_now()

    case Repo.get_by(PromotionCode, code: code) do
      nil ->
        {:error, :not_found}

      %PromotionCode{active: false} ->
        {:error, :inactive}

      %PromotionCode{
        max_redemptions: max,
        times_redeemed: redeemed
      }
      when is_integer(max) and redeemed >= max ->
        {:error, :max_redemptions_reached}

      %PromotionCode{expires_at: %DateTime{} = exp} = promo ->
        if DateTime.compare(exp, now) == :lt do
          {:error, :expired}
        else
          {:ok, promo}
        end

      %PromotionCode{} = promo ->
        {:ok, promo}
    end
  end

  defp fetch_coupon(nil), do: {:error, :coupon_missing}

  defp fetch_coupon(coupon_id) when is_binary(coupon_id) do
    case Repo.get(Coupon, coupon_id) do
      nil -> {:error, :coupon_missing}
      %Coupon{} = c -> {:ok, c}
    end
  end

  defp resolve_coupon_fk(nil), do: {:ok, nil}

  defp resolve_coupon_fk(processor_id) when is_binary(processor_id) do
    case Repo.get_by(Coupon, processor_id: processor_id) do
      nil -> {:ok, nil}
      %Coupon{id: id} -> {:ok, id}
    end
  end

  # Accept processor-shape atom- or string-keyed maps, normalize to the
  # Coupon schema's attrs map. Mirrors the thin-passthrough shape
  # established by Phase 3 D3-16 for amount_off / percent_off / duration
  # columns; everything else rides in `data`.
  # Upsert by processor_id: look up existing, otherwise insert. Avoids
  # the Phase 3 coupons schema/DB drift on `{:replace_all_except, ...}`
  # (redeem_by + amount_off_minor are in the schema but not the
  # migration).
  defp upsert_coupon(attrs) do
    attrs = Map.put(attrs, :processor, processor_name())

    case Repo.get_by(Coupon, processor_id: attrs[:processor_id]) do
      nil ->
        %Coupon{} |> Coupon.changeset(attrs) |> Repo.insert()

      %Coupon{} = existing ->
        existing |> Coupon.changeset(attrs) |> Repo.update()
    end
  end

  defp project_coupon(%{} = processor_result) do
    get = fn key ->
      Map.get(processor_result, key) || Map.get(processor_result, Atom.to_string(key))
    end

    %{
      processor_id: get.(:id),
      name: get.(:name),
      amount_off_cents: get.(:amount_off),
      amount_off_minor: get.(:amount_off),
      percent_off: normalize_percent(get.(:percent_off)),
      currency: get.(:currency),
      duration: get.(:duration),
      duration_in_months: get.(:duration_in_months),
      max_redemptions: get.(:max_redemptions),
      times_redeemed: get.(:times_redeemed) || 0,
      valid: get.(:valid) != false,
      redeem_by: unix_dt(get.(:redeem_by)),
      metadata: get.(:metadata) || %{},
      data: stringify(processor_result)
    }
  end

  defp unix_dt(nil), do: nil
  defp unix_dt(%DateTime{} = dt), do: dt
  defp unix_dt(n) when is_integer(n) and n > 0, do: DateTime.from_unix!(n)
  defp unix_dt(_), do: nil

  defp normalize_percent(nil), do: nil
  defp normalize_percent(%Decimal{} = d), do: d
  defp normalize_percent(n) when is_integer(n), do: Decimal.new(n)
  defp normalize_percent(n) when is_float(n), do: Decimal.from_float(n)
  defp normalize_percent(s) when is_binary(s) do
    case Decimal.parse(s) do
      {d, ""} -> d
      _ -> nil
    end
  end

  defp stringify(value) do
    Accrue.Billing.SubscriptionProjection.to_string_keys(value)
  end

  defp resolve_operation_id(opts) do
    Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
  end

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end
end
