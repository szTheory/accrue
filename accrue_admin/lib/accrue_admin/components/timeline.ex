defmodule AccrueAdmin.Components.Timeline do
  @moduledoc """
  Shared vertical timeline for billing events and webhook attempt history.
  """

  use Phoenix.Component

  attr(:items, :list, required: true)
  attr(:label, :string, default: "Timeline")
  attr(:empty_label, :string, default: "No events yet")
  attr(:class, :string, default: nil)

  def timeline(assigns) do
    ~H"""
    <section class={["ax-timeline", @class]} aria-label={@label}>
      <ol :if={@items != []} class="ax-timeline-list">
        <li :for={item <- @items} class="ax-timeline-item">
          <span class={["ax-timeline-dot", "ax-timeline-dot-" <> tone(item)]} aria-hidden="true"></span>

          <div class="ax-timeline-card">
            <div class="ax-timeline-header">
              <div>
                <p class="ax-label"><%= Map.get(item, :title, "Event") %></p>
                <p :if={Map.get(item, :at)} class="ax-body ax-muted"><%= Map.get(item, :at) %></p>
              </div>
              <span :if={Map.get(item, :status)} class="ax-timeline-status"><%= humanize(Map.get(item, :status)) %></span>
            </div>

            <p :if={Map.get(item, :body)} class="ax-body"><%= Map.get(item, :body) %></p>

            <details :if={Map.get(item, :details)} class="ax-timeline-details" open={Map.get(item, :expanded, false)}>
              <summary>Inspect details</summary>
              <pre><%= Map.get(item, :details) %></pre>
            </details>

            <div :if={Map.get(item, :meta)} class="ax-timeline-meta"><%= Map.get(item, :meta) %></div>
          </div>
        </li>
      </ol>

      <p :if={@items == []} class="ax-body ax-filter-chip-empty"><%= @empty_label %></p>
    </section>
    """
  end

  defp tone(item) do
    case Map.get(item, :tone) || Map.get(item, :status) do
      value when value in ["moss", "cobalt", "amber", "slate", "ink"] -> value
      value when value in [:moss, :cobalt, :amber, :slate, :ink] -> Atom.to_string(value)
      value when value in [:success, :succeeded, :paid, :active] -> "moss"
      value when value in [:info, :processing, :queued, :retrying] -> "cobalt"
      value when value in [:warning, :past_due, :failed_retry, :grace_period, :dlq] -> "amber"
      value when value in [:neutral, :void, :canceled] -> "slate"
      _ -> "ink"
    end
  end

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_value), do: "Unknown"
end
