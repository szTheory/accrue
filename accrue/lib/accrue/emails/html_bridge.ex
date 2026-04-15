defmodule Accrue.Emails.HtmlBridge do
  @moduledoc """
  Renders a `Phoenix.Component` function component to a safe HTML string
  for embedding inside `<mj-raw>` in an `mjml_eex` template.

  `mjml_eex` is NOT HEEx-based (`MjmlEEx.Component` uses string-return
  functions, not HEEx). This module is the one-way bridge: HEEx function
  components → string → `<mj-raw>` block.

  ## Call shape

      iex> assigns = %{name: "Jo"}
      iex> Accrue.Emails.HtmlBridge.render(&MyComponents.greeting/1, assigns)
      "<p>Jo</p>"

  ## Style discipline (D6-01 Pitfall 2)

  Styles inside components MUST be inlined at the element level via the
  `brand_style/1` helper in `Accrue.Invoices.Components`. MJML's
  post-render CSS inliner does not descend into `<mj-raw>` blocks, so any
  classname-only styling will be invisible inside the email shell.

  ## Why this module exists

  `Phoenix.Component` returns a `Phoenix.LiveView.Rendered` struct, which
  implements the `Phoenix.HTML.Safe` protocol. We don't need a LiveView
  mount context — we just call the function and convert the returned
  iodata to a binary.
  """

  @doc """
  Invokes a `Phoenix.Component` function component with `assigns` and
  returns the rendered HTML as a binary.

  The first argument must be a 1-arity function (`use Phoenix.Component`
  in the caller), and the second argument must be a map of assigns.
  """
  @spec render((map() -> Phoenix.LiveView.Rendered.t()), map()) :: String.t()
  def render(component, assigns) when is_function(component, 1) and is_map(assigns) do
    component
    |> apply([assigns])
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
