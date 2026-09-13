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
    4. Materializes the queued proration items into a Stripe draft invoice.
       Asserts preview lines match committed lines line-for-line on amount
       and description.

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
  use Accrue.RepoCase, async: false

  @moduletag :live_stripe
  @moduletag timeout: 90_000

  unless Enum.all?(
           [
             System.get_env("STRIPE_TEST_SECRET_KEY", ""),
             System.get_env("ACCRUE_LIVE_BASIC_PRICE", ""),
             System.get_env("ACCRUE_LIVE_PRO_PRICE", "")
           ],
           &(String.trim(&1) != "")
         ) do
    @moduletag :skip
  end

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, UpcomingInvoice}

  setup_all do
    secret = System.get_env("STRIPE_TEST_SECRET_KEY", "") |> String.trim()
    basic = System.get_env("ACCRUE_LIVE_BASIC_PRICE", "") |> String.trim()
    pro = System.get_env("ACCRUE_LIVE_PRO_PRICE", "") |> String.trim()

    cond do
      secret == "" ->
        {:ok, skip: true}

      basic == "" or pro == "" ->
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
    {:ok, attached_pm} =
      Accrue.Processor.Stripe.attach_payment_method(
        "pm_card_visa",
        %{customer: customer.processor_id},
        []
      )

    attached_pm_id = attached_pm[:id] || attached_pm["id"]

    {:ok, sub} =
      Billing.subscribe(customer, basic_price, default_payment_method: attached_pm_id)

    # `Billing.subscribe/3` intentionally creates Stripe subscriptions with
    # `payment_behavior=default_incomplete`. Pay the first invoice before
    # attempting a plan swap; Stripe rejects item changes that would create
    # another invoice while the initial subscription is incomplete. Dahlia's
    # Invoice shape no longer exposes the legacy `payment_intent` field here,
    # so exercise the invoice payment action directly.
    client = stripe_client()
    first_invoice_id = get_in(sub.data, ["latest_invoice", "id"])

    assert is_binary(first_invoice_id),
           "Expected an expanded latest_invoice on the subscription"

    assert {:ok, %{status: :paid}} =
             LatticeStripe.Invoice.pay(
               client,
               first_invoice_id,
               %{"payment_method" => attached_pm_id}
             )

    assert {:ok, %{status: :active}} =
             LatticeStripe.Subscription.retrieve(client, sub.processor_id)

    proration_date = System.system_time(:second)

    # --- Preview the swap ------------------------------------------
    assert {:ok, %UpcomingInvoice{} = preview} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: pro_price,
               proration: :create_prorations,
               proration_date: proration_date
             )

    assert is_list(preview.lines)
    assert length(preview.lines) >= 1

    # --- Commit the swap -------------------------------------------
    assert {:ok, committed_sub} =
             Billing.swap_plan(sub, pro_price,
               proration: :create_prorations,
               proration_date: proration_date
             )

    refute is_nil(committed_sub.id)

    # `create_prorations` queues invoice items instead of forcing an immediate
    # invoice. Materialize those subscription-scoped pending items into a draft
    # invoice so this proof compares previewed math with committed Stripe data.
    assert {:ok, committed} =
             LatticeStripe.Invoice.create(client, %{
               "auto_advance" => false,
               "customer" => customer.processor_id,
               "subscription" => committed_sub.processor_id
             })

    # --- Line-for-line comparison -----------------------------------
    preview_lines =
      preview.lines
      |> Enum.filter(& &1.proration?)
      |> normalize_preview_lines()

    committed_lines =
      committed
      |> committed_invoice_lines()
      |> Enum.filter(&proration_line?/1)
      |> normalize_committed_lines()

    assert preview_lines != []
    assert committed_lines != []

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

  defp stripe_client do
    LatticeStripe.Client.new!(
      api_key: System.get_env("STRIPE_TEST_SECRET_KEY"),
      api_version: "2026-03-25.dahlia"
    )
  end

  defp normalize_preview_lines(lines) do
    Enum.map(lines, fn line ->
      {line.description || "", line.amount && line.amount.amount_minor}
    end)
  end

  defp normalize_committed_lines(lines) do
    Enum.map(lines, fn line ->
      desc = line[:description] || line["description"] || ""
      amount = line[:amount] || line["amount"]
      {desc, amount}
    end)
  end

  defp committed_invoice_lines(%{lines: %{data: lines}}) when is_list(lines), do: lines
  defp committed_invoice_lines(%{"lines" => %{"data" => lines}}) when is_list(lines), do: lines

  defp proration_line?(line) do
    parent = field(line, :parent) || line |> field(:extra) |> field(:parent)

    details =
      field(parent, :invoice_item_details) ||
        field(parent, :subscription_item_details)

    field(line, :proration) == true || field(details, :proration) == true
  end

  defp field(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
  defp field(_, _), do: nil
end
