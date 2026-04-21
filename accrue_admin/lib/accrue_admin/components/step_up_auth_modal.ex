defmodule AccrueAdmin.Components.StepUpAuthModal do
  @moduledoc """
  Shared modal rendered when a destructive admin action requires fresh auth.

  Host layouts may register an optional tab-cycle hook (reserved name in phase
  CONTEXT) when a full focus trap is required; this component does not import
  Alpine.js or other client-side trap libraries.
  """

  use Phoenix.Component

  alias AccrueAdmin.Copy

  attr(:pending, :boolean, required: true)
  attr(:challenge, :map, default: nil)
  attr(:error, :string, default: nil)

  def step_up_auth_modal(assigns) do
    ~H"""
    <section
      :if={@pending}
      id="accrue-admin-step-up-dialog"
      class="ax-card ax-step-up-modal"
      role="dialog"
      aria-labelledby="step-up-title"
      phx-mounted={Phoenix.LiveView.JS.push_focus() |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")}
      phx-remove={Phoenix.LiveView.JS.pop_focus()}
    >
      <header class="ax-page-header">
        <p class="ax-eyebrow"><%= Copy.step_up_eyebrow() %></p>
        <h2 id="step-up-title" class="ax-heading"><%= Copy.step_up_title() %></h2>
        <p class="ax-body">
          <%= Map.get(@challenge || %{}, :message) || Copy.step_up_default_challenge_message() %>
        </p>
      </header>

      <p :if={@error} class="ax-body" data-role="step-up-error"><%= @error %></p>

      <form phx-submit="step_up_submit" class="ax-page">
        <input
          :if={input_name(@challenge) != nil}
          type={input_type(@challenge)}
          name={input_name(@challenge)}
          value=""
          placeholder={input_placeholder(@challenge)}
        />

        <button type="button" phx-click="step_up_dismiss" class="ax-button ax-button-ghost">
          <%= Copy.step_up_cancel_label() %>
        </button>

        <button type="submit" class="ax-link"><%= Copy.step_up_submit_label() %></button>
      </form>
    </section>
    """
  end

  defp input_name(%{kind: kind}) when kind in [:password, :totp], do: "code"
  defp input_name(%{kind: :webauthn}), do: "assertion"
  defp input_name(_), do: nil

  defp input_type(%{kind: :password}), do: "password"
  defp input_type(_), do: "text"

  defp input_placeholder(%{kind: :password}), do: "Password"
  defp input_placeholder(%{kind: :webauthn}), do: "Assertion payload"
  defp input_placeholder(_), do: "Verification code"
end
