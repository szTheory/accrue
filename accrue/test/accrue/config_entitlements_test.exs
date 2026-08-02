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
    prev_processor = Application.get_env(:accrue, :processor, :__unset__)
    prev_rails = Application.get_env(:accrue, :rails, :__unset__)
    prev_default_rail = Application.get_env(:accrue, :default_rail, :__unset__)

    prev_webhook_signing_secrets =
      Application.get_env(:accrue, :webhook_signing_secrets, :__unset__)

    # Other sync config suites intentionally exercise a missing signing-secret
    # state. Keep this module hermetic when it selects the Stripe processor,
    # regardless of sync-module execution order in the full suite.
    Application.put_env(:accrue, :webhook_signing_secrets, %{
      stripe: ["whsec_config_entitlements_test"]
    })

    on_exit(fn ->
      case prev do
        :__unset__ -> Application.delete_env(:accrue, :entitlements)
        value -> Application.put_env(:accrue, :entitlements, value)
      end

      for {key, value} <- [
            processor: prev_processor,
            rails: prev_rails,
            default_rail: prev_default_rail,
            webhook_signing_secrets: prev_webhook_signing_secrets
          ] do
        case value do
          :__unset__ -> Application.delete_env(:accrue, key)
          configured -> Application.put_env(:accrue, key, configured)
        end
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

    test "the validated value is readable via entitlements/0 with nested defaults applied" do
      Application.put_env(:accrue, :entitlements, @valid_entitlements)

      assert Config.validate_at_boot!() == :ok

      ent = Config.entitlements()
      assert Keyword.has_key?(ent, :plans)

      assert Keyword.get(Keyword.fetch!(ent, :plans), :pro)[:features] == [
               :basic_reports,
               :api_access,
               :advanced_reports
             ]
    end
  end

  describe "multi-rail entitlement catalog (RAIL-01, RAIL-02)" do
    test "validates a Stripe default rail with Apple observer and normalizes qualified products" do
      Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)

      Application.put_env(:accrue, :rails,
        stripe: [
          source: :stripe,
          processor: Accrue.Processor.Stripe,
          environments: [:production],
          default_environment: :production
        ],
        apple: [
          source: :apple,
          environments: [:production],
          default_environment: :production
        ]
      )

      Application.put_env(:accrue, :default_rail, :stripe)

      Application.put_env(:accrue, :entitlements,
        plans: [pro: [products: [stripe: [production: ["price_pro"]]]]]
      )

      assert Config.validate_at_boot!() == :ok
      assert Config.rails() |> Keyword.fetch!(:stripe) |> Keyword.fetch!(:source) == :stripe
      assert Config.default_rail() == :stripe

      assert Config.entitlement_product_catalog() == %{
               {:stripe, :production, "price_pro"} => :pro
             }

      assert Application.get_env(:accrue, :processor) == Accrue.Processor.Stripe
    end
  end

  describe "rail registration and legacy default aliasing (RAIL-01, D-01 to D-03, D-17)" do
    test "legacy custom processors and price_ids remain untouched when rails are omitted" do
      Application.put_env(:accrue, :processor, Accrue.ConfigEntitlementsTest.CustomProcessor)

      Application.put_env(:accrue, :entitlements, plans: [pro: [price_ids: ["legacy_price"]]])

      assert Config.validate_at_boot!() == :ok
      assert Config.rails() == []
      assert Config.default_rail() == nil
      assert Config.entitlement_product_catalog() == %{}

      assert Application.get_env(:accrue, :processor) ==
               Accrue.ConfigEntitlementsTest.CustomProcessor
    end

    test "a host-fake proof rail is controllable in test configuration" do
      Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

      Application.put_env(:accrue, :rails,
        host_fake: [
          source: :host_fake,
          processor: Accrue.Processor.Fake,
          environments: [:sandbox],
          default_environment: :sandbox
        ]
      )

      Application.put_env(:accrue, :default_rail, :host_fake)

      assert Config.validate_at_boot!() == :ok
      assert Config.default_rail() == :host_fake
    end

    test "a host-fake proof rail honors the schema processor default" do
      Application.delete_env(:accrue, :processor)

      Application.put_env(:accrue, :rails,
        host_fake: [
          source: :host_fake,
          processor: Accrue.Processor.Fake,
          environments: [:sandbox],
          default_environment: :sandbox
        ]
      )

      Application.put_env(:accrue, :default_rail, :host_fake)

      assert Config.validate_at_boot!() == :ok
      assert Config.default_rail() == :host_fake
    end

    test "explicit defaults reject missing, unregistered, observer, and processor-mismatched rails" do
      Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)

      Application.put_env(:accrue, :rails,
        stripe: [source: :stripe, processor: Accrue.Processor.Stripe, environments: [:production]],
        apple: [source: :apple, environments: [:production]]
      )

      for {default_rail, expected} <- [
            {nil, "default_rail nil"},
            {:missing, "default_rail :missing"},
            {:apple, "default_rail :apple"}
          ] do
        Application.put_env(:accrue, :default_rail, default_rail)

        error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
        assert Exception.message(error) =~ expected
        assert Exception.message(error) =~ "registered controllable"
      end

      Application.put_env(:accrue, :rails,
        stripe: [source: :stripe, processor: Accrue.Processor.Fake, environments: [:production]]
      )

      Application.put_env(:accrue, :default_rail, :stripe)

      error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
      assert Exception.message(error) =~ "default_rail :stripe"
      assert Exception.message(error) =~ "matching :processor"
    end

    test "rail declaration order and concurrent reads leave configuration unchanged" do
      Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)

      rails = [
        apple: [
          source: :apple,
          environments: [:sandbox, :production],
          default_environment: :production
        ],
        stripe: [
          source: :stripe,
          processor: Accrue.Processor.Stripe,
          environments: [:production],
          default_environment: :production
        ]
      ]

      Application.put_env(:accrue, :rails, rails)
      Application.put_env(:accrue, :default_rail, :stripe)
      Application.put_env(:accrue, :entitlements, plans: [pro: [price_ids: ["price_pro"]]])

      assert Config.validate_at_boot!() == :ok
      expected = {Config.rails(), Config.default_rail(), Config.entitlement_product_catalog()}

      assert Enum.all?(1..8, fn _ -> Config.validate_at_boot!() == :ok end)

      assert Task.async_stream(1..8, fn _ ->
               {Config.rails(), Config.default_rail(), Config.entitlement_product_catalog()}
             end)
             |> Enum.map(fn {:ok, value} -> value end) == List.duplicate(expected, 8)

      assert Application.get_env(:accrue, :rails) == rails
    end
  end

  describe "qualified product catalog normalization (RAIL-02, D-04 to D-06)" do
    setup do
      Application.put_env(:accrue, :processor, Accrue.Processor.Stripe)

      Application.put_env(:accrue, :rails,
        stripe: [
          source: :stripe,
          processor: Accrue.Processor.Stripe,
          environments: [:sandbox, :production],
          default_environment: :production
        ],
        apple: [
          source: :apple,
          environments: [:sandbox, :production],
          default_environment: :production
        ]
      )

      Application.put_env(:accrue, :default_rail, :stripe)
      :ok
    end

    test "normalizes nested products by their full rail/environment/product tuple" do
      Application.put_env(:accrue, :entitlements,
        plans: [
          pro: [products: [apple: [sandbox: ["same"], production: ["apple_pro"]]]],
          enterprise: [products: [stripe: [production: ["same"], sandbox: ["stripe_sandbox"]]]]
        ]
      )

      assert Config.validate_at_boot!() == :ok

      assert Config.entitlement_product_catalog() == %{
               {:apple, :sandbox, "same"} => :pro,
               {:apple, :production, "apple_pro"} => :pro,
               {:stripe, :production, "same"} => :enterprise,
               {:stripe, :sandbox, "stripe_sandbox"} => :enterprise
             }
    end

    test "rejects offline and unregistered provider catalog locations" do
      Application.put_env(:accrue, :entitlements,
        plans: [pro: [products: [apple: [offline: ["offline_proof"]]]]]
      )

      error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
      assert Exception.message(error) =~ "{:apple, :offline}"

      Application.put_env(:accrue, :entitlements,
        plans: [pro: [products: [unknown: [production: ["unregistered"]]]]]
      )

      error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
      assert Exception.message(error) =~ "unregistered rail :unknown"
    end

    test "deduplicates same-plan tuples and names both plans for exact tuple collisions" do
      Application.put_env(:accrue, :entitlements,
        plans: [pro: [products: [stripe: [production: ["price_pro", "price_pro"]]]]]
      )

      assert Config.validate_at_boot!() == :ok

      assert Config.entitlement_product_catalog() == %{
               {:stripe, :production, "price_pro"} => :pro
             }

      Application.put_env(:accrue, :entitlements,
        plans: [
          pro: [products: [stripe: [production: ["price_shared"]]]],
          enterprise: [products: [stripe: [production: ["price_shared"]]]]
        ]
      )

      error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
      message = Exception.message(error)
      assert message =~ "pro"
      assert message =~ "enterprise"
      assert message =~ "{:stripe, :production, \"price_shared\"}"
    end

    test "expands bare price_ids only into the default rail/environment and catches alias collisions" do
      Application.put_env(:accrue, :entitlements,
        plans: [
          pro: [price_ids: ["price_shared"]],
          enterprise: [products: [stripe: [production: ["price_shared"]]]]
        ]
      )

      error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
      message = Exception.message(error)
      assert message =~ "pro"
      assert message =~ "enterprise"
      assert message =~ "{:stripe, :production, \"price_shared\"}"
    end

    test "reports default-alias collisions as qualified tuples, not raw identifiers" do
      Application.put_env(:accrue, :entitlements,
        plans: [
          pro: [price_ids: ["price_shared"]],
          enterprise: [price_ids: ["price_shared"]]
        ]
      )

      error = assert_raise Accrue.ConfigError, fn -> Config.validate_at_boot!() end
      message = Exception.message(error)
      assert message =~ "pro"
      assert message =~ "enterprise"
      assert message =~ "{:stripe, :production, \"price_shared\"}"
    end

    test "empty, singleton, reordered, repeated, and concurrent reads remain deterministic" do
      Application.put_env(:accrue, :entitlements, plans: [])
      assert Config.validate_at_boot!() == :ok
      assert Config.entitlement_product_catalog() == %{}

      plans = [
        enterprise: [products: [apple: [production: ["apple_enterprise"]]]],
        pro: [price_ids: ["stripe_pro"]]
      ]

      Application.put_env(:accrue, :entitlements, plans: plans)
      assert Config.validate_at_boot!() == :ok
      expected = Config.entitlement_product_catalog()
      assert map_size(expected) == 2
      assert Enum.all?(1..8, fn _ -> Config.entitlement_product_catalog() == expected end)

      assert Task.async_stream(1..8, fn _ -> Config.entitlement_product_catalog() end)
             |> Enum.map(fn {:ok, value} -> value end) == List.duplicate(expected, 8)

      Application.put_env(:accrue, :entitlements, plans: Enum.reverse(plans))
      assert Config.entitlement_product_catalog() == expected
    end
  end

  describe "invalid :entitlements config (ENT-01)" do
    test "a bad feature type (string instead of list) raises NimbleOptions.ValidationError" do
      Application.put_env(:accrue, :entitlements, plans: [pro: [features: "not-a-list"]])

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end

    test "an unknown inner key raises NimbleOptions.ValidationError" do
      Application.put_env(:accrue, :entitlements, plans: [pro: [features: [:x], bogus_key: true]])

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
    test "absent config has no :plans and validates clean" do
      Application.delete_env(:accrue, :entitlements)

      assert Config.validate_at_boot!() == :ok
      # Phase 124: entitlements/0 now surfaces the guard-key defaults via
      # Keyword.put_new, so the raw [] gains billable/on_deny/deny_path.
      # :plans (the Phase 123 catalog) stays absent.
      refute Keyword.has_key?(Config.entitlements(), :plans)
    end

    test "explicitly empty config validates clean" do
      Application.put_env(:accrue, :entitlements, [])

      assert Config.validate_at_boot!() == :ok
      refute Keyword.has_key?(Config.entitlements(), :plans)
    end
  end

  # --- Phase 124 (ENT-06/07): guard config keys -------------------------
  describe "guard config defaults (ENT-06/07)" do
    test "billable/on_deny/deny_path default to nil/:forbidden/\"/\" when unset" do
      Application.delete_env(:accrue, :entitlements)

      ent = Config.entitlements()
      assert Keyword.get(ent, :billable) == nil
      assert Keyword.get(ent, :on_deny) == :forbidden
      assert Keyword.get(ent, :deny_path) == "/"
    end

    test "guard defaults are surfaced even when only :plans is configured" do
      Application.put_env(:accrue, :entitlements, plans: [pro: [features: [:api_access]]])

      ent = Config.entitlements()
      assert Keyword.get(ent, :on_deny) == :forbidden
      assert Keyword.get(ent, :deny_path) == "/"
    end

    test "host-supplied guard keys override the defaults" do
      Application.put_env(:accrue, :entitlements,
        billable: fn _container -> :ok end,
        on_deny: {:redirect, "/pricing"},
        deny_path: "/login"
      )

      ent = Config.entitlements()
      assert is_function(Keyword.get(ent, :billable), 1)
      assert Keyword.get(ent, :on_deny) == {:redirect, "/pricing"}
      assert Keyword.get(ent, :deny_path) == "/login"
    end
  end

  describe "on_deny boot validation (ENT-06, T-124-01)" do
    test "a valid {:redirect, path} passes boot validation" do
      Application.put_env(:accrue, :entitlements, on_deny: {:redirect, "/pricing"})
      assert Config.validate_at_boot!() == :ok
    end

    test ":forbidden passes boot validation" do
      Application.put_env(:accrue, :entitlements, on_deny: :forbidden)
      assert Config.validate_at_boot!() == :ok
    end

    test "a {status, body} pair passes boot validation" do
      Application.put_env(:accrue, :entitlements, on_deny: {402, "Payment required"})
      assert Config.validate_at_boot!() == :ok
    end

    test "a 2-arity fun passes boot validation" do
      Application.put_env(:accrue, :entitlements, on_deny: fn _container, _ctx -> :halt end)
      assert Config.validate_at_boot!() == :ok
    end

    test "an MFA tuple passes boot validation" do
      Application.put_env(:accrue, :entitlements, on_deny: {MyMod, :handle, []})
      assert Config.validate_at_boot!() == :ok
    end

    test "a bare integer raises at boot (fail loud, not fail open)" do
      Application.put_env(:accrue, :entitlements, on_deny: 42)

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end

    test "a malformed {:redirect, non_string} raises at boot" do
      Application.put_env(:accrue, :entitlements, on_deny: {:redirect, 99})

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end
  end

  describe "deny_path boot validation (ENT-07)" do
    test "a non-string deny_path raises at boot" do
      Application.put_env(:accrue, :entitlements, deny_path: :not_a_string)

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end
  end

  # --- Phase 125 (ENT-09): past_due_grace knob -------------------------
  describe "past_due_grace config key (ENT-09, D-16)" do
    test "defaults to :none when unset (fail-closed)" do
      Application.delete_env(:accrue, :entitlements)
      assert Config.past_due_grace() == :none
    end

    test "default is surfaced even when only :plans is configured" do
      Application.put_env(:accrue, :entitlements, plans: [pro: [features: [:api_access]]])
      assert Config.past_due_grace() == :none
    end

    test ":none passes boot validation and reads back" do
      Application.put_env(:accrue, :entitlements, past_due_grace: :none)
      assert Config.validate_at_boot!() == :ok
      assert Config.past_due_grace() == :none
    end

    test ":dunning passes boot validation and reads back" do
      Application.put_env(:accrue, :entitlements, past_due_grace: :dunning)
      assert Config.validate_at_boot!() == :ok
      assert Config.past_due_grace() == :dunning
    end

    test "a positive integer passes boot validation and reads back" do
      Application.put_env(:accrue, :entitlements, past_due_grace: 7)
      assert Config.validate_at_boot!() == :ok
      assert Config.past_due_grace() == 7
    end

    test "an unknown atom raises at boot (fail loud, not fail open)" do
      Application.put_env(:accrue, :entitlements, past_due_grace: :bogus)

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end

    test "zero raises at boot (not a positive integer)" do
      Application.put_env(:accrue, :entitlements, past_due_grace: 0)

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end

    test "a negative integer raises at boot" do
      Application.put_env(:accrue, :entitlements, past_due_grace: -3)

      assert_raise NimbleOptions.ValidationError, fn ->
        Config.validate_at_boot!()
      end
    end
  end

  describe "validate_on_deny/1 (ENT-06, custom validator)" do
    test "accepts every conforming shape" do
      assert {:ok, :forbidden} = Config.validate_on_deny(:forbidden)
      assert {:ok, {:redirect, "/x"}} = Config.validate_on_deny({:redirect, "/x"})
      assert {:ok, {403, "no"}} = Config.validate_on_deny({403, "no"})
      fun = fn _a, _b -> :ok end
      assert {:ok, ^fun} = Config.validate_on_deny(fun)
      assert {:ok, {M, :f, []}} = Config.validate_on_deny({M, :f, []})
    end

    test "rejects non-conforming shapes with a descriptive message" do
      assert {:error, msg} = Config.validate_on_deny(42)
      assert msg =~ ":forbidden"
      assert {:error, _} = Config.validate_on_deny({:redirect, 99})
      assert {:error, _} = Config.validate_on_deny({200, :not_a_binary})
      assert {:error, _} = Config.validate_on_deny(fn _only_one_arg -> :ok end)
    end
  end
end
