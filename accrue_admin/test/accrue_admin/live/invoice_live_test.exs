defmodule AccrueAdmin.InvoiceLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Invoice, InvoiceItem}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Processor.Fake
  alias AccrueAdmin.Copy
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
    prior_invoice_pdf = Application.get_env(:accrue, :invoice_pdf_adapter)

    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    Application.put_env(:accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.Test)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior_auth)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)

      if prior_invoice_pdf do
        Application.put_env(:accrue, :invoice_pdf_adapter, prior_invoice_pdf)
      else
        Application.delete_env(:accrue, :invoice_pdf_adapter)
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

  test "D-10 D-14 D-15 D-16 D-17 renders invoice summary-first detail contract", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    assert heading_count(html, "h1") == 1
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-action-band") == 1
    assert data_attr_count(html, "data-ax-primary-action") <= 2
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1

    refute has_element?(view, "[data-ax-action-band] form")
    refute has_element?(view, "form[phx-submit='add_manual_item']")
    refute has_element?(view, "[data-role='confirm-panel']")

    assert html =~ "Status"
    assert html =~ "Customer"
    assert html =~ "Amount due"
    assert html =~ "Amount remaining"
    assert html =~ "Amount paid"
    assert html =~ "Collection method"
    assert html =~ "Document state"
    assert html =~ "Tax risk"
    assert html =~ "Line items"
    assert html =~ "Collection and actions"
    assert html =~ "Tax and documents"

    refute html =~ ~s(class="ax-kpi-grid")
  end

  test "invoice action fixture retains the scoped target and raw money contract", %{
    conn: conn,
    invoice: invoice
  } do
    customer = TestRepo.get!(Customer, invoice.customer_id)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert invoice.status == :draft
    assert invoice.amount_due_minor == 9_900
    assert invoice.currency == "usd"
    assert customer.owner_type == "User"
    assert is_binary(customer.owner_id)

    assert {:ok, view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    assert has_element?(view, "[data-ax-primary-action]", Copy.Invoice.invoice_action_finalize())
    assert html =~ "INV-2000"
    assert invoice.customer_id == customer.id
  end

  test "payment review shows exact amount and cancels when amount or currency changes", %{
    conn: conn,
    invoice: invoice
  } do
    invoice =
      invoice
      |> Invoice.changeset(%{
        status: :open,
        amount_remaining_minor: 9_900,
        amount_due_minor: 9_900
      })
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")

    render_click(element(view, "button", Copy.Invoice.invoice_action_manual_pay()))

    html =
      render_submit(
        element(view, "form[data-action-type='pay']"),
        %{"action_type" => "pay"}
      )

    assert html =~ "99.00"
    assert html =~ "(usd)"

    invoice
    |> Invoice.changeset(%{amount_remaining_minor: 10_100, currency: "eur"})
    |> TestRepo.update!()

    html = render_click(element(view, "button[data-role='confirm-action']"))

    refute Enum.any?(Fake.calls(), fn {operation, _args} -> operation == :pay_invoice end)
    assert html =~ "changed"
    assert TestRepo.get!(Invoice, invoice.id).amount_remaining_minor == 10_100
  end

  test "step-up continuation cancels when invoice leaves the reviewed owner scope", %{
    conn: conn,
    invoice: invoice
  } do
    customer =
      TestRepo.get!(Customer, invoice.customer_id)
      |> Customer.changeset(%{owner_type: "Organization", owner_id: "reviewed-invoice-org"})
      |> TestRepo.update!()

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "reviewed-invoice-org",
        active_organization_slug: "reviewed-invoice-org",
        admin_organization_ids: ["reviewed-invoice-org"]
      )

    Application.put_env(:accrue_admin, :expected_step_up_subject_id, invoice.id)

    assert {:ok, view, _html} =
             live(conn, "/billing/invoices/#{invoice.id}?org=reviewed-invoice-org")

    render_click(element(view, "button[role='menuitem']", Copy.Invoice.invoice_action_void()))

    render_submit(
      element(view, "form[data-action-type='void']"),
      %{"action_type" => "void"}
    )

    render_click(view, "confirm_action", %{})

    customer
    |> Customer.changeset(%{owner_id: "changed-invoice-org"})
    |> TestRepo.update!()

    result = render_submit(view, "step_up_submit", %{"code" => "123456"})

    refute Enum.any?(Fake.calls(), fn {operation, _args} -> operation == :void_invoice end)
    assert match?({:error, {:redirect, _redirect}}, result)
    assert TestRepo.get!(Invoice, invoice.id).status == :draft
  end

  test "payment result is tied to the refreshed scoped invoice and duplicate confirm is inert", %{
    conn: conn,
    invoice: invoice
  } do
    invoice =
      invoice
      |> Invoice.changeset(%{status: :open, amount_remaining_minor: 9_900})
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")
    render_click(element(view, "button", Copy.Invoice.invoice_action_manual_pay()))

    render_submit(element(view, "form[data-action-type='pay']"), %{"action_type" => "pay"})

    html = render_click(element(view, "button[data-role='confirm-action']"))

    assert html =~ "processor returned a successful payment response"
    assert html =~ "current scoped invoice reports Paid"
    refute html =~ "settlement confirmed"
    assert TestRepo.get!(Invoice, invoice.id).status == :paid

    render_click(view, "confirm_action", %{})

    assert Enum.count(Fake.calls(), fn {operation, _args} -> operation == :pay_invoice end) == 1
  end

  test "finalization result names the refreshed invoice state", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")
    render_click(element(view, "button", Copy.Invoice.invoice_action_finalize()))

    render_submit(
      element(view, "form[data-action-type='finalize']"),
      %{"action_type" => "finalize"}
    )

    html = render_click(element(view, "button[data-role='confirm-action']"))

    assert html =~ "processor returned success for Finalize invoice"
    assert html =~ "current scoped invoice reports Open"
    refute html =~ "processor settlement"
    assert TestRepo.get!(Invoice, invoice.id).status == :open
  end

  test "requires-action payment result stays distinct from a completed invoice", %{
    conn: conn,
    invoice: invoice
  } do
    invoice =
      invoice
      |> Invoice.changeset(%{
        status: :open,
        amount_remaining_minor: 9_900,
        data: %{
          "payment_intent" => %{
            "id" => "pi_review_required",
            "object" => "payment_intent",
            "status" => "requires_action",
            "next_action" => %{"type" => "use_stripe_sdk"}
          }
        }
      })
      |> TestRepo.update!()

    assert {:ok, stripe_invoice} = Fake.retrieve_invoice(invoice.processor_id)

    :ok =
      Fake.scripted_response(
        :pay_invoice,
        {:ok,
         Map.merge(stripe_invoice, %{
           status: "open",
           amount_due: 9_900,
           amount_remaining: 9_900,
           amount_paid: 0,
           payment_intent: %{
             id: "pi_review_required",
             object: "payment_intent",
             status: "requires_action",
             next_action: %{type: "use_stripe_sdk"}
           }
         })}
      )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")
    render_click(element(view, "button", Copy.Invoice.invoice_action_manual_pay()))
    render_submit(element(view, "form[data-action-type='pay']"), %{"action_type" => "pay"})

    html = render_click(element(view, "button[data-role='confirm-action']"))

    assert html =~ "Customer action is required"
    assert html =~ "payment is not complete"
    refute html =~ "payment response"
    assert TestRepo.get!(Invoice, invoice.id).status == :open
  end

  test "definitive card decline is distinct from an ambiguous processor outcome", %{
    conn: conn,
    invoice: invoice
  } do
    invoice =
      invoice
      |> Invoice.changeset(%{status: :open, amount_remaining_minor: 9_900})
      |> TestRepo.update!()

    :ok =
      Fake.scripted_response(
        :pay_invoice,
        {:error, %Accrue.CardError{code: "card_declined", message: "card declined"}}
      )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")
    render_click(element(view, "button", Copy.Invoice.invoice_action_manual_pay()))
    render_submit(element(view, "form[data-action-type='pay']"), %{"action_type" => "pay"})

    html = render_click(element(view, "button[data-role='confirm-action']"))

    assert html =~ "processor declined"
    assert html =~ "No payment was accepted"
    refute html =~ "Outcome not confirmed"
    assert TestRepo.get!(Invoice, invoice.id).status == :open
  end

  test "ambiguous payment error stays unconfirmed and is not automatically retried", %{
    conn: conn,
    invoice: invoice
  } do
    invoice =
      invoice
      |> Invoice.changeset(%{status: :open, amount_remaining_minor: 9_900})
      |> TestRepo.update!()

    :ok =
      Fake.scripted_response(
        :pay_invoice,
        {:error, %Accrue.APIError{code: "rate_limit", http_status: 429, message: "rate limited"}}
      )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")
    render_click(element(view, "button", Copy.Invoice.invoice_action_manual_pay()))

    render_submit(element(view, "form[data-action-type='pay']"), %{"action_type" => "pay"})

    html = render_click(element(view, "button[data-role='confirm-action']"))

    assert html =~ "Outcome not confirmed"
    assert html =~ "will not retry automatically"
    refute html =~ "processor declined"

    render_click(view, "confirm_action", %{})

    assert Enum.count(Fake.calls(), fn {operation, _args} -> operation == :pay_invoice end) == 1
  end

  test "invoice detail preserves supported money precision, unavailable evidence, and overdue separation",
       %{
         conn: conn,
         invoice: invoice
       } do
    now = Accrue.Clock.utc_now()
    customer = TestRepo.get!(Customer, invoice.customer_id)

    _customer =
      customer
      |> Customer.changeset(%{name: "顧客 🧾 Long Name"})
      |> TestRepo.update!()

    invoice =
      invoice
      |> Invoice.changeset(%{
        number: "INV-精密-🧾-0001",
        status: :open,
        currency: "jpy",
        amount_due_minor: 1_234,
        amount_remaining_minor: 1_234,
        amount_paid_minor: 0,
        due_date: DateTime.add(now, -1, :second)
      })
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    assert html =~ "顧客 🧾 Long Name"
    assert html =~ "INV-精密-🧾-0001"
    assert html =~ "Open"
    assert html =~ "Overdue"
    assert html =~ "1,234"
    refute html =~ "1,234.00"
    assert html =~ "Due"

    invoice =
      invoice
      |> Invoice.changeset(%{
        currency: "kwd",
        amount_due_minor: 1_234,
        amount_remaining_minor: 1_234,
        amount_paid_minor: 0
      })
      |> TestRepo.update!()

    assert {:ok, _view, kwd_html} = live(conn, "/billing/invoices/#{invoice.id}")
    assert kwd_html =~ "1.234"

    invoice =
      invoice
      |> Invoice.changeset(%{
        currency: "usd",
        amount_due_minor: 0,
        amount_remaining_minor: 0,
        amount_paid_minor: 0
      })
      |> TestRepo.update!()

    assert {:ok, _view, zero_html} = live(conn, "/billing/invoices/#{invoice.id}")
    assert zero_html =~ "$0.00"

    invoice =
      invoice
      |> Invoice.changeset(%{
        currency: "zzz",
        amount_due_minor: 1_234,
        amount_remaining_minor: nil,
        amount_paid_minor: 0
      })
      |> TestRepo.update!()

    assert {:ok, _view, unavailable_html} = live(conn, "/billing/invoices/#{invoice.id}")
    assert unavailable_html =~ "--"
    refute unavailable_html =~ "$12.34"

    invoice =
      invoice
      |> Invoice.changeset(%{
        currency: nil,
        amount_due_minor: 1_234,
        amount_remaining_minor: 1_234,
        amount_paid_minor: 0
      })
      |> TestRepo.update!()

    assert {:ok, _view, missing_currency_html} = live(conn, "/billing/invoices/#{invoice.id}")
    assert missing_currency_html =~ "--"
    refute missing_currency_html =~ "$12.34"
  end

  test "invoice contextual return rebuilds active owner scope and rejects foreign customer origin",
       %{
         conn: conn,
         invoice: invoice
       } do
    customer =
      TestRepo.get!(Customer, invoice.customer_id)
      |> Customer.changeset(%{owner_type: "Organization", owner_id: "invoice-return-org"})
      |> TestRepo.update!()

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "invoice-return-org",
        active_organization_slug: "invoice-return-org",
        admin_organization_ids: ["invoice-return-org"]
      )

    foreign_customer_id = Ecto.UUID.generate()
    raw_origin = "/billing/customers/#{foreign_customer_id}?org=foreign-org&tab=payments"

    assert {:ok, view, html} =
             live(
               conn,
               "/billing/invoices/#{invoice.id}?org=invoice-return-org&return_to=#{URI.encode_www_form(raw_origin)}"
             )

    refute html =~ foreign_customer_id

    back_href =
      view
      |> element("a", "Back to results")
      |> render()
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> hd()

    assert URI.parse(back_href).path == "/billing/invoices"
    assert URI.decode_query(URI.parse(back_href).query)["org"] == "invoice-return-org"

    own_origin = "/billing/customers/#{customer.id}?org=foreign-org&tab=payments"

    assert {:ok, view, _html} =
             live(
               conn,
               "/billing/invoices/#{invoice.id}?org=invoice-return-org&return_to=#{URI.encode_www_form(own_origin)}"
             )

    back_href =
      view
      |> element("a", "Back to results")
      |> render()
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> hd()

    back_params = URI.parse(back_href).query |> URI.decode_query()
    assert back_params["org"] == "invoice-return-org"
    assert back_params["tab"] == "payments"
    refute back_href =~ "foreign-org"
  end

  test "D-10 D-11 D-12 D-13 invoice danger actions stay overflow-owned and step-up gated",
       %{
         conn: conn,
         invoice: invoice
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, invoice.id)

    assert {:ok, view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    assert has_element?(view, "[data-ax-primary-action]", Copy.Invoice.invoice_action_finalize())
    assert data_attr_count(html, "data-ax-primary-action") <= 2
    assert html =~ "Danger zone"

    assert_text_order(html, [
      "Danger zone",
      Copy.Invoice.invoice_action_void(),
      Copy.Invoice.invoice_action_mark_uncollectible()
    ])

    refute has_element?(view, "[data-ax-action-band] [data-role='void-form']")
    refute has_element?(view, "[data-ax-action-band] [data-role='mark-uncollectible-form']")

    html =
      render_click(element(view, "button[role='menuitem']", Copy.Invoice.invoice_action_void()))

    refute TestRepo.get!(Invoice, invoice.id).status == :void
    assert html =~ Copy.step_up_title()
  end

  test "D-13 collectible invoices prioritize pay and keep danger actions in overflow", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    customer = TestRepo.get!(Customer, invoice.customer_id)

    open_invoice =
      insert_invoice(customer, %{
        status: :open,
        number: "INV-OPEN",
        amount_due_minor: 9_900,
        amount_paid_minor: 0,
        amount_remaining_minor: 9_900,
        total_minor: 9_900,
        hosted_url: nil,
        pdf_url: nil
      })

    assert {:ok, _view, html} = live(conn, "/billing/invoices/#{open_invoice.id}")

    assert data_attr_count(html, "data-ax-primary-action") <= 2
    assert html =~ "Pay invoice"
    refute html =~ Copy.Invoice.invoice_action_add_line_item()
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 1

    assert_text_order(html, [
      "Danger zone",
      Copy.Invoice.invoice_action_void(),
      Copy.Invoice.invoice_action_mark_uncollectible()
    ])
  end

  test "D-10 invoice overflow is absent when no valid overflow actions exist", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    customer = TestRepo.get!(Customer, invoice.customer_id)

    paid_invoice =
      insert_invoice(customer, %{
        status: :paid,
        number: "INV-PAID",
        amount_due_minor: 9_900,
        amount_paid_minor: 9_900,
        amount_remaining_minor: 0,
        total_minor: 9_900,
        hosted_url: nil,
        pdf_url: nil
      })

    assert {:ok, _view, html} = live(conn, "/billing/invoices/#{paid_invoice.id}")

    assert data_attr_count(html, "data-ax-primary-action") == 0
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 0
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
    assert html =~ AccrueAdmin.Copy.Invoice.invoice_open_pdf_button()
    assert html =~ "Automatic tax disabled reason: Finalization Requires Location Inputs."
    assert html =~ "Finalization failure code: customer_tax_location_invalid."
    assert html =~ AccrueAdmin.Copy.Invoice.invoice_tax_recovery_body()
    refute html =~ "Invoice payload"
    refute html =~ "123 Private Lane"

    customer = TestRepo.get!(Customer, invoice.customer_id)
    assert html =~ ~s(href="/billing/customers/#{customer.id}")

    # Related card must use /payments not /charges
    assert html =~ "/billing/payments"
    refute html =~ ~s(href="/billing/charges)

    html = render_click(element(view, "button", "Open PDF"))
    assert html =~ "Open rendered PDF"
    assert html =~ "Download rendered PDF"
    assert html =~ Copy.invoice_pdf_open_info()
  end

  test "void invoice requires step-up and records admin invoice audit rows", %{
    conn: conn,
    invoice: invoice,
    source_event: source_event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, invoice.id)

    {:ok, view, _html} = live(conn, "/billing/invoices/#{invoice.id}")

    render_click(element(view, "button[role='menuitem']", Copy.Invoice.invoice_action_void()))

    assert has_element?(
             view,
             "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='void-form']"
           )

    html =
      render_submit(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='void-form']"
        ),
        %{
          "action_type" => "mark_uncollectible",
          "source_event_id" => Integer.to_string(source_event.id)
        }
      )

    assert html =~ AccrueAdmin.Copy.Invoice.invoice_confirm_panel_label()

    html = render_click(element(view, "[data-role='confirm-action']"))
    assert html =~ Copy.step_up_title()

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "current scoped invoice reports Void"
    refute html =~ Copy.invoice_action_recorded_info()

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.invoice.action.completed" and
              event.caused_by_event_id == ^source_event.id
        )
      )

    assert audit_event.actor_type == "admin"
    assert audit_event.data["action_type"] == "void"
    assert TestRepo.get!(Invoice, invoice.id).status == :void
  end

  test "can add and remove manual line items on draft invoice", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    assert html =~ Copy.invoice_empty_manual_items_heading()
    refute has_element?(view, "form[phx-submit='add_manual_item']")

    render_click(element(view, "button", "Add line item"))

    assert has_element?(
             view,
             "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='add-line-item-form']"
           )

    html =
      render_submit(
        element(view, "form[phx-submit='add_manual_item']"),
        %{
          "new_item_form" => %{
            "description" => "Custom setup fee",
            "amount_minor" => "50000",
            "currency" => "usd"
          }
        }
      )

    assert html =~ "Custom setup fee"
    assert html =~ Copy.invoice_manual_row_badge()
    assert html =~ Copy.invoice_add_manual_item_success()

    html = render_click(element(view, "button", "Remove"))
    assert html =~ Copy.invoice_remove_manual_item_confirm()

    html = render_click(element(view, "button", "Confirm"))
    assert html =~ Copy.invoice_remove_manual_item_success()
  end

  test "applies ax-measure to tax-risk prose paragraphs", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, _view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    # tax-risk panel prose paragraphs must have ax-measure for reading-width constraint
    assert html =~ ~s(class="ax-body ax-measure")
  end

  test "applies ax-measure to actions body paragraph", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, _view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    # The actions-body paragraph in the actions header must use ax-body ax-measure
    assert html =~ AccrueAdmin.Copy.Invoice.invoice_actions_body()
    # It must be wrapped with ax-measure
    assert html =~ ~s(class="ax-body ax-measure")
  end

  test "does NOT apply ax-measure to field-lists or json_viewer", %{
    conn: conn,
    invoice: invoice
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, _view, html} = live(conn, "/billing/invoices/#{invoice.id}")

    # ax-measure must NEVER be applied to ax-field-list containers or json_viewer
    refute html =~ ~s(ax-field-list ax-measure)
    refute html =~ ~s(json_viewer ax-measure)
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

  test "out-of-scope invoice route redirects with denial flash before rendering detail", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    allowed_invoice =
      insert_invoice(allowed_customer, %{status: :open, number: "INV-ORG-ALLOWED"})

    denied_invoice = insert_invoice(denied_customer, %{status: :open, number: "INV-ORG-DENIED"})

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, allowed_html} =
             live(conn, "/billing/invoices/#{allowed_invoice.id}?org=allowed-org")

    assert allowed_html =~ "INV-ORG-ALLOWED"

    assert {:error, {:redirect, %{to: "/billing/invoices?org=allowed-org", flash: flash_token}}} =
             redirect =
             live(conn, "/billing/invoices/#{denied_invoice.id}?org=allowed-org")

    assert %{"error" => denied} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert denied == Copy.Locked.owner_access_denied()
    assert redirect
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

  defp data_attr_count(html, attr) do
    attr
    |> Regex.escape()
    |> then(&Regex.compile!("\\b" <> &1 <> "(?:\\s|=|>)"))
    |> Regex.scan(html)
    |> length()
  end

  defp heading_count(html, tag) do
    tag
    |> Regex.escape()
    |> then(&Regex.compile!("<" <> &1 <> "\\b"))
    |> Regex.scan(html)
    |> length()
  end

  defp assert_text_order(html, labels) do
    positions =
      Enum.map(labels, fn label ->
        case :binary.match(html, label) do
          :nomatch -> flunk("expected #{inspect(label)} to be present in rendered HTML")
          {position, _length} -> {label, position}
        end
      end)

    positions
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [{left_label, left_position}, {right_label, right_position}] ->
      assert left_position < right_position,
             "expected #{inspect(left_label)} to render before #{inspect(right_label)}"
    end)
  end
end
