defmodule Accrue.Workers.MailerIdempotencyTest do
  @moduledoc """
  DUN-04 immediate idempotency proof for `:invoice_payment_failed`.

  Proves the Phase 128 Plan 04 must-fix: a duplicate
  `Accrue.Mailer.deliver(:invoice_payment_failed, ...)` for the SAME invoice
  never creates a second Oban job (the second enqueue returns
  `{:ok, %Oban.Job{conflict?: true}}`), even across a simulated week-2 Stripe
  Smart-Retry redelivery (the prior job in `:completed` state still blocks);
  while two DISTINCT invoices each get their OWN job (per-invoice granularity,
  NOT global suppression — the regression a nested-only `invoice_id` would
  cause). The dedup discriminator (`invoice_id`) is a TOP-LEVEL Oban arg, the
  D-14 backstop key resolves on `invoice_id`, and every non-failed type is
  un-deduped (no regression).

  Flips `:mailer` to `Accrue.Mailer.Default` per-test so the REAL
  `Oban.insert` path with the derived `unique` runs (the env default is the
  capture-only `Accrue.Mailer.Test`).
  """
  use ExUnit.Case, async: false

  use Oban.Testing, repo: Accrue.TestRepo

  import Ecto.Query, only: [from: 2]

  alias Accrue.Mailer.Default
  alias Accrue.Workers.Mailer

  setup do
    # Shared sandbox conn so the Oban insert path reaches the same connection
    # (mirrors test/accrue/mailer_test.exs:31).
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    # The test-env default mailer is Accrue.Mailer.Test (capture-only). This
    # suite needs the real Default adapter so the derived `unique` actually
    # hits Oban. Restore on exit.
    prior_mailer = Application.get_env(:accrue, :mailer)
    Application.put_env(:accrue, :mailer, Accrue.Mailer.Default)

    # Ensure the dunning campaign doesn't short-circuit anything here — this
    # suite exercises the mailer enqueue directly, not the webhook gate.
    prior_emails = Application.get_env(:accrue, :emails, [])

    on_exit(fn ->
      if prior_mailer,
        do: Application.put_env(:accrue, :mailer, prior_mailer),
        else: Application.delete_env(:accrue, :mailer)

      Application.put_env(:accrue, :emails, prior_emails)
    end)

    :ok
  end

  defp jobs_for(invoice_id) do
    [worker: Mailer]
    |> all_enqueued()
    |> Enum.filter(fn job ->
      job.args["type"] == "invoice_payment_failed" and
        job.args["invoice_id"] == invoice_id
    end)
  end

  describe "same-invoice dedup (DUN-04 primary)" do
    test "a duplicate deliver for the SAME invoice yields conflict?: true and one job" do
      assigns = %{invoice_id: "in_A", customer_id: "cus_A", to: "a@example.test"}

      assert {:ok, %Oban.Job{conflict?: false}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, assigns)

      assert {:ok, %Oban.Job{conflict?: true}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, assigns)

      assert [_only_one] = jobs_for("in_A")
    end

    test "the deduped job carries invoice_id as a TOP-LEVEL Oban arg" do
      assigns = %{invoice_id: "in_TOP", customer_id: "cus_T", to: "t@example.test"}

      assert {:ok, %Oban.Job{}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, assigns)

      # Read the persisted job back (DB round-trip → string-keyed args). The
      # discriminator must be top-level so `keys: [:type, :invoice_id]` (Oban's
      # `Map.take` over top-level stringified arg keys) can resolve it.
      assert [job] = jobs_for("in_TOP")
      assert job.args["invoice_id"] == "in_TOP"
      # And it still lives inside assigns for the worker/email to read.
      assert job.args["assigns"]["invoice_id"] == "in_TOP"
    end
  end

  describe "per-invoice granularity (DUN-04 — NOT global suppression)" do
    test "two DISTINCT invoices each enqueue a SEPARATE job (conflict?: false on the second)" do
      a = %{invoice_id: "in_A", customer_id: "cus_A", to: "a@example.test"}
      b = %{invoice_id: "in_B", customer_id: "cus_B", to: "b@example.test"}

      assert {:ok, %Oban.Job{conflict?: false}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, a)

      # If invoice_id were nested-only, this distinct invoice would be
      # suppressed by invoice A's signature — this assertion is the one that
      # proves per-invoice granularity rather than global suppression.
      assert {:ok, %Oban.Job{conflict?: false}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, b)

      assert [_a_job] = jobs_for("in_A")
      assert [_b_job] = jobs_for("in_B")

      ids =
        [worker: Mailer]
        |> all_enqueued()
        |> Enum.filter(&(&1.args["type"] == "invoice_payment_failed"))
        |> Enum.map(& &1.args["invoice_id"])
        |> Enum.sort()

      assert ids == ["in_A", "in_B"]
    end
  end

  describe "week-2 Smart-Retry redelivery survives a :completed prior job" do
    test "a completed prior job still blocks the SAME invoice; a distinct invoice is unaffected" do
      a = %{invoice_id: "in_A", customer_id: "cus_A", to: "a@example.test"}

      assert {:ok, %Oban.Job{conflict?: false} = first} =
               Accrue.Mailer.deliver(:invoice_payment_failed, a)

      # Simulate the first job having long since completed (week 1's email was
      # already sent). `period: :infinity` + `:completed` in the unique states
      # must STILL block a week-2 redelivery for the same invoice.
      {1, _} =
        from(j in Oban.Job, where: j.id == ^first.id)
        |> Accrue.TestRepo.update_all(set: [state: "completed", completed_at: DateTime.utc_now()])

      assert {:ok, %Oban.Job{conflict?: true}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, a)

      # A DISTINCT invoice is unaffected by the completed in_A job.
      b = %{invoice_id: "in_B", customer_id: "cus_B", to: "b@example.test"}

      assert {:ok, %Oban.Job{conflict?: false}} =
               Accrue.Mailer.deliver(:invoice_payment_failed, b)

      assert [_b_job] = jobs_for("in_B")
    end
  end

  describe "D-14 backstop idempotency_key/2 (via delivered Mailglass metadata)" do
    setup do
      # The Mailglass lane needs its Fake adapter, tenant, suppression store
      # and branding wired (cloned from default_handler_mailer_dispatch_test).
      prior_mailglass = Application.get_env(:mailglass, :adapter)
      prior_mailglass_repo = Application.get_env(:mailglass, :repo)
      prior_suppression_store = Application.get_env(:mailglass, :suppression_store)
      prior_branding = Application.get_env(:accrue, :branding)
      prior_tenant = Mailglass.Tenancy.current()

      Application.put_env(:mailglass, :repo, Accrue.TestRepo)
      Application.put_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.ETS)
      Mailglass.SuppressionStore.ETS.reset()

      Application.put_env(:accrue, :branding,
        business_name: "Acme Corp",
        from_name: "Acme Billing",
        from_email: "billing@acme.test",
        support_email: "support@acme.test"
      )

      Application.put_env(:mailglass, :adapter, {Mailglass.Adapters.Fake, []})
      Mailglass.Tenancy.put_current("test-tenant")
      Mailglass.Adapters.Fake.checkout()
      Mailglass.Adapters.Fake.clear()

      # Override the :invoice_payment_failed template with CardExpiringSoon for
      # this backstop test: it renders cleanly from a hydrated customer + an
      # update_pm_url CTA (no invoice struct needed), while idempotency_key/2
      # still keys on the :invoice_payment_failed TYPE regardless of template.
      prior_overrides = Application.get_env(:accrue, :email_overrides, [])

      Application.put_env(:accrue, :email_overrides,
        invoice_payment_failed: Accrue.Emails.CardExpiringSoon
      )

      # Seed a real customer (reusing the shared sandbox conn from the
      # top-level setup) so enrich/2 hydrates an atom-keyed struct (the
      # template reads @customer.name).
      {:ok, customer} =
        %Accrue.Billing.Customer{}
        |> Accrue.Billing.Customer.changeset(%{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "fake",
          processor_id: "cus_idem_backstop",
          name: "Jo",
          email: "k@example.test"
        })
        |> Accrue.TestRepo.insert()

      on_exit(fn -> Application.put_env(:accrue, :email_overrides, prior_overrides) end)

      on_exit(fn ->
        case prior_mailglass do
          nil -> Application.delete_env(:mailglass, :adapter)
          v -> Application.put_env(:mailglass, :adapter, v)
        end

        case prior_mailglass_repo do
          nil -> Application.delete_env(:mailglass, :repo)
          v -> Application.put_env(:mailglass, :repo, v)
        end

        case prior_suppression_store do
          nil -> Application.delete_env(:mailglass, :suppression_store)
          v -> Application.put_env(:mailglass, :suppression_store, v)
        end

        case prior_branding do
          nil -> Application.delete_env(:accrue, :branding)
          v -> Application.put_env(:accrue, :branding, v)
        end

        Mailglass.Tenancy.put_current(prior_tenant)
      end)

      %{customer: customer}
    end

    test "delivering :invoice_payment_failed stamps accrue:v1:invoice_payment_failed:<id>",
         %{customer: customer} do
      # Drive the worker directly so the Mailglass lane runs and stamps the
      # key. The template is overridden to CardExpiringSoon (renders from a
      # hydrated customer + update_pm_url, no invoice struct needed); the
      # idempotency_key still keys on the :invoice_payment_failed TYPE.
      args = %{
        "type" => "invoice_payment_failed",
        "invoice_id" => "in_KEY",
        "assigns" => %{
          "invoice_id" => "in_KEY",
          "customer_id" => customer.id,
          "to" => "k@example.test",
          "update_pm_url" => "https://acme.test/portal/update-payment-method"
        }
      }

      assert {:ok, _} = perform_job(Mailer, args)

      msg = Mailglass.TestAssertions.last_mail()
      assert msg.metadata.idempotency_key == "accrue:v1:invoice_payment_failed:in_KEY"
    end

    test "a missing invoice_id cancels delivery with :missing_invoice_id" do
      args = %{
        "type" => "invoice_payment_failed",
        "assigns" => %{"to" => "k@example.test"}
      }

      assert {:cancel, :missing_invoice_id} = perform_job(Mailer, args)
    end
  end

  describe "no regression: non-:invoice_payment_failed types are NOT deduped" do
    test "two deliveries of :receipt both enqueue (no conflict) and carry no top-level invoice_id" do
      assigns = %{invoice_id: "in_R", customer_id: "cus_R", charge_id: "ch_R", to: "r@example.test"}

      assert {:ok, %Oban.Job{conflict?: false} = j1} =
               Accrue.Mailer.deliver(:receipt, assigns)

      assert {:ok, %Oban.Job{conflict?: false} = j2} =
               Accrue.Mailer.deliver(:receipt, assigns)

      refute j1.id == j2.id
      # Non-failed types keep the bare %{type:, assigns:} shape — no promotion.
      refute Map.has_key?(j1.args, "invoice_id")
      refute Map.has_key?(j2.args, "invoice_id")
    end

    test "two deliveries of :payment_succeeded both enqueue and carry no top-level invoice_id" do
      assigns = %{
        invoice_id: "in_PS",
        customer_id: "cus_PS",
        invoice_number: "INV-PS",
        to: "ps@example.test"
      }

      assert {:ok, %Oban.Job{conflict?: false} = j1} =
               Accrue.Mailer.deliver(:payment_succeeded, assigns)

      assert {:ok, %Oban.Job{conflict?: false} = j2} =
               Accrue.Mailer.deliver(:payment_succeeded, assigns)

      refute j1.id == j2.id
      refute Map.has_key?(j1.args, "invoice_id")
      refute Map.has_key?(j2.args, "invoice_id")
    end
  end

  describe "degenerate invoice_id guard (no global-suppression footgun)" do
    test "a nil/empty invoice_id falls back to the non-deduped shape" do
      # Two deliveries with an empty invoice_id must BOTH enqueue (the guard
      # falls back to unique: false rather than promoting a degenerate key
      # that would globally suppress).
      assigns = %{invoice_id: "", customer_id: "cus_X", to: "x@example.test"}

      assert {:ok, %Oban.Job{conflict?: false} = j1} =
               Default.deliver(:invoice_payment_failed, assigns)

      assert {:ok, %Oban.Job{conflict?: false} = j2} =
               Default.deliver(:invoice_payment_failed, assigns)

      refute j1.id == j2.id
      # No degenerate top-level invoice_id key promoted.
      refute Map.has_key?(j1.args, "invoice_id")
    end
  end
end
