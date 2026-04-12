defmodule Accrue.Cldr do
  @moduledoc """
  Default CLDR backend used by `:ex_money` (and, transitively, `Accrue.Money`).

  `:ex_money` requires a CLDR backend to start its application supervisor. We
  define a minimal one here — Plan 02 (D-01..04) wraps this as part of
  `Accrue.Money`'s public API. The locale list stays small by default so the
  compile cost is low; users can override by configuring their own
  `:default_cldr_backend` in the host app.
  """

  use Cldr,
    default_locale: "en",
    locales: ["en"],
    providers: [Cldr.Number, Money]
end
