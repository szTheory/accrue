defmodule Accrue.Entitlements.SourceTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.Source
  alias Accrue.Entitlements.Source.{CapabilityError, Outcome, Registry}

  test "the public vocabulary is closed and ordered" do
    assert Source.capabilities() == [:observation, :control, :restore, :reconciliation, :management, :offline]

    assert Source.states() == [
             :supported,
             :externally_managed,
             :host_owned,
             :deferred,
             :unavailable,
             :feasibility_blocked
           ]
  end

  test "a valid source has one ordered typed outcome for every capability" do
    assert {:ok, outcomes} = Registry.inspect(:apple)
    assert Enum.map(outcomes, & &1.capability) == Source.capabilities()
    assert Enum.all?(outcomes, &match?(%Outcome{source: :apple}, &1))
  end

  test "registry configuration rejects null empty and duplicate inputs but accepts a single source" do
    for sources <- [nil, [], [:apple, :apple]] do
      assert {:error, %CapabilityError{code: :invalid_source_registry}} = Registry.validate(sources)
    end

    assert {:ok, [:apple]} = Registry.validate([:apple])
  end

  test "apple management is actionable and unavailable operations are typed" do
    assert {:ok,
            %Outcome{
              state: :externally_managed,
              guidance: %{key: :manage_apple_subscription, action_label: "Manage subscription", url: url}
            }} = Registry.outcome(:apple, :management)

    assert url == "https://apps.apple.com/account/subscriptions"

    assert {:error,
            %CapabilityError{
              source: :apple,
              capability: :control,
              code: :operation_unavailable,
              next_action: :manage_in_apple
            }} = Registry.outcome(:apple, :control)
  end

  test "inspection is structurally independent from processor configuration" do
    previous = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :processor, __MODULE__)
    on_exit(fn -> if previous, do: Application.put_env(:accrue, :processor, previous), else: Application.delete_env(:accrue, :processor) end)

    assert {:ok, _} = Registry.inspect(:apple)
  end
end
