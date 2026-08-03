defmodule Accrue.Entitlements.ProjectorTest do
  use ExUnit.Case, async: true

  test "exposes the canonical projector boundary" do
    assert function_exported?(Accrue.Entitlements.Projector, :project, 2)
  end
end
