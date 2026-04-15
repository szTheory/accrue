defmodule Accrue.PDF.NullTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Accrue.Error.PdfDisabled
  alias Accrue.PDF.Null

  describe "render/2 direct adapter call" do
    test "returns tagged error with PdfDisabled struct, does not raise" do
      assert {:error, %PdfDisabled{reason: :adapter_disabled} = err} = Null.render("<html/>", [])

      assert err.docs_url == "https://hexdocs.pm/accrue/pdf.html#null-adapter"
    end

    test "does not crash when called repeatedly (Oban-safe)" do
      for _ <- 1..10 do
        assert {:error, %PdfDisabled{}} = Null.render("<html/>", size: :a4)
      end
    end

    test "logs at :debug level only (not :info / :warning)" do
      log =
        capture_log([level: :debug], fn ->
          Null.render("<html/>", [])
        end)

      assert log =~ "Accrue.PDF.Null"
    end

    test "does not emit at :info level" do
      log =
        capture_log([level: :info], fn ->
          Null.render("<html/>", [])
        end)

      refute log =~ "Accrue.PDF.Null: skipping"
    end
  end

  describe "full Accrue.PDF facade with Null adapter" do
    setup do
      prev = Application.get_env(:accrue, :pdf_adapter)
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Null)

      on_exit(fn ->
        if prev do
          Application.put_env(:accrue, :pdf_adapter, prev)
        else
          Application.delete_env(:accrue, :pdf_adapter)
        end
      end)

      :ok
    end

    test "Accrue.PDF.render/2 returns tagged PdfDisabled error through the facade" do
      assert {:error, %PdfDisabled{reason: :adapter_disabled}} =
               Accrue.PDF.render("<html/>", [])
    end
  end
end
