defmodule AccruePortal.AuthorizeAssertions do
  @moduledoc false

  import ExUnit.Assertions
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias AccruePortal.Copy

  @endpoint AccruePortal.TestEndpoint

  def assert_subscription_not_found(conn, subscription_id) when is_binary(subscription_id) do
    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription_id}")
    assert html =~ Copy.subscription_not_found_title()

    assert html =~
             Phoenix.HTML.safe_to_string(
               Phoenix.HTML.html_escape(Copy.subscription_not_found_body())
             )

    html
  end
end
