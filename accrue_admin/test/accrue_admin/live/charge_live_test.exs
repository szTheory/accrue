defmodule AccrueAdmin.ChargeLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Charge, Customer, Refund, Subscription}
  alias Accrue.Events
  alias Accrue.Events.Event
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
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify refund"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, _action), do: :ok
    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    customer =
      insert_customer(%{
        name: "Charge Detail",
        email: "charge-detail@example.com",
        preferred_locale: "en"
      })

    subscription = insert_subscription(customer)

    charge =
      insert_charge(customer, subscription, %{
        processor: "fake",
        processor_id: "ch_detail",
        status: "succeeded",
        amount_cents: 10_000,
        stripe_fee_amount_minor: 300,
        fees_settled_at: DateTime.utc_now(),
        data: %{
          "application_fee_amount" => 200,
          "balance_transaction" => %{"net" => 9_700}
        }
      })

    insert_refund(charge, %{
      stripe_id: "re_seeded",
      amount_minor: 2_500,
      currency: "usd",
      status: :succeeded,
      stripe_fee_refunded_amount_minor: 75,
      merchant_loss_amount_minor: 25
    })

    {:ok, source_event} =
      Events.record(%{
        type: "charge.succeeded",
        subject_type: "Charge",
        subject_id: charge.id,
        actor_type: "system"
      })

    {:ok, charge: charge, source_event: source_event}
  end

  test "renders fee breakdown and existing refund fee fields", %{conn: conn, charge: charge} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/charges/#{charge.id}")

    assert html =~ "Platform fee"
    assert html =~ "merchant loss"
    assert html =~ "fee refunded"
  end

  test "refund initiation requires step-up and records admin refund audit linkage", %{
    conn: conn,
    charge: charge,
    source_event: source_event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/charges/#{charge.id}")

    html =
      render_submit(
        element(view, "[data-role='refund-form']"),
        %{
          "amount_minor" => "4000",
          "reason" => "requested_by_customer",
          "source_event_id" => Integer.to_string(source_event.id)
        }
      )

    assert html =~ "Confirm refund"

    html = render_click(element(view, "[data-role='confirm-refund']"))
    assert html =~ "Step-up required"

    html =
      render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})

    assert html =~ "Refund created with fee-aware fields"

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.charge.refund.completed" and
              event.caused_by_event_id == ^source_event.id
        )
      )

    assert audit_event.actor_type == "admin"

    refund =
      TestRepo.one!(
        from(refund in Refund,
          where: refund.charge_id == ^charge.id and refund.amount_minor == 4_000,
          order_by: [desc: refund.inserted_at],
          limit: 1
        )
      )

    assert refund.amount_minor == 4_000
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer) do
    defaults = %{
      customer_id: customer.id,
      processor: "fake",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Subscription{}
    |> Subscription.changeset(defaults)
    |> TestRepo.insert!()
  end

  defp insert_charge(customer, subscription, attrs) do
    defaults = %{
      customer_id: customer.id,
      subscription_id: subscription.id,
      currency: "usd",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Charge{}
    |> Charge.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_refund(charge, attrs) do
    defaults = %{
      charge_id: charge.id,
      amount_minor: 1_000,
      currency: "usd",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Refund{}
    |> Refund.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end
end
