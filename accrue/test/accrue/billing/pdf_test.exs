defmodule Accrue.Billing.PdfTest do
  @moduledoc """
  Plan 06-06 Task 1: Accrue.Invoices facade + Accrue.Billing delegates.

  Covers the D6-04 lazy render path:
    * Accrue.PDF.Test adapter → {:ok, "%PDF-TEST"} + {:pdf_rendered, ...}
    * Accrue.PDF.Null adapter → {:error, %Accrue.Error.PdfDisabled{}}
    * ChromicPDF configured but process absent → {:error, :chromic_pdf_not_started}
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

    prior_pdf = Application.get_env(:accrue, :pdf_adapter)
    prior_storage = Application.get_env(:accrue, :storage_adapter)

    on_exit(fn ->
      if prior_pdf do
        Application.put_env(:accrue, :pdf_adapter, prior_pdf)
      else
        Application.delete_env(:accrue, :pdf_adapter)
      end

      if prior_storage do
        Application.put_env(:accrue, :storage_adapter, prior_storage)
      else
        Application.delete_env(:accrue, :storage_adapter)
      end
    end)

    %{cus: cus, inv: inv}
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with Accrue.PDF.Test" do
    setup do
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)
      :ok
    end

    test "returns {:ok, binary} and sends {:pdf_rendered, ...}", %{inv: inv} do
      assert {:ok, "%PDF-TEST"} = Accrue.Invoices.render_invoice_pdf(inv)
      {html, _opts} = assert_pdf_rendered()
      assert html =~ "INV-PDF-0001"
      assert html =~ "$29.00"
    end

    test "html contains print_shell markup with invoice number + total", %{inv: inv} do
      assert {:ok, _} = Accrue.Invoices.render_invoice_pdf(inv)
      assert_pdf_rendered(contains: "INV-PDF-0001")
    end

    test "accepts invoice id (string) as first arg", %{inv: inv} do
      assert {:ok, _} = Accrue.Invoices.render_invoice_pdf(inv.id)
      assert_pdf_rendered(contains: "INV-PDF-0001")
    end

    test "accepts :locale + :timezone + :archival + :size opts", %{inv: inv} do
      assert {:ok, _} =
               Accrue.Invoices.render_invoice_pdf(inv,
                 locale: "en",
                 timezone: "America/New_York",
                 archival: true,
                 size: :a4
               )

      assert_pdf_rendered(opts_include: [archival: true, size: :a4])
    end

    test "locale/timezone from opts thread through RenderContext (PDF-10)", %{inv: inv} do
      assert {:ok, _} =
               Accrue.Invoices.render_invoice_pdf(inv, locale: "en", timezone: "Etc/UTC")

      {html, _opts} = assert_pdf_rendered()
      # The print_shell includes the invoice number + business_name from branding
      assert html =~ "INV-PDF-0001"
    end

    test "Accrue.Billing.render_invoice_pdf/2 defdelegates", %{inv: inv} do
      Code.ensure_loaded!(Accrue.Billing)
      assert function_exported?(Accrue.Billing, :render_invoice_pdf, 2)
      assert {:ok, "%PDF-TEST"} = Billing.render_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with Accrue.PDF.Null" do
    setup do
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Null)
      :ok
    end

    test "returns {:error, %PdfDisabled{}} WITHOUT raising", %{inv: inv} do
      assert {:error, %PdfDisabled{}} = Accrue.Invoices.render_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.render_invoice_pdf/2 with ChromicPDF adapter but process absent" do
    setup do
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)
      refute Process.whereis(ChromicPDF), "test precondition: ChromicPDF must not be started"
      :ok
    end

    test "returns {:error, :chromic_pdf_not_started}", %{inv: inv} do
      assert {:error, :chromic_pdf_not_started} = Accrue.Invoices.render_invoice_pdf(inv)
    end
  end

  describe "Accrue.Invoices.store_invoice_pdf/2" do
    setup do
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)
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
