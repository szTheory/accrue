defmodule Accrue.Entitlements.AppleNotificationTest do
  use Accrue.RepoCase, async: false

  import Plug.Test

  alias Accrue.Entitlements.Apple.NotificationPlug

  defmodule FakeVerifier do
    def verify_notification("verified", _config) do
      {:ok,
       %{
         notification: %{"notificationUUID" => "notification-1"},
         transaction: %{
           "originalTransactionId" => "original-1",
           "transactionId" => "transaction-1",
           "productId" => "product_pro"
         },
         renewal: %{}
       }}
    end

    def verify_notification("quarantine", _config), do: {:error, :invalid_payload}
    def verify_notification("retry", _config), do: {:error, :provider_unavailable}
  end

  test "acknowledges verified notifications only after durable intake" do
    conn = request("verified") |> NotificationPlug.call(base_opts())

    assert conn.status == 200
  end

  defp request(body), do: conn(:post, "/apple/notifications", body) |> Plug.Conn.assign(:raw_body, [body])

  defp base_opts do
    NotificationPlug.init(
      verifier: FakeVerifier,
      verifier_config: %{},
      repo: Accrue.TestRepo,
      rate_limiter: fn _conn -> :allow end
    )
  end
end
