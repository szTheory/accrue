defmodule AccrueAdmin.InvoiceLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Invoice, InvoiceItem}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Processor.Fake
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Invoices
  alias AccrueAdmin.TestRepo

  import Ecto.Query

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]

    @impl Accrue.Auth
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify invoice action"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, action) do
      case Application.get_env(:accrue_admin, :expected_step_up_subject_id) do
        nil -> :ok
        expected when action.subject_id == expected -> :ok
        _expected -> {:error, :wrong_subject_id}
      end
    end

    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior_auth = Application.get_env(:accrue, :auth_adapter)
    prior_pdf = Application.get_env(:accrue, :pdf_adapter)

    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior_auth)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)

      if prior_pdf do
        Application.put_env(:accrue, :pdf_adapter, prior_pdf)
      else
        Application.delete_env(:accrue, :pdf_adapter)
      end
    end)

    customer = insert_customer(%{name: "Invoice Detail", email: "invoice-detail@example.com"})

    {:ok, stripe_invoice} =
      Fake.create_invoice(
        %{customer: customer.processor_id, amount_due: 9_900, currency: "usd"},
        []
      )

    invoice =
      insert_invoice(customer, %{
        processor: "fake",
        number: "INV-2000",
        processor_id: stripe_invoice.id,
        status: :draft,
        amount_due_minor: 9_900,
        amount_paid_minor: 0,
        amount_remaining_minor: 9_900,
        total_minor: 9_900,
        automatic_tax_disabled_reason: "finalization_requires_location_inputs",
        last_finalization_error_code: "customer_tax_location_invalid",
        hosted_url: "https://example.test/hosted-invoice",
        pdf_url: "https://example.test/invoice.pdf",
        data: %{
          "customer_address" => %{"line1" => "123 Private Lane"},
          "last_finalization_error" => %{
            "message" => "Raw provider message with address 123 Private Lane"
          }
        }
      })

    insert_invoice_item(invoice, %{
      stripe_id: "ii_1",
      description: "Base plan",
      amount_minor: 9_900,
      currency: "usd",
      quantity: 1
    })

    {:ok, source_event} =
      Events.record(%{
        type: "invoice.created",
        subject_type: "Invoice",
        subject_id: invoice.id,
        actor_type: "system"
      })

    {:ok, invoice: invoice, source_event: source_event}
  end

  test "renders invoice line items and can open the shared PDF render path", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    # UX-02: single ax-page on invoice detail
    assert Regex.scan(~r/class="ax-page"/, html) |> length() == 1

    assert html =~ "Tax &amp; ownership"
    assert html =~ "Base plan"
    assert html =~ "Open PDF"
    assert html =~ "Automatic tax disabled reason: Finalization Requires Location Inputs."
    assert html =~ "Finalization failure code: customer_tax_location_invalid."
    assert html =~ "Repair the customer tax location, then retry finalization from Accrue."
    refute html =~ "Invoice payload"
    refute html =~ "123 Private Lane"

    html = render_click(element(view, "button", "Open PDF"))
    assert html =~ "Open rendered PDF"
    assert html =~ "Download rendered PDF"
  end

  test "void invoice requires step-up and records admin invoice audit rows", %{
    conn: conn,
    invoice: invoice,
    source_event: source_event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, invoice.id)

    {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")

    html =
      render_submit(
        element(view, "[data-role='void-form']"),
        %{"action_type" => "void", "source_event_id" => Integer.to_string(source_event.id)}
      )

    assert html =~ "Confirm action"

    html = render_click(element(view, "[data-role='confirm-action']"))
    assert html =~ "Step-up required"

    html =
      render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})

    assert html =~ "Invoice action recorded."

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.invoice.action.completed" and
              event.caused_by_event_id == ^source_event.id
        )
      )

    assert audit_event.actor_type == "admin"
    assert TestRepo.get!(Invoice, invoice.id).status == :void
  end

  test "invoice loader denies rows outside the active organization" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_invoice = insert_invoice(allowed_customer, %{status: :open, number: "INV-ORG-1"})
    denied_invoice = insert_invoice(denied_customer, %{status: :open, number: "INV-ORG-2"})
    allowed_invoice_id = allowed_invoice.id

    owner_scope = organization_owner_scope("org_allowed")

    assert {:ok, %{id: ^allowed_invoice_id}} = Invoices.detail(allowed_invoice.id, owner_scope)
    assert :not_found = Invoices.detail(denied_invoice.id, owner_scope)
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      preferred_locale: "en"
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      currency: "usd",
      collection_method: "charge_automatically",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Invoice{}
    |> Invoice.force_status_changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_invoice_item(invoice, attrs) do
    defaults = %{
      invoice_id: invoice.id,
      amount_minor: 1_000,
      currency: "usd"
    }

    %InvoiceItem{}
    |> InvoiceItem.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
