defmodule Accrue.Connect.LoginLinkTest do
  use ExUnit.Case, async: true

  alias Accrue.Connect.LoginLink

  @url "https://connect.stripe.test/express/acct_test_xyz_secret_token"

  describe "from_stripe/1" do
    test "builds struct from atom-keyed map (Fake shape)" do
      link =
        LoginLink.from_stripe(%{
          url: @url,
          created: 1_700_000_000,
          object: "login_link"
        })

      assert %LoginLink{
               url: @url,
               created: %DateTime{},
               object: "login_link"
             } = link

      assert DateTime.to_unix(link.created) == 1_700_000_000
    end

    test "builds struct from string-keyed map (Stripe wire shape)" do
      link =
        LoginLink.from_stripe(%{
          "url" => @url,
          "created" => 1_700_000_000,
          "object" => "login_link"
        })

      assert link.url == @url
      assert %DateTime{} = link.created
    end

    test "defaults :object to login_link when missing" do
      link =
        LoginLink.from_stripe(%{
          url: @url,
          created: 1_700_000_000
        })

      assert link.object == "login_link"
    end
  end

  describe "@enforce_keys" do
    test "rejects construction without :url" do
      assert_raise ArgumentError, fn ->
        struct!(LoginLink, created: DateTime.utc_now())
      end
    end

    test "rejects construction without :created" do
      assert_raise ArgumentError, fn ->
        struct!(LoginLink, url: @url)
      end
    end
  end

  describe "Inspect masking (T-05-03-01)" do
    test "inspect output contains <redacted> in the :url field" do
      link = %LoginLink{
        url: @url,
        created: DateTime.from_unix!(1_700_000_000),
        object: "login_link"
      }

      output = Kernel.inspect(link)

      assert output =~ "url: \"<redacted>\""
      assert output =~ "#Accrue.Connect.LoginLink<"
    end

    test "inspect output does NOT leak the raw url string" do
      link = %LoginLink{
        url: @url,
        created: DateTime.from_unix!(1_700_000_000),
        object: "login_link"
      }

      output = Kernel.inspect(link)

      refute output =~ @url
      refute output =~ "secret_token"
      refute output =~ "connect.stripe.test"
    end
  end
end
