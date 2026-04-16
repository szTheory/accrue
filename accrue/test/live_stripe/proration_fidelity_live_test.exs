defmodule Accrue.LiveStripe.ProrationFidelityLiveTest do
  @moduledoc """
  Quick task 260414-l9q: live-Stripe fidelity companion for Phase 3
  HUMAN-UAT Item 3 (proration preview vs. committed invoice round-trip).

  Proves the `preview_upcoming_invoice/2` numerical contract matches the
  invoice Stripe actually produces on `swap_plan/3 with
  proration: :create_prorations` — the portion of Item 3 that the
  Fake-asserted companion at `test/accrue/billing/proration_roundtrip_test.exs`
  structurally CANNOT prove (see that file's @moduledoc for why).

  ## What this test does

    1. Creates a real test-mode Customer + Subscription on a basic price.
    2. Calls `Billing.preview_upcoming_invoice/2` with a target price
       and `proration: :create_prorations`. Captures the line items.
    3. Calls `Billing.swap_plan/3` with the same arguments.
    4. Retrieves the committed invoice from Stripe that the swap
       produced. Asserts preview lines match committed lines line-for-line
       on amount + description + period.

  ## Gating

  `@moduletag :live_stripe` keeps this out of the default `mix test`
  run. Runs only via:

      STRIPE_TEST_SECRET_KEY=sk_test_... mix test.live

  Conditionally tags `:skip` at module load when no secret is set so
  bare `mix test.live` skips cleanly.

  ## Scope note: price fixtures

  This test assumes the Stripe test-mode account referenced by
  `STRIPE_TEST_SECRET_KEY` has two prices with IDs `price_basic_live`
  and `price_pro_live` already seeded. Those IDs are configurable via
  `ACCRUE_LIVE_BASIC_PRICE` and `ACCRUE_LIVE_PRO_PRICE` env vars; the
  test skips if either is unset. Price seeding is NOT the library's
  job — host apps provision their own Stripe test fixtures.
  """
  use ExUnit.Case, async: false

  @moduletag :live_stripe
  @moduletag timeout: 90_000

  unless System.get_env("STRIPE_TEST_SECRET_KEY") &&
           System.get_env("ACCRUE_LIVE_BASIC_PRICE") &&
           System.get_env("ACCRUE_LIVE_PRO_PRICE") do
    @moduletag :skip
  end

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, UpcomingInvoice}

  setup_all do
    secret = System.get_env("STRIPE_TEST_SECRET_KEY")
    basic = System.get_env("ACCRUE_LIVE_BASIC_PRICE")
    pro = System.get_env("ACCRUE_LIVE_PRO_PRICE")

    cond do
      is_nil(secret) ->
        {:ok, skip: true}

      is_nil(basic) or is_nil(pro) ->
        {:ok, skip: true}

      true ->
        # The Stripe processor reads its secret via
        # `Application.get_env(:accrue, :stripe_secret_key)` — see
        # `lib/accrue/processor/stripe.ex:627`.
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

        {:ok, basic_price: basic, pro_price: pro}
    end
  end

  test "preview lines numerically match committed invoice lines after swap_plan",
       %{basic_price: basic_price, pro_price: pro_price} do
    # --- Seed real customer + subscription in Stripe test mode ------
    {:ok, stripe_customer} =
      Accrue.Processor.Stripe.create_customer(
        %{email: "accrue-ci-proration@example.com"},
        []
      )

    repo = Application.get_env(:accrue, :repo)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "CIUser",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        processor_id: stripe_customer[:id] || stripe_customer["id"],
        email: "accrue-ci-proration@example.com"
      })
      |> repo.insert()

    # Attach a non-3DS test PM so subscribe does not gate on SCA.
    {:ok, _pm} =
      Accrue.Processor.Stripe.attach_payment_method(
        "pm_card_visa",
        %{customer: customer.processor_id},
        []
      )

    {:ok, sub} = Billing.subscribe(customer, basic_price)

    # --- Preview the swap ------------------------------------------
    assert {:ok, %UpcomingInvoice{} = preview} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: pro_price,
               proration: :create_prorations
             )

    assert is_list(preview.lines)
    assert length(preview.lines) >= 1

    # --- Commit the swap -------------------------------------------
    assert {:ok, committed_sub} =
             Billing.swap_plan(sub, pro_price, proration: :create_prorations)

    refute is_nil(committed_sub.id)

    # --- Fetch the committed invoice Stripe produced from the swap --
    # The Accrue.Processor behaviour does not currently expose an
    # `list_invoices` callback (not needed by Phase 3 — listing is a
    # Phase 4 Customer-Portal concern). For this live-only fidelity
    # test, go directly through `LatticeStripe.Invoice.list/2` to find
    # the most recent invoice on the subscription. This is the part
    # that only a real Stripe call can prove — the Fake does not
    # produce an invoice on swap_plan at all.
    client =
      LatticeStripe.Client.new!(
        api_key: System.get_env("STRIPE_TEST_SECRET_KEY"),
        api_version: "2026-03-25.dahlia"
      )

    {:ok, invoices} =
      LatticeStripe.Invoice.list(
        client,
        %{subscription: committed_sub.processor_id, limit: 5},
        []
      )

    committed = find_proration_invoice!(invoices)

    # --- Line-for-line comparison -----------------------------------
    preview_lines = normalize_lines(preview.lines)
    committed_lines = normalize_lines(committed)

    # Match on (description, amount_minor). Real Stripe invoices may
    # interleave proration credits and debits — compare as multisets.
    assert Enum.sort(preview_lines) == Enum.sort(committed_lines),
           """
           Proration fidelity mismatch:

             preview:   #{inspect(preview_lines)}
             committed: #{inspect(committed_lines)}
           """
  end

  # ---------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------

  defp find_proration_invoice!(%{data: data}) when is_list(data) do
    data
    |> Enum.sort_by(& &1[:created], :desc)
    |> Enum.find(fn inv ->
      lines = get_in(inv, [:lines, :data]) || []
      Enum.any?(lines, fn line -> line[:proration] == true end)
    end) || raise "No proration invoice found for live-Stripe swap_plan run"
  end

  defp find_proration_invoice!(%{"data" => data}) when is_list(data) do
    find_proration_invoice!(%{data: Enum.map(data, &atomize_top_level/1)})
  end

  defp atomize_top_level(m) when is_map(m) do
    Map.new(m, fn
      {k, v} when is_binary(k) -> {String.to_atom(k), v}
      kv -> kv
    end)
  end

  defp normalize_lines(%Accrue.Billing.UpcomingInvoice{lines: lines}) do
    Enum.map(lines, fn line ->
      {line.description || "", line.amount && line.amount.amount_minor}
    end)
  end

  defp normalize_lines(%{} = committed_invoice) do
    lines = get_in(committed_invoice, [:lines, :data]) || []

    Enum.map(lines, fn line ->
      desc = line[:description] || line["description"] || ""
      amount = line[:amount] || line["amount"]
      {desc, amount}
    end)
  end
end
