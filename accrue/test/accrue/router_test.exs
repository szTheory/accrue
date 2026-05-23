defmodule Accrue.RouterTest do
  @moduledoc """
  Macro-expansion coverage for the `Accrue.Router` entitlement sugar (SC#1).

  `require_feature/1` and `require_plan/1` are thin single-arg macros that MUST
  expand to the canonical `plug Accrue.Plug.RequireEntitlement, …` registration
  — they add no logic, only sugar. We assert the expanded AST directly (a
  `quote`/`Macro.expand` round-trip) so the test is deterministic and needs no
  `Plug.Builder` host module.

  This file is NEW — `router_test.exs` did not previously exist (the existing
  `accrue_webhook/2` macro had no dedicated unit test).
  """

  use ExUnit.Case, async: true

  require Accrue.Router

  # Expand a single `Accrue.Router` macro call to its underlying AST node.
  defp expand(call) do
    Macro.expand_once(call, __ENV__)
  end

  describe "require_feature/1" do
    test "expands to plug(Accrue.Plug.RequireEntitlement, feature: <atom>)" do
      ast = expand(quote(do: Accrue.Router.require_feature(:api_access)))

      assert {:plug, _meta, [{:__aliases__, _, [:Accrue, :Plug, :RequireEntitlement]}, opts]} =
               ast

      assert opts == [feature: :api_access]
    end
  end

  describe "require_plan/1" do
    test "expands to plug(Accrue.Plug.RequireEntitlement, plan: <atom>)" do
      ast = expand(quote(do: Accrue.Router.require_plan(:pro)))

      assert {:plug, _meta, [{:__aliases__, _, [:Accrue, :Plug, :RequireEntitlement]}, opts]} =
               ast

      assert opts == [plan: :pro]
    end

    test "expands a String.t() plan target verbatim" do
      ast = expand(quote(do: Accrue.Router.require_plan("price_pro")))

      assert {:plug, _meta, [{:__aliases__, _, [:Accrue, :Plug, :RequireEntitlement]}, opts]} =
               ast

      assert opts == [plan: "price_pro"]
    end
  end

  describe "single-arg sugar contract" do
    test "require_feature/1 is exported as a macro of arity 1" do
      assert macro_exported?(Accrue.Router, :require_feature, 1)
      refute macro_exported?(Accrue.Router, :require_feature, 2)
    end

    test "require_plan/1 is exported as a macro of arity 1" do
      assert macro_exported?(Accrue.Router, :require_plan, 1)
      refute macro_exported?(Accrue.Router, :require_plan, 2)
    end
  end
end
