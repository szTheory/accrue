defmodule AccruePortal.WrongTenantPropertyTest do
  use AccruePortal.ConnCase, async: false

  import AccruePortal.AuthorizeAssertions
  import AccruePortal.Fixtures

  @iterations 25

  test "generated wrong-tenant subscription ids always resolve to not-found behavior", %{
    conn: conn
  } do
    %{user: user, subscription: subscription} = subscription_bundle_fixture!()
    conn = sign_in_customer(conn, user)

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")
    assert html =~ subscription.processor_id

    Enum.each(1..@iterations, fn index ->
      %{subscription: foreign_subscription} = foreign_subscription_fixture!(index)
      denied_html = assert_subscription_not_found(conn, foreign_subscription.id)
      refute denied_html =~ foreign_subscription.processor_id
    end)
  end
end
