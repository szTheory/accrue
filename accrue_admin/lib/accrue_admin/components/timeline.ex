defmodule AccrueAdmin.Components.Timeline do
  @moduledoc """
  Shared vertical timeline for billing events and webhook attempt history.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.EventIcon
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
        <li :for={item <- @items} class={["ax-timeline-item", Map.has_key?(item, :event_type) && "ax-timeline-item-with-icon"]}>
          <span :if={Map.has_key?(item, :event_type)} class="ax-timeline-marker" aria-hidden="true">
            <EventIcon.event_icon type={item.event_type} size="lg" />
          </span>
          <span :if={!Map.has_key?(item, :event_type)} class={["ax-timeline-dot", "ax-timeline-dot-" <> tone(item)]} aria-hidden="true"></span>

          <div class={["ax-timeline-card", Map.get(item, :subject_id) && "ax-timeline-record"]}>
            <div class="ax-timeline-header">
              <div>
                <p class="ax-label">
                  <a
                    :if={title_link?(item)}
                    class="ax-link ax-timeline-title-link"
                    href={item.href}
                    aria-label={"Open #{Map.get(item, :title, "billing")} event #{Map.get(item, :id, "")}"}
                  ><%= Map.get(item, :title, "Event") %></a>
                  <span :if={!title_link?(item)}><%= Map.get(item, :title, "Event") %></span>
                </p>
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
              <span class="ax-timeline-subject-label"><%= subject_label(item) %></span>
              <IdBadge.id_badge
                id={"timeline-subject-#{Map.get(item, :id, :erlang.phash2(item))}"}
                variant="plain"
                id_value={to_string(Map.get(item, :subject_id))}
                label={"Copy #{Map.get(item, :subject_type) || "record"} ID #{Map.get(item, :subject_id)}"}
              />
            </div>
            <p :if={Map.get(item, :actor) && Map.get(item, :actor) != "system"} class="ax-timeline-actor">
              Recorded by <%= Map.get(item, :actor) %>
              <IdBadge.id_badge :if={Map.get(item, :actor_id)} id={"timeline-actor-#{Map.get(item, :id, :erlang.phash2(item))}"} id_value={to_string(Map.get(item, :actor_id))} label="Copy actor ID" variant="plain" />
            </p>
            <p :if={Map.get(item, :body)} class="ax-body"><%= Map.get(item, :body) %></p>

            <details :if={Map.get(item, :details)} class="ax-timeline-details" open={Map.get(item, :expanded, false)}>
              <summary><%= Map.get(item, :details_label, "Inspect details") %></summary>
              <pre><%= Map.get(item, :details) %></pre>
            </details>

            <div :if={Map.get(item, :meta)} class="ax-timeline-meta"><%= Map.get(item, :meta) %></div>

            <a :if={Map.get(item, :href) && !title_link?(item)} class="ax-timeline-link" href={Map.get(item, :href)}>
              <%= Map.get(item, :href_label, "Open details") %>
            </a>
          </div>
        </li>
      </ol>

      <p :if={@items == []} class="ax-body ax-timeline-empty"><%= @empty_label %></p>
    </section>
    """
  end

  defp title_link?(item), do: Map.has_key?(item, :event_type) && is_binary(Map.get(item, :href))

  # Shorten only when the rendered heading itself names this exact record type.
  # An ambiguous/unknown event still needs "Subscription ID", "Customer ID", etc.
  defp subject_label(item) do
    subject_type = Map.get(item, :subject_type) || "Record"
    title = Map.get(item, :title) || ""
    if String.starts_with?(title, subject_type <> " "), do: "ID", else: subject_type <> " ID"
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
