defmodule AccrueAdmin.Components.StepUpAuthModal do
  @moduledoc """
  Shared modal rendered when a destructive admin action requires fresh auth.
  """

  use Phoenix.Component

  attr(:pending, :boolean, required: true)
  attr(:challenge, :map, default: nil)
  attr(:error, :string, default: nil)

  def step_up_auth_modal(assigns) do
    ~H"""
    <section :if={@pending} class="ax-card ax-step-up-modal" role="dialog" aria-labelledby="step-up-title">
      <header class="ax-page-header">
        <p class="ax-eyebrow">Sensitive action</p>
        <h2 id="step-up-title" class="ax-heading">Step-up required</h2>
        <p class="ax-body">
          <%= Map.get(@challenge || %{}, :message) || "Confirm your identity to continue." %>
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

        <button type="submit" class="ax-link">Verify</button>
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
