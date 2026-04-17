System.put_env("ACCRUE_HOST_SEED_E2E_NOAUTO", "1")
Code.require_file("../../../../scripts/ci/accrue_host_seed_e2e.exs", __DIR__)
System.delete_env("ACCRUE_HOST_SEED_E2E_NOAUTO")

defmodule AccrueHost.SeedE2ECleanupTest do
  use AccrueHost.DataCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.SubscriptionItem
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Repo

  import Ecto.Query

  @moduletag :phase17

  test "deletes fixture-owned replay rows on rerun and preserves unrelated invoice.payment_failed and admin.webhook.replay.completed rows" do
    fixture_file = Path.join(System.tmp_dir!(), "accrue-host-seed-#{System.unique_integer([:positive])}.json")
    on_exit(fn -> File.rm(fixture_file) end)

    first_fixture = AccrueHostSeedE2E.run!(fixture_file)

    fixture_webhook_id = first_fixture.webhook_id
    fixture_subscription_id = first_fixture.subscription_id

    assert Repo.aggregate(
             from(event in Event,
               where: event.actor_id in ["evt_host_browser_replay", "evt_host_browser_first_run"]
             ),
             :count
           ) == 1

    assert Repo.aggregate(
             from(event in Event,
               where:
                 event.caused_by_webhook_event_id == ^fixture_webhook_id or
                   (event.subject_type == "Subscription" and
                      event.subject_id == ^fixture_subscription_id)
             ),
             :count
           ) == 1

    unrelated = insert_unrelated_rows!()

    second_fixture = AccrueHostSeedE2E.run!(fixture_file)

    assert second_fixture.webhook_id != fixture_webhook_id
    assert second_fixture.subscription_id != fixture_subscription_id

    refute Repo.get(WebhookEvent, fixture_webhook_id)

    refute Repo.exists?(
             from(job in Oban.Job,
               where: fragment("?->>'webhook_event_id'", job.args) == ^fixture_webhook_id
             )
           )

    refute Repo.exists?(
             from(event in Event,
               where:
                 event.caused_by_webhook_event_id == ^fixture_webhook_id or
                   (event.subject_type == "Subscription" and
                      event.subject_id == ^fixture_subscription_id)
             )
           )

    assert Repo.get!(WebhookEvent, unrelated.webhook.id).processor_event_id == "evt_unrelated_replay"

    assert Repo.get!(Oban.Job, unrelated.job.id).args["webhook_event_id"] == unrelated.webhook.id

    assert Repo.get!(Event, unrelated.payment_failed.id).actor_id == "evt_unrelated_invoice"
    assert Repo.get!(Event, unrelated.payment_failed.id).subject_id == unrelated.subscription.id

    assert Repo.get!(Event, unrelated.replay_completed.id).actor_id == "admin-user-42"
    assert Repo.get!(Event, unrelated.replay_completed.id).caused_by_webhook_event_id ==
             unrelated.webhook.id

    assert Repo.exists?(
             from(event in Event,
               where:
                 event.actor_id == "evt_host_browser_replay" and
                   event.caused_by_webhook_event_id == ^second_fixture.webhook_id and
                   event.subject_id == ^second_fixture.subscription_id
             )
           )
  end

  defp insert_unrelated_rows! do
    user = AccountsFixtures.user_fixture(%{email: "unrelated-billing-history@example.test"})

    customer =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: user.id,
        processor: "fake",
        processor_id: "cus_unrelated_replay",
        email: user.email
      })
      |> Repo.insert!()

    subscription =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "fake",
        processor_id: "sub_unrelated_replay",
        status: :active,
        data: %{
          "items" => %{
            "data" => [
              %{"price" => %{"id" => "price_basic"}}
            ]
          }
        }
      })
      |> Repo.insert!()

    %SubscriptionItem{}
    |> SubscriptionItem.changeset(%{
      subscription_id: subscription.id,
      processor: "fake",
      processor_id: "si_unrelated_replay",
      price_id: "price_basic",
      quantity: 1
    })
    |> Repo.insert!()

    webhook =
      %{
        processor: "stripe",
        processor_event_id: "evt_unrelated_replay",
        type: "invoice.payment_failed",
        livemode: false,
        endpoint: :default,
        status: :dead,
        raw_body:
          Jason.encode!(%{
            "id" => "evt_unrelated_replay",
            "type" => "invoice.payment_failed",
            "data" => %{
              "object" => %{
                "id" => "in_unrelated_replay",
                "object" => "invoice",
                "customer" => customer.processor_id,
                "subscription" => subscription.processor_id
              }
            }
          }),
        received_at: DateTime.utc_now(),
        data: %{
          "id" => "evt_unrelated_replay",
          "type" => "invoice.payment_failed",
          "data" => %{
            "object" => %{
              "id" => "in_unrelated_replay",
              "customer" => customer.processor_id,
              "subscription" => subscription.processor_id
            }
          }
        }
      }
      |> WebhookEvent.ingest_changeset()
      |> Repo.insert!()
      |> Ecto.Changeset.change(%{status: :dead})
      |> Repo.update!()

    {:ok, payment_failed} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "webhook",
        actor_id: "evt_unrelated_invoice",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, replay_completed} =
      Events.record(%{
        type: "admin.webhook.replay.completed",
        subject_type: "WebhookEvent",
        subject_id: webhook.id,
        actor_type: "admin",
        actor_id: "admin-user-42",
        caused_by_webhook_event_id: webhook.id
      })

    job =
      Repo.insert!(%Oban.Job{
        state: "discarded",
        queue: "accrue_webhooks",
        worker: "Accrue.Webhook.DispatchWorker",
        args: %{"webhook_event_id" => webhook.id},
        errors: [%{"attempt" => 3, "error" => "unrelated processor timeout"}],
        attempt: 3,
        max_attempts: 25,
        inserted_at: ~U[2026-04-15 10:01:00.000000Z],
        attempted_at: ~U[2026-04-15 10:02:00.000000Z],
        discarded_at: ~U[2026-04-15 10:03:00.000000Z]
      })

    %{
      subscription: subscription,
      webhook: webhook,
      job: job,
      payment_failed: payment_failed,
      replay_completed: replay_completed
    }
  end
end
