defmodule Accrue.Billing.PaymentMethodDedupTest do
  @moduledoc """
  Plan 06 Task 2: `attach_payment_method/2` fingerprint dedup (BILL-23).

  Same-fingerprint attach → existing row + `existing?: true`.
  Null fingerprint → always insert fresh.
  Concurrent races → partial unique index backstop keeps row count at 1.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, PaymentMethod}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dedup",
        email: "dedup@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  defp scripted_pm(id, fingerprint) do
    %{
      id: id,
      object: "payment_method",
      type: "card",
      card: %{
        fingerprint: fingerprint,
        brand: "visa",
        last4: "4242",
        exp_month: 12,
        exp_year: 2030
      },
      customer: nil
    }
  end

  test "attach unique fingerprint returns existing?: false", %{customer: cus} do
    pm_id = "pm_fake_unique"
    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm(pm_id, "fp_unique_1")})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm(pm_id, "fp_unique_1")})

    assert {:ok, %PaymentMethod{} = pm} = Billing.attach_payment_method(cus, pm_id)
    assert pm.existing? == false
    assert pm.fingerprint == "fp_unique_1"
    assert pm.customer_id == cus.id
  end

  test "attach same fingerprint twice returns existing?: true on second call", %{
    customer: cus
  } do
    pm1 = "pm_fake_first"
    pm2 = "pm_fake_second"
    fp = "fp_dedup_test"

    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm(pm1, fp)})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm(pm1, fp)})

    {:ok, first} = Billing.attach_payment_method(cus, pm1)
    assert first.existing? == false

    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm(pm2, fp)})
    # The dedup path must detach pm2 from Stripe — script that too.
    Fake.scripted_response(:detach_payment_method, {:ok, scripted_pm(pm2, fp)})

    assert {:ok, %PaymentMethod{} = dup} = Billing.attach_payment_method(cus, pm2)
    assert dup.existing? == true
    # The returned row is the pre-existing one
    assert dup.id == first.id
    assert dup.processor_id == pm1

    # DB has exactly one row for this customer+fingerprint
    count =
      Repo.aggregate(
        from(p in PaymentMethod,
          where: p.customer_id == ^cus.id and p.fingerprint == ^fp
        ),
        :count
      )

    assert count == 1
  end

  test "attach PM with fingerprint=nil twice inserts both rows", %{customer: cus} do
    pm1 = "pm_fake_nofp_a"
    pm2 = "pm_fake_nofp_b"

    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm(pm1, nil)})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm(pm1, nil)})
    {:ok, _} = Billing.attach_payment_method(cus, pm1)

    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm(pm2, nil)})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm(pm2, nil)})
    {:ok, _} = Billing.attach_payment_method(cus, pm2)

    count =
      Repo.aggregate(
        from(p in PaymentMethod,
          where: p.customer_id == ^cus.id and is_nil(p.fingerprint)
        ),
        :count
      )

    assert count == 2
  end

  test "detach_payment_method deletes the DB row", %{customer: cus} do
    pm_id = "pm_fake_detach"
    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm(pm_id, "fp_detach")})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm(pm_id, "fp_detach")})

    {:ok, pm} = Billing.attach_payment_method(cus, pm_id)

    Fake.scripted_response(:detach_payment_method, {:ok, scripted_pm(pm_id, "fp_detach")})
    assert {:ok, _} = Billing.detach_payment_method(pm)

    assert Repo.get(PaymentMethod, pm.id) == nil
  end
end
