defmodule Accrue.Emails.CouponApplied do
  @moduledoc """
  Coupon applied notification (MAIL-13).

  Sent when a discount is applied via an action module
  (`Accrue.Billing.apply_promotion_code/3`) or when Stripe emits
  `invoice.updated` with a new discount. Body references the coupon
  (`name`, `percent_off` / `formatted_amount_off`) and the associated
  promotion code. Does NOT embed shared invoice components.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/coupon_applied.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{coupon: %{name: name}}}) when is_binary(name),
    do: "Discount applied — #{name}"

  def subject(%{context: %{promotion_code: %{code: code}}}) when is_binary(code),
    do: "Discount applied — #{code}"

  def subject(_), do: "Discount applied"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/coupon_applied.text.eex")
  end

  defp to_keyword(map) do
    Enum.reduce(map, [], fn
      {k, v}, acc when is_atom(k) ->
        [{k, v} | acc]

      {k, v}, acc when is_binary(k) ->
        try do
          [{String.to_existing_atom(k), v} | acc]
        rescue
          ArgumentError -> acc
        end
    end)
  end
end
