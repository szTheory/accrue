defmodule AccrueAdmin.WebhookReplayTest do
  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Events.Event
  alias Accrue.Webhooks.DLQ
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.TestRepo

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]

    @impl Accrue.Auth
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify webhook replay"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, _action), do: :ok
    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    prior_requeue_fun = Application.get_env(:accrue_admin, :webhook_requeue_fun)
    prior_detail_fun = Application.get_env(:accrue_admin, :webhook_replay_detail_fun)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior)

      if prior_requeue_fun do
        Application.put_env(:accrue_admin, :webhook_requeue_fun, prior_requeue_fun)
      else
        Application.delete_env(:accrue_admin, :webhook_requeue_fun)
      end

      if prior_detail_fun do
        Application.put_env(:accrue_admin, :webhook_replay_detail_fun, prior_detail_fun)
      else
        Application.delete_env(:accrue_admin, :webhook_replay_detail_fun)
      end
    end)

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_single",
        type: "invoice.payment_failed",
        status: :dead
      })

    bulk_one =
      insert_webhook(%{
        processor_event_id: "evt_bulk_1",
        type: "invoice.payment_failed",
        status: :dead
      })

    bulk_two =
      insert_webhook(%{
        processor_event_id: "evt_bulk_2",
        type: "invoice.payment_failed",
        status: :failed
      })

    {:ok, webhook: webhook, bulk_webhooks: [webhook, bulk_one, bulk_two]}
  end

  test "single replay requeues the webhook and records admin audit linkage", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")

    _ = render_click(element(view, "[data-role='replay-single']"))
    challenge = render_click(element(view, "[data-role='confirm-replay']"))
    assert challenge =~ "Step-up required"
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert html =~ "Webhook replay requested."

    updated = TestRepo.get!(WebhookEvent, webhook.id)
    assert updated.status == :received

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.webhook.replay.completed" and
              event.subject_id == ^webhook.id
        )
      )

    assert audit_event.actor_type == "admin"
    assert audit_event.caused_by_webhook_event_id == webhook.id
  end

  test "replay claims a delivery once and keeps one active dispatch job", %{webhook: webhook} do
    assert {:ok, %{status: :received}} = DLQ.requeue(webhook.id)
    assert {:error, :not_dead_lettered} = DLQ.requeue(webhook.id)

    jobs =
      TestRepo.all(
        from(job in Oban.Job,
          where:
            job.worker == "Accrue.Webhook.DispatchWorker" and
              fragment("?->>'webhook_event_id' = ?", job.args, ^webhook.id)
        )
      )

    assert length(jobs) == 1
  end

  test "selection-driven retry confirms once and records one admin audit event", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/webhooks?type=invoice.payment_failed")

    audit_count_before =
      TestRepo.aggregate(
        from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
        :count,
        :id
      )

    # Exercise one selected row through the parent bulk-selection message.
    send(view.pid, {:data_table_bulk_action, "retry_selected", [webhook.id]})
    confirmation = render(view)
    assert confirmation =~ "Only deliveries still eligible when confirmed will be queued"
    assert confirmation =~ "Queue acceptance does not mean processing is complete"
    assert confirmation =~ "Queue eligible deliveries"
    assert confirmation =~ webhook.id
    assert confirmation =~ "Reviewed for Global admin"

    challenge = render_click(element(view, "[data-role='confirm-retry-selected']"))
    assert challenge =~ "Step-up required"
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead

    assert dispatch_jobs(webhook.id) == []
    refute TestRepo.exists?(from(event in Event, where: event.type == "webhook.replay_requested"))

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert html =~ "Queued 1 delivery"
    refute html =~ "processed"

    audit_count_after =
      TestRepo.aggregate(
        from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
        :count,
        :id
      )

    assert audit_count_after == audit_count_before + 1

    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received

    _ = render_click(view, "confirm_retry_selected")
    _ = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert TestRepo.aggregate(
             from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
             :count,
             :id
           ) == audit_count_before + 1

    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received
  end

  test "rejected bulk step-up leaves the selected delivery untouched and records no replay completion",
       %{
         conn: conn,
         webhook: webhook
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    send(view.pid, {:data_table_bulk_action, "retry_selected", [webhook.id]})
    _ = render(view)
    _ = render_click(element(view, "[data-role='confirm-retry-selected']"))

    html = render_submit(view, "step_up_submit", %{"code" => "000000"})

    assert html =~ "Step-up verification failed"
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert dispatch_jobs(webhook.id) == []

    assert TestRepo.aggregate(
             from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
             :count,
             :id
           ) == 0
  end

  test "empty selection opens no confirmation and records no replay completion", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")

    send(view.pid, {:data_table_bulk_action, "retry_selected", []})
    html = render(view)

    refute html =~ ~s(data-role="bulk-replay-confirm")
    assert html =~ "Select at least one delivery to replay first."

    assert TestRepo.aggregate(
             from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
             :count,
             :id
           ) == 0
  end

  test "duplicate ids collapse and mixed ineligible rows produce exact ordered audit outcomes", %{
    conn: conn,
    webhook: webhook,
    bulk_webhooks: [_webhook, eligible, ineligible]
  } do
    fixed_time = ~U[2026-01-01 12:00:00.000000Z]
    webhook = set_received_at(webhook, fixed_time)
    eligible = set_received_at(eligible, fixed_time)
    ineligible = set_received_at(ineligible, fixed_time)

    ineligible
    |> Ecto.Changeset.change(status: :received)
    |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=failed,dead")
    html = submit_selection(view, [eligible.id, webhook.id, eligible.id, ineligible.id])

    assert html =~ "Queued 2 deliveries. 1 skipped; 0 denied; 0 failed; 0 unknown."
    refute html =~ "processed successfully"

    event = bulk_replay_event!()
    assert event.data["selected"] == 3
    assert event.data["eligible"] == 2
    assert event.data["attempted"] == 2
    assert event.data["queued"] == 2
    assert event.data["skipped"] == 1
    assert event.data["denied"] == 0
    assert outcome_total(event.data) == event.data["selected"]
    assert event.data["failed"] == 0

    assert Enum.map(event.data["outcomes"], & &1["id"]) ==
             Enum.sort([webhook.id, eligible.id, ineligible.id], :desc)

    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received
    assert TestRepo.get!(WebhookEvent, eligible.id).status == :received
    assert TestRepo.get!(WebhookEvent, ineligible.id).status == :received
  end

  test "status changed after selection is skipped without a queue attempt", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    send(view.pid, {:data_table_bulk_action, "retry_selected", [webhook.id]})
    _ = render(view)

    webhook
    |> Ecto.Changeset.change(status: :succeeded)
    |> TestRepo.update!()

    _ = render_click(element(view, "[data-role='confirm-retry-selected']"))
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "No eligible deliveries were queued. 1 skipped; 0 denied; 0 failed; 0 unknown."
    event = bulk_replay_event!()
    assert event.data["eligible"] == 0
    assert event.data["attempted"] == 0
    assert event.data["queued"] == 0
    assert event.data["skipped"] == 1
    assert outcome_total(event.data) == event.data["selected"]
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :succeeded
  end

  test "foreign owner selection is skipped without recording its id in replay audit data", %{
    conn: conn
  } do
    foreign_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_foreign"})
    foreign_invoice = insert_invoice(foreign_customer, %{processor_id: "in_foreign_webhook"})

    foreign_webhook =
      insert_webhook(%{
        processor_event_id: "evt_foreign_bulk",
        status: :dead,
        data: %{"object" => %{"id" => foreign_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_foreign_bulk",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => foreign_invoice.processor_id}}
          })
      })

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    {:ok, view, _html} = live(conn, "/billing/webhooks?org=allowed-org&status=dead")
    html = submit_selection(view, [foreign_webhook.id])

    assert html =~ "No eligible deliveries were queued. 1 skipped; 0 denied; 0 failed; 0 unknown."
    event = bulk_replay_event!()
    assert event.data["selected"] == 1
    assert event.data["eligible"] == 0
    assert event.data["attempted"] == 0
    assert event.data["queued"] == 0
    assert event.data["skipped"] == 1
    assert event.data["ids"] == []
    assert event.data["outcomes"] == []
    assert TestRepo.get!(WebhookEvent, foreign_webhook.id).status == :dead
  end

  test "bulk replay revalidates organization ownership inside the claim transaction", %{
    conn: conn
  } do
    allowed_customer =
      insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})

    invoice = insert_invoice(allowed_customer, %{processor_id: "in_reassigned_webhook"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_reassigned_bulk",
        status: :dead,
        data: %{"object" => %{"id" => invoice.processor_id}}
      })

    # The initial scope read has already accepted the row when this seam runs. Move the
    # customer before DLQ.requeue/2 so only the in-transaction authorization can reject it.
    Application.put_env(:accrue_admin, :webhook_requeue_fun, fn id, authorize_fun ->
      allowed_customer
      |> Ecto.Changeset.change(owner_id: "org_foreign")
      |> TestRepo.update!()

      DLQ.requeue(id, authorize_fun)
    end)

    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    {:ok, view, _html} = live(conn, "/billing/webhooks?org=allowed-org&status=dead")
    html = submit_selection(view, [webhook.id])

    assert html =~ "No deliveries were queued. 0 skipped; 1 denied; 0 failed; 0 unknown."
    event = bulk_replay_event!()
    assert event.data["eligible"] == 1
    assert event.data["attempted"] == 0
    assert event.data["queued"] == 0
    assert event.data["skipped"] == 0
    assert event.data["denied"] == 1
    assert event.data["ids"] == []
    assert event.data["outcomes"] == []

    denied_row =
      html
      |> Floki.parse_document!()
      |> Floki.find(~s([data-role="bulk-replay-results"] [data-delivery-id="#{webhook.id}"]))
      |> hd()

    assert Floki.find(denied_row, "a") == []
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead

    refute TestRepo.exists?(
             from(event in Event,
               where: event.type == "webhook.replay_requested" and event.subject_id == ^webhook.id
             )
           )
  end

  test "a mid-batch queue failure preserves earlier results and continues to later deliveries", %{
    conn: conn,
    bulk_webhooks: [first, failed, last]
  } do
    first = set_received_at(first, ~U[2026-01-01 12:00:00.000000Z])
    failed = set_received_at(failed, ~U[2026-01-01 11:00:00.000000Z])
    last = set_received_at(last, ~U[2026-01-01 10:00:00.000000Z])

    Application.put_env(:accrue_admin, :webhook_requeue_fun, fn id, authorize_fun ->
      if id == failed.id do
        {:error, :dispatch_failed}
      else
        DLQ.requeue(id, authorize_fun)
      end
    end)

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=failed,dead")
    html = submit_selection(view, [last.id, failed.id, first.id])

    assert html =~ "Queued 2 deliveries. 0 skipped; 0 denied; 1 failed; 0 unknown."
    event = bulk_replay_event!()
    assert event.data["selected"] == 3
    assert event.data["eligible"] == 3
    assert event.data["attempted"] == 3
    assert event.data["queued"] == 2
    assert event.data["failed"] == 1
    assert event.data["denied"] == 0
    assert outcome_total(event.data) == event.data["selected"]

    assert Enum.map(event.data["outcomes"], &{&1["id"], &1["outcome"]}) ==
             [{first.id, "queued"}, {failed.id, "failed"}, {last.id, "queued"}]

    assert TestRepo.get!(WebhookEvent, first.id).status == :received
    assert TestRepo.get!(WebhookEvent, failed.id).status == :dead
    assert TestRepo.get!(WebhookEvent, last.id).status == :received
  end

  test "unclassifiable enqueue exception remains unknown rather than reporting a failure", %{
    conn: conn,
    webhook: webhook
  } do
    Application.put_env(:accrue_admin, :webhook_requeue_fun, fn _id, _authorize_fun ->
      raise "dispatch outcome not observable"
    end)

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    html = submit_selection(view, [webhook.id])

    assert html =~ "0 skipped; 0 denied; 0 failed; 1 unknown."
    assert html =~ ~s(data-role="bulk-replay-results")
    assert html =~ ~s(data-delivery-id="#{webhook.id}")
    assert html =~ "Dispatch result could not be confirmed"
    assert html =~ "Inspect its current status and history before deciding what to do next."

    result_row =
      html
      |> Floki.parse_document!()
      |> Floki.find(~s([data-role="bulk-replay-results"] [data-delivery-id="#{webhook.id}"]))
      |> hd()

    assert Floki.attribute(result_row, "a", "href") == ["/billing/webhooks/#{webhook.id}"]
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert dispatch_jobs(webhook.id) == []
    assert outcome_total(bulk_replay_event!().data) == 1
    refute html =~ "processed successfully"
  end

  test "mixed bulk outcomes stay attached to their selected delivery rows", %{
    conn: conn,
    bulk_webhooks: [queued_before, unknown, queued_after]
  } do
    queued_before = set_received_at(queued_before, ~U[2026-01-03 12:00:00.000000Z])
    unknown = set_received_at(unknown, ~U[2026-01-02 12:00:00.000000Z])
    queued_after = set_received_at(queued_after, ~U[2026-01-01 12:00:00.000000Z])

    Application.put_env(:accrue_admin, :webhook_requeue_fun, fn id, authorize_fun ->
      if id == unknown.id do
        raise "dispatch outcome not observable"
      else
        DLQ.requeue(id, authorize_fun)
      end
    end)

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=failed,dead")
    html = submit_selection(view, [queued_after.id, unknown.id, queued_before.id])
    document = Floki.parse_document!(html)

    results = Floki.find(document, ~s([data-role="bulk-replay-results"] [data-delivery-id]))

    assert Enum.map(results, &Floki.attribute(&1, "data-delivery-id")) ==
             [[queued_before.id], [unknown.id], [queued_after.id]]

    unknown_row = Enum.at(results, 1)
    assert Floki.text(unknown_row) =~ "Dispatch result could not be confirmed"
    assert Floki.attribute(unknown_row, "a", "href") == ["/billing/webhooks/#{unknown.id}"]
    assert TestRepo.get!(WebhookEvent, unknown.id).status == :dead
    assert dispatch_jobs(unknown.id) == []
  end

  test "accepted enqueue is retained when the scoped reread fails", %{
    conn: conn,
    webhook: webhook
  } do
    {:ok, counter} = Agent.start_link(fn -> 0 end)
    Process.unlink(counter)

    Application.put_env(:accrue_admin, :webhook_replay_detail_fun, fn id, owner_scope ->
      call = Agent.get_and_update(counter, fn n -> {n + 1, n + 1} end)

      if call == 3 do
        raise "reread unavailable after queue acceptance"
      else
        AccrueAdmin.Queries.Webhooks.detail(id, owner_scope)
      end
    end)

    on_exit(fn -> if Process.alive?(counter), do: Agent.stop(counter) end)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    html = submit_selection(view, [webhook.id])

    assert html =~ "Queued 1 delivery"
    assert html =~ "1 accepted enqueue(s) could not be reread; processing status is unknown."
    result = bulk_replay_event!().data
    assert result["queued"] == 1
    assert result["reread_unknown"] == 1
    assert outcome_total(result) == result["selected"]
    assert html =~ ~s(data-delivery-id="#{webhook.id}")
    assert html =~ "Queue request accepted."
    assert html =~ "processing status is unknown."
    assert html =~ "Delivery detail is currently unavailable in this scope."

    result_row =
      html
      |> Floki.parse_document!()
      |> Floki.find(~s([data-role="bulk-replay-results"] [data-delivery-id="#{webhook.id}"]))
      |> hd()

    assert Floki.find(result_row, "a") == []
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :received
    assert length(dispatch_jobs(webhook.id)) == 1
    assert TestRepo.exists?(from(event in Event, where: event.type == "webhook.replay_requested"))
    refute html =~ "processed successfully"
  end

  test "pre-dispatch read failure is unknown and does not create a dispatch job", %{
    conn: conn,
    webhook: webhook
  } do
    {:ok, counter} = Agent.start_link(fn -> 0 end)
    Process.unlink(counter)

    Application.put_env(:accrue_admin, :webhook_replay_detail_fun, fn id, owner_scope ->
      call = Agent.get_and_update(counter, fn n -> {n + 1, n + 1} end)

      if call == 2 do
        raise "pre-dispatch delivery read unavailable"
      else
        AccrueAdmin.Queries.Webhooks.detail(id, owner_scope)
      end
    end)

    on_exit(fn -> if Process.alive?(counter), do: Agent.stop(counter) end)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    html = submit_selection(view, [webhook.id])

    assert html =~ "No deliveries were queued. 0 skipped; 0 denied; 0 failed; 1 unknown."
    assert html =~ ~s(data-delivery-id="#{webhook.id}")
    assert html =~ "Delivery detail is currently unavailable in this scope."

    result_row =
      html
      |> Floki.parse_document!()
      |> Floki.find(~s([data-role="bulk-replay-results"] [data-delivery-id="#{webhook.id}"]))
      |> hd()

    assert Floki.find(result_row, "a") == []
    result = bulk_replay_event!().data
    assert result["attempted"] == 0
    assert outcome_total(result) == result["selected"]
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert dispatch_jobs(webhook.id) == []
    refute TestRepo.exists?(from(event in Event, where: event.type == "webhook.replay_requested"))
  end

  test "dismissing the reviewed set performs no dispatch or audit mutation", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    send(view.pid, {:data_table_bulk_action, "retry_selected", [webhook.id]})
    _ = render(view)
    html = render_click(element(view, "[phx-click='cancel_bulk_replay']"))

    refute html =~ ~s(data-role="bulk-replay-confirm")
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert dispatch_jobs(webhook.id) == []
    refute TestRepo.exists?(from(event in Event, where: event.type == "webhook.replay_requested"))

    refute TestRepo.exists?(
             from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed")
           )
  end

  test "confirmation refuses a changed reviewed ID set", %{conn: conn, webhook: webhook} do
    replacement = insert_webhook(%{processor_event_id: "evt_replacement", status: :dead})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/webhooks?status=dead")
    send(view.pid, {:data_table_bulk_action, "retry_selected", [webhook.id]})
    _ = render(view)

    _ =
      render_click(element(view, "[data-role='confirm-retry-selected']"), %{
        "reviewed_ids" => replacement.id
      })

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "1 denied"
    assert TestRepo.get!(WebhookEvent, webhook.id).status == :dead
    assert TestRepo.get!(WebhookEvent, replacement.id).status == :dead
    assert dispatch_jobs(webhook.id) == []
    assert dispatch_jobs(replacement.id) == []
    assert outcome_total(bulk_replay_event!().data) == 1
  end

  defp submit_selection(view, ids) do
    send(view.pid, {:data_table_bulk_action, "retry_selected", ids})
    _ = render(view)
    _ = render_click(element(view, "[data-role='confirm-retry-selected']"))
    render_submit(view, "step_up_submit", %{"code" => "123456"})
  end

  defp bulk_replay_event! do
    TestRepo.one!(
      from(event in Event,
        where: event.type == "admin.webhook.bulk_replay.completed",
        order_by: [desc: event.inserted_at, desc: event.id],
        limit: 1
      )
    )
  end

  defp dispatch_jobs(id) do
    TestRepo.all(
      from(job in Oban.Job,
        where:
          job.worker == "Accrue.Webhook.DispatchWorker" and
            fragment("?->>'webhook_event_id' = ?", job.args, ^id)
      )
    )
  end

  defp outcome_total(data) do
    data["queued"] + data["skipped"] + data["denied"] + data["failed"] + data["unknown"]
  end

  defp set_received_at(webhook, received_at) do
    webhook
    |> Ecto.Changeset.change(received_at: received_at)
    |> TestRepo.update!()
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      currency: "usd",
      status: :open,
      collection_method: "charge_automatically",
      metadata: %{},
      data: %{},
      lock_version: 1,
      processor_id: "in_" <> Integer.to_string(System.unique_integer([:positive]))
    }

    %Invoice{}
    |> Invoice.force_status_changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      livemode: false,
      endpoint: :default,
      status: :received,
      raw_body: Jason.encode!(%{"id" => "evt_seed", "object" => "event"}),
      received_at: DateTime.utc_now(),
      data: %{}
    }

    Map.merge(defaults, attrs)
    |> WebhookEvent.ingest_changeset()
    |> TestRepo.insert!()
    |> then(fn webhook ->
      webhook
      |> Ecto.Changeset.change(%{status: Map.get(attrs, :status, :received)})
      |> TestRepo.update!()
    end)
  end
end
