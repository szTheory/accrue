defmodule Accrue.Error.PdfDisabledTest do
  use ExUnit.Case, async: true

  alias Accrue.Error.PdfDisabled

  describe "raise/struct" do
    test "raises with default message when no message override is supplied" do
      assert_raise PdfDisabled, ~r/PDF rendering disabled/, fn ->
        raise PdfDisabled, reason: :adapter_disabled
      end
    end

    test "raises with custom message exactly when :message override supplied" do
      assert_raise PdfDisabled, "custom boom", fn ->
        raise PdfDisabled, message: "custom boom"
      end
    end

    test "is pattern-matchable on :reason field" do
      err = %PdfDisabled{reason: :adapter_disabled}
      assert %PdfDisabled{reason: r} = err
      assert r == :adapter_disabled
    end

    test "struct supports :docs_url field" do
      err = %PdfDisabled{reason: :adapter_disabled, docs_url: "https://example.test"}
      assert err.docs_url == "https://example.test"
    end

    test "default message/1 mentions Accrue.PDF.Null" do
      assert Exception.message(%PdfDisabled{}) =~ "Accrue.PDF.Null"
    end
  end
end
