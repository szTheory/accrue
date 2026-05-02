defmodule Accrue.Billing.DiscountMappingActions do
  @moduledoc """
  Local write/read/resolve helpers for Braintree discount mappings.
  """

  import Ecto.Query, only: [from: 2]

  alias Accrue.Billing.DiscountMapping
  alias Accrue.Error.DiscountMappingInvalid
  alias Accrue.Repo

  @processor "braintree"

  @type resolve_error ::
          :not_found
          | :inactive
          | :expired
          | :max_redemptions_reached
          | DiscountMappingInvalid.t()
          | term()

  @spec upsert_discount_mapping(String.t(), map()) ::
          {:ok, DiscountMapping.t()} | {:error, Ecto.Changeset.t() | term()}
  def upsert_discount_mapping(code, attrs) when is_binary(code) and is_map(attrs) do
    normalized_code = normalize_code(code)

    Repo.transact(fn ->
      attrs =
        attrs
        |> Map.new()
        |> Map.put(:processor, @processor)
        |> Map.put(:code, normalized_code)

      case Repo.get_by(DiscountMapping, processor: @processor, code: normalized_code) do
        nil ->
          %DiscountMapping{}
          |> DiscountMapping.changeset(attrs)
          |> Repo.insert()

        %DiscountMapping{} = mapping ->
          mapping
          |> DiscountMapping.changeset(attrs)
          |> Repo.update()
      end
    end)
  end

  @spec upsert_discount_mapping!(String.t(), map()) :: DiscountMapping.t()
  def upsert_discount_mapping!(code, attrs) when is_binary(code) and is_map(attrs) do
    case upsert_discount_mapping(code, attrs) do
      {:ok, mapping} -> mapping
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "upsert_discount_mapping!/2 failed: #{inspect(other)}"
    end
  end

  @spec get_discount_mapping(String.t(), keyword()) ::
          {:ok, DiscountMapping.t()} | {:error, :not_found}
  def get_discount_mapping(code, opts \\ []) when is_binary(code) and is_list(opts) do
    _ = opts

    case Repo.get_by(DiscountMapping, processor: @processor, code: normalize_code(code)) do
      %DiscountMapping{} = mapping -> {:ok, mapping}
      nil -> {:error, :not_found}
    end
  end

  @spec resolve_discount_mapping(String.t(), non_neg_integer(), keyword()) ::
          {:ok,
           %{
             mapping: DiscountMapping.t(),
             amount_off_minor: non_neg_integer(),
             estimated_total_minor: non_neg_integer()
           }}
          | {:error, resolve_error()}
  def resolve_discount_mapping(code, checkout_amount_minor, opts \\ [])
      when is_binary(code) and is_integer(checkout_amount_minor) and checkout_amount_minor >= 0 and
             is_list(opts) do
    _ = opts

    with {:ok, mapping} <- fetch_applicable_mapping(code),
         :ok <- validate_mapping_for_resolution(mapping) do
      amount_off_minor = min(mapping.amount_off_minor, checkout_amount_minor)

      {:ok,
       %{
         mapping: mapping,
         amount_off_minor: amount_off_minor,
         estimated_total_minor: max(checkout_amount_minor - amount_off_minor, 0)
       }}
    end
  end

  @spec record_discount_mapping_redemption(String.t() | DiscountMapping.t(), keyword()) ::
          {:ok, DiscountMapping.t()} | {:error, :not_found | :max_redemptions_reached | term()}
  def record_discount_mapping_redemption(mapping_or_code, opts \\ [])

  def record_discount_mapping_redemption(%DiscountMapping{} = mapping, opts) when is_list(opts) do
    _ = opts

    Repo.transact(fn ->
      mapping =
        from(m in DiscountMapping, where: m.id == ^mapping.id)
        |> Repo.one()

      case mapping do
        nil ->
          {:error, :not_found}

        %DiscountMapping{} = fresh_mapping ->
          with :ok <- ensure_redemption_capacity(fresh_mapping) do
            fresh_mapping
            |> DiscountMapping.changeset(%{
              times_redeemed: fresh_mapping.times_redeemed + 1
            })
            |> Repo.update()
          end
      end
    end)
  end

  def record_discount_mapping_redemption(code, opts) when is_binary(code) and is_list(opts) do
    with {:ok, mapping} <- get_discount_mapping(code, opts) do
      record_discount_mapping_redemption(mapping, opts)
    end
  end

  defp fetch_applicable_mapping(code) do
    now = Accrue.Clock.utc_now()

    case Repo.get_by(DiscountMapping, processor: @processor, code: normalize_code(code)) do
      nil ->
        {:error, :not_found}

      %DiscountMapping{active: false} ->
        {:error, :inactive}

      %DiscountMapping{} = mapping ->
        with :ok <- ensure_not_expired(mapping, now),
             :ok <- ensure_redemption_capacity(mapping) do
          {:ok, mapping}
        end
    end
  end

  defp ensure_not_expired(%DiscountMapping{expires_at: %DateTime{} = expires_at}, now) do
    if DateTime.compare(expires_at, now) == :lt, do: {:error, :expired}, else: :ok
  end

  defp ensure_not_expired(%DiscountMapping{}, _now), do: :ok

  defp ensure_redemption_capacity(%DiscountMapping{
         max_redemptions: max,
         times_redeemed: redeemed
       })
       when is_integer(max) and redeemed >= max do
    {:error, :max_redemptions_reached}
  end

  defp ensure_redemption_capacity(%DiscountMapping{}), do: :ok

  defp validate_mapping_for_resolution(%DiscountMapping{} = mapping) do
    cond do
      not is_binary(mapping.discount_id) or String.trim(mapping.discount_id) == "" ->
        {:error, invalid_mapping(mapping, :discount_id_missing)}

      not is_integer(mapping.amount_off_minor) or mapping.amount_off_minor < 0 ->
        {:error, invalid_mapping(mapping, :amount_off_minor_invalid)}

      not is_binary(mapping.currency) or String.trim(mapping.currency) == "" ->
        {:error, invalid_mapping(mapping, :currency_missing)}

      true ->
        :ok
    end
  end

  defp invalid_mapping(%DiscountMapping{} = mapping, reason) do
    %DiscountMappingInvalid{
      mapping_id: mapping.id,
      code: mapping.code,
      discount_id: mapping.discount_id,
      reason: reason
    }
  end

  defp normalize_code(code) do
    code
    |> String.trim()
    |> String.upcase()
  end
end
