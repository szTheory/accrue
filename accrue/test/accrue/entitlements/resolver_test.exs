defmodule Accrue.Entitlements.ResolverTest do
  @moduledoc """
  Contract tests for `Accrue.Entitlements.Resolver` — the behaviour seam +
  runtime dispatch (`__impl__/0`). The `resolve/2` callback shape itself is
  exercised through `Accrue.Entitlements.Resolver.LocalMap` (see
  `local_map_test.exs`) and the public context (`entitlements_test.exs`).
  """

  use ExUnit.Case, async: false

  alias Accrue.Entitlements.Resolver

  setup do
    prev = Application.get_env(:accrue, :entitlements)

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    :ok
  end

  describe "__impl__/0 runtime dispatch" do
    test "defaults to LocalMap when :entitlements has no :resolver" do
      Application.delete_env(:accrue, :entitlements)
      assert Resolver.__impl__() == Accrue.Entitlements.Resolver.LocalMap
    end

    test "defaults to LocalMap when :entitlements is set but :resolver is absent" do
      Application.put_env(:accrue, :entitlements, plans: [])
      assert Resolver.__impl__() == Accrue.Entitlements.Resolver.LocalMap
    end

    test "honors a configured :resolver override" do
      defmodule CustomResolver do
        @behaviour Accrue.Entitlements.Resolver
        @impl true
        def resolve(_billable, _opts),
          do: {:ok, %{plan: nil, active_plans: MapSet.new(), features: MapSet.new(), quantities: %{}}}
      end

      Application.put_env(:accrue, :entitlements, resolver: CustomResolver)
      assert Resolver.__impl__() == CustomResolver
    end
  end
end
