defmodule AccrueAdmin.Components.DunningBannerTest do
  use AccrueAdmin.RepoCase, async: false

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias Accrue.Billing.Subscription
  alias Accrue.Repo
  alias Accrue.Test.Factory
  alias AccrueAdmin.Components.DunningBanner

  defp set_dunning(sub, value) do
    Repo.update_all(
      from(s in Subscription, where: s.id == ^sub.id),
      set: [dunning_campaign_started_at: value]
    )
  end

  describe "dunning_banner/1" do
    test "renders the default message when dunning is active and no inner_block is given" do
      %{customer: customer, subscription: sub} = Factory.active_subscription()
      set_dunning(sub, Accrue.Clock.utc_now())

      html = render_component(&DunningBanner.dunning_banner/1, %{customer: customer})

      assert html =~ "accrue-dunning-banner-wrapper"
      assert html =~ "accrue-default-dunning-banner"
      assert html =~ "Action Required"
      refute html =~ ~s(style=), "inline style= attribute must not appear in dunning banner (DSY-02)"
    end

    test "renders custom inner_block content and suppresses the default message when dunning is active" do
      %{customer: customer, subscription: sub} = Factory.active_subscription()
      set_dunning(sub, Accrue.Clock.utc_now())

      html =
        render_component(
          fn assigns ->
            ~H"""
            <DunningBanner.dunning_banner customer={@customer}>
              CUSTOM CONTENT
            </DunningBanner.dunning_banner>
            """
          end,
          %{customer: customer}
        )

      assert html =~ "accrue-dunning-banner-wrapper"
      assert html =~ "CUSTOM CONTENT"
      refute html =~ "Action Required"
      refute html =~ "accrue-default-dunning-banner"
    end

    test "renders nothing when the customer is not in active dunning" do
      %{customer: customer, subscription: sub} = Factory.active_subscription()
      set_dunning(sub, nil)

      html = render_component(&DunningBanner.dunning_banner/1, %{customer: customer})

      refute html =~ "accrue-dunning-banner-wrapper"
      refute html =~ "Action Required"
      assert String.trim(html) == ""
    end
  end
end
