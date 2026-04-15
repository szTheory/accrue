defmodule Accrue.Telemetry.OTel do
  @moduledoc """
  Optional OpenTelemetry bridge for Accrue telemetry spans.

  The module is always available, but calls into OpenTelemetry only when
  `OpenTelemetry.Tracer` is loaded. Without the optional dependency, `span/3`
  executes the passed function unchanged and emits no compiler warnings.
  """

  @compile {:no_warn_undefined, [OpenTelemetry.Tracer]}

  @allowed_attributes %{
    :processor => "accrue.processor",
    :customer_id => "accrue.customer_id",
    :subscription_id => "accrue.subscription_id",
    :invoice_id => "accrue.invoice_id",
    :event_type => "accrue.event_type",
    :operation => "accrue.operation",
    :status => "accrue.status",
    "accrue.processor" => "accrue.processor",
    "accrue.customer_id" => "accrue.customer_id",
    "accrue.subscription_id" => "accrue.subscription_id",
    "accrue.invoice_id" => "accrue.invoice_id",
    "accrue.event_type" => "accrue.event_type",
    "accrue.operation" => "accrue.operation",
    "accrue.status" => "accrue.status"
  }

  @prohibited_keys MapSet.new([
                     :email,
                     :address,
                     :raw_body,
                     :payload,
                     :metadata,
                     :api_key,
                     :webhook_secret,
                     :stripe_secret_key,
                     :card,
                     "email",
                     "address",
                     "raw_body",
                     "payload",
                     "metadata",
                     "api_key",
                     "webhook_secret",
                     "stripe_secret_key",
                     "card"
                   ])

  @type event_name :: [atom()]

  @doc """
  Wraps `fun` in an OpenTelemetry span when the optional dependency is loaded.
  """
  @spec span(event_name(), map(), (-> result)) :: result when result: var
  if Code.ensure_loaded?(OpenTelemetry.Tracer) do
    def span(event, metadata \\ %{}, fun)
        when is_list(event) and is_map(metadata) and is_function(fun, 0) do
      name = span_name(event)
      attrs = sanitize_attributes(metadata)

      OpenTelemetry.Tracer.with_span name do
        try do
          OpenTelemetry.Tracer.set_attributes(attrs)

          fun.()
          |> tap(&set_result_status/1)
        rescue
          exception ->
            OpenTelemetry.Tracer.set_status(:error, Exception.message(exception))
            reraise exception, __STACKTRACE__
        end
      end
    end
  else
    def span(_event, _metadata \\ %{}, fun) when is_function(fun, 0), do: fun.()
  end

  @doc """
  Converts an Accrue telemetry event name to the dotted OTel span name.
  """
  @spec span_name(event_name()) :: String.t()
  def span_name(event) when is_list(event) do
    event
    |> Enum.map(&to_string/1)
    |> Enum.join(".")
  end

  @doc """
  Returns the allowlisted, PII-free OpenTelemetry attributes for metadata.
  """
  @spec sanitize_attributes(map()) :: map()
  def sanitize_attributes(metadata) when is_map(metadata) do
    Enum.reduce(metadata, %{}, fn {key, value}, attrs ->
      if MapSet.member?(@prohibited_keys, key) do
        attrs
      else
        case Map.fetch(@allowed_attributes, key) do
          {:ok, attribute} -> Map.put(attrs, attribute, sanitize_value(value))
          :error -> attrs
        end
      end
    end)
  end

  defp sanitize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp sanitize_value(value) when is_binary(value), do: value
  defp sanitize_value(value) when is_integer(value), do: value
  defp sanitize_value(value) when is_float(value), do: value
  defp sanitize_value(value) when is_boolean(value), do: value
  defp sanitize_value(value), do: inspect(value)

  if Code.ensure_loaded?(OpenTelemetry.Tracer) do
    defp set_result_status(:ok), do: OpenTelemetry.Tracer.set_status(:ok, "")
    defp set_result_status({:ok, _}), do: OpenTelemetry.Tracer.set_status(:ok, "")

    defp set_result_status({:error, reason}),
      do: OpenTelemetry.Tracer.set_status(:error, inspect(reason))

    defp set_result_status(_result), do: :ok
  end
end
