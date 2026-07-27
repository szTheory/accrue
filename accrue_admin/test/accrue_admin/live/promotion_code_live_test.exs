defmodule AccrueAdmin.PromotionCodeLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias AccrueAdmin.Copy
  alias AccrueAdmin.TestRepo

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
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    coupon =
      insert_coupon(%{
        name: "Referral coupon",
        processor_id: "coupon_referral"
      })

    promotion_code =
      insert_promotion_code(coupon, %{
        code: "REFER15",
        processor_id: "promo_referral",
        active: true,
        metadata: %{"campaign" => "referrals"},
        data: %{"processor" => "stripe"}
      })

    {:ok, promotion_code: promotion_code}
  end

  test "D-02 D-14 D-15 D-16 D-17 renders promotion code summary-first read-only detail contract",
       %{
         conn: conn,
         promotion_code: promotion_code
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    assert heading_count(html, "h1") == 1
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1
    assert data_attr_count(html, "data-ax-action-band") == 0
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 0

    assert html =~ "REFER15"
    assert html =~ "Active state"
    assert html =~ "Code"
    assert html =~ "Parent coupon"
    assert html =~ "Expiry"
    assert html =~ "Redemption count"
    assert html =~ "Redemption limit"
    assert html =~ "Customer restriction"
    assert html =~ Copy.promotion_code_section_navigate_heading()
    assert html =~ "Referral coupon"
    assert html =~ "/billing/coupons/"
    assert html =~ "Open this section to load"

    refute html =~ ~s(class="ax-kpi-grid")
    refute html =~ "campaign"
    refute html =~ "processor"

    assert major_band_order(html) == [
             :summary_card,
             :summary_list,
             :drill_section,
             :related_resources,
             :lazy_activity,
             :lazy_json
           ]
  end

  test "renders RelatedResources card with coupon link and events link", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    # Related resources card must be present
    assert html =~ ~s(class="ax-card ax-related ax-related-resources")
    # Source coupon link in related resources
    assert html =~ "/billing/coupons/#{promotion_code.coupon_id}"
    # Events filtered by PromotionCode subject in related resources
    assert html =~ "subject_type=PromotionCode"
    assert html =~ "subject_id=#{promotion_code.id}"
  end

  test "keeps activity collapsed until the operator opens the marker", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    assert html =~ "Open this section to load activity."
    refute html =~ "This record has no recorded activity yet."

    html = render_click(view, "load_activity", %{})

    assert html =~ "This record has no recorded activity yet."
    assert html =~ "Core details remain available above."
  end

  test "keeps raw promotion code payload collapsed until the operator opens the marker", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    assert html =~ Copy.promotion_code_json_payload_label()
    refute html =~ "campaign"
    refute html =~ "processor"

    html = render_click(view, "load_raw_json", %{})

    assert html =~ "campaign"
    assert html =~ "processor"
  end

  test "renders Detail.summary_card hero not a hand-rolled page header", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    # Detail.summary_card renders ax-summary-card — not a raw ax-page-header standalone element
    assert html =~ "ax-summary-card"
    # Title is rendered in the summary card
    assert html =~ "REFER15"
    # Eyebrow present (from promotion_code_detail_eyebrow)
    assert html =~ Copy.promotion_code_detail_eyebrow()
  end

  test "renders parent coupon section in Detail.detail_section wrapper", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/promotion-codes/#{promotion_code.id}")

    # Detail.detail_section renders ax-detail-section class
    assert html =~ "ax-detail-section"
    # Parent coupon navigate heading
    assert html =~ Copy.promotion_code_section_navigate_heading()
    # Parent coupon link
    assert html =~ "Referral coupon"
  end

  test "breadcrumbs preserve active organization scope", %{
    conn: conn,
    promotion_code: promotion_code
  } do
    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, html} =
             live(conn, "/billing/promotion-codes/#{promotion_code.id}?org=allowed-org")

    assert html =~ ~s(href="/billing?org=allowed-org")
    assert html =~ ~s(href="/billing/promotion-codes?org=allowed-org")
  end

  test "redirects with flash when promotion_code id is not found", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    nonexistent_id = Ecto.UUID.generate()
    result = live(conn, "/billing/promotion-codes/#{nonexistent_id}")

    # Should redirect (not render)
    assert {:error, {:redirect, redirect_info}} = result
    assert redirect_info.to =~ "/billing/promotion-codes"
    # Flash must carry a not-found error message — may be a decoded map or a signed token
    flash =
      case redirect_info[:flash] do
        flash when is_map(flash) ->
          flash

        token when is_binary(token) ->
          Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, token)

        _ ->
          %{}
      end

    assert flash["error"] != nil
  end

  defp insert_coupon(attrs) do
    defaults = %{
      processor: "stripe",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Coupon{}
    |> Coupon.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_promotion_code(coupon, attrs) do
    defaults = %{
      processor: "stripe",
      coupon_id: coupon.id,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %PromotionCode{}
    |> PromotionCode.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
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

  defp major_band_order(html) do
    [
      summary_card: ~s(class="ax-card ax-summary-card"),
      summary_list: "data-ax-summary-list",
      drill_section: ~s(class="ax-detail-section"),
      related_resources: "data-ax-related-resources",
      lazy_activity: "data-ax-lazy-activity",
      lazy_json: "data-ax-lazy-json",
      kpi_grid: ~s(class="ax-kpi-grid")
    ]
    |> Enum.flat_map(fn {band, marker} ->
      case :binary.match(html, marker) do
        :nomatch -> []
        {position, _length} -> [{position, band}]
      end
    end)
    |> Enum.sort()
    |> Enum.map(fn {_position, band} -> band end)
  end
end
