defmodule Accrue.PDF.ChromicPDF do
  @moduledoc """
  ChromicPDF adapter for `Accrue.PDF` (D-32, D-33).

  ## CRITICAL: Accrue does NOT start ChromicPDF (D-33, Pitfall #4)

  This adapter ONLY calls into a ChromicPDF instance that the **host
  application** has started in its own supervision tree. Neither this
  module nor `Accrue.Application` (Plan 06) adds ChromicPDF to any
  supervisor — doing so would fight with the host's config and make the
  Chrome pool impossible to tune per-environment.

  ### Recommended host wiring

      # Dev / test
      children = [
        {ChromicPDF, on_demand: true}
      ]

      # Prod
      children = [
        {ChromicPDF, session_pool: [size: 5]}
      ]

  Consult the `ChromicPDF` README for the full option set.

  ## Opts translation (RESEARCH Summary point 5)

  The `Accrue.PDF` facade accepts `:header_html` / `:footer_html` (readable
  English names). This adapter translates them to the `:header` / `:footer`
  keys that `ChromicPDF.Template.source_and_options/1` actually wants. If
  `:archival` is `true`, we route to `ChromicPDF.print_to_pdfa/1` instead
  of `print_to_pdf/1`.
  """

  @behaviour Accrue.PDF

  @impl true
  def render(html, opts) when is_binary(html) and is_list(opts) do
    chromic_opts = translate_opts(html, opts)
    source = ChromicPDF.Template.source_and_options(chromic_opts)

    if opts[:archival] do
      ChromicPDF.print_to_pdfa(source)
    else
      ChromicPDF.print_to_pdf(source)
    end
  rescue
    e -> {:error, e}
  end

  defp translate_opts(html, opts) do
    [
      content: html,
      size: opts[:size] || :a4
    ]
    |> maybe_put(:header, opts[:header_html])
    |> maybe_put(:footer, opts[:footer_html])
    |> maybe_put(:header_height, opts[:header_height])
    |> maybe_put(:footer_height, opts[:footer_height])
  end

  defp maybe_put(list, _key, nil), do: list
  defp maybe_put(list, key, val), do: Keyword.put(list, key, val)
end
