defmodule AccruePortal.AuthorizeAssertions do
  @moduledoc false

  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  alias AccruePortal.Copy

  @spec assert_subscription_not_found(Plug.Conn.t(), String.t(), String.t()) :: String.t()
  def assert_subscription_not_found(conn, subscription_id, mount_path \\ "/billing")
      when is_binary(subscription_id) and is_binary(mount_path) do
    assert {:ok, _view, html} = live(conn, "#{mount_path}/subscriptions/#{subscription_id}")
    assert html =~ Copy.subscription_not_found_title()
    assert html =~ Copy.subscription_not_found_body()
    html
  end
end
