defmodule Accrue.Test.PdfAssertions do
  @moduledoc """
  ExUnit-style assertions for `Accrue.PDF.Test` render captures (D-34).
  Symmetric with `Accrue.Test.MailerAssertions`.

  ## Usage

      use Accrue.Test.PdfAssertions
      # or
      import Accrue.Test.PdfAssertions

  ## Matching

  - `:invoice_id` -> `opts[:invoice_id] || opts["invoice_id"]`
  - `:contains` (string) -> `String.contains?(html, value)`
  - `:matches` (1-arity fn) -> predicate escape hatch on normalized render data
  - `:opts_include` (keyword) -> subset match on the opts keyword list

  All helpers consume `{:pdf_rendered, html, opts}` tuples sent by
  `Accrue.PDF.Test.render/2`. Messages are process-local; `async: true`
  is safe. Cross-process owner or global capture modes are intentionally
  not the default; if a host test needs them, name that mode explicitly
  and treat it with the same caution as Mox or Swoosh global mode.
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
      observed = Accrue.Test.PdfAssertions.__collect_pdfs__(t)

      case Enum.find(observed, fn {html, opts} ->
             Accrue.Test.PdfAssertions.__match__(html, opts, matchers)
           end) do
        {html, opts} ->
          {html, opts}

        nil ->
          ExUnit.Assertions.flunk(
            "no PDF rendered within #{t}ms and did not match #{inspect(matchers)}; " <>
              "Observed PDFs: #{inspect(Accrue.Test.PdfAssertions.__summaries__(observed))}"
          )
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
      observed = Accrue.Test.PdfAssertions.__collect_pdfs__(t)

      case Enum.find(observed, fn {html, opts} ->
             Accrue.Test.PdfAssertions.__match__(html, opts, matchers)
           end) do
        {_html, _opts} ->
          ExUnit.Assertions.flunk(
            "unexpected PDF rendered matching #{inspect(matchers)}; " <>
              "Observed PDFs: #{inspect(Accrue.Test.PdfAssertions.__summaries__(observed))}"
          )

        nil ->
          :ok
      end
    end
  end

  @doc false
  def __match__(html, opts, matchers) do
    render = %{html: html, opts: opts, invoice_id: opts_value(opts, :invoice_id)}

    Enum.all?(normalize_matcher(matchers), fn
      {:invoice_id, value} ->
        render.invoice_id == value

      {:contains, value} when is_binary(value) ->
        String.contains?(html, value)

      {:matches, fun} when is_function(fun, 1) ->
        predicate_match?(fun, render, html)

      {:opts_include, kw} when is_list(kw) ->
        Enum.all?(kw, fn {key, value} -> opts_value(opts, key) == value end)

      {key, value} ->
        opts_value(opts, key) == value
    end)
  end

  @doc false
  def __collect_pdfs__(timeout), do: collect_pdfs([], timeout)

  @doc false
  def __summaries__(observed) do
    Enum.map(observed, fn {html, opts} ->
      %{
        invoice_id: opts_value(opts, :invoice_id),
        html_preview: String.slice(html, 0, 80),
        opts_keys: opts_keys(opts)
      }
    end)
  end

  defp collect_pdfs(acc, timeout) do
    receive do
      {:pdf_rendered, html, opts} -> collect_pdfs([{html, opts} | acc], 0)
    after
      timeout -> Enum.reverse(acc)
    end
  end

  defp normalize_matcher(matchers) when is_list(matchers), do: matchers
  defp normalize_matcher(matchers) when is_map(matchers), do: Map.to_list(matchers)
  defp normalize_matcher(matchers) when is_function(matchers, 1), do: [matches: matchers]
  defp normalize_matcher(nil), do: []

  defp opts_value(opts, key) when is_list(opts) do
    keyword_value = if is_atom(key), do: Keyword.get(opts, key)
    keyword_value || list_string_value(opts, key)
  end

  defp opts_value(opts, key) when is_map(opts),
    do: Map.get(opts, key, Map.get(opts, to_string(key)))

  defp opts_value(_opts, _key), do: nil

  defp opts_keys(opts) when is_list(opts), do: Keyword.keys(opts)
  defp opts_keys(opts) when is_map(opts), do: Map.keys(opts)
  defp opts_keys(_opts), do: []

  defp list_string_value(opts, key) do
    string_key = to_string(key)

    Enum.find_value(opts, fn
      {^string_key, value} -> value
      _other -> nil
    end)
  end

  defp predicate_match?(fun, preferred, fallback) do
    fun.(preferred)
  rescue
    _ -> fun.(fallback)
  end
end
