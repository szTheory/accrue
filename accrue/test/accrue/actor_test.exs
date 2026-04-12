defmodule Accrue.ActorTest do
  use ExUnit.Case, async: true

  alias Accrue.Actor

  setup do
    Actor.put_current(nil)
    :ok
  end

  describe "put_current/1 and current/0" do
    test "round-trips a valid actor" do
      :ok = Actor.put_current(%{type: :webhook, id: "evt_1"})
      assert %{type: :webhook, id: "evt_1"} = Actor.current()
    end

    test "supports all 5 valid types" do
      for t <- [:user, :system, :webhook, :oban, :admin] do
        :ok = Actor.put_current(%{type: t, id: "x"})
        assert Actor.current().type == t
      end
    end

    test "put_current(nil) clears the dict" do
      Actor.put_current(%{type: :admin, id: "u"})
      Actor.put_current(nil)
      assert is_nil(Actor.current())
    end

    test "invalid type raises (D-15 fixed enum)" do
      assert_raise ArgumentError, ~r/invalid actor type/, fn ->
        Actor.put_current(%{type: :root, id: "evil"})
      end
    end

    test "non-map raises" do
      assert_raise ArgumentError, fn -> Actor.put_current("not-a-map") end
    end
  end

  describe "with_actor/2" do
    test "scopes the actor to the block and restores" do
      Actor.put_current(%{type: :system, id: "sys_1"})

      result =
        Actor.with_actor(%{type: :admin, id: "u_1"}, fn ->
          assert Actor.current().type == :admin
          :inside
        end)

      assert result == :inside
      assert Actor.current().type == :system
    end

    test "restores nil when no prior actor was set" do
      assert is_nil(Actor.current())

      Actor.with_actor(%{type: :oban, id: "job_1"}, fn ->
        assert Actor.current().type == :oban
      end)

      assert is_nil(Actor.current())
    end

    test "restores on exception" do
      assert is_nil(Actor.current())

      assert_raise RuntimeError, fn ->
        Actor.with_actor(%{type: :webhook, id: "x"}, fn ->
          raise "boom"
        end)
      end

      assert is_nil(Actor.current())
    end
  end

  describe "types/0" do
    test "returns the fixed enum" do
      assert Actor.types() == [:user, :system, :webhook, :oban, :admin]
    end
  end
end
