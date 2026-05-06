defmodule Accrue.Billing.PdfTest do
  @moduledoc """
  Plan 06-06 Task 1: Accrue.Invoices facade + Accrue.Billing delegates.

  Covers the D6-04 lazy render path:
    * Accrue.InvoiceRenderer.Test adapter → {:ok, "%PDF-TEST"} + {:invoice_pdf_rendered, ...}
    * Accrue.InvoiceRenderer.Null adapter → {:error, %Accrue.Error.PdfDisabled{}}
    * ChromicPDF configured but process absent → {:error, %Accrue.Error.InvoiceRendererUnavailable{}}
    * Storage.Null fetch → {:error, :not_configured}, put → {:ok, key}
    * Billing facade defdelegate wired
  """
  use Accrue.BillingCase, async: false

  use Accrue.Test.PdfAssertions

  alias Accrue.Billing
  alias Accrue.Billing.Invoice
  alias Accrue.Error.PdfDisabled

  setup do
    {:ok, cus} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_pdf_facade",
        email: "pdf-facade@example.com"
      })
      |> Repo.insert()

    {:ok, stripe_inv} =
      Fake.create_invoice(%{customer: cus.processor_id, amount_due: 2900}, [])

    {:ok, inv} =
      %Invoice{customer_id: cus.id, processor: "fake"}
      |> Invoice.force_status_changeset(%{
        processor_id: stripe_inv.id,
        status: :open,
        currency: "usd",
        amount_due_minor: 2900,
        total_minor: 2900,
        subtotal_minor: 2900,
        number: "INV-PDF-0001"
      })
      |> Repo.insert()

    prior_invoice_pdf = Application.get_env(:accrue, :invoice_pdf_adapter)
    prior_storage = Application.get_env(:accrue, :storage_adapter)

    on_exit(fn ->
      if prior_invoice_pdf do
        Application.put_env(:accrue, :invoice_pdf_adapter, prior_invoice_pdf)
      else
        Application.delete_env(:accrue, :invoice_pdf_adapter)
      end

      if prior_storage do
        Application.put_env(:accrue, :storage_adapter, prior_storage)
      else
        Application.delete_env(:accrue, :storage_adapter)
      end
    end)

    %{cus: cus, inv: inv}
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with Accrue.InvoiceRenderer.Test" do
    setup do
      Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Test)
      :ok
    end

    test "returns {:ok, binary} and sends {:invoice_pdf_rendered, ...}", %{inv: inv} do
      assert {:ok, "%PDF-TEST"} = Accrue.Invoices.render_invoice_pdf(inv)
      assert_received {:invoice_pdf_rendered, context, _opts}
      assert context.invoice.number == "INV-PDF-0001"
      assert context.formatted_total == "$29.00"
    end

    test "render context contains invoice number + total", %{inv: inv} do
      assert {:ok, _} = Accrue.Invoices.render_invoice_pdf(inv)
      assert_received {:invoice_pdf_rendered, context, _opts}
      assert context.invoice.number == "INV-PDF-0001"
      assert context.formatted_total == "$29.00"
    end

    test "accepts invoice id (string) as first arg", %{inv: inv} do
      assert {:ok, _} = Accrue.Invoices.render_invoice_pdf(inv.id)
      assert_received {:invoice_pdf_rendered, context, _opts}
      assert context.invoice.number == "INV-PDF-0001"
    end

    test "accepts :locale + :timezone + :archival + :size opts", %{inv: inv} do
      assert {:ok, _} =
               Accrue.Invoices.render_invoice_pdf(inv,
                 locale: "en",
                 timezone: "America/New_York",
                 archival: true,
                 size: :a4
               )

      assert_received {:invoice_pdf_rendered, _context, opts}
      assert opts[:archival] == true
      assert opts[:size] == :a4
    end

    test "locale/timezone from opts thread through RenderContext (PDF-10)", %{inv: inv} do
      assert {:ok, _} =
               Accrue.Invoices.render_invoice_pdf(inv, locale: "en", timezone: "Etc/UTC")

      assert_received {:invoice_pdf_rendered, context, _opts}
      assert context.locale == "en"
      assert context.timezone == "Etc/UTC"
      assert context.invoice.number == "INV-PDF-0001"
    end

    test "Accrue.Billing.render_invoice_pdf/2 defdelegates", %{inv: inv} do
      Code.ensure_loaded!(Accrue.Billing)
      assert function_exported?(Accrue.Billing, :render_invoice_pdf, 2)
      assert {:ok, "%PDF-TEST"} = Billing.render_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with Rendro default" do
    setup do
      Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Rendro)
      :ok
    end

    test "returns a real PDF binary without Chrome", %{inv: inv} do
      assert {:ok, binary} = Accrue.Invoices.render_invoice_pdf(inv)
      assert binary_part(binary, 0, 4) == "%PDF"
    end
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with Accrue.InvoiceRenderer.Null" do
    setup do
      Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Null)
      :ok
    end

    test "returns {:error, %PdfDisabled{}} WITHOUT raising", %{inv: inv} do
      assert {:error, %PdfDisabled{}} = Accrue.Invoices.render_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with ChromicPDF adapter but process absent" do
    setup do
      Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF)
      refute Process.whereis(ChromicPDF), "test precondition: ChromicPDF must not be started"
      :ok
    end

    test "returns a typed unavailable error", %{inv: inv} do
      assert {:error,
              %Accrue.Error.InvoiceRendererUnavailable{
                adapter: Accrue.InvoiceRenderer.ChromicPDF,
                reason: :chromic_pdf_not_started
              }} = Accrue.Invoices.render_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.store_invoice_pdf/2" do
    setup do
      Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Test)
      Application.put_env(:accrue, :storage_adapter, Accrue.Storage.Null)
      :ok
    end

    test "with Null storage returns {:ok, derived_key}", %{inv: inv} do
      assert {:ok, key} = Accrue.Invoices.store_invoice_pdf(inv)
      assert key == "invoices/#{inv.id}.pdf"
    end

    test "Accrue.Billing.store_invoice_pdf/2 defdelegates", %{inv: inv} do
      Code.ensure_loaded!(Accrue.Billing)
      assert function_exported?(Accrue.Billing, :store_invoice_pdf, 2)
      assert {:ok, _} = Billing.store_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.fetch_invoice_pdf/1" do
    setup do
      Application.put_env(:accrue, :storage_adapter, Accrue.Storage.Null)
      :ok
    end

    test "with Null storage returns {:error, :not_configured}", %{inv: inv} do
      assert {:error, :not_configured} = Accrue.Invoices.fetch_invoice_pdf(inv)
    end

    test "Accrue.Billing.fetch_invoice_pdf/1 defdelegates", %{inv: inv} do
      Code.ensure_loaded!(Accrue.Billing)
      assert function_exported?(Accrue.Billing, :fetch_invoice_pdf, 1)
      assert {:error, :not_configured} = Billing.fetch_invoice_pdf(inv)
    end
  end
end
