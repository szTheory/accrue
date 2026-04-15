defmodule Accrue.Telemetry.OTelTest do
  use ExUnit.Case, async: false

  @without_cmd "ACCRUE_OTEL_MATRIX=without_opentelemetry mix compile --warnings-as-errors --force"
  @with_cmd "ACCRUE_OTEL_MATRIX=with_opentelemetry mix compile --warnings-as-errors --force"

  test "converts telemetry event names to dotted OpenTelemetry span names" do
    assert Accrue.Telemetry.OTel.span_name([:accrue, :billing, :subscription, :create]) ==
             "accrue.billing.subscription.create"
  end

  test "sanitizes metadata to the OBS-02 allowlisted business attributes" do
    metadata = %{
      processor: :stripe,
      customer_id: "cus_123",
      subscription_id: "sub_123",
      invoice_id: "in_123",
      event_type: "invoice.payment_failed",
      operation: :renewal,
      status: :error,
      email: "customer@example.com",
      address: "123 Main St",
      raw_body: "{\"secret\":true}",
      payload: %{"object" => "event"},
      metadata: %{"note" => "free text"},
      api_key: "sk_test_fixture_123",
      webhook_secret: "whsec_fixture_123",
      stripe_secret_key: "sk_live_fixture_123",
      card: %{last4: "4242"}
    }

    assert Accrue.Telemetry.OTel.sanitize_attributes(metadata) == %{
             "accrue.processor" => "stripe",
             "accrue.customer_id" => "cus_123",
             "accrue.subscription_id" => "sub_123",
             "accrue.invoice_id" => "in_123",
             "accrue.event_type" => "invoice.payment_failed",
             "accrue.operation" => "renewal",
             "accrue.status" => "error"
           }
  end

  test "drops prohibited sensitive keys from span attributes" do
    prohibited = %{
      email: "customer@example.com",
      address: "123 Main St",
      raw_body: "raw",
      payload: %{"id" => "evt_1"},
      metadata: %{"freeform" => "text"},
      api_key: "sk_test_fixture_123",
      webhook_secret: "whsec_fixture_123",
      stripe_secret_key: "sk_live_fixture_123",
      card: %{brand: "visa"}
    }

    attrs = Accrue.Telemetry.OTel.sanitize_attributes(prohibited)

    refute Map.has_key?(attrs, "email")
    refute Map.has_key?(attrs, "address")
    refute Map.has_key?(attrs, "raw_body")
    refute Map.has_key?(attrs, "payload")
    refute Map.has_key?(attrs, "metadata")
    refute Map.has_key?(attrs, "api_key")
    refute Map.has_key?(attrs, "webhook_secret")
    refute Map.has_key?(attrs, "stripe_secret_key")
    refute Map.has_key?(attrs, "card")
  end

  test "compiles warning-free with and without OpenTelemetry optional dependency" do
    assert_compile_matrix!(@without_cmd)
    assert_compile_matrix!(@with_cmd)
  end

  defp assert_compile_matrix!(cmd) do
    env =
      cmd
      |> String.split(" ")
      |> Enum.take_while(&String.contains?(&1, "="))
      |> Map.new(fn assignment ->
        [key, value] = String.split(assignment, "=", parts: 2)
        {key, value}
      end)

    args =
      cmd
      |> String.split(" ")
      |> Enum.drop_while(&String.contains?(&1, "="))

    {executable, executable_args} = List.pop_at(args, 0)
    previous = Map.new(env, fn {key, _value} -> {key, System.get_env(key)} end)

    try do
      Enum.each(env, fn {key, value} -> System.put_env(key, value) end)
      assert {_, 0} = System.cmd(executable, executable_args, stderr_to_stdout: true)
    after
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end
  end
end
