defmodule AccrueAdmin.Components.FlashGroup do
  @moduledoc """
  Shared flash notice stack for admin pages.
  """

  use Phoenix.Component

  attr(:flashes, :list, required: true)

  def flash_group(assigns) do
    ~H"""
    <section :if={@flashes != []} class="ax-flash-group" aria-label="Notifications">
      <article
        :for={flash <- @flashes}
        class={["ax-flash", flash_class(flash[:kind])]}
        role="status"
        phx-mounted={Phoenix.LiveView.JS.show(transition: {"ax-flash-entering", "ax-flash-enter-from", "ax-flash-enter-to"}, time: 180)}
        phx-remove={Phoenix.LiveView.JS.hide(transition: {"ax-flash-leaving", "ax-flash-leave-from", "ax-flash-leave-to"}, time: 140)}
      >
        <p class="ax-label"><%= flash_title(flash) %></p>
        <p class="ax-body"><%= flash[:message] %></p>
      </article>
    </section>
    """
  end

  defp flash_title(%{title: title}) when is_binary(title) and title != "", do: title
  defp flash_title(%{kind: :info}), do: "Notice"
  defp flash_title(%{kind: :error}), do: "Action required"
  defp flash_title(%{kind: :warning}), do: "Warning"
  defp flash_title(_flash), do: "Update"

  defp flash_class(:info), do: "ax-flash-info"
  defp flash_class(:success), do: "ax-flash-success"
  defp flash_class(:warning), do: "ax-flash-warning"
  defp flash_class(:error), do: "ax-flash-error"
  defp flash_class(_kind), do: "ax-flash-neutral"
end
