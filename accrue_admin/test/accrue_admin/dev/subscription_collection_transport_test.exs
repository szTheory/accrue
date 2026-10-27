defmodule AccrueAdmin.Dev.SubscriptionCollectionTransportTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Test.Factory
  alias AccrueAdmin.Dev.Storybook
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
    assert {:ok, view, html} = live(conn, "/billing" <> direct_path)

    assert html =~ ~s(data-ax-page-header)
    assert html =~ ~s(data-ax-page-title)
    assert html =~ ~s(data-ax-page-filter-toolbar)

    rows = Floki.parse_document!(html) |> Floki.find("tbody > tr[data-row-id]")
    assert length(rows) == 1
    assert Floki.text(hd(rows)) =~ "Northstar Research" or Floki.text(hd(rows)) =~ "Juniper Labs"

    [load_more] = Floki.parse_document!(html) |> Floki.find("[data-role=load-more]")
    [target] = Floki.attribute(load_more, "phx-target")
    assert target != ""

    updated_html = view |> element("[data-role=load-more]") |> render_click()
    updated_rows = Floki.parse_document!(updated_html) |> Floki.find("tbody > tr[data-row-id]")
    assert length(updated_rows) == 2

    write_transport_evidence!(direct_path, story)
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
