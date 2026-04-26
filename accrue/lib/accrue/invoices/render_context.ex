defmodule Accrue.Invoices.RenderContext do
  @moduledoc """
  Format-neutral hydrated invoice payload (D6-04).

  Built once per render by `Accrue.Invoices.Render.build_assigns/2` and
  passed through BOTH the email body and
  the PDF shell (via `Accrue.Invoices.Layouts.print_shell/1`). This
  guarantees every format sees byte-identical money strings and the
  same frozen branding snapshot.

  ## Branding snapshot freeze (Pitfall 8)

  The `:branding` field holds a keyword list captured at build time from
  `Accrue.Config.branding/0`. It MUST NOT be re-read downstream — if a
  component needs branding it reads `ctx.branding`. This prevents config
  drift between the email header, the PDF header, and the footer within
  a single render.

  ## Pre-formatted fields

  Money + date fields are pre-formatted into `formatted_*` strings at
  build time (CLDR calls live off the hot template path). Components
  read `ctx.formatted_total` directly instead of calling `format_money/3`
  from inside `~H`.
  """

  @enforce_keys [:invoice, :customer, :branding, :locale, :timezone, :currency]
  defstruct [
    :invoice,
    :customer,
    :line_items,
    :subtotal_minor,
    :discount_minor,
    :tax_minor,
    :total_minor,
    :currency,
    :branding,
    :locale,
    :timezone,
    :now,
    :hosted_invoice_url,
    :receipt_url,
    :formatted_total,
    :formatted_subtotal,
    :formatted_discount,
    :formatted_tax,
    :formatted_issued_at
  ]

  @type t :: %__MODULE__{
          invoice: term(),
          customer: term(),
          line_items: [term()] | nil,
          subtotal_minor: integer() | nil,
          discount_minor: integer() | nil,
          tax_minor: integer() | nil,
          total_minor: integer() | nil,
          currency: atom(),
          branding: keyword(),
          locale: String.t(),
          timezone: String.t(),
          now: DateTime.t() | nil,
          hosted_invoice_url: String.t() | nil,
          receipt_url: String.t() | nil,
          formatted_total: String.t() | nil,
          formatted_subtotal: String.t() | nil,
          formatted_discount: String.t() | nil,
          formatted_tax: String.t() | nil,
          formatted_issued_at: String.t() | nil
        }
end
