defmodule Accrue.PDF.Null do
  @moduledoc """
  Null `Accrue.PDF` adapter for Chrome-hostile deploys (D6-06).

  Returns `{:error, %Accrue.Error.PdfDisabled{}}` without raising.
  Invoice email workers pattern-match on this tagged error and fall
  through to including the Stripe `hosted_invoice_url` as a link
  instead of attaching a rendered PDF binary — graceful degradation
  satisfies Phase 6 SC #4.

  Log level is fixed at `:debug` (locked by D6-06) — this is an
  expected, configuration-driven branch, not an error or warning
  condition.
  """

  @behaviour Accrue.PDF

  require Logger

  @impl true
  def render(_html, _opts) do
    Logger.debug("Accrue.PDF.Null: skipping PDF render (adapter disabled)")

    {:error,
     %Accrue.Error.PdfDisabled{
       reason: :adapter_disabled,
       docs_url: "https://hexdocs.pm/accrue/pdf.html#null-adapter"
     }}
  end
end
