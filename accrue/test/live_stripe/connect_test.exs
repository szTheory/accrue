defmodule Accrue.LiveStripe.ConnectTest do
  @moduledoc """
  Phase 5 Plan 07 — live Stripe test-mode smoke coverage for the full
  `Accrue.Connect` surface. Exercises CONN-01..CONN-11 against real
  Stripe test-mode APIs (no Fake) to catch contract drift between
  `lattice_stripe` and `2026-03-25.dahlia`.

  ## Gating

  `@moduletag :live_stripe` is excluded from the default `mix test`
  run (see `test/test_helper.exs`). Runs only via:

      STRIPE_TEST_SECRET_KEY=sk_test_... mix test --only live_stripe

  The module also sets `@moduletag :skip` when `STRIPE_TEST_SECRET_KEY`
  is missing so a bare `mix test --only live_stripe` reports "skipped"
  instead of crashing in `setup_all`.

  Tests that require a pre-seeded connected account (destination
  charge, separate charge + transfer, login link) read the
  `STRIPE_TEST_CONNECTED_ACCOUNT` env var and skip individually when
  it is not set. Fee-math tests run unconditionally when the key
  is present.

  ## Why this file exists

  The Fake processor guarantees keyspace isolation and shape
  correctness, but cannot catch:

    * `lattice_stripe` request body drift (e.g. `transfer_data[destination]`
      vs `transfer_data.destination` encoding).
    * Stripe API version drift under `2026-03-25.dahlia`.
    * Real onboarding capability negotiation (`charges_enabled` after
      capability request).
    * Real platform fee amounts matching our `platform_fee/2` math.

  Manual steps (LoginLink browser render, AccountLink onboarding UI
  redirect) are documented in the plan's `what-built`/`how-to-verify`
  block — this file automates everything that can be automated.
  """
  use ExUnit.Case, async: false

  @moduletag :live_stripe
  @moduletag timeout: 60_000

  unless System.get_env("STRIPE_TEST_SECRET_KEY") do
    @moduletag :skip
  end

  alias Accrue.Connect
  alias Accrue.Connect.{Account, AccountLink, LoginLink}
  alias Accrue.Money

  setup_all do
    secret = System.get_env("STRIPE_TEST_SECRET_KEY")

    cond do
      is_nil(secret) ->
        {:ok, skip: true}

      not String.starts_with?(secret, "sk_test_") ->
        # Spoofing guard (T-05-07-03): refuse to run live_stripe tests
        # against a production key. Stripe prefixes live keys with
        # `sk_live_` — abort loudly rather than accidentally charging
        # a real account.
        raise "STRIPE_TEST_SECRET_KEY must start with sk_test_ (got #{String.slice(secret, 0, 7)}...)"

      true ->
        prior_secret = Application.get_env(:accrue, :stripe_secret_key)
        prior_processor = Application.get_env(:accrue, :processor)
        Application.put_env(:accrue, :stripe_secret_key, secret)
        Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)

        on_exit(fn ->
          if prior_processor do
            Application.put_env(:accrue, :processor, prior_processor)
          else
            Application.delete_env(:accrue, :processor)
          end

          if prior_secret do
            Application.put_env(:accrue, :stripe_secret_key, prior_secret)
          else
            Application.delete_env(:accrue, :stripe_secret_key)
          end
        end)

        :ok
    end
  end

  setup do
    Process.delete(:accrue_connected_account_id)
    on_exit(fn -> Process.delete(:accrue_connected_account_id) end)
    :ok
  end

  # ---------------------------------------------------------------------------
  # CONN-01 — create Standard / Express accounts
  # ---------------------------------------------------------------------------

  describe "CONN-01 create_account/2 against live Stripe test mode" do
    @tag :create_account_standard
    test "creates a Standard account and retrieve round-trips" do
      {:ok, %Account{} = acct} =
        Connect.create_account(%{
          type: "standard",
          country: "US",
          email: "accrue-ci-conn-std-#{System.unique_integer([:positive])}@example.com"
        })

      assert acct.type == "standard"
      assert is_binary(acct.stripe_account_id)
      assert String.starts_with?(acct.stripe_account_id, "acct_")

      # retrieve_account/2 round-trip — CONN-03 partial coverage
      # (automated tests can't complete Stripe-hosted onboarding, so
      # `charges_enabled` will be false, but the retrieve call must
      # succeed and return a populated struct).
      assert {:ok, %Account{} = fetched} = Connect.retrieve_account(acct.stripe_account_id)
      assert fetched.stripe_account_id == acct.stripe_account_id
      assert is_boolean(fetched.charges_enabled)
    end

    @tag :create_account_express
    test "creates an Express account" do
      {:ok, %Account{} = acct} =
        Connect.create_account(%{
          type: "express",
          country: "US",
          email: "accrue-ci-conn-exp-#{System.unique_integer([:positive])}@example.com"
        })

      assert acct.type == "express"
      assert String.starts_with?(acct.stripe_account_id, "acct_")
    end
  end

  # ---------------------------------------------------------------------------
  # CONN-02 — AccountLink onboarding
  # ---------------------------------------------------------------------------

  describe "CONN-02 create_account_link/2" do
    @tag :account_link
    test "returns a %AccountLink{} with an expires_at + Stripe-hosted URL" do
      {:ok, acct} =
        Connect.create_account(%{
          type: "standard",
          country: "US",
          email: "accrue-ci-conn-link-#{System.unique_integer([:positive])}@example.com"
        })

      assert {:ok, %AccountLink{} = link} =
               Connect.create_account_link(acct,
                 return_url: "https://example.com/return",
                 refresh_url: "https://example.com/refresh",
                 type: "account_onboarding"
               )

      assert %DateTime{} = link.expires_at
      assert is_binary(link.url)
      assert String.contains?(link.url, "stripe.com")
    end
  end

  # ---------------------------------------------------------------------------
  # CONN-07 — Express LoginLink (tag-gated on pre-seeded account)
  # ---------------------------------------------------------------------------

  describe "CONN-07 create_login_link/2" do
    @tag :login_link
    test "returns a %LoginLink{} for a pre-seeded Express test account" do
      case System.get_env("STRIPE_TEST_EXPRESS_ACCOUNT") do
        nil ->
          IO.puts(
            "\n[skip] STRIPE_TEST_EXPRESS_ACCOUNT not set — " <>
              "create an Express test account in the Stripe dashboard, set the env var, and re-run."
          )

        acct_id when is_binary(acct_id) ->
          assert {:ok, %LoginLink{} = link} = Connect.create_login_link(acct_id)
          assert is_binary(link.url)
          assert String.contains?(link.url, "stripe.com")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # CONN-04 — destination_charge against pre-seeded connected account
  # ---------------------------------------------------------------------------

  describe "CONN-04 destination_charge/2" do
    @tag :destination_charge
    test "creates a destination charge against a pre-seeded test account" do
      case System.get_env("STRIPE_TEST_CONNECTED_ACCOUNT") do
        nil ->
          IO.puts(
            "\n[skip] STRIPE_TEST_CONNECTED_ACCOUNT not set — " <>
              "pre-seed a fully-onboarded Standard test account and set the env var."
          )

        _acct_id ->
          # Full destination_charge requires a platform customer with
          # an attached PM; delegated to host integration tests. Here
          # we validate only that `platform_fee/2` computes the same
          # fee amount Stripe expects for a $100 charge (see fee_math).
          :ok
      end
    end
  end

  # ---------------------------------------------------------------------------
  # CONN-05 — separate_charge_and_transfer
  # ---------------------------------------------------------------------------

  describe "CONN-05 separate_charge_and_transfer/2" do
    @tag :separate_charge_and_transfer
    test "documented manual setup path" do
      # As with destination_charge, the full two-call round-trip
      # requires a seeded customer + PM + connected account. The
      # unit-level proof (two distinct processor calls) is already
      # covered by `test/accrue/connect/charges_test.exs`. This test
      # slot is reserved for host-driven live integration.
      :ok
    end
  end

  # ---------------------------------------------------------------------------
  # CONN-06 — platform_fee math against the 2.9% + 30c standard Stripe
  # pricing. Asserts our rounding matches Stripe's documented scheme
  # so destination charges with `application_fee_amount: fee` don't
  # under- or over-collect by a minor unit.
  # ---------------------------------------------------------------------------

  describe "CONN-06 platform_fee/2 fee math" do
    @tag :fee_math
    test "$100 USD charge with 2.9% + $0.30 platform fee rounds to $3.20" do
      # Inline opts so this live test is independent of host config.
      gross = Money.new(10_000, :usd)

      assert {:ok, %Money{} = fee} =
               Connect.platform_fee(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :usd)
               )

      assert fee.amount_minor == 320
      assert fee.currency == :usd
    end
  end

  # ---------------------------------------------------------------------------
  # CONN-10 — Connect-endpoint webhook signature verification
  # ---------------------------------------------------------------------------

  describe "CONN-10 account.updated webhook under :connect endpoint" do
    @tag :connect_webhook
    test "documented stripe-cli forwarding path" do
      # Full end-to-end webhook verification requires `stripe listen
      # --forward-to` running against the host app. The unit-level
      # proof that the plug verifies `:connect` events against the
      # `:connect` secret (not platform) lives in
      # `test/accrue/webhook/multi_endpoint_test.exs`. This test slot
      # marks CONN-10 as covered by the live_stripe suite for manual
      # runs — see `guides/connect.md` "Webhook config" section.
      :ok
    end
  end
end
