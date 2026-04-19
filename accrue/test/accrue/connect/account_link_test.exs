defmodule Accrue.Connect.AccountLinkTest do
  use ExUnit.Case, async: true

  alias Accrue.Connect.AccountLink

  @url "https://connect.stripe.test/setup/acct_test_xyz_secret_token"

  describe "from_stripe/1" do
    test "builds struct from atom-keyed map (Fake shape)" do
      link =
        AccountLink.from_stripe(%{
          url: @url,
          expires_at: 1_700_000_300,
          created: 1_700_000_000,
          object: "account_link"
        })

      assert %AccountLink{
               url: @url,
               expires_at: %DateTime{},
               created: %DateTime{},
               object: "account_link"
             } = link

      assert DateTime.to_unix(link.expires_at) == 1_700_000_300
      assert DateTime.to_unix(link.created) == 1_700_000_000
    end

    test "builds struct from string-keyed map (Stripe wire shape)" do
      link =
        AccountLink.from_stripe(%{
          "url" => @url,
          "expires_at" => 1_700_000_300,
          "created" => 1_700_000_000,
          "object" => "account_link"
        })

      assert link.url == @url
      assert %DateTime{} = link.expires_at
      assert %DateTime{} = link.created
    end

    test "defaults :object to account_link when missing" do
      link =
        AccountLink.from_stripe(%{
          url: @url,
          expires_at: 1_700_000_300,
          created: 1_700_000_000
        })

      assert link.object == "account_link"
    end

    test "accepts a LatticeStripe.AccountLink-style struct (Map.from_struct path)" do
      # Use a bare Map.from_struct-style map to avoid a compile dep on
      # LatticeStripe.AccountLink from test code.
      raw = %{
        __struct__: LatticeStripe.AccountLink,
        url: @url,
        expires_at: 1_700_000_300,
        created: 1_700_000_000,
        object: "account_link",
        extra: %{}
      }

      # Exercise the `%_{} = struct` clause via struct/2 on an ad-hoc module.
      dummy_struct =
        Map.put(raw, :__struct__, Accrue.Connect.AccountLinkTest.FakeStripeLink)

      link = AccountLink.from_stripe(dummy_struct)
      assert link.url == @url
    end
  end

  describe "@enforce_keys" do
    test "rejects construction without :url" do
      assert_raise ArgumentError, fn ->
        struct!(AccountLink,
          expires_at: DateTime.utc_now(),
          created: DateTime.utc_now(),
          object: "account_link"
        )
      end
    end

    test "rejects construction without :expires_at" do
      assert_raise ArgumentError, fn ->
        struct!(AccountLink, url: @url, created: DateTime.utc_now(), object: "account_link")
      end
    end
  end

  describe "Inspect masking" do
    test "inspect output contains <redacted> in the :url field" do
      link = %AccountLink{
        url: @url,
        expires_at: DateTime.from_unix!(1_700_000_300),
        created: DateTime.from_unix!(1_700_000_000),
        object: "account_link"
      }

      output = Kernel.inspect(link)

      assert output =~ "url: \"<redacted>\""
      assert output =~ "#Accrue.Connect.AccountLink<"
    end

    test "inspect output does NOT leak the raw url string" do
      link = %AccountLink{
        url: @url,
        expires_at: DateTime.from_unix!(1_700_000_300),
        created: DateTime.from_unix!(1_700_000_000),
        object: "account_link"
      }

      output = Kernel.inspect(link)

      refute output =~ @url
      refute output =~ "secret_token"
      refute output =~ "connect.stripe.test"
    end

    test "nil url is still masked to nil (not the string 'nil')" do
      link = %AccountLink{
        url: nil,
        expires_at: DateTime.from_unix!(1_700_000_300),
        created: DateTime.from_unix!(1_700_000_000),
        object: "account_link"
      }

      assert Kernel.inspect(link) =~ "url: nil"
    end
  end
end

defmodule Accrue.Connect.AccountLinkTest.FakeStripeLink do
  defstruct [:url, :expires_at, :created, :object, extra: %{}]
end
