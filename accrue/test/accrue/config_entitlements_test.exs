defmodule Accrue.ConfigEntitlementsTest do
  # Mutates the :accrue app env (:entitlements) and exercises the boot
  # validation path, so this case MUST be async: false (mirrors
  # test/accrue/storage/null_test.exs L6-19).
  use ExUnit.Case, async: false

  alias Accrue.Config

  # The CONTEXT.md example catalog (123-CONTEXT.md L92-102): free/pro/enterprise
  # with features/limits/price_ids. Used as the "valid config" fixture.
  @valid_entitlements [
    plans: [
      free: [features: [:basic_reports], limits: [seats: 1, projects: 3]],
      pro: [
        features: [:basic_reports, :api_access, :advanced_reports],
        limits: [seats: 10, projects: 100],
        price_ids: ["price_pro_monthly", "price_pro_annual"]
      ],
      enterprise: [
        features: [:basic_reports, :api_access, :advanced_reports, :sso, :audit_log],
        limits: [seats: 250],
        price_ids: ["price_ent_monthly", "price_ent_annual"]
      ]
    ],
    unmapped_action: :deny
  ]

  setup do
    prev = Application.get_env(:accrue, :entitlements, :__unset__)

    on_exit(fn ->
      case prev do
        :__unset__ -> Application.delete_env(:accrue, :entitlements)
        value -> Application.put_env(:accrue, :entitlements, value)
      end
    end)

    :ok
  end

  describe "valid :entitlements config (ENT-01)" do
    test "validates clean at boot" do
      Application.put_env(:accrue, :entitlements, @valid_entitlements)

      # validate_at_boot!/0 runs the @schema validation AND
      # maybe_validate_boot_setup!/1; under :test the migration check is
      # skipped (config.ex L789), and :repo is set in config/test.exs.
      assert Config.validate_at_boot!() == :ok
    end

    test "the schema fragment validates via validate!/1 directly" do
      assert Keyword.fetch!(Config.validate!(repo: Accrue.TestRepo, entitlements: @valid_entitlements), :entitlements)
    end
  end

  describe "invalid :entitlements config (ENT-01)" do
    test "a bad feature type (string instead of list) raises NimbleOptions.ValidationError" do
      Application.put_env(:accrue, :entitlements,
        plans: [pro: [features: "not-a-list"]]
      )

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end

    test "an unknown inner key raises NimbleOptions.ValidationError" do
      Application.put_env(:accrue, :entitlements,
        plans: [pro: [features: [:x], bogus_key: true]]
      )

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end
  end

  describe "duplicate price_id collision guard (ENT-01, D-04, T-123-01)" do
    test "the same price_id under two plans raises Accrue.ConfigError naming both plans + the price_id" do
      Application.put_env(:accrue, :entitlements,
        plans: [
          pro: [features: [:api_access], price_ids: ["price_shared"]],
          enterprise: [features: [:sso], price_ids: ["price_shared"]]
        ]
      )

      error =
        assert_raise Accrue.ConfigError, fn ->
          Config.validate_at_boot!()
        end

      message = Exception.message(error)
      assert message =~ "price_shared"
      assert message =~ "pro"
      assert message =~ "enterprise"
    end

    test "the same price_id repeated within ONE plan does NOT raise" do
      Application.put_env(:accrue, :entitlements,
        plans: [
          pro: [features: [:api_access], price_ids: ["price_pro_monthly", "price_pro_monthly"]]
        ]
      )

      assert Config.validate_at_boot!() == :ok
    end
  end

  describe "absent / empty :entitlements (ENT-01)" do
    test "absent config defaults to [] and validates clean" do
      Application.delete_env(:accrue, :entitlements)

      assert Config.validate_at_boot!() == :ok
      assert Config.entitlements() == []
    end

    test "explicitly empty config validates clean" do
      Application.put_env(:accrue, :entitlements, [])

      assert Config.validate_at_boot!() == :ok
      assert Config.entitlements() == []
    end
  end
end
