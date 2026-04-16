if Mix.env() != :prod do
  defmodule AccrueAdmin.Components.DevToolbar do
    @moduledoc false

    use Phoenix.Component

    def visible? do
      Application.get_env(:accrue, :processor, Accrue.Processor.Fake) == Accrue.Processor.Fake
    end

    attr(:current_path, :string, required: true)
    attr(:mount_path, :string, required: true)

    def dev_toolbar(assigns) do
      assigns = assign(assigns, :items, items(assigns.mount_path))

      ~H"""
      <nav class="ax-dev-toolbar" aria-label="Billing dev tools">
        <p class="ax-dev-toolbar-label">Dev tools</p>

        <div class="ax-dev-toolbar-links">
          <a
            :for={item <- @items}
            href={item.href}
            class={[
              "ax-dev-toolbar-link",
              item.href == @current_path && "ax-dev-toolbar-link-active"
            ]}
          >
            {item.label}
          </a>
        </div>
      </nav>
      """
    end

    defp items(mount_path) do
      [
        %{label: "Clock", href: mount_path <> "/dev/clock"},
        %{label: "Email preview", href: mount_path <> "/dev/email-preview"},
        %{label: "Webhook fixtures", href: mount_path <> "/dev/webhook-fixtures"},
        %{label: "Components", href: mount_path <> "/dev/components"},
        %{label: "Fake inspect", href: mount_path <> "/dev/fake-inspect"}
      ]
    end
  end
end
