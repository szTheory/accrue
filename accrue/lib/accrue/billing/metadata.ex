defmodule Accrue.Billing.Metadata do
  @moduledoc """
  Stripe-compatible metadata validation and merge helpers.

  Metadata in Accrue follows the exact Stripe metadata contract:

    - Flat `%{String.t() => String.t()}` map (no nested maps)
    - Maximum 50 keys
    - Key length: max 40 characters
    - Value length: max 500 characters
    - `""` or `nil` value means "delete this key" on update

  ## Merge semantics

  `shallow_merge/2` merges new keys into existing metadata. Keys whose
  value is `""` or `nil` are removed from the result. No deep merge is
  supported (D2-10).
  """

  import Ecto.Changeset

  @max_keys 50
  @max_key_length 40
  @max_value_length 500

  @doc """
  Validates a metadata field on the given changeset.

  Checks that the value is a flat string-key/string-value map within
  Stripe-compatible constraints. Returns the changeset with errors added
  if validation fails.
  """
  @spec validate_metadata(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_metadata(%Ecto.Changeset{} = changeset, field) when is_atom(field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      metadata when is_map(metadata) ->
        changeset
        |> validate_flat_map(field, metadata)
        |> validate_key_count(field, metadata)
        |> validate_key_lengths(field, metadata)
        |> validate_value_lengths(field, metadata)

      _other ->
        add_error(changeset, field, "must be a map")
    end
  end

  @doc """
  Shallow-merges `new_metadata` into `existing_metadata`.

  Keys with `""` or `nil` values in `new_metadata` are deleted from
  the result. All other keys are set or overwritten.

  ## Examples

      iex> Accrue.Billing.Metadata.shallow_merge(%{"a" => "1"}, %{"b" => "2"})
      %{"a" => "1", "b" => "2"}

      iex> Accrue.Billing.Metadata.shallow_merge(%{"a" => "1", "b" => "2"}, %{"a" => ""})
      %{"b" => "2"}

      iex> Accrue.Billing.Metadata.shallow_merge(%{"a" => "1"}, %{"a" => nil})
      %{}
  """
  @spec shallow_merge(map(), map()) :: map()
  def shallow_merge(existing, new) when is_map(existing) and is_map(new) do
    Enum.reduce(new, existing, fn {key, value}, acc ->
      if value in ["", nil] do
        Map.delete(acc, key)
      else
        Map.put(acc, key, value)
      end
    end)
  end

  # --- Private validation helpers ---

  defp validate_flat_map(changeset, field, metadata) do
    has_nested =
      Enum.any?(metadata, fn
        {_key, value} when is_map(value) -> true
        {key, _value} when not is_binary(key) -> true
        {_key, value} when not is_binary(value) and not is_nil(value) -> true
        _ -> false
      end)

    if has_nested do
      add_error(
        changeset,
        field,
        "must be a flat map with string keys and string values (no nested maps)"
      )
    else
      changeset
    end
  end

  defp validate_key_count(changeset, field, metadata) do
    if map_size(metadata) > @max_keys do
      add_error(changeset, field, "must have at most #{@max_keys} keys",
        count: @max_keys,
        validation: :metadata_key_count
      )
    else
      changeset
    end
  end

  defp validate_key_lengths(changeset, field, metadata) do
    long_keys =
      metadata
      |> Map.keys()
      |> Enum.filter(&(is_binary(&1) and String.length(&1) > @max_key_length))

    if long_keys != [] do
      add_error(
        changeset,
        field,
        "keys must be at most #{@max_key_length} characters (violations: #{inspect(long_keys)})",
        validation: :metadata_key_length
      )
    else
      changeset
    end
  end

  defp validate_value_lengths(changeset, field, metadata) do
    long_values =
      metadata
      |> Enum.filter(fn {_key, value} ->
        is_binary(value) and String.length(value) > @max_value_length
      end)
      |> Enum.map(fn {key, _} -> key end)

    if long_values != [] do
      add_error(
        changeset,
        field,
        "values must be at most #{@max_value_length} characters (violations: #{inspect(long_values)})",
        validation: :metadata_value_length
      )
    else
      changeset
    end
  end
end
