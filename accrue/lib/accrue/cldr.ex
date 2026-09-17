defmodule Accrue.Cldr do
  @moduledoc """
  Default CLDR backend used for Accrue locale validation.

  Accrue keeps this minimal backend for backwards-compatible locale validation.
  `ex_money` 6.x uses Localize for its own formatting and no longer registers a
  Money provider with CLDR. The locale list stays small by default so the
  compile cost is low.
  """

  use Cldr,
    default_locale: "en",
    locales: ["en"],
    providers: [Cldr.Number]
end
