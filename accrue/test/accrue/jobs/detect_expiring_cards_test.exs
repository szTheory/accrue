defmodule Accrue.Jobs.DetectExpiringCardsTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Jobs.DetectExpiringCards

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_expiring",
        email: "expiring@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  # Compute days remaining from clock `now` until the end of the
  # (year, month), matching DetectExpiringCards.end_of_month/2 semantics.
  defp days_until_end_of_month(now, year, month) do
    last_day = :calendar.last_day_of_the_month(year, month)
    {:ok, dt} = DateTime.new(Date.new!(year, month, last_day), Time.new!(23, 59, 59))
    DateTime.diff(dt, now, :second) |> div(86_400)
  end

  test "emits card.expiring_soon when days_until matches a threshold and dedups on re-run",
       %{customer: customer} do
    now = Accrue.Clock.utc_now()
    target = DateTime.add(now, 25 * 86_400, :second)
    exp_year = target.year
    exp_month = target.month

    {:ok, pm} =
      %PaymentMethod{customer_id: customer.id, processor: "fake"}
      |> PaymentMethod.changeset(%{
        processor_id: "pm_expiring_near",
        type: "card",
        fingerprint: "fp_expiring_near",
        exp_month: exp_month,
        exp_year: exp_year,
        card_brand: "visa",
        card_last4: "4242"
      })
      |> Repo.insert()

    days_out = days_until_end_of_month(now, exp_year, exp_month)
    Application.put_env(:accrue, :expiring_card_thresholds, [days_out])

    test_pid = self()

    :telemetry.attach(
      "test-expiring",
      [:accrue, :billing, :payment_method, :expiring_soon],
      fn _evt, meas, meta, _ -> send(test_pid, {:expiring, meas, meta}) end,
      nil
    )

    try do
      :ok = DetectExpiringCards.scan()
    after
      :telemetry.detach("test-expiring")
    end

    assert_received {:expiring, %{days_until: ^days_out}, %{payment_method_id: pm_id}}
    assert pm_id == pm.id

    # Re-run: events-table dedup should suppress the second emission.
    :telemetry.attach(
      "test-expiring2",
      [:accrue, :billing, :payment_method, :expiring_soon],
      fn _evt, meas, meta, _ -> send(test_pid, {:expiring2, meas, meta}) end,
      nil
    )

    try do
      :ok = DetectExpiringCards.scan()
    after
      :telemetry.detach("test-expiring2")
      Application.delete_env(:accrue, :expiring_card_thresholds)
    end

    refute_received {:expiring2, _, _}
  end

  test "does not emit for PM not near any threshold", %{customer: customer} do
    now = Accrue.Clock.utc_now()
    target = DateTime.add(now, 200 * 86_400, :second)

    {:ok, _pm} =
      %PaymentMethod{customer_id: customer.id, processor: "fake"}
      |> PaymentMethod.changeset(%{
        processor_id: "pm_expiring_far",
        type: "card",
        fingerprint: "fp_expiring_far",
        exp_month: target.month,
        exp_year: target.year,
        card_brand: "visa",
        card_last4: "4242"
      })
      |> Repo.insert()

    test_pid = self()

    :telemetry.attach(
      "test-noexpire",
      [:accrue, :billing, :payment_method, :expiring_soon],
      fn _evt, meas, meta, _ -> send(test_pid, {:never, meas, meta}) end,
      nil
    )

    try do
      :ok = DetectExpiringCards.scan()
    after
      :telemetry.detach("test-noexpire")
    end

    refute_received {:never, _, _}
  end
end
