defmodule AccrueAdmin.Components.StepUpAuthModal do
  @moduledoc """
  Shared modal rendered when a destructive admin action requires fresh auth.

  Uses the package-local FocusTrap hook for focus containment and dismissal.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Overlay
  alias AccrueAdmin.Copy

  attr(:pending, :boolean, required: true)
  attr(:challenge, :map, default: nil)
  attr(:error, :string, default: nil)

  def step_up_auth_modal(assigns) do
    assigns =
      assign(
        assigns,
        challenge_message:
          Map.get(assigns.challenge || %{}, :message) || Copy.step_up_default_challenge_message()
      )

    ~H"""
    <Overlay.overlay
      id="accrue-admin-step-up-dialog"
      open={@pending}
      presentation={:modal}
      title={Copy.step_up_title()}
      title_id="step-up-title"
      subtitle={@challenge_message}
      description_id="step-up-description"
      close_label=""
      close_event="step_up_dismiss"
      initial_focus="#step-up-code"
      component_group="modal-confirm"
    >
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
    </Overlay.overlay>
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
