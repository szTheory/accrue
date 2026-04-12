defmodule Accrue.PDF.Test do
  @moduledoc """
  Chrome-free `Accrue.PDF` adapter for test environments (D-34).

  `render/2` sends `{:pdf_rendered, html, opts}` to `self()` so the
  calling test can `assert_received` on the render attempt, and returns
  `{:ok, "%PDF-TEST"}`. This lets Phase 1 tests exercise the full PDF
  plumbing without requiring a Chrome binary on CI runners.
  """

  @behaviour Accrue.PDF

  @impl true
  def render(html, opts) when is_binary(html) and is_list(opts) do
    send(self(), {:pdf_rendered, html, opts})
    {:ok, "%PDF-TEST"}
  end
end
