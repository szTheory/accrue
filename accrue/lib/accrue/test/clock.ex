defmodule Accrue.Test.Clock do
  @moduledoc """
  Deterministic clock helpers for host tests.

  The helper drives `Accrue.Processor.Fake` directly and never sleeps.
  """

  @type duration ::
          binary()
          | integer()
          | [
              months: integer(),
              days: integer(),
              hours: integer(),
              minutes: integer(),
              seconds: integer()
            ]

  @doc """
  Advances the Fake test clock by a readable, keyword, or integer duration.

  If `subject` carries a `processor_id` or `stripe_id`, the subscription-aware
  Fake clock API is used so trial and renewal lifecycle effects can fire.
  """
  @spec advance(term(), duration()) :: {:ok, term()} | {:error, term()}
  def advance(subject, duration)

  def advance(duration, opts)
      when (is_binary(duration) or is_integer(duration) or is_list(duration)) and is_list(opts) do
    do_advance(nil, duration, opts)
  end

  def advance(subject, duration) do
    do_advance(subject, duration, [])
  end

  @doc false
  def advance_clock(subject, duration), do: advance(subject, duration)

  defp do_advance(subject, duration, opts) do
    with {:ok, parts} <- normalize_duration(duration) do
      processor = Keyword.get(opts, :processor, Accrue.Processor.Fake)
      seconds = seconds_from_parts(parts)

      result =
        case subject_processor_id(subject) do
          nil ->
            processor.advance(processor, seconds)

          processor_id ->
            processor.advance_subscription(processor_id, seconds: seconds)
        end

      case result do
        :ok -> {:ok, %{advanced_by: seconds, clock: processor.now()}}
        {:ok, _} = ok -> ok
        {:error, _} = error -> error
        other -> {:ok, other}
      end
    end
  rescue
    error -> {:error, error}
  end

  defp normalize_duration(seconds) when is_integer(seconds) and seconds >= 0 do
    {:ok, [seconds: seconds]}
  end

  defp normalize_duration(parts) when is_list(parts) do
    allowed = [:months, :days, :hours, :minutes, :seconds]

    if Keyword.keyword?(parts) and
         Enum.all?(parts, fn {key, value} -> key in allowed and valid_count?(value) end) do
      {:ok, parts}
    else
      {:error, {:invalid_duration, parts}}
    end
  end

  defp normalize_duration(duration) when is_binary(duration) do
    case Regex.run(
           ~r/^\s*(\d+)\s+(month|months|day|days|hour|hours|minute|minutes|second|seconds)\s*$/,
           duration
         ) do
      [_match, count, unit] ->
        count = String.to_integer(count)
        key = unit_to_key(unit)
        {:ok, [{key, count}]}

      _ ->
        {:error, {:invalid_duration, duration}}
    end
  end

  defp normalize_duration(duration), do: {:error, {:invalid_duration, duration}}

  defp valid_count?(value), do: is_integer(value) and value >= 0

  defp unit_to_key(unit) when unit in ["month", "months"], do: :months
  defp unit_to_key(unit) when unit in ["day", "days"], do: :days
  defp unit_to_key(unit) when unit in ["hour", "hours"], do: :hours
  defp unit_to_key(unit) when unit in ["minute", "minutes"], do: :minutes
  defp unit_to_key(unit) when unit in ["second", "seconds"], do: :seconds

  defp seconds_from_parts(parts) do
    Keyword.get(parts, :seconds, 0) +
      Keyword.get(parts, :minutes, 0) * 60 +
      Keyword.get(parts, :hours, 0) * 3_600 +
      Keyword.get(parts, :days, 0) * 86_400 +
      Keyword.get(parts, :months, 0) * 30 * 86_400
  end

  defp subject_processor_id(nil), do: nil

  defp subject_processor_id(subject) when is_map(subject) do
    Map.get(subject, :processor_id) ||
      Map.get(subject, "processor_id") ||
      Map.get(subject, :stripe_id) ||
      Map.get(subject, "stripe_id")
  end

  defp subject_processor_id(subject) do
    cond do
      function_exported?(subject.__struct__, :__schema__, 1) ->
        Map.get(subject, :processor_id) || Map.get(subject, :stripe_id)

      true ->
        nil
    end
  rescue
    _ -> nil
  end
end
