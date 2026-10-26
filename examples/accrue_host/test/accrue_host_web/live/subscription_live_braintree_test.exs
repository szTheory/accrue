if System.get_env("ACCRUE_HOST_BROWSER_USE_BRAINTREE") == "1" do
  defmodule AccrueHostWeb.SubscriptionLiveBraintreeTest do
    use AccrueHostWeb.ConnCase, async: false

    import Phoenix.LiveViewTest

    alias Accrue.Billing.Customer
    alias Accrue.Checkout.LocalSession
    alias AccrueHost.Accounts.{OrganizationMembership, Scope}
    alias AccrueHost.AccountsFixtures
    alias AccrueHost.Billing
    alias AccrueHost.Billing.Plans
    alias AccrueHost.Repo

    setup do
      assert Accrue.Processor.name() == "braintree"

      user = AccountsFixtures.user_fixture()
      organization = AccountsFixtures.organization_fixture(%{owner: user})
      customer = insert_customer!(organization, user)

      membership =
        Repo.get_by!(OrganizationMembership, user_id: user.id, organization_id: organization.id)

      %{user: user, organization: organization, customer: customer, membership: membership}
    end

    test "completed scoped Braintree LocalSession renders an honest completion", %{
      conn: conn,
      user: user,
      organization: organization,
      customer: customer
    } do
      plan = Plans.get("price_basic")
      selection_id = Ecto.UUID.generate()
      session = insert_session!(customer, organization, plan, selection_id)
      session_count = Repo.aggregate(LocalSession, :count)
      return_path = return_path(plan.id, selection_id)

      {:ok, view, _html} =
        conn
        |> log_in_user(user, active_organization_id: organization.id)
        |> live(return_path)

      assert render(view) =~ "Checkout completed"

      for _ <- 1..2 do
        {:ok, repeated_view, _html} =
          Phoenix.ConnTest.build_conn()
          |> log_in_user(user, active_organization_id: organization.id)
          |> live(return_path)

        assert render(repeated_view) =~ "Checkout completed"
      end

      assert Repo.get!(LocalSession, session.id).status == "completed"
      assert Repo.aggregate(LocalSession, :count) == session_count
    end

    test "Braintree handoff uses a local plan selection return without a Stripe placeholder", %{
      conn: conn,
      user: user,
      organization: organization,
      customer: customer
    } do
      selection_id = Ecto.UUID.generate()
      operation_id = "pricing:#{organization.id}:price_basic:#{selection_id}"

      {:ok, view, _html} =
        conn
        |> log_in_user(user, active_organization_id: organization.id)
        |> live("/app/billing?plan=price_basic&selection=#{selection_id}")

      assert render(view) =~ "Checkout link"

      session = Repo.get_by!(LocalSession, customer_id: customer.id, operation_id: operation_id)
      query = session.success_url |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      assert query["checkout"] == "success"
      assert query["plan"] == "price_basic"
      assert query["selection"] == selection_id
      refute Map.has_key?(query, "checkout_session_id")
      refute session.success_url =~ "{CHECKOUT_SESSION_ID}"
    end

    for status <- ["open", "processing", "uncertain", "rejected"] do
      test "#{status} LocalSession never claims Braintree completion", %{
        conn: conn,
        user: user,
        organization: organization,
        customer: customer
      } do
        plan = Plans.get("price_basic")
        selection_id = Ecto.UUID.generate()
        insert_session!(customer, organization, plan, selection_id, status: unquote(status))

        {:ok, view, _html} =
          conn
          |> log_in_user(user, active_organization_id: organization.id)
          |> live(return_path(plan.id, selection_id))

        html = render(view)
        refute html =~ "Checkout completed"
        refute html =~ "Payment confirmed by the provider"
        assert html =~ "billing status" or html =~ "support"
      end
    end

    test "foreign customer and forged plan or selection locators stay unavailable", %{
      user: user,
      organization: organization,
      customer: customer
    } do
      plan = Plans.get("price_basic")
      selection_id = Ecto.UUID.generate()
      insert_session!(customer, organization, plan, selection_id)

      foreign_organization = AccountsFixtures.organization_fixture(%{owner: user})
      foreign_customer = insert_customer!(foreign_organization, user)
      foreign_selection_id = Ecto.UUID.generate()

      insert_session!(foreign_customer, foreign_organization, plan, foreign_selection_id)

      for locator <- [
            return_path(plan.id, foreign_selection_id),
            return_path("price_pro", selection_id),
            return_path(plan.id, Ecto.UUID.generate()),
            "/app/billing?checkout=success&plan=price_basic&selection=not-a-uuid"
          ] do
        {:ok, view, _html} =
          Phoenix.ConnTest.build_conn()
          |> log_in_user(user, active_organization_id: organization.id)
          |> live(locator)

        html = render(view)
        refute html =~ "Checkout completed"
        refute html =~ "Payment confirmed by the provider"
      end
    end

    test "fresh billing permission is required even when a prior scope allowed checkout", %{
      user: user,
      organization: organization,
      customer: customer,
      membership: membership
    } do
      plan = Plans.get("price_basic")
      selection_id = Ecto.UUID.generate()
      insert_session!(customer, organization, plan, selection_id)
      scope = %Scope{user: user, active_organization: organization, membership: membership}

      membership
      |> Ecto.Changeset.change(role: :member)
      |> Repo.update!()

      assert {:error, :forbidden} =
               Billing.checkout_session_for_scope(
                 scope,
                 operation_id(organization, plan, selection_id)
               )
    end

    defp insert_customer!(organization, user) do
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "Organization",
        owner_id: to_string(organization.id),
        processor: "braintree",
        processor_id: "cus_bt_host_#{Ecto.UUID.generate()}",
        email: user.email
      })
      |> Repo.insert!()
    end

    defp insert_session!(customer, organization, plan, selection_id, overrides \\ []) do
      attrs = %{
        processor: "braintree",
        mode: "subscription",
        ui_mode: "hosted",
        status: "completed",
        price_id: plan.id,
        line_items: [
          %{
            "price" => plan.id,
            "quantity" => 1,
            "amount_minor" => plan.unit_amount_minor,
            "currency" => plan.currency,
            "interval" => Atom.to_string(plan.billing_cycle.unit),
            "interval_count" => plan.billing_cycle.count
          }
        ],
        success_url: return_path(plan.id, selection_id),
        operation_id: operation_id(organization, plan, selection_id),
        metadata: %{
          "billable_type" => "Organization",
          "billable_id" => to_string(organization.id),
          "processor" => "braintree",
          "plan_id" => plan.id,
          "selection_id" => selection_id,
          "amount_minor" => plan.unit_amount_minor,
          "currency" => plan.currency,
          "interval" => Atom.to_string(plan.billing_cycle.unit),
          "interval_count" => plan.billing_cycle.count
        }
      }

      {:ok, session} =
        LocalSession.create_or_reuse(customer, Map.merge(attrs, Map.new(overrides)))

      session
    end

    defp operation_id(organization, plan, selection_id),
      do: "pricing:#{organization.id}:#{plan.id}:#{selection_id}"

    defp return_path(plan_id, selection_id) do
      "/app/billing?" <>
        URI.encode_query(%{checkout: "success", plan: plan_id, selection: selection_id})
    end
  end
end
