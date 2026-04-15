defmodule Accrue.Test.PdfAssertionsTest do
  use ExUnit.Case, async: true

  use Accrue.Test.PdfAssertions

  describe "assert_pdf_rendered/2" do
    test "passes on any :pdf_rendered message with no matchers" do
      send(self(), {:pdf_rendered, "<html/>", [size: :a4]})
      {html, opts} = assert_pdf_rendered()
      assert html == "<html/>"
      assert opts == [size: :a4]
    end

    test "flunks when no message within timeout" do
      assert_raise ExUnit.AssertionError, ~r/no PDF rendered within 100ms/, fn ->
        assert_pdf_rendered()
      end
    end

    test ":contains matches substring in html" do
      send(self(), {:pdf_rendered, "<h1>Invoice #123</h1>", []})
      assert_pdf_rendered(contains: "Invoice #123")
    end

    test ":contains flunks when substring absent" do
      send(self(), {:pdf_rendered, "<h1>Receipt</h1>", []})

      assert_raise ExUnit.AssertionError, ~r/did not match/, fn ->
        assert_pdf_rendered(contains: "Invoice")
      end
    end

    test ":matches runs 1-arity predicate on html" do
      send(self(), {:pdf_rendered, "<h1>Invoice #42</h1>", []})
      assert_pdf_rendered(matches: fn html -> String.contains?(html, "Invoice") end)
    end

    test ":opts_include matches keyword subset on opts" do
      send(self(), {:pdf_rendered, "<html/>", [size: :a4, orientation: :portrait]})
      assert_pdf_rendered(opts_include: [size: :a4])
    end

    test ":opts_include flunks when key missing" do
      send(self(), {:pdf_rendered, "<html/>", [orientation: :portrait]})

      assert_raise ExUnit.AssertionError, ~r/did not match/, fn ->
        assert_pdf_rendered(opts_include: [size: :a4])
      end
    end

    test "explicit timeout override accepted" do
      assert_raise ExUnit.AssertionError, ~r/within 500ms/, fn ->
        assert_pdf_rendered([], 500)
      end
    end
  end

  describe "refute_pdf_rendered/2" do
    test "passes when no message within timeout" do
      refute_pdf_rendered()
    end

    test "passes when message is present but matchers don't match" do
      send(self(), {:pdf_rendered, "<html/>", []})
      refute_pdf_rendered(contains: "Invoice")
    end

    test "flunks when matching message received" do
      send(self(), {:pdf_rendered, "<h1>Invoice #42</h1>", [size: :a4]})

      assert_raise ExUnit.AssertionError, ~r/unexpected PDF rendered/, fn ->
        refute_pdf_rendered(contains: "Invoice")
      end
    end
  end
end
