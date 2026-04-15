defmodule AccrueAdmin.Components.Input do
  @moduledoc """
  Shared text-like form input for mounted admin pages.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:type, :string, default: "text")
  attr(:value, :string, default: nil)
  attr(:placeholder, :string, default: nil)
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:rest, :global, include: ~w(autocomplete disabled inputmode maxlength minlength pattern phx-debounce phx-hook phx-target required step))

  def input(assigns) do
    assigns = assign(assigns, :has_errors, assigns.errors != [])

    ~H"""
    <div class="ax-field">
      <label for={@id} class="ax-field-label"><%= @label %></label>
      <input
        id={@id}
        name={@name}
        type={@type}
        value={@value}
        placeholder={@placeholder}
        class={["ax-field-control", @has_errors && "ax-field-control-error"]}
        aria-invalid={if(@has_errors, do: "true", else: "false")}
        aria-describedby={described_by(@id, @help_text, @errors)}
        {@rest}
      />

      <p :if={@help_text} id={@id <> "-help"} class="ax-field-help"><%= @help_text %></p>
      <p :for={error <- @errors} id={@id <> "-error"} class="ax-field-error"><%= error %></p>
    </div>
    """
  end

  defp described_by(id, help_text, errors) do
    []
    |> maybe_add(help_text && id <> "-help")
    |> maybe_add(errors != [] && id <> "-error")
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
