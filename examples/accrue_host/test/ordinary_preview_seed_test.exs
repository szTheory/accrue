defmodule AccrueHost.OrdinaryPreviewSeedTest do
  use AccrueHost.DataCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice, Subscription}
  alias Accrue.Events.Event
  alias AccrueHost.Repo

  @ordinary_seed Path.expand("../priv/repo/seeds/ordinary.exs", __DIR__)

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    previous_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :dev)
    on_exit(fn -> Application.put_env(:accrue, :env, previous_env) end)

    previous_project = System.get_env("COMPOSE_PROJECT_NAME")
    previous_skip = System.get_env("ACCRUE_HOST_SKIP_SEEDS")
    System.put_env("COMPOSE_PROJECT_NAME", "accrue-host-phase245-ordinary")
    System.put_env("ACCRUE_HOST_SKIP_SEEDS", "1")

    on_exit(fn ->
      if previous_project,
        do: System.put_env("COMPOSE_PROJECT_NAME", previous_project),
        else: System.delete_env("COMPOSE_PROJECT_NAME")

      if previous_skip,
        do: System.put_env("ACCRUE_HOST_SKIP_SEEDS", previous_skip),
        else: System.delete_env("ACCRUE_HOST_SKIP_SEEDS")
    end)

    :ok
  end

  test "ordinary seed reruns keep one coherent invoice journey and exclude Phase 191" do
    seed_if_available()
    first = invoice_journey()

    seed_if_available()
    second = invoice_journey()

    assert first == second
    assert first.invoice_number == "PORTAL-LAUNCH-001"
    assert first.invoice_count == 1
    assert first.customer_count == 1
    assert first.subscription_count == 1
    assert first.amounts == %{subtotal: 1_500, tax: 0, total: 1_500, paid: 1_500, remaining: 0}
    assert first.currency == "usd"
    assert first.customer_owner_type == "User"
    assert first.subscription_status == :active
    assert first.phase191_events == 0
  end

  defp seed_if_available do
    Code.eval_file(@ordinary_seed)
  end

  defp invoice_journey do
    invoice =
      Repo.get_by(Invoice, processor: "fake", processor_id: "in_seed_healthy_portal_launch_paid")

    assert not is_nil(invoice), "expected the ordinary paid invoice journey to be seeded"
    customer = Repo.get!(Customer, invoice.customer_id)
    subscription = Repo.get!(Subscription, invoice.subscription_id)

    invoice_count =
      Repo.aggregate(
        from(row in Invoice,
          where:
            row.processor == "fake" and row.processor_id == "in_seed_healthy_portal_launch_paid"
        ),
        :count
      )

    customer_count =
      Repo.aggregate(from(row in Customer, where: row.id == ^invoice.customer_id), :count)

    subscription_count =
      Repo.aggregate(from(row in Subscription, where: row.id == ^invoice.subscription_id), :count)

    %{
      invoice_number: invoice.number,
      invoice_id: invoice.id,
      invoice_count: invoice_count,
      customer_id: customer.id,
      customer_count: customer_count,
      customer_owner_type: customer.owner_type,
      subscription_id: subscription.id,
      subscription_count: subscription_count,
      subscription_status: subscription.status,
      currency: invoice.currency,
      amounts: %{
        subtotal: invoice.subtotal_minor,
        tax: invoice.tax_minor,
        total: invoice.total_minor,
        paid: invoice.amount_paid_minor,
        remaining: invoice.amount_remaining_minor
      },
      phase191_events:
        Repo.aggregate(
          from(e in Event, where: like(e.idempotency_key, "seed-phase191-%")),
          :count
        )
    }
  end
end
