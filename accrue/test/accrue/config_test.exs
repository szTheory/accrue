defmodule Accrue.ConfigTest do
  use ExUnit.Case, async: false

  alias Accrue.Config

  # The nested `:branding` schema has two required inner keys
  # (:from_email + :support_email). Any direct `Config.validate!/1`
  # call site must supply them or NimbleOptions raises at the nested
  # schema level. This helper keeps existing test intent untouched while
  # satisfying that schema contract.
  @test_branding [from_email: "noreply@example.test", support_email: "support@example.test"]

  defp with_branding(opts), do: Keyword.put_new(opts, :branding, @test_branding)

  describe "validate!/1" do
    test "happy path with required :repo" do
      opts = Config.validate!(with_branding(repo: SomeApp.Repo))
      assert opts[:repo] == SomeApp.Repo
      assert opts[:processor] == Accrue.Processor.Fake
      assert opts[:default_currency] == :usd
    end

    test "missing :repo raises" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate!([])
      end
    end

    test "type mismatch on :processor raises" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate!(repo: SomeApp.Repo, processor: "not-an-atom")
      end
    end

    test "type mismatch on :emails raises" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate!(repo: SomeApp.Repo, emails: "nope")
      end
    end
  end

  describe "get!/1 defaults" do
    test ":default_currency defaults to :usd" do
      Application.delete_env(:accrue, :default_currency)
      assert :usd == Config.get!(:default_currency)
    end

    test ":stripe_api_version default" do
      Application.delete_env(:accrue, :stripe_api_version)
      assert "2026-03-25.dahlia" == Config.get!(:stripe_api_version)
    end

    test ":emails defaults to []" do
      Application.delete_env(:accrue, :emails)
      assert [] == Config.get!(:emails)
    end

    test ":email_overrides defaults to []" do
      Application.delete_env(:accrue, :email_overrides)
      assert [] == Config.get!(:email_overrides)
    end

    test ":attach_invoice_pdf defaults to true" do
      Application.delete_env(:accrue, :attach_invoice_pdf)
      assert true == Config.get!(:attach_invoice_pdf)
    end

    test ":enforce_immutability defaults to false" do
      Application.delete_env(:accrue, :enforce_immutability)
      assert false == Config.get!(:enforce_immutability)
    end

    test ":business_name defaults to \"Accrue\"" do
      Application.delete_env(:accrue, :business_name)
      assert "Accrue" == Config.get!(:business_name)
    end

    test "adapter defaults resolve to module atoms" do
      Application.delete_env(:accrue, :pdf_adapter)
      Application.delete_env(:accrue, :auth_adapter)
      Application.delete_env(:accrue, :mailer)
      Application.delete_env(:accrue, :mailer_adapter)
      assert Accrue.PDF.ChromicPDF == Config.get!(:pdf_adapter)
      assert Accrue.Auth.Default == Config.get!(:auth_adapter)
      assert Accrue.Mailer.Default == Config.get!(:mailer)
      assert Accrue.Mailer.Swoosh == Config.get!(:mailer_adapter)
    end
  end

  describe "get!/1 runtime overrides" do
    test "reads value from Application env when set" do
      Application.put_env(:accrue, :default_currency, :eur)
      assert :eur == Config.get!(:default_currency)
    after
      Application.delete_env(:accrue, :default_currency)
    end
  end

  describe "get!/1 unknown key" do
    test "raises Accrue.ConfigError" do
      err =
        assert_raise Accrue.ConfigError, fn ->
          Config.get!(:totally_made_up)
        end

      assert err.key == :totally_made_up
    end
  end

  describe "setup diagnostics" do
    test "missing webhook signing secret raises shared diagnostic" do
      Application.put_env(:accrue, :webhook_signing_secrets, %{})

      error =
        assert_raise Accrue.ConfigError, fn ->
          Config.webhook_signing_secrets(:stripe)
        end

      assert error.diagnostic.code == "ACCRUE-DX-WEBHOOK-SECRET-MISSING"

      assert Exception.message(error) =~
               "/guides/troubleshooting.html#accrue-dx-webhook-secret-missing"
    after
      Application.put_env(:accrue, :webhook_signing_secrets, %{stripe: ["whsec_test_secret"]})
    end

    test "missing Oban config raises shared diagnostic" do
      error =
        assert_raise Accrue.ConfigError, fn ->
          Config.ensure_oban_configured!(nil)
        end

      assert error.diagnostic.code == "ACCRUE-DX-OBAN-NOT-CONFIGURED"
    end

    test "pending migrations raise shared diagnostic" do
      error =
        assert_raise Accrue.ConfigError, fn ->
          Config.ensure_migrations_current!([{:down, 20_260_416_000_000, "pending"}])
        end

      assert error.diagnostic.code == "ACCRUE-DX-MIGRATIONS-PENDING"
    end

    test "migration lookup failures raise shared diagnostic instead of returning :ok" do
      error =
        assert_raise Accrue.ConfigError, fn ->
          Config.ensure_migrations_current!(fn ->
            raise DBConnection.ConnectionError,
              message: "migration lookup failed for STRIPE_SECRET_KEY=sk_test_hidden"
          end)
        end

      assert error.diagnostic.code == "ACCRUE-DX-MIGRATIONS-PENDING"
      assert Exception.message(error) =~ "ACCRUE-DX-MIGRATIONS-PENDING"
      refute Exception.message(error) =~ "sk_test_hidden"
    end

    test "unexpected migration lookup exceptions are not suppressed" do
      assert_raise RuntimeError, "unexpected migration lookup failure", fn ->
        Config.ensure_migrations_current!(fn ->
          raise "unexpected migration lookup failure"
        end)
      end
    end
  end

  describe "schema/0" do
    test "returns a keyword list with every Phase 1 key" do
      schema = Config.schema()
      assert is_list(schema)
      keys = Keyword.keys(schema)

      expected = [
        :repo,
        :processor,
        :mailer,
        :mailer_adapter,
        :pdf_adapter,
        :auth_adapter,
        :stripe_secret_key,
        :stripe_api_version,
        :emails,
        :email_overrides,
        :attach_invoice_pdf,
        :enforce_immutability,
        :business_name,
        :business_address,
        :logo_url,
        :support_email,
        :from_email,
        :from_name,
        :default_currency
      ]

      for key <- expected do
        assert key in keys, "missing schema key: #{inspect(key)}"
      end

      assert length(keys) >= 18
    end
  end

  describe "Phase 4 config — dunning defaults (D4-02)" do
    setup do
      Application.delete_env(:accrue, :dunning)
      :ok
    end

    test ":dunning defaults match D4-02" do
      dunning = Config.get!(:dunning)
      assert dunning[:mode] == :stripe_smart_retries
      assert dunning[:grace_days] == 14
      assert dunning[:terminal_action] == :unpaid
      assert dunning[:telemetry_prefix] == [:accrue, :ops]
    end

    test "Config.dunning/0 helper returns the defaults" do
      assert Config.dunning()[:grace_days] == 14
    end
  end

  describe "Phase 4 config — DLQ + retention defaults (D4-04)" do
    setup do
      for key <- [
            :dead_retention_days,
            :succeeded_retention_days,
            :dlq_replay_batch_size,
            :dlq_replay_stagger_ms,
            :dlq_replay_max_rows,
            :webhook_endpoints
          ] do
        Application.delete_env(:accrue, key)
      end

      :ok
    end

    test "retention defaults" do
      assert Config.get!(:dead_retention_days) == 90
      assert Config.get!(:succeeded_retention_days) == 14
    end

    test "DLQ replay defaults" do
      assert Config.get!(:dlq_replay_batch_size) == 100
      assert Config.get!(:dlq_replay_stagger_ms) == 1_000
      assert Config.get!(:dlq_replay_max_rows) == 10_000
    end

    test "Phase 4 helper functions" do
      assert Config.dlq_replay_batch_size() == 100
      assert Config.dlq_replay_stagger_ms() == 1_000
      assert Config.dlq_replay_max_rows() == 10_000
      assert Config.webhook_endpoints() == []
    end

    test "webhook_endpoints default is []" do
      assert Config.get!(:webhook_endpoints) == []
    end
  end

  describe "Phase 4 config — NimbleOptions validation" do
    test "dead_retention_days accepts :infinity" do
      opts =
        Config.validate!(
          with_branding(
            repo: SomeApp.Repo,
            dead_retention_days: :infinity
          )
        )

      assert opts[:dead_retention_days] == :infinity
    end

    test "succeeded_retention_days accepts :infinity" do
      opts =
        Config.validate!(
          with_branding(
            repo: SomeApp.Repo,
            succeeded_retention_days: :infinity
          )
        )

      assert opts[:succeeded_retention_days] == :infinity
    end

    test "dead_retention_days rejects negative integers" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate!(with_branding(repo: SomeApp.Repo, dead_retention_days: -1))
      end
    end

    test "dlq_replay_max_rows rejects 0" do
      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate!(with_branding(repo: SomeApp.Repo, dlq_replay_max_rows: 0))
      end
    end

    test "dlq_replay_stagger_ms accepts 0 (non_neg_integer)" do
      opts = Config.validate!(with_branding(repo: SomeApp.Repo, dlq_replay_stagger_ms: 0))
      assert opts[:dlq_replay_stagger_ms] == 0
    end

    test "dunning accepts a keyword list override" do
      opts =
        Config.validate!(
          with_branding(
            repo: SomeApp.Repo,
            dunning: [
              mode: :disabled,
              grace_days: 30,
              terminal_action: :canceled,
              telemetry_prefix: [:myapp, :billing]
            ]
          )
        )

      assert opts[:dunning][:mode] == :disabled
      assert opts[:dunning][:grace_days] == 30
    end
  end

  describe "moduledoc" do
    test "contains NimbleOptions-generated docs" do
      {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(Accrue.Config)
      assert doc =~ "repo"
      assert doc =~ "stripe_secret_key"
      assert doc =~ "attach_invoice_pdf"
    end
  end
end
