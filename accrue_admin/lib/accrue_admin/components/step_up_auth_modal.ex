defmodule AccrueAdmin.Components.StepUpAuthModal do
  @moduledoc """
  Shared modal rendered when a destructive admin action requires fresh auth.

  Uses the package-local FocusTrap hook for focus containment and dismissal.
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
      class="ax-step-up-modal-shell"
      data-component-group="modal-confirm"
      role="dialog"
      aria-modal="true"
      aria-labelledby="step-up-title"
      aria-describedby="step-up-description"
      phx-hook="FocusTrap"
      data-focus-trap-close-event="step_up_dismiss"
      data-focus-trap-fallback="#step-up-title"
      data-focus-trap-initial="#step-up-code"
      phx-mounted={Phoenix.LiveView.JS.push_focus() |> Phoenix.LiveView.JS.focus_first(to: "#accrue-admin-step-up-dialog")}
      phx-remove={Phoenix.LiveView.JS.pop_focus()}
    >
      <div class="ax-step-up-modal-backdrop" aria-hidden="true" phx-click="step_up_dismiss"></div>

      <article class="ax-card ax-step-up-modal">
        <header class="ax-page-header">
          <p class="ax-eyebrow"><%= Copy.step_up_eyebrow() %></p>
          <h2 id="step-up-title" class="ax-heading" tabindex="-1" data-focus-trap-fallback><%= Copy.step_up_title() %></h2>
          <p id="step-up-description" class="ax-body">
            <%= Map.get(@challenge || %{}, :message) || Copy.step_up_default_challenge_message() %>
          </p>
        </header>

        <p :if={@error} id="step-up-error" class="ax-body" data-role="step-up-error"><%= @error %></p>

        <form phx-submit="step_up_submit" class="ax-step-up-modal-form">
          <label :if={input_name(@challenge) != nil} class="ax-visually-hidden" for="step-up-code">
            <%= input_placeholder(@challenge) %>
          </label>
          <input
            :if={input_name(@challenge) != nil}
            id="step-up-code"
            type={input_type(@challenge)}
            name={input_name(@challenge)}
            value=""
            placeholder={input_placeholder(@challenge)}
            aria-invalid={if @error, do: "true", else: "false"}
            aria-describedby={step_up_input_describedby(@error)}
            data-focus-trap-initial
          />

          <div class="ax-step-up-modal-actions">
            <button type="button" phx-click="step_up_dismiss" class="ax-button ax-button-ghost" data-role="step-up-cancel">
              <%= Copy.step_up_cancel_label() %>
            </button>

            <button type="submit" class="ax-button ax-button-primary" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
          </div>
        </form>
      </article>
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

  defp step_up_input_describedby(nil), do: "step-up-description"
  defp step_up_input_describedby(""), do: "step-up-description"
  defp step_up_input_describedby(_error), do: "step-up-description step-up-error"
end
