defmodule Accrue.Test.PdfAssertions do
  @moduledoc """
  ExUnit-style assertions for `Accrue.PDF.Test` render captures (D-34).
  Symmetric with `Accrue.Test.MailerAssertions`.

  ## Usage

      use Accrue.Test.PdfAssertions
      # or
      import Accrue.Test.PdfAssertions

  ## Matching

  - `:contains` (string) → `String.contains?(html, value)`
  - `:matches` (1-arity fn) → predicate escape hatch on html
  - `:opts_include` (keyword) → subset match on the opts keyword list

  All helpers consume `{:pdf_rendered, html, opts}` tuples sent by
  `Accrue.PDF.Test.render/2`. Messages are process-local; `async: true`
  is safe.
  """

  defmacro __using__(_opts) do
    quote do
      import Accrue.Test.PdfAssertions
    end
  end

  @doc """
  Asserts that a PDF was rendered (via `Accrue.PDF.Test`) matching the
  given `matchers`. Flunks if no matching message is received within
  `timeout` (default 100ms).
  """
  defmacro assert_pdf_rendered(matchers \\ [], timeout \\ 100) do
    quote do
      matchers = unquote(matchers)
      t = unquote(timeout)

      receive do
        {:pdf_rendered, html, opts} ->
          unless Accrue.Test.PdfAssertions.__match__(html, opts, matchers) do
            ExUnit.Assertions.flunk(
              "PDF was rendered but did not match opts #{inspect(matchers)}; " <>
                "got html=#{inspect(String.slice(html, 0, 80))} opts=#{inspect(opts)}"
            )
          end

          {html, opts}
      after
        t ->
          ExUnit.Assertions.flunk("no PDF rendered within #{t}ms")
      end
    end
  end

  @doc """
  Refutes that a PDF render matching `matchers` occurred within `timeout`
  (default 100ms). Non-matching render messages are ignored.
  """
  defmacro refute_pdf_rendered(matchers \\ [], timeout \\ 100) do
    quote do
      matchers = unquote(matchers)
      t = unquote(timeout)

      receive do
        {:pdf_rendered, html, opts} ->
          if Accrue.Test.PdfAssertions.__match__(html, opts, matchers) do
            ExUnit.Assertions.flunk(
              "unexpected PDF rendered matching #{inspect(matchers)}; " <>
                "html=#{inspect(String.slice(html, 0, 80))} opts=#{inspect(opts)}"
            )
          end

          :ok
      after
        t -> :ok
      end
    end
  end

  @doc false
  def __match__(html, opts, matchers) do
    Enum.all?(matchers, fn
      {:contains, v} when is_binary(v) ->
        String.contains?(html, v)

      {:matches, fun} when is_function(fun, 1) ->
        fun.(html)

      {:opts_include, kw} when is_list(kw) ->
        Enum.all?(kw, fn {k, v} -> Keyword.get(opts, k) == v end)

      _other ->
        true
    end)
  end
end
