defmodule AccrueAdmin.ConnectAccountLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Connect.Account
  alias Accrue.Events.Event
  alias Accrue.Money
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
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify fee override"}

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
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)
    end)

    account =
      insert_account(%{
        stripe_account_id: "acct_override",
        owner_type: "Team",
        owner_id: "team_override",
        type: "express",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        capabilities: %{"transfers" => "active"},
        requirements: %{"currently_due" => ["external_account"]}
      })

    {:ok, account: account}
  end

  test "D-09 D-13 D-14 D-15 D-16 D-17 renders connect summary and fee drawer contract",
       %{conn: conn, account: account} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/connect/#{account.id}")

    assert heading_count(html, "h1") == 1
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-action-band") == 1
    assert data_attr_count(html, "data-ax-primary-action") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1

    for label <- [
          "Last stored Stripe snapshot readiness",
          "Owner",
          "Country",
          "Charges enabled",
          "Payouts enabled",
          "Onboarding / details submitted",
          "Local platform fee override"
        ] do
      assert html =~ label
    end

    assert html =~ "Capabilities / requirements"

    assert html =~
             "Provider readiness, capabilities, and requirements below are the last stored Stripe snapshot"

    assert html =~ "this page does not track when Stripe last reported them"
    assert html =~ "Platform fee policy"
    assert html =~ "Unavailable"

    assert has_element?(view, "[data-ax-primary-action]", "Edit platform fee override")
    refute has_element?(view, "form[phx-submit='save_override']")
    refute has_element?(view, "[data-role='save-override']")
    refute html =~ ~s(class="ax-kpi-grid")
  end

  test "renders RelatedResources card with events link", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/connect/#{account.id}")

    # Related resources card must be present
    assert html =~ ~s(class="ax-card ax-related ax-related-resources")
    # Events filtered by ConnectAccount subject in related resources
    assert html =~ "subject_type=ConnectAccount"
    assert html =~ "subject_id=#{account.id}"
  end

  test "previews and saves a platform fee override on the local account data", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, account.id)

    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")

    html = render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    assert html =~ "Save a per-account fee policy"
    assert html =~ "Default policy"
    assert html =~ "Account under review:"
    assert html =~ account.stripe_account_id
    assert html =~ "Owner under review:"
    assert html =~ "Team team_override"
    assert html =~ "Remove local override; use the global default"

    html =
      render_change(
        element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
        %{
          "override" => %{
            "percent" => "1.9",
            "fixed_cents" => "30",
            "min_cents" => "",
            "max_cents" => "",
            "preview_amount_minor" => "10000",
            "preview_currency" => "usd"
          }
        }
      )

    assert html =~ "$2.20"
    assert html =~ "Current local override:"
    assert html =~ "No override saved"
    assert html =~ "Proposed local override:"
    assert html =~ "1.9% percent · 30 fixed"

    assert {:ok, expected_fee} =
             Accrue.Connect.platform_fee(Money.new(10_000, :usd),
               percent: Decimal.new("1.9"),
               fixed: Money.new(30, :usd)
             )

    assert Money.to_string(expected_fee) == "$2.20"

    html =
      render_submit(
        element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
        %{
          "override" => %{
            "percent" => "1.9",
            "fixed_cents" => "30",
            "min_cents" => "",
            "max_cents" => "",
            "preview_amount_minor" => "10000",
            "preview_currency" => "usd"
          }
        }
      )

    assert html =~ "Step-up required"

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Platform fee override saved."
    assert html =~ "1.9% percent"

    updated = TestRepo.get!(Account, account.id)
    assert updated.data["platform_fee_override"] == %{"percent" => "1.9", "fixed_cents" => "30"}

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.connect.platform_fee_override.updated" and
              event.subject_id == ^account.id
        )
      )

    assert audit_event.actor_type == "admin"
    assert audit_event.actor_id == "admin_1"
  end

  test "explicit zero override remains distinct from an unset override", %{
    conn: conn,
    account: account
  } do
    account =
      account
      |> Account.changeset(%{data: %{"platform_fee_override" => %{"fixed_cents" => "0"}}})
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, html} = live(conn, "/billing/connect/#{account.id}")

    assert html =~ "Stored override:"
    assert html =~ "0 fixed"
    refute html =~ "No override saved"
  end

  test "fee preview applies the domain minimum and maximum clamps without persisting", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")
    render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    html =
      render_change(
        element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
        %{
          "override" => %{
            "percent" => "1.9",
            "fixed_cents" => "500",
            "min_cents" => "300",
            "max_cents" => "400",
            "preview_amount_minor" => "10000",
            "preview_currency" => "usd"
          }
        }
      )

    assert html =~ "$4.00"
    assert TestRepo.get!(Account, account.id).data["platform_fee_override"] == nil
  end

  test "same-value override save preserves independent Stripe observations", %{
    conn: conn,
    account: account
  } do
    account =
      account
      |> Account.changeset(%{
        data: %{
          "charges_enabled" => true,
          "payouts_enabled" => true,
          "details_submitted" => true,
          "platform_fee_override" => %{"percent" => "1.5"}
        }
      })
      |> TestRepo.update!()

    Application.put_env(:accrue_admin, :expected_step_up_subject_id, account.id)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, html} = live(conn, "/billing/connect/#{account.id}")

    assert html =~ "Last stored Stripe snapshot readiness"
    assert html =~ "Local platform fee override"
    assert html =~ "Ready"

    render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    render_submit(
      element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
      %{
        "override" => %{
          "percent" => "1.5",
          "fixed_cents" => "",
          "min_cents" => "",
          "max_cents" => "",
          "preview_amount_minor" => "10000",
          "preview_currency" => "usd"
        }
      }
    )

    assert render_submit(view, "step_up_submit", %{"code" => "123456"}) =~
             "already matches this policy"

    saved = TestRepo.get!(Account, account.id)
    assert saved.data["platform_fee_override"] == %{"percent" => "1.5"}
    assert saved.data["charges_enabled"]
    assert saved.data["payouts_enabled"]
    assert saved.data["details_submitted"]
    assert saved.charges_enabled and saved.payouts_enabled and saved.details_submitted
  end

  test "rejected step-up leaves the local override unchanged", %{conn: conn, account: account} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")

    render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    render_submit(
      element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
      %{
        "override" => %{
          "percent" => "1.9",
          "fixed_cents" => "",
          "min_cents" => "",
          "max_cents" => "",
          "preview_amount_minor" => "10000",
          "preview_currency" => "usd"
        }
      }
    )

    render_submit(view, "step_up_submit", %{"code" => "incorrect"})

    assert TestRepo.get!(Account, account.id).data["platform_fee_override"] == nil
  end

  test "stale current policy invalidates the reviewed fee before persistence", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, account.id)
    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")
    render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    render_submit(
      element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
      override_params("2.5", "40")
    )

    account
    |> Account.changeset(%{data: %{"platform_fee_override" => %{"percent" => "1.25"}}})
    |> TestRepo.update!()

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert html =~ "changed after review"

    assert TestRepo.get!(Account, account.id).data["platform_fee_override"] == %{
             "percent" => "1.25"
           }

    assert TestRepo.aggregate(
             from(event in Event,
               where:
                 event.type == "admin.connect.platform_fee_override.updated" and
                   event.subject_id == ^account.id
             ),
             :count
           ) == 0
  end

  test "invalid fee input and dismissed challenge leave policy and update audit unchanged", %{
    conn: conn,
    account: account
  } do
    account =
      account
      |> Account.changeset(%{data: %{"platform_fee_override" => %{"percent" => "1.5"}}})
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, account.id)
    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")
    render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    invalid_html =
      render_submit(
        element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
        override_params("not-a-decimal", "40")
      )

    assert invalid_html =~ "Percent must be a decimal value"
    refute invalid_html =~ "Step-up required"

    render_submit(
      element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
      override_params("2.5", "40")
    )

    html = render_submit(view, "step_up_dismiss", %{})

    assert TestRepo.get!(Account, account.id).data["platform_fee_override"] == %{
             "percent" => "1.5"
           }

    refute html =~ "Platform fee override saved."

    assert TestRepo.aggregate(
             from(event in Event,
               where:
                 event.type == "admin.connect.platform_fee_override.updated" and
                   event.subject_id == ^account.id
             ),
             :count
           ) == 0
  end

  test "repeat confirmation is idempotent and does not add a second fee audit row", %{
    conn: conn,
    account: account
  } do
    account =
      account
      |> Account.changeset(%{data: %{"platform_fee_override" => %{"percent" => "1.5"}}})
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, account.id)
    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")
    render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    render_submit(
      element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
      override_params("1.5", "")
    )

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert html =~ "already matches this policy"

    assert TestRepo.get!(Account, account.id).data["platform_fee_override"] == %{
             "percent" => "1.5"
           }

    assert TestRepo.aggregate(
             from(event in Event,
               where:
                 event.type == "admin.connect.platform_fee_override.updated" and
                   event.subject_id == ^account.id
             ),
             :count
           ) == 0
  end

  test "applies ax-measure to platform-fee description prose", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/connect/#{account.id}")

    # ax-measure must appear on the platform-fee description paragraph
    assert html =~ ~s(class="ax-body ax-measure")
  end

  test "D-09 preserves save_override form only after Edit platform fee override intent", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/connect/#{account.id}")

    refute html =~ ~s(phx-submit="save_override")
    refute html =~ ~s(data-role="save-override")

    html = render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    assert html =~ ~s(phx-submit="save_override")
    assert html =~ ~s(data-role="save-override")
    assert html =~ ~s(data-ax-action-drawer-form)
  end

  defp insert_account(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      type: "standard",
      country: "US",
      email: "owner@example.com",
      data: %{},
      capabilities: %{},
      requirements: %{},
      lock_version: 1
    }

    %Account{}
    |> Account.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp override_params(percent, fixed) do
    %{
      "override" => %{
        "percent" => percent,
        "fixed_cents" => fixed,
        "min_cents" => "",
        "max_cents" => "",
        "preview_amount_minor" => "10000",
        "preview_currency" => "usd"
      }
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
end
