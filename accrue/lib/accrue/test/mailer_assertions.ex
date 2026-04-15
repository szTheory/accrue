defmodule Accrue.Test.MailerAssertions do
  @moduledoc """
  ExUnit-style assertions for `Accrue.Mailer.Test` intent captures
  (D6-05). Symmetric with `Accrue.Test.PdfAssertions`.

  ## Usage

      use Accrue.Test.MailerAssertions
      # or
      import Accrue.Test.MailerAssertions

  ## Matching

  - `:to` → `assigns[:to] || assigns["to"]`
  - `:customer_id` → `assigns[:customer_id]`
  - `:assigns` → subset match via `Map.take(assigns, Map.keys(expected)) == expected`
  - `:matches` → 1-arity predicate escape hatch

  All helpers consume `{:accrue_email_delivered, type, assigns}` tuples
  sent by `Accrue.Mailer.Test.deliver/2`. Messages are process-local
  (no cross-test leakage) — `async: true` is safe.
  """

  import ExUnit.Assertions

  defmacro __using__(_opts) do
    quote do
      import Accrue.Test.MailerAssertions
    end
  end

  @doc """
  Asserts that an email of `type` was delivered (via `Accrue.Mailer.Test`)
  matching the given `opts`. Flunks if no matching message is received
  within `timeout` (default 100ms).
  """
  defmacro assert_email_sent(type, opts \\ [], timeout \\ 100) do
    quote do
      expected_type = unquote(type)
      matchers = unquote(opts)
      t = unquote(timeout)

      receive do
        {:accrue_email_delivered, ^expected_type, assigns} ->
          unless Accrue.Test.MailerAssertions.__match__(assigns, matchers) do
            ExUnit.Assertions.flunk(
              "email of type #{inspect(expected_type)} delivered but did not match " <>
                "opts #{inspect(matchers)}; got assigns #{inspect(assigns)}"
            )
          end

          assigns
      after
        t ->
          ExUnit.Assertions.flunk(
            "no email of type #{inspect(expected_type)} delivered within #{t}ms"
          )
      end
    end
  end

  @doc """
  Refutes that an email of `type` matching `opts` was delivered within
  `timeout` (default 100ms). Non-matching messages of the same type are
  ignored (allowed).
  """
  defmacro refute_email_sent(type, opts \\ [], timeout \\ 100) do
    quote do
      expected_type = unquote(type)
      matchers = unquote(opts)
      t = unquote(timeout)

      receive do
        {:accrue_email_delivered, ^expected_type, assigns} ->
          if Accrue.Test.MailerAssertions.__match__(assigns, matchers) do
            ExUnit.Assertions.flunk(
              "unexpected email of type #{inspect(expected_type)} delivered with assigns #{inspect(assigns)}"
            )
          end

          :ok
      after
        t -> :ok
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
  def __match__(assigns, opts) do
    Enum.all?(opts, fn
      {:to, v} ->
        (Map.get(assigns, :to) || Map.get(assigns, "to")) == v

      {:customer_id, v} ->
        Map.get(assigns, :customer_id) == v

      {:assigns, expected} when is_map(expected) ->
        Map.take(assigns, Map.keys(expected)) == expected

      {:matches, fun} when is_function(fun, 1) ->
        fun.(assigns)

      _other ->
        true
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
end
