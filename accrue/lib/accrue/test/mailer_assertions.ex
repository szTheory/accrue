defmodule Accrue.Test.MailerAssertions do
  @moduledoc """
  ExUnit-style assertions for `Accrue.Mailer.Test` intent captures
  (D6-05). Symmetric with `Accrue.Test.PdfAssertions`.

  ## Usage

      use Accrue.Test.MailerAssertions
      # or
      import Accrue.Test.MailerAssertions

  ## Matching

  - `:type` -> email intent type, also accepted as the first argument
  - `:to` -> `assigns[:to] || assigns["to"]`
  - `:customer_id` -> `assigns[:customer_id] || assigns["customer_id"]`
  - `:assigns` -> subset match on the provided assign keys
  - `:matches` -> 1-arity predicate escape hatch on `%{type:, assigns:}`

  All helpers consume `{:accrue_email_delivered, type, assigns}` tuples
  sent by `Accrue.Mailer.Test.deliver/2`. Messages are process-local
  (no cross-test leakage), so `async: true` is safe. Cross-process owner
  or global capture modes are intentionally not the default; if a host
  test needs them, name that mode explicitly and treat it with the same
  caution as Mox or Swoosh global mode.
  """

  import ExUnit.Assertions

  defmacro __using__(_opts) do
    quote do
      import Accrue.Test.MailerAssertions
    end
  end

  @doc """
  Asserts that an email matching `type_or_matcher` and `opts` was delivered
  through `Accrue.Mailer.Test`.
  """
  defmacro assert_email_sent(type_or_matcher, opts \\ [], timeout \\ 100) do
    quote do
      matcher = Accrue.Test.MailerAssertions.__matcher__(unquote(type_or_matcher), unquote(opts))
      t = unquote(timeout)
      observed = Accrue.Test.MailerAssertions.__collect_emails__(t)

      case Enum.find(observed, &Accrue.Test.MailerAssertions.__match__(&1, matcher)) do
        {_type, assigns} ->
          assigns

        nil ->
          ExUnit.Assertions.flunk(
            Accrue.Test.MailerAssertions.__failure_message__(matcher, observed, t)
          )
      end
    end
  end

  @doc """
  Refutes that an email matching `type_or_matcher` and `opts` was delivered
  within `timeout` (default 100ms).
  """
  defmacro refute_email_sent(type_or_matcher, opts \\ [], timeout \\ 100) do
    quote do
      matcher = Accrue.Test.MailerAssertions.__matcher__(unquote(type_or_matcher), unquote(opts))
      t = unquote(timeout)
      observed = Accrue.Test.MailerAssertions.__collect_emails__(t)

      case Enum.find(observed, &Accrue.Test.MailerAssertions.__match__(&1, matcher)) do
        {type, assigns} ->
          ExUnit.Assertions.flunk(
            "unexpected email of type #{inspect(type)} delivered matching #{inspect(matcher)}; " <>
              "Observed emails: #{inspect(Accrue.Test.MailerAssertions.__summaries__(observed))}; " <>
              "assign keys=#{inspect(Map.keys(assigns))}"
          )

        nil ->
          :ok
      end
    end
  end

  @doc """
  Asserts that no `:accrue_email_delivered` messages are in the mailbox.
  Drains any pending message and flunks on the first one found.
  """
  def assert_no_emails_sent do
    case drain_any_email() do
      {:ok, nil} -> :ok
      {:ok, msg} -> flunk("unexpected email delivered: #{inspect(msg)}")
    end
  end

  @doc """
  Asserts exactly `expected_count` emails are delivered within the
  100ms window. Flunks with the actual count on mismatch.
  """
  def assert_emails_sent(expected_count)
      when is_integer(expected_count) and expected_count >= 0 do
    actual = count_emails(expected_count + 1, 100)

    unless actual == expected_count do
      flunk("expected #{expected_count} emails delivered, got #{actual}")
    end

    :ok
  end

  @doc false
  def __matcher__(type, opts) when is_atom(type) or is_binary(type) do
    opts
    |> normalize_matcher()
    |> Keyword.put_new(:type, type)
  end

  def __matcher__(matcher, []) when is_function(matcher, 1), do: [matches: matcher]
  def __matcher__(matcher, []), do: normalize_matcher(matcher)

  def __matcher__(matcher, opts) do
    matcher
    |> normalize_matcher()
    |> Keyword.merge(normalize_matcher(opts))
  end

  @doc false
  def __match__({type, assigns}, matcher) do
    Enum.all?(normalize_matcher(matcher), fn
      {:type, value} ->
        type == value or to_string(type) == to_string(value)

      {:to, value} ->
        map_value(assigns, :to) == value

      {:customer_id, value} ->
        map_value(assigns, :customer_id) == value

      {:assigns, expected} when is_map(expected) ->
        partial_map_match?(assigns, expected)

      {:matches, fun} when is_function(fun, 1) ->
        predicate_match?(fun, %{type: type, assigns: assigns}, assigns)

      {key, value} ->
        map_value(assigns, key) == value
    end)
  end

  def __match__(assigns, opts) when is_map(assigns) do
    __match__({Keyword.get(normalize_matcher(opts), :type), assigns}, opts)
  end

  @doc false
  def __collect_emails__(timeout), do: collect_emails([], timeout)

  @doc false
  def __failure_message__(matcher, observed, timeout) do
    matcher = normalize_matcher(matcher)
    type = Keyword.get(matcher, :type)

    prefix =
      if type do
        "no email of type #{inspect(type)} delivered within #{timeout}ms"
      else
        "no email delivered within #{timeout}ms"
      end

    prefix <>
      " and did not match #{inspect(matcher)}; Observed emails: #{inspect(__summaries__(observed))}"
  end

  @doc false
  def __summaries__(observed) do
    Enum.map(observed, fn {type, assigns} ->
      %{
        type: type,
        customer_id: map_value(assigns, :customer_id),
        assign_keys: Map.keys(assigns)
      }
    end)
  end

  defp drain_any_email do
    receive do
      {:accrue_email_delivered, _, _} = msg -> {:ok, msg}
    after
      0 -> {:ok, nil}
    end
  end

  defp count_emails(limit, timeout) do
    count_emails_loop(0, limit, timeout)
  end

  defp count_emails_loop(count, limit, _timeout) when count >= limit, do: count

  defp count_emails_loop(count, limit, timeout) do
    receive do
      {:accrue_email_delivered, _, _} -> count_emails_loop(count + 1, limit, timeout)
    after
      timeout -> count
    end
  end

  defp collect_emails(acc, timeout) do
    receive do
      {:accrue_email_delivered, type, assigns} -> collect_emails([{type, assigns} | acc], 0)
    after
      timeout -> Enum.reverse(acc)
    end
  end

  defp normalize_matcher(matcher) when is_list(matcher), do: matcher
  defp normalize_matcher(matcher) when is_map(matcher), do: Map.to_list(matcher)
  defp normalize_matcher(matcher) when is_function(matcher, 1), do: [matches: matcher]
  defp normalize_matcher(nil), do: []
  defp normalize_matcher(matcher), do: [type: matcher]

  defp partial_map_match?(actual, expected) do
    Enum.all?(expected, fn {key, value} -> map_value(actual, key) == value end)
  end

  defp map_value(map, key), do: Map.get(map, key, Map.get(map, to_string(key)))

  defp predicate_match?(fun, preferred, fallback) do
    fun.(preferred)
  rescue
    _ -> fun.(fallback)
  end
end
