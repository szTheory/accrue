defmodule Accrue.Emails.PaymentSucceeded do
  @moduledoc """
  Reference email template for the `payment_succeeded` receipt email.

  ## mjml_eex integration (CORRECTED pattern — RESEARCH.md Pitfall #3)

  This module uses the idiomatic `use MjmlEEx, mjml_template:` pattern,
  NOT the broken `use Phoenix.Swoosh, formats: %{"mjml" => :html_body}`
  shape that CONTEXT.md D-22 originally sketched. MjmlEEx's `__using__/1`
  compiles the MJML template at build time (via the Rustler NIF backend)
  and generates a `render/1` function that returns rendered HTML.

  The `:mjml_template` option is resolved relative to the calling
  module's source file — so the template lives at
  `priv/accrue/templates/emails/payment_succeeded.mjml.eex` and is
  referenced here with a relative path from `lib/accrue/emails/`.

  ## Assigns

  - `:customer_name` — string, shown in the greeting
  - `:amount` — pre-formatted string (e.g., `"$10.00"`); formatting
    happens at render-call time via `Accrue.Money.to_string/1`
  - `:invoice_number` — string
  - `:receipt_url` — absolute URL to the hosted receipt
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/payment_succeeded.mjml.eex"

  @doc "Subject line for the receipt email."
  @spec subject(map()) :: String.t()
  def subject(_assigns), do: "Receipt for your payment"

  @doc "Plain-text body rendered from the sibling `.text.eex` template."
  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/payment_succeeded.text.eex")
  end

  defp to_keyword(map) do
    Enum.map(map, fn
      {k, v} when is_atom(k) -> {k, v}
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
    end)
  end
end
