defmodule AccrueAdmin.Components.Timeline do
  @moduledoc """
  Shared vertical timeline for billing events and webhook attempt history.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.IdBadge
  alias AccrueAdmin.Components.StatusBadge
  alias AccrueAdmin.Components.Timestamp

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
                <Timestamp.timestamp
                  :if={match?(%DateTime{}, Map.get(item, :at))}
                  value={Map.get(item, :at)}
                  id={timestamp_id(item)}
                />
                <time
                  :if={Map.get(item, :at) && not match?(%DateTime{}, Map.get(item, :at))}
                  class="ax-timeline-time"
                ><%= Map.get(item, :at) %></time>
              </div>
              <StatusBadge.status_badge :if={Map.get(item, :status)} status={Map.get(item, :status)} tone={tone(item)} />
            </div>

            <div :if={Map.get(item, :subject_id)} class="ax-timeline-subject">
              <span class="ax-timeline-subject-label"><%= Map.get(item, :subject_type) || "Record" %> ID</span>
              <IdBadge.id_badge
                id={"timeline-subject-#{Map.get(item, :id, :erlang.phash2(item))}"}
                id_value={to_string(Map.get(item, :subject_id))}
                label={"Copy #{Map.get(item, :subject_type) || "record"} ID #{Map.get(item, :subject_id)}"}
              />
            </div>
            <p :if={Map.get(item, :actor)} class="ax-timeline-actor">
              <%= if Map.get(item, :actor) == "system", do: "Recorded automatically", else: "Recorded by #{Map.get(item, :actor)}" %>
              <IdBadge.id_badge :if={Map.get(item, :actor_id)} id={"timeline-actor-#{Map.get(item, :id, :erlang.phash2(item))}"} id_value={to_string(Map.get(item, :actor_id))} label="Copy actor ID" />
            </p>
            <p :if={Map.get(item, :body)} class="ax-body"><%= Map.get(item, :body) %></p>

            <details :if={Map.get(item, :details)} class="ax-timeline-details" open={Map.get(item, :expanded, false)}>
              <summary><%= Map.get(item, :details_label, "Inspect details") %></summary>
              <pre><%= Map.get(item, :details) %></pre>
            </details>

            <div :if={Map.get(item, :meta)} class="ax-timeline-meta"><%= Map.get(item, :meta) %></div>

            <a :if={Map.get(item, :href)} class="ax-timeline-link" href={Map.get(item, :href)}>
              <%= Map.get(item, :href_label, "Open details") %>
            </a>
          </div>
        </li>
      </ol>

      <p :if={@items == []} class="ax-body ax-timeline-empty"><%= @empty_label %></p>
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

  defp timestamp_id(item), do: "timeline-timestamp-#{Map.get(item, :id, :erlang.phash2(item))}"
end
