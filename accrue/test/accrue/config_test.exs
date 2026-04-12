defmodule Accrue.ConfigTest do
  use ExUnit.Case, async: false

  alias Accrue.Config

  describe "validate!/1" do
    test "happy path with required :repo" do
      opts = Config.validate!(repo: SomeApp.Repo)
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

  describe "moduledoc" do
    test "contains NimbleOptions-generated docs" do
      {:docs_v1, _, _, _, %{"en" => doc}, _, _} = Code.fetch_docs(Accrue.Config)
      assert doc =~ "repo"
      assert doc =~ "stripe_secret_key"
      assert doc =~ "attach_invoice_pdf"
    end
  end
end
