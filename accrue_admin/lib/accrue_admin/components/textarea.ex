defmodule AccrueAdmin.Components.Textarea do
  @moduledoc """
  Shared textarea form control for mounted admin pages.

  Follows the same `ax-field` wrapper pattern as `Input`. Emits
  `aria-invalid` and `aria-describedby` for screen-reader error
  linking. Error paragraph IDs are indexed to avoid duplicate `id`
  attributes when multiple error messages are present (D-08 fix).
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:rows, :integer, default: 4)
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])

  attr(:rest, :global,
    include: ~w(disabled placeholder readonly phx-debounce phx-hook required)
  )

  def textarea(assigns) do
    assigns = assign(assigns, :has_errors, assigns.errors != [])

    ~H"""
    <div class="ax-field">
      <label for={@id} class="ax-field-label"><%= @label %></label>
      <textarea
        id={@id}
        name={@name}
        rows={@rows}
        class={["ax-field-control", "ax-textarea", @has_errors && "ax-field-control-error"]}
        aria-invalid={if(@has_errors, do: "true", else: "false")}
        aria-describedby={described_by(@id, @help_text, @errors)}
        {@rest}
      ><%= @value %></textarea>

      <p :if={@help_text} id={@id <> "-help"} class="ax-field-help"><%= @help_text %></p>
      <div :if={@errors != []} id={@id <> "-errors"}>
        <p
          :for={{error, i} <- Enum.with_index(@errors)}
          id={@id <> "-error-#{i}"}
          class="ax-field-error"
        ><%= error %></p>
      </div>
    </div>
    """
  end

  defp described_by(id, help_text, errors) do
    []
    |> maybe_add(help_text && id <> "-help")
    |> maybe_add(errors != [] && id <> "-errors")
    |> Enum.join(" ")
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp maybe_add(list, false), do: list
  defp maybe_add(list, nil), do: list
  defp maybe_add(list, value), do: list ++ [value]
end
