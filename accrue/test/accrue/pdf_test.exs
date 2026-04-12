defmodule Accrue.PDFTest do
  @moduledoc """
  Plan 05 Task 2 — Accrue.PDF behaviour + facade + ChromicPDF adapter
  (compile-only) + Test adapter (full functional coverage).

  Phase 1 does NOT exercise the ChromicPDF adapter end-to-end (that would
  require a Chrome binary on CI). We only assert it compiles and conforms
  to the behaviour. The Test adapter covers the behaviour contract fully.
  """

  use ExUnit.Case, async: false

  setup do
    prior = Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)
    Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)
    on_exit(fn -> Application.put_env(:accrue, :pdf_adapter, prior) end)
    :ok
  end

  describe "Accrue.PDF.render/2 via Test adapter" do
    test "returns {:ok, \"%PDF-TEST\"} and sends :pdf_rendered message" do
      assert {:ok, "%PDF-TEST"} = Accrue.PDF.render("<h1>x</h1>", size: :a4)
      assert_received {:pdf_rendered, "<h1>x</h1>", [size: :a4]}
    end

    test "forwards opts untouched to the adapter (:header_html passthrough)" do
      {:ok, _} = Accrue.PDF.render("<p>body</p>", header_html: "<h>top</h>")
      assert_received {:pdf_rendered, "<p>body</p>", opts}
      assert opts[:header_html] == "<h>top</h>"
    end

    test "defaults opts to [] when none supplied" do
      assert {:ok, "%PDF-TEST"} = Accrue.PDF.render("<p/>")
      assert_received {:pdf_rendered, "<p/>", []}
    end
  end

  describe "telemetry" do
    test "emits [:accrue, :pdf, :render, :start|:stop] with PII-safe metadata" do
      ref = make_ref()
      pid = self()

      :telemetry.attach_many(
        "pdf-test-#{inspect(ref)}",
        [
          [:accrue, :pdf, :render, :start],
          [:accrue, :pdf, :render, :stop]
        ],
        fn event, _m, meta, _ -> send(pid, {:telemetry, event, meta}) end,
        nil
      )

      {:ok, _} = Accrue.PDF.render("<html>SENSITIVE</html>", size: :a4, archival: false)

      assert_received {:telemetry, [:accrue, :pdf, :render, :start], start_meta}
      assert_received {:telemetry, [:accrue, :pdf, :render, :stop], _}

      assert start_meta.size == :a4
      assert start_meta.archival == false
      assert start_meta.adapter == Accrue.PDF.Test

      # T-PDF-01: HTML body must never appear in metadata.
      refute Map.has_key?(start_meta, :html)
      refute inspect(start_meta) =~ "SENSITIVE"

      :telemetry.detach("pdf-test-#{inspect(ref)}")
    end
  end

  describe "Accrue.PDF.ChromicPDF (compile-only check)" do
    test "module compiles and declares @behaviour Accrue.PDF" do
      # Just assert the module loads and exports render/2. We do NOT invoke
      # it — Phase 1 tests are Chrome-free.
      assert Code.ensure_loaded?(Accrue.PDF.ChromicPDF)
      assert function_exported?(Accrue.PDF.ChromicPDF, :render, 2)
      behaviours = Accrue.PDF.ChromicPDF.module_info(:attributes)[:behaviour] || []
      assert Accrue.PDF in behaviours
    end

    test "Accrue.PDF.ChromicPDF source does not start ChromicPDF (Pitfall #4)" do
      # We guard against code paths that would start ChromicPDF from
      # inside Accrue. The moduledoc contains example child-spec syntax as
      # documentation for host apps — strip it before scanning.
      source = File.read!("lib/accrue/pdf/chromic_pdf.ex")

      # Strip the moduledoc (which documents host-side child_spec examples)
      # before scanning for actual supervisor-start calls.
      code_only =
        Regex.replace(~r/@moduledoc\s+"""[\s\S]*?"""/m, source, "@moduledoc false")

      refute code_only =~ ~r/ChromicPDF\.start_link/
      refute code_only =~ ~r/use ChromicPDF\b/
      refute code_only =~ ~r/def child_spec/
    end
  end
end
