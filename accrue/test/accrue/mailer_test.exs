defmodule Accrue.MailerTest do
  @moduledoc """
  Plan 05 Task 1 — Accrue.Mailer behaviour + Default adapter + Oban worker
  + Accrue.Emails.PaymentSucceeded reference template.

  Swoosh test adapter is already wired by Plan 01 in `config/test.exs`
  (`config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Test`).
  Oban is started in `:manual` testing mode by `test/test_helper.exs`.
  """

  use ExUnit.Case, async: false

  use Oban.Testing, repo: Accrue.TestRepo

  import Swoosh.TestAssertions

  @valid_assigns %{
    customer_id: "cus_1",
    invoice_id: "in_1",
    customer_name: "Alice",
    amount: "$10.00",
    invoice_number: "INV-1",
    receipt_url: "https://example.com/r/1",
    to: "alice@example.com"
  }

  setup tags do
    # Check out a sandboxed DB connection for the Oban insert path. Plan 03
    # wired Accrue.TestRepo in the sandbox; this test shares it in non-async
    # mode so the Oban worker process (if it runs) can reach the same conn.
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    # Reset transient env between tests.
    prior_emails = Application.get_env(:accrue, :emails, [])
    prior_overrides = Application.get_env(:accrue, :email_overrides, [])

    on_exit(fn ->
      Application.put_env(:accrue, :emails, prior_emails)
      Application.put_env(:accrue, :email_overrides, prior_overrides)
    end)

    :ok
  end

  describe "Accrue.Mailer.deliver/2" do
    test "enqueues an Oban job on :accrue_mailers with scalar args" do
      assert {:ok, %Oban.Job{}} = Accrue.Mailer.deliver(:payment_succeeded, @valid_assigns)

      assert_enqueued(
        worker: Accrue.Workers.Mailer,
        queue: :accrue_mailers,
        args: %{"type" => "payment_succeeded"}
      )

      [job] = all_enqueued(worker: Accrue.Workers.Mailer)
      # Args must be fully string-keyed scalars (Oban-safe).
      assert %{"type" => "payment_succeeded", "assigns" => assigns} = job.args
      assert assigns["customer_id"] == "cus_1"
      assert assigns["customer_name"] == "Alice"
    end

    test "kill switch: config :accrue, :emails, [type: false] returns {:ok, :skipped}" do
      Application.put_env(:accrue, :emails, payment_succeeded: false)

      assert {:ok, :skipped} = Accrue.Mailer.deliver(:payment_succeeded, @valid_assigns)
      refute_enqueued(worker: Accrue.Workers.Mailer)
    end

    test "raises when assigns contain a struct (Oban-safety, T-MAIL-01)" do
      assert_raise ArgumentError, ~r/Oban-safe/, fn ->
        Accrue.Mailer.deliver(:payment_succeeded, %{customer: URI.parse("https://x")})
      end
    end

    test "emits [:accrue, :mailer, :deliver, :stop] telemetry with PII-safe metadata" do
      ref = make_ref()
      test_pid = self()

      :telemetry.attach_many(
        "mailer-test-#{inspect(ref)}",
        [
          [:accrue, :mailer, :deliver, :start],
          [:accrue, :mailer, :deliver, :stop]
        ],
        fn event, measurements, meta, _ ->
          send(test_pid, {:telemetry, event, measurements, meta})
        end,
        nil
      )

      {:ok, _} = Accrue.Mailer.deliver(:payment_succeeded, @valid_assigns)

      assert_received {:telemetry, [:accrue, :mailer, :deliver, :start], _, start_meta}
      assert_received {:telemetry, [:accrue, :mailer, :deliver, :stop], _, stop_meta}

      assert start_meta.email_type == :payment_succeeded
      assert start_meta.customer_id == "cus_1"
      assert stop_meta.email_type == :payment_succeeded

      # T-MAIL-02: no raw assigns / bodies in metadata.
      refute Map.has_key?(start_meta, :assigns)
      refute Map.has_key?(start_meta, :body)

      :telemetry.detach("mailer-test-#{inspect(ref)}")
    end
  end

  describe "Accrue.Workers.Mailer.perform/1" do
    test "renders the PaymentSucceeded template and delivers via Swoosh test adapter" do
      job = %Oban.Job{
        args: %{
          "type" => "payment_succeeded",
          "assigns" => %{
            "to" => "alice@example.com",
            "customer_name" => "Alice",
            "amount" => "$10.00",
            "invoice_number" => "INV-1",
            "receipt_url" => "https://example.com/r/1"
          }
        }
      }

      assert {:ok, _} = Accrue.Workers.Mailer.perform(job)

      assert_email_sent(fn email ->
        assert email.subject == "Receipt for your payment"
        assert Enum.any?(email.to, fn {_name, addr} -> addr == "alice@example.com" end)
        assert email.html_body =~ "Alice"
        assert email.html_body =~ "INV-1"
        assert email.text_body =~ "Alice"
        assert email.text_body =~ "INV-1"
      end)
    end

    test "honors :email_overrides to swap the template module (D-23 rung 3)" do
      defmodule StubTemplate do
        def subject(_), do: "STUB"
        def render(_), do: "<p>STUB HTML</p>"
        def render_text(_), do: "STUB TEXT"
      end

      Application.put_env(:accrue, :email_overrides, payment_succeeded: StubTemplate)
      on_exit(fn -> Application.put_env(:accrue, :email_overrides, []) end)

      assert Accrue.Workers.Mailer.resolve_template(:payment_succeeded) == StubTemplate
    end
  end

  describe "Accrue.Emails.PaymentSucceeded" do
    test "MJML template compiles to HTML containing the assigns" do
      html =
        Accrue.Emails.PaymentSucceeded.render(
          customer_name: "Alice",
          amount: "$10.00",
          invoice_number: "INV-1",
          receipt_url: "https://example.com/r/1"
        )

      assert is_binary(html)
      assert html =~ "Alice"
      assert html =~ "INV-1"
      assert html =~ "$10.00"
      assert html =~ "https://example.com/r/1"
    end

    test "render_text/1 produces plain-text with the same assigns" do
      text =
        Accrue.Emails.PaymentSucceeded.render_text(%{
          customer_name: "Alice",
          amount: "$10.00",
          invoice_number: "INV-1",
          receipt_url: "https://example.com/r/1"
        })

      assert text =~ "Alice"
      assert text =~ "$10.00"
      assert text =~ "INV-1"
    end
  end
end
