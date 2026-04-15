defmodule AccrueAdmin.Components.Select do
  @moduledoc """
  Shared select control for bounded admin choices.
  """

  use Phoenix.Component

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:label, :string, required: true)
  attr(:value, :string, default: nil)
  attr(:prompt, :string, default: nil)
  attr(:options, :list, default: [])
  attr(:help_text, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:rest, :global, include: ~w(disabled multiple phx-change phx-target required))

  def select(assigns) do
    assigns = assign(assigns, :has_errors, assigns.errors != [])

    ~H"""
    <div class="ax-field">
      <label for={@id} class="ax-field-label"><%= @label %></label>
      <select
        id={@id}
        name={@name}
        class={["ax-field-control", "ax-select-control", @has_errors && "ax-field-control-error"]}
        aria-invalid={if(@has_errors, do: "true", else: "false")}
        aria-describedby={described_by(@id, @help_text, @errors)}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <option
          :for={option <- @options}
          value={option_value(option)}
          selected={to_string(option_value(option)) == to_string(@value)}
        >
          <%= option_label(option) %>
        </option>
      </select>

      <p :if={@help_text} id={@id <> "-help"} class="ax-field-help"><%= @help_text %></p>
      <p :for={error <- @errors} id={@id <> "-error"} class="ax-field-error"><%= error %></p>
    </div>
    """
  end

  defp option_label({label, _value}), do: label
  defp option_label(%{label: label}), do: label
  defp option_label(option), do: option

  defp option_value({_label, value}), do: value
  defp option_value(%{value: value}), do: value
  defp option_value(option), do: option

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
