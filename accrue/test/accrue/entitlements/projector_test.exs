defmodule Accrue.Entitlements.ProjectorTest do
  use ExUnit.Case, async: true

  test "exposes the canonical projector boundary" do
    assert Code.ensure_loaded?(Accrue.Entitlements.Projector)
    assert function_exported?(Accrue.Entitlements.Projector, :project, 2)
  end
end
