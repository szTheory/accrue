defmodule AccrueAdmin.Queries.Behaviour do
  @moduledoc """
  Shared contract and helpers for admin list queries.
  """

  import Ecto.Query

  alias AccrueAdmin.Queries.Cursor

  @type row :: map()
  @type filter :: map()
  @type opts :: keyword()

  @callback list(opts()) :: {[row()], binary() | nil}
  @callback count_newer_than(opts()) :: non_neg_integer()
  @callback decode_filter(map()) :: filter()
  @callback encode_filter(filter()) :: map()

  @default_limit 50
  @max_limit 100

  @spec normalize_limit(keyword()) :: pos_integer()
  def normalize_limit(opts) do
    opts
    |> Keyword.get(:limit, @default_limit)
    |> case do
      limit when is_integer(limit) and limit > 0 -> min(limit, @max_limit)
      _ -> @default_limit
    end
  end

  @spec decode_cursor(keyword()) :: Cursor.value() | nil
  def decode_cursor(opts) do
    opts
    |> Keyword.get(:cursor)
    |> Cursor.decode()
    |> case do
      {:ok, value} -> value
      :error -> nil
    end
  end

  @spec apply_cursor(Ecto.Queryable.t(), atom(), Cursor.value() | nil) :: Ecto.Query.t()
  def apply_cursor(query, _field, nil), do: from(row in query)

  def apply_cursor(query, field, {%DateTime{} = timestamp, id}) do
    from(row in query,
      where:
        field(row, ^field) < ^timestamp or
          (field(row, ^field) == ^timestamp and row.id < ^id)
    )
  end

  @spec count_newer(Ecto.Queryable.t(), atom(), Cursor.value() | nil) :: Ecto.Query.t()
  def count_newer(query, _field, nil), do: from(row in query, where: false)

  def count_newer(query, field, {%DateTime{} = timestamp, id}) do
    from(row in query,
      where:
        field(row, ^field) > ^timestamp or
          (field(row, ^field) == ^timestamp and row.id > ^id)
    )
  end

  @spec paginate([map()], pos_integer(), atom()) :: {[map()], binary() | nil}
  def paginate(rows, limit, field) do
    {page_rows, next_row} = Enum.split(rows, limit)

    next_cursor =
      case next_row do
        [row | _rest] -> Cursor.encode(Map.fetch!(row, field), Map.fetch!(row, :id))
        [] -> nil
      end

    {page_rows, next_cursor}
  end

  @spec parse_boolean(term()) :: boolean() | nil
  def parse_boolean(value)

  def parse_boolean(value) when value in [true, "true", "1", 1], do: true
  def parse_boolean(value) when value in [false, "false", "0", 0], do: false
  def parse_boolean(_value), do: nil

  @spec normalize_string(term()) :: binary() | nil
  def normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  def normalize_string(_value), do: nil

  @spec compact_filter(map()) :: map()
  def compact_filter(filter) when is_map(filter) do
    Map.reject(filter, fn
      {_key, nil} -> true
      {_key, ""} -> true
      _ -> false
    end)
  end
end
