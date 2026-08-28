defmodule Accrue.RuntimeConfigTest do
  use ExUnit.Case, async: false

  alias Accrue.Config

  @environment_keys ["STRIPE_TEST_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"]
  @application_keys [:processor, :stripe_secret_key, :webhook_signing_secrets]

  setup do
    previous_environment = Map.new(@environment_keys, &{&1, System.get_env(&1)})
    previous_application = Map.new(@application_keys, &{&1, Application.get_env(:accrue, &1, :__unset__)})

    on_exit(fn ->
      Enum.each(previous_environment, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)

      Enum.each(previous_application, fn
        {key, :__unset__} -> Application.delete_env(:accrue, key)
        {key, value} -> Application.put_env(:accrue, key, value)
      end)
    end)

    :ok
  end

  test "live Stripe runtime maps the signing secret and validates without a processor request" do
    stripe_key = "sk_test_runtime_config_contract"
    signing_secret = "whsec_runtime_config_contract"
    System.put_env("STRIPE_TEST_SECRET_KEY", "  #{stripe_key}  ")
    System.put_env("STRIPE_WEBHOOK_SECRET", "  #{signing_secret}  ")

    apply_runtime_config!()

    assert Application.get_env(:accrue, :processor) == Accrue.Processor.Stripe
    assert Application.get_env(:accrue, :stripe_secret_key) == stripe_key
    assert Application.get_env(:accrue, :webhook_signing_secrets) == %{stripe: [signing_secret]}

    :erlang.trace_pattern({Accrue.Processor.Stripe, :_, :_}, true, [:local])
    :erlang.trace(self(), true, [:call])

    try do
      assert Config.validate_at_boot!() == :ok
      refute_received {:trace, _, :call, {Accrue.Processor.Stripe, _, _}}
    after
      :erlang.trace(self(), false, [:call])
      :erlang.trace_pattern({Accrue.Processor.Stripe, :_, :_}, false, [:local])
    end
  end

  test "ordinary secretless test runtime remains Fake-backed" do
    System.delete_env("STRIPE_TEST_SECRET_KEY")
    System.delete_env("STRIPE_WEBHOOK_SECRET")
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

    apply_runtime_config!()

    assert Application.get_env(:accrue, :processor) == Accrue.Processor.Fake
  end

  defp apply_runtime_config! do
    runtime_config =
      Path.expand("../../config/runtime.exs", __DIR__)
      |> Elixir.Config.Reader.read!(env: :test)
      |> Keyword.get(:accrue, [])

    Enum.each(@application_keys, fn key ->
      if Keyword.has_key?(runtime_config, key) do
        Application.put_env(:accrue, key, Keyword.fetch!(runtime_config, key))
      end
    end)
  end
end
