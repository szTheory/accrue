defmodule Accrue.Invoices.Styles do
  @moduledoc """
  Static branding-aware inline-CSS lookup used by
  `Accrue.Invoices.Components` to stamp `style="..."` attributes on every
  structural element.

  ## Why inline, not classname-driven?

  MJML's post-render CSS inliner does NOT descend into `<mj-raw>` blocks
  (D6-01 Pitfall 2). Components rendered via `Accrue.Emails.HtmlBridge`
  into an `<mj-raw>` therefore cannot rely on classname selectors — every
  structural element must carry its styling inline, and every inline
  style must be derived from the frozen branding snapshot in the render
  context.

  The second parameter is always the `branding` keyword list — a direct
  slice of `ctx.branding`. Callers must NEVER re-read
  `Accrue.Config.branding/0` inside component code; pass the frozen
  snapshot through.
  """

  @type key ::
          :table_reset
          | :logo_cell
          | :number_cell
          | :line_items
          | :line_row
          | :th
          | :td
          | :td_num
          | :totals
          | :totals_row
          | :totals_label
          | :totals_value
          | :footer
          | :footer_line
          | :cta_button
          | :heading
          | :body

  @doc """
  Returns an inline CSS string for the given style key and frozen
  branding snapshot. Always returns a binary — never nil.
  """
  @spec for(key(), keyword()) :: String.t()
  def for(key, branding) when is_list(branding) do
    accent = to_string(Keyword.get(branding, :accent_color, "#3B82F6"))
    secondary = to_string(Keyword.get(branding, :secondary_color, "#6B7280"))
    font_stack = to_string(Keyword.get(branding, :font_stack, "Helvetica, Arial, sans-serif"))

    do_for(key, accent, secondary, font_stack)
  end

  defp do_for(:table_reset, _accent, _secondary, font_stack) do
    "border-collapse: collapse; width: 100%; font-family: #{font_stack}; color: #111827;"
  end

  defp do_for(:logo_cell, _accent, _secondary, font_stack) do
    "padding: 8px 12px; text-align: left; font-family: #{font_stack}; font-size: 18px; font-weight: 700;"
  end

  defp do_for(:number_cell, _accent, secondary, font_stack) do
    "padding: 8px 12px; text-align: right; font-family: #{font_stack}; font-size: 14px; color: #{secondary};"
  end

  defp do_for(:line_items, _accent, _secondary, font_stack) do
    "border-collapse: collapse; width: 100%; margin-top: 16px; font-family: #{font_stack}; font-size: 14px;"
  end

  defp do_for(:line_row, _accent, _secondary, _font_stack) do
    "border-bottom: 1px solid #E5E7EB;"
  end

  defp do_for(:th, accent, _secondary, font_stack) do
    "padding: 8px 12px; text-align: left; font-family: #{font_stack}; font-size: 12px; text-transform: uppercase; color: #{accent}; border-bottom: 2px solid #{accent};"
  end

  defp do_for(:td, _accent, _secondary, font_stack) do
    "padding: 8px 12px; text-align: left; font-family: #{font_stack}; vertical-align: top;"
  end

  defp do_for(:td_num, _accent, _secondary, font_stack) do
    "padding: 8px 12px; text-align: right; font-family: #{font_stack}; font-variant-numeric: tabular-nums;"
  end

  defp do_for(:totals, _accent, _secondary, font_stack) do
    "border-collapse: collapse; width: 100%; margin-top: 16px; font-family: #{font_stack}; font-size: 14px;"
  end

  defp do_for(:totals_row, _accent, _secondary, _font_stack) do
    "border-bottom: 1px solid #E5E7EB;"
  end

  defp do_for(:totals_label, _accent, secondary, font_stack) do
    "padding: 6px 12px; text-align: right; font-family: #{font_stack}; color: #{secondary};"
  end

  defp do_for(:totals_value, _accent, _secondary, font_stack) do
    "padding: 6px 12px; text-align: right; font-family: #{font_stack}; font-variant-numeric: tabular-nums; color: #111827;"
  end

  defp do_for(:footer, _accent, secondary, font_stack) do
    "border-collapse: collapse; width: 100%; margin-top: 24px; font-family: #{font_stack}; font-size: 12px; color: #{secondary};"
  end

  defp do_for(:footer_line, _accent, secondary, font_stack) do
    "padding: 4px 12px; text-align: center; font-family: #{font_stack}; color: #{secondary};"
  end

  defp do_for(:cta_button, accent, _secondary, font_stack) do
    "display: inline-block; padding: 12px 20px; background-color: #{accent}; color: #FFFFFF; font-family: #{font_stack}; font-weight: 600; text-decoration: none; border-radius: 4px;"
  end

  defp do_for(:heading, _accent, _secondary, font_stack) do
    "margin: 0 0 12px 0; font-family: #{font_stack}; font-size: 20px; font-weight: 700; color: #111827;"
  end

  defp do_for(:body, _accent, _secondary, font_stack) do
    "margin: 0 0 12px 0; font-family: #{font_stack}; font-size: 14px; line-height: 1.5; color: #111827;"
  end
end
