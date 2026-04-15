defmodule Accrue.Test.EventAssertions do
  @moduledoc """
  ExUnit-style assertions for Accrue's append-only event ledger.

  ## Usage

      use Accrue.Test.EventAssertions
      # or
      import Accrue.Test.EventAssertions

      assert_event_recorded(
        type: "subscription.created",
        subject: subscription,
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "system",
        data: %{"status" => "active"},
        matches: fn event -> event.schema_version == 1 end
      )

  ## Matching

  - `:type` matches `event.type`
  - `:subject` derives `subject_type` and `subject_id` from a struct or map with `:id`
  - `:subject_type`, `:subject_id`, and `:actor_type` match the event fields directly
  - `:data` subset-matches only the provided keys
  - `:matches` runs a 1-arity predicate against `%Accrue.Events.Event{}`

  Assertions query the test process' database sandbox state. Failure messages
  include the matcher and observed event type/subject summaries, but avoid
  dumping raw event payload data.
  """

  import Ecto.Query

  alias Accrue.Events.Event

  defmacro __using__(_opts) do
    quote do
      import Accrue.Test.EventAssertions
    end
  end

  @doc """
  Asserts that an event matching `matcher` was recorded.
  """
  defmacro assert_event_recorded(matcher) do
    quote do
      matcher = unquote(matcher)

      case Accrue.Test.EventAssertions.__find_event__(matcher) do
        {:ok, event} ->
          event

        {:error, observed} ->
          ExUnit.Assertions.flunk(
            Accrue.Test.EventAssertions.__failure_message__(
              :assert,
              matcher,
              observed
            )
          )
      end
    end
  end

  @doc """
  Asserts that an event matching `subject` and `matchers` was recorded.
  """
  defmacro assert_event_recorded(subject, matchers) do
    quote do
      Accrue.Test.EventAssertions.assert_event_recorded(
        Keyword.put(List.wrap(unquote(matchers)), :subject, unquote(subject))
      )
    end
  end

  @doc """
  Refutes that an event matching `matcher` was recorded.
  """
  defmacro refute_event_recorded(matcher) do
    quote do
      matcher = unquote(matcher)

      case Accrue.Test.EventAssertions.__find_event__(matcher) do
        {:ok, event} ->
          ExUnit.Assertions.flunk(
            Accrue.Test.EventAssertions.__unexpected_message__(matcher, event)
          )

        {:error, _observed} ->
          :ok
      end
    end
  end

  @doc """
  Refutes that an event matching `subject` and `matchers` was recorded.
  """
  defmacro refute_event_recorded(subject, matchers) do
    quote do
      Accrue.Test.EventAssertions.refute_event_recorded(
        Keyword.put(List.wrap(unquote(matchers)), :subject, unquote(subject))
      )
    end
  end

  @doc """
  Asserts that no event matching `matcher` was recorded.
  """
  defmacro assert_no_events_recorded(matcher \\ []) do
    quote do
      Accrue.Test.EventAssertions.refute_event_recorded(unquote(matcher))
    end
  end

  @doc false
  def __find_event__(matcher) do
    observed = observed_events()

    case Enum.find(observed, &__match__(&1, matcher)) do
      nil -> {:error, observed}
      event -> {:ok, event}
    end
  end

  @doc false
  def __match__(%Event{} = event, matcher) when is_function(matcher, 1), do: matcher.(event)

  def __match__(%Event{} = event, matcher) do
    matcher
    |> normalize_matcher()
    |> Enum.all?(fn
      {:type, value} ->
        event.type == to_string(value)

      {:subject, subject} ->
        subject_match?(event, subject)

      {:subject_type, value} ->
        event.subject_type == to_string(value)

      {:subject_id, value} ->
        event.subject_id == to_string(value)

      {:actor_type, value} ->
        event.actor_type == to_string(value)

      {:data, expected} when is_map(expected) ->
        partial_map_match?(event.data || %{}, expected)

      {:matches, fun} when is_function(fun, 1) ->
        fun.(event)

      _other ->
        true
    end)
  end

  @doc false
  def __failure_message__(:assert, matcher, observed) do
    "expected event recorded matching #{inspect(matcher)}; " <>
      "observed event count=#{length(observed)}; " <>
      "observed events=#{inspect(observed_summary(observed))}"
  end

  @doc false
  def __unexpected_message__(matcher, %Event{} = event) do
    "unexpected event recorded matching #{inspect(matcher)}; " <>
      "observed event=#{inspect(event_summary(event))}"
  end

  defp observed_events do
    from(e in Event, order_by: [desc: e.id], limit: 100)
    |> Accrue.Repo.all()
  end

  defp normalize_matcher(matcher) when is_list(matcher), do: matcher
  defp normalize_matcher(matcher) when is_map(matcher), do: Map.to_list(matcher)
  defp normalize_matcher(matcher) when is_function(matcher, 1), do: [matches: matcher]
  defp normalize_matcher(matcher), do: [type: matcher]

  defp subject_match?(%Event{} = event, subject) do
    case normalize_subject(subject) do
      {subject_type, subject_id} ->
        event.subject_type == subject_type and event.subject_id == subject_id

      :error ->
        false
    end
  end

  defp normalize_subject(subject) when is_map(subject) do
    with module when not is_nil(module) <- Map.get(subject, :__struct__),
         id when not is_nil(id) <- Map.get(subject, :id) || Map.get(subject, "id") do
      {subject_type(module), to_string(id)}
    else
      _ -> :error
    end
  end

  defp normalize_subject(_subject), do: :error

  defp subject_type(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end

  defp subject_type(other), do: to_string(other)

  defp partial_map_match?(actual, expected) when is_map(actual) and is_map(expected) do
    Enum.all?(expected, fn {key, value} ->
      actual_value = Map.get(actual, key, Map.get(actual, to_string(key)))
      actual_value == value
    end)
  end

  defp observed_summary(events), do: Enum.map(events, &event_summary/1)

  defp event_summary(%Event{} = event) do
    %{
      type: event.type,
      subject_type: event.subject_type,
      subject_id: event.subject_id,
      actor_type: event.actor_type
    }
  end
end
