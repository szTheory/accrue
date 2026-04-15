defmodule Accrue.ConfigBrandingTest do
  @moduledoc """
  Phase 6 Plan 01 Task 1: Nested `:branding` NimbleOptions schema + helpers +
  `validate_hex/1` custom validator (D6-02).
  """
  use ExUnit.Case, async: false

  alias Accrue.Config

  setup do
    # Snapshot + restore the :accrue app env for keys we touch so per-test
    # manipulation doesn't bleed into other suites running in the same BEAM.
    flat_keys = [
      :business_name,
      :logo_url,
      :from_email,
      :from_name,
      :support_email,
      :business_address
    ]

    branding = Application.get_env(:accrue, :branding)
    flats = Enum.map(flat_keys, fn k -> {k, Application.get_env(:accrue, k)} end)

    on_exit(fn ->
      if is_nil(branding) do
        Application.delete_env(:accrue, :branding)
      else
        Application.put_env(:accrue, :branding, branding)
      end

      for {k, v} <- flats do
        if is_nil(v),
          do: Application.delete_env(:accrue, k),
          else: Application.put_env(:accrue, k, v)
      end
    end)

    :ok
  end

  describe "branding/0 and branding/1" do
    test "branding/0 returns keyword list with all D6-02 keys populated with defaults" do
      kw = Config.branding()
      assert is_list(kw)

      expected_keys = [
        :business_name,
        :from_name,
        :from_email,
        :support_email,
        :reply_to_email,
        :logo_url,
        :logo_dark_url,
        :accent_color,
        :secondary_color,
        :font_stack,
        :company_address,
        :support_url,
        :social_links,
        :list_unsubscribe_url
      ]

      for k <- expected_keys do
        assert Keyword.has_key?(kw, k), "expected branding key #{inspect(k)}"
      end
    end

    test "branding/1 returns default business_name Accrue" do
      assert Config.branding(:business_name) == "Accrue"
    end

    test "branding/1 returns default accent_color #1F6FEB" do
      assert Config.branding(:accent_color) == "#1F6FEB"
    end

    test "branding/1 returns default secondary_color #6B7280" do
      assert Config.branding(:secondary_color) == "#6B7280"
    end

    test "social_links default is empty keyword list" do
      assert Config.branding(:social_links) == []
    end

    test "reply_to_email default is nil" do
      assert Config.branding(:reply_to_email) == nil
    end
  end

  describe "validate_hex/1" do
    test "accepts #rgb (3-char)" do
      assert Config.validate_hex("#fff") == {:ok, "#fff"}
      assert Config.validate_hex("#0A1") == {:ok, "#0A1"}
    end

    test "accepts #rrggbb (6-char)" do
      assert Config.validate_hex("#1F6FEB") == {:ok, "#1F6FEB"}
      assert Config.validate_hex("#6b7280") == {:ok, "#6b7280"}
    end

    test "accepts #rrggbbaa (8-char)" do
      assert Config.validate_hex("#1F6FEBff") == {:ok, "#1F6FEBff"}
    end

    test "rejects non-hex string" do
      assert {:error, _} = Config.validate_hex("not-hex")
    end

    test "rejects non-hex characters inside # prefix" do
      assert {:error, _} = Config.validate_hex("#xyz")
      assert {:error, _} = Config.validate_hex("#gggggg")
    end

    test "rejects wrong length" do
      assert {:error, _} = Config.validate_hex("#12")
      assert {:error, _} = Config.validate_hex("#12345")
      assert {:error, _} = Config.validate_hex("#1234567")
    end

    test "rejects non-string input" do
      assert {:error, _} = Config.validate_hex(nil)
      assert {:error, _} = Config.validate_hex(123)
      assert {:error, _} = Config.validate_hex(:red)
    end
  end

  describe "validate_at_boot!/0 with branding schema" do
    test "fails loud when :from_email is missing from nested branding" do
      Application.put_env(:accrue, :branding, support_email: "support@example.test")

      assert_raise NimbleOptions.ValidationError, ~r/from_email/, fn ->
        Config.validate_at_boot!()
      end
    end

    test "fails loud when :support_email is missing from nested branding" do
      Application.put_env(:accrue, :branding, from_email: "noreply@example.test")

      assert_raise NimbleOptions.ValidationError, ~r/support_email/, fn ->
        Config.validate_at_boot!()
      end
    end

    test "fails loud when accent_color is not hex" do
      Application.put_env(:accrue, :branding,
        from_email: "noreply@example.test",
        support_email: "support@example.test",
        accent_color: "red"
      )

      assert_raise NimbleOptions.ValidationError, ~r/hex/, fn ->
        Config.validate_at_boot!()
      end
    end
  end
end
