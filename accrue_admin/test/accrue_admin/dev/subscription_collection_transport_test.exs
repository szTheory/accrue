defmodule AccrueAdmin.Dev.SubscriptionCollectionTransportTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Test.Factory
  alias AccrueAdmin.Dev.Storybook
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Storybook.Groups.SubscriptionsCollection
  alias AccrueAdmin.Storybook.SubscriptionCollectionQuery
  alias PhoenixStorybook.NavigationHelpers
  alias PhoenixStorybook.StoryEntry

  @story_path "/groups/subscriptions_collection"
  @storybook_root "/dev/storybook"

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_253", role: :admin}
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

    :ok
  end

  test "compiled Storybook declares the production subscription collection path" do
    assert [%StoryEntry{path: @story_path}] =
             Enum.filter(Storybook.leaves(), &(&1.path == @story_path))
  end

  test "the compiled one-row story mounts the connected production DataTable", %{conn: conn} do
    assert [%StoryEntry{path: @story_path}] =
             Enum.filter(Storybook.leaves(), &(&1.path == @story_path))

    assert {:ok, story} = Storybook.load_story(String.trim_leading(@story_path, "/"))
    assert inspect(story.storybook_type()) == ":live_component"

    direct_path =
      NavigationHelpers.path_to_story(@storybook_root, String.trim_leading(@story_path, "/"), %{
        variation_id: "one_row"
      })

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _story_view, story_page_html} = live(conn, "/billing" <> direct_path)

    iframe_sources =
      story_page_html
      |> Floki.parse_document!()
      |> Floki.find("iframe")
      |> Enum.flat_map(&Floki.attribute(&1, "src"))

    assert Enum.any?(iframe_sources, &String.contains?(&1, "variation_id=one_row"))

    component_path = story_component_path("one_row")
    assert {:ok, _view, html} = live(conn, "/billing" <> component_path)
    assert html =~ ~s(data-storybook-subscription-state="one_row")
    assert html =~ ~s(data-ax-page-header)
    assert html =~ ~s(data-ax-page-title)
    assert html =~ ~s(data-ax-page-filter-toolbar)

    rows = Floki.parse_document!(html) |> Floki.find("tbody > tr[data-row-id]")
    assert length(rows) == 1
    assert Floki.text(hd(rows)) =~ "Northstar Research" or Floki.text(hd(rows)) =~ "Juniper Labs"
    refute html =~ ~s(data-role="load-more")

    write_transport_evidence!(component_path, story)
  end

  test "the compiled collection story declares all supported settled states" do
    expected_variations =
      MapSet.new(~w(
        new_host_empty
        filtered_empty
        queue_empty
        one_row
        multiple_rows
        page_boundary
        loading
        unavailable
        partial_cursor_error
        incomplete_projection
      ))

    assert MapSet.new(Enum.map(SubscriptionsCollection.variations(), &to_string(&1.id))) ==
             expected_variations

    states = %{
      "new_host_empty" => {"first-run-empty", "first-run"},
      "filtered_empty" => {"filtered-empty", "filter"},
      "queue_empty" => {"filtered-empty", "queue"},
      "one_row" => {"populated", nil},
      "multiple_rows" => {"populated", nil},
      "page_boundary" => {"populated", nil},
      "loading" => {"loading-skeleton", nil},
      "unavailable" => {"unavailable", nil},
      "partial_cursor_error" => {"populated", nil},
      "incomplete_projection" => {"populated", nil}
    }

    for {variation_id, {list_state, empty_reason}} <- states do
      component_path = story_component_path(variation_id)

      story_conn =
        Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

      assert {:ok, view, html} = live(story_conn, "/billing" <> component_path)

      assert html =~ ~s(data-ax-state="#{list_state}")

      if empty_reason do
        assert html =~ ~s(data-ax-empty-reason="#{empty_reason}")
      end

      case variation_id do
        "new_host_empty" ->
          assert html =~ "No subscriptions yet."
          assert html =~ "Subscriptions appear after a customer completes checkout."
          assert Floki.find(Floki.parse_document!(html), "tbody > tr[data-row-id]") == []
          assert subscription_summary_count(html) == "0"

        "filtered_empty" ->
          assert html =~ "No subscriptions match these filters."
          assert html =~ "Clear filters or adjust the search to see subscriptions."
          assert html =~ ~s(data-role="clear-filters")

        "queue_empty" ->
          assert html =~ "Nothing at risk."

          assert html =~
                   "No past-due or canceling subscriptions. View All to see every subscription."

          assert html =~ "View all subscriptions"

        "one_row" ->
          assert length(Floki.find(Floki.parse_document!(html), "tbody > tr[data-row-id]")) == 1
          assert subscription_summary_count(html) == "1"
          assert html =~ "Amount unavailable"

        "multiple_rows" ->
          rows = Floki.find(Floki.parse_document!(html), "tbody > tr[data-row-id]")
          assert length(rows) == 2
          assert length(Enum.uniq(Floki.attribute(rows, "data-row-id"))) == 2
          assert subscription_summary_count(html) == "2"
          refute html =~ ~s(data-role="load-more")

        "page_boundary" ->
          rows = Floki.find(Floki.parse_document!(html), "tbody > tr[data-row-id]")
          assert length(rows) == 1
          assert html =~ ~s(data-role="load-more")

          next_page = view |> element("[data-role='load-more']") |> render_click()
          next_rows = Floki.find(Floki.parse_document!(next_page), "tbody > tr[data-row-id]")
          assert length(next_rows) == 2
          refute next_page =~ ~s(data-role="load-more")
          assert next_page =~ "End of list"

        "loading" ->
          assert html =~ ~s(data-role="loading-skeleton")
          assert html =~ "Loading subscriptions."

        "unavailable" ->
          assert html =~ ~s(data-role="unavailable-state")
          assert html =~ "History unavailable"
          assert html =~ "This history could not be loaded. Try again."
          [retry] = Floki.find(Floki.parse_document!(html), "[data-role='retry-read']")
          assert Floki.text(retry) =~ "Retry"
          assert [target] = Floki.attribute(retry, "phx-target")
          assert target != ""

        "partial_cursor_error" ->
          initial_rows = Floki.find(Floki.parse_document!(html), "tbody > tr[data-row-id]")
          assert length(initial_rows) == 1

          partial = view |> element("[data-role='load-more']") |> render_click()
          assert partial =~ ~s(data-role="partial-read-error")

          assert partial =~
                   "Some results could not be loaded. The rows shown may be incomplete. Try again."

          assert length(Floki.find(Floki.parse_document!(partial), "tbody > tr[data-row-id]")) ==
                   1

          [retry] = Floki.find(Floki.parse_document!(partial), "[data-role='retry-read']")
          assert Floki.text(retry) =~ "Retry loading remaining rows"
          assert [target] = Floki.attribute(retry, "phx-target")
          assert target != ""

          recovered = view |> element("[data-role='retry-read']") |> render_click()

          assert length(Floki.find(Floki.parse_document!(recovered), "tbody > tr[data-row-id]")) ==
                   2

          refute recovered =~ ~s(data-role="partial-read-error")

        "incomplete_projection" ->
          assert html =~ "Amount unavailable"
          assert length(Floki.find(Floki.parse_document!(html), "tbody > tr[data-row-id]")) == 1
      end
    end
  end

  test "page-boundary fixture keeps its one-row cursor contract when query defaults are broader" do
    facts = Enum.map([:launch, :growing_team], &CadenceSubscriptionFacts.fetch!/1)

    owner_scope = %OwnerScope{
      mode: :global,
      current_admin: %{id: "admin_253", role: :admin},
      platform_admin?: true,
      admin_org_ids: Enum.map(facts, & &1.owner.id)
    }

    owner_scope =
      Map.put(owner_scope, :story_collection_context, %{
        state: :page_boundary,
        scenario: :launch,
        instance: "phase253-boundary-regression"
      })

    {rows, next_cursor} = SubscriptionCollectionQuery.list(owner_scope: owner_scope, limit: 25)

    assert length(rows) == 1
    assert is_binary(next_cursor)
  end

  test "page-boundary Storybook route renders one row and the real continuation control", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    component_path = story_component_path("page_boundary")

    assert {:ok, _view, html} = live(conn, "/billing" <> component_path)
    rows = Floki.parse_document!(html) |> Floki.find("tbody > tr[data-row-id]")

    assert length(rows) == 1
    assert html =~ ~s(data-role="load-more")
    assert html =~ ~s(data-pagination-cursor=)
  end

  test "production route uses the scoped Subscriptions query despite query-module input", %{
    conn: conn
  } do
    owner_id = Ecto.UUID.generate()
    outside_owner_id = Ecto.UUID.generate()
    org_slug = "phase253-#{System.unique_integer([:positive])}"
    shared_email = "phase253-scope-#{System.unique_integer([:positive])}@example.test"

    %{subscription: visible_subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: owner_id,
        email: shared_email
      })

    %{subscription: hidden_subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: outside_owner_id,
        email: shared_email
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: owner_id,
        active_organization_slug: org_slug,
        admin_organization_ids: [owner_id]
      )

    params =
      URI.encode_query(%{
        "org" => org_slug,
        "view" => "all",
        "status" => "active",
        "q" => shared_email,
        "query_module" => "AccrueAdmin.Storybook.SubscriptionCollectionQuery"
      })

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?" <> params)
    rows = Floki.parse_document!(html) |> Floki.find("tbody > tr[data-row-id]")

    assert Enum.map(rows, &(Floki.attribute(&1, "data-row-id") |> hd())) == [
             to_string(visible_subscription.id)
           ]

    refute html =~ hidden_subscription.processor_id
    assert html =~ visible_subscription.processor_id
  end

  defp story_component_path(variation_id) do
    NavigationHelpers.path_to_story(
      "#{@storybook_root}/iframe",
      String.trim_leading(@story_path, "/"),
      %{variation_id: variation_id}
    )
  end

  defp subscription_summary_count(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[aria-label='Subscription summary'] .ax-stat-value-text")
    |> hd()
    |> Floki.text()
  end

  defp write_transport_evidence!(direct_path, story) do
    evidence = %{
      schema_version: 1,
      story_path: @story_path,
      direct_path: "/billing" <> direct_path,
      transport_kind: Atom.to_string(story.storybook_type()),
      story_module: inspect(story),
      renderer: "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1",
      query_module: "AccrueAdmin.Storybook.SubscriptionCollectionQuery",
      fact_sources: [
        "CadenceSubscriptionFacts.fetch!(:launch)",
        "CadenceSubscriptionFacts.fetch!(:growing_team)"
      ],
      mounted_event: "load-more targeted to the DataTable LiveComponent"
    }

    path = Path.expand("../../../tmp/phase253/transport.json", __DIR__)
    path |> Path.dirname() |> File.mkdir_p!()
    File.write!(path, Jason.encode!(evidence, pretty: true) <> "\n")
  end
end
