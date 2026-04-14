defmodule Accrue.Billing.ProrationRoundtripTest do
  @moduledoc """
  Quick task 260414-l9q: Fake-asserted correctness test for Phase 3
  HUMAN-UAT Item 3 (proration preview vs. committed round-trip).

  ## Scope & limitations

  The Accrue Fake processor synthesizes invoice previews from a static
  generator (`Fake.handle_call({:create_invoice_preview, ...})`, see
  `lib/accrue/processor/fake.ex:701`) — every preview line is a
  deterministic 1000-cent line per requested item, not a real proration
  computation. Swap-plan in the Fake calls `update_subscription` and
  does NOT produce a committed invoice row. This means **a
  numerically-faithful preview-vs-committed comparison against the
  Fake is structurally impossible** — both sides would have to read
  from the same synthetic generator.

  What this test CAN prove (and does prove) is that the preview →
  swap_plan → preview pipeline stays continuously wired:

    1. `preview_upcoming_invoice/2` with `new_price_id` + `proration:
       :create_prorations` returns `{:ok, %UpcomingInvoice{}}` with
       typed `Accrue.Money` totals and a non-empty lines list, and the
       preview reflects the requested target price.
    2. `swap_plan/3` with `proration: :create_prorations` succeeds and
       returns `{:ok, %Subscription{}}`.
    3. A subsequent `preview_upcoming_invoice/2` call on the committed
       subscription returns a stable, typed preview — proving the Fake
       stays coherent across the two calls and the projection layer
       does not drop data on the swap path.

  The numerical-fidelity portion of HUMAN-UAT Item 3 is covered by
  the live-Stripe companion at
  `test/live_stripe/proration_fidelity_live_test.exs`, which runs
  against real Stripe test mode and compares preview lines vs. the
  invoice Stripe actually produces after `swap_plan`.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, UpcomingInvoice}
  alias Accrue.Money

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_proration_roundtrip",
        email: "proration@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    %{customer: customer, sub: sub}
  end

  test "preview → swap_plan → preview round-trip stays coherent", %{sub: sub} do
    # --- Leg 1: preview the swap ------------------------------------
    assert {:ok, %UpcomingInvoice{} = preview} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: "price_pro",
               proration: :create_prorations
             )

    assert is_list(preview.lines)
    assert length(preview.lines) >= 1
    assert %Money{} = preview.total
    assert %Money{} = preview.subtotal
    assert preview.total.currency == :usd

    # Preview reflects the target price on the line (Fake's generator
    # echoes new_price_id back into the line description/price_id).
    assert Enum.any?(preview.lines, fn line ->
             (line.description || "") =~ "price_pro" or line.price_id == "price_pro"
           end)

    # --- Leg 2: commit the swap with the same proration setting -----
    assert {:ok, committed_sub} =
             Billing.swap_plan(sub, "price_pro", proration: :create_prorations)

    assert committed_sub.id == sub.id

    # --- Leg 3: re-preview the committed subscription ---------------
    # Keep the pipeline continuity invariant honest: after swap, the
    # projection layer must still produce a typed preview without
    # choking on the post-swap state.
    assert {:ok, %UpcomingInvoice{} = post_preview} =
             Billing.preview_upcoming_invoice(committed_sub, proration: :create_prorations)

    assert is_list(post_preview.lines)
    assert %Money{} = post_preview.total
    assert %Money{} = post_preview.subtotal
    assert post_preview.total.currency == :usd
  end

  test "preview with :none proration still returns a typed preview", %{sub: sub} do
    # D3-22 / BILL-09: callers MUST specify :proration explicitly on
    # swap_plan. The preview API mirrors the same keyword but is more
    # lenient (defaults to :create_prorations). Exercise the :none
    # branch so it stays wired through the projection.
    assert {:ok, %UpcomingInvoice{} = preview} =
             Billing.preview_upcoming_invoice(sub,
               new_price_id: "price_pro",
               proration: :none
             )

    assert is_list(preview.lines)
    assert %Money{} = preview.total
  end
end
