defmodule Accrue.Emails.HtmlBridgeTest do
  @moduledoc """
  Spike test for the HEEx function component → HTML string bridge.

  Validates RESEARCH Pattern 1 / A1 + A9: that
  `Phoenix.HTML.Safe.to_iodata/1` round-trips a `Phoenix.Component`
  call-result (a `%Phoenix.LiveView.Rendered{}` struct) to a plain
  HTML binary OUTSIDE any LiveView mount context. This is the
  greenfield architectural question the whole plan depends on.
  """

  use ExUnit.Case, async: true

  alias Accrue.Emails.HtmlBridge

  defmodule Trivial do
    @moduledoc false
    use Phoenix.Component

    def trivial(assigns) do
      ~H"<p><%= @name %></p>"
    end

    def nested(assigns) do
      ~H"<div><.trivial name={@name} /></div>"
    end

    def multi_assign(assigns) do
      ~H"<span><%= @label %>: <%= @count %> (<%= @flag %>)</span>"
    end
  end

  describe "render/2 — spike validation" do
    test "renders a trivial function component to a plain HTML string" do
      out = HtmlBridge.render(&Trivial.trivial/1, %{name: "Jo"})
      assert out =~ "<p>"
      assert out =~ "Jo"
      assert out =~ "</p>"
    end

    test "HTML-escapes assigns containing tags" do
      out = HtmlBridge.render(&Trivial.trivial/1, %{name: "<script>alert(1)</script>"})
      refute out =~ "<script>"
      assert out =~ "&lt;script&gt;"
      assert out =~ "&lt;/script&gt;"
    end

    test "nested function components compose" do
      out = HtmlBridge.render(&Trivial.nested/1, %{name: "Nested"})
      assert out =~ "<div>"
      assert out =~ "<p>"
      assert out =~ "Nested"
    end

    test "mixed-type assigns (atom, string, integer) round-trip without crash" do
      out =
        HtmlBridge.render(&Trivial.multi_assign/1, %{
          label: "Count",
          count: 42,
          flag: :active
        })

      assert out =~ "Count"
      assert out =~ "42"
      assert out =~ "active"
    end

    test "render is callable outside a LiveView process (no mount context)" do
      # If Phoenix.HTML.Safe.to_iodata/1 required a LiveView socket or
      # mount context, this call would raise. Assertion: it returns a binary.
      result = HtmlBridge.render(&Trivial.trivial/1, %{name: "plain"})
      assert is_binary(result)
    end
  end
end
