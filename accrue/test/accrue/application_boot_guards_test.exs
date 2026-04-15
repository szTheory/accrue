defmodule Accrue.ApplicationBootGuardsTest do
  @moduledoc """
  Plan 06-07 Task 2: boot-time guard warnings introduced by this plan.

    * `warn_pdf_adapter_unavailable/0` — Pitfall 3 (ChromicPDF absent)
    * `warn_oban_queue_vs_pdf_pool/0` — Pitfall 4 (queue > pool)
    * `warn_company_address_locale_mismatch/0` — D6-07 (EU/CA locale
      without `:branding[:company_address]`)

  Each guard is idempotent via `:persistent_term` dedupe; tests clear
  the dedupe key before each scenario.
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Accrue.Application, as: App

  defp clear_dedupe_keys do
    for k <- [
          :accrue_pdf_adapter_unavailable_warned?,
          :accrue_oban_queue_vs_pdf_pool_warned?,
          :accrue_company_address_locale_warned?
        ] do
      try do
        :persistent_term.erase(k)
      rescue
        _ -> :ok
      end
    end
  end

  setup do
    clear_dedupe_keys()

    original_pdf = Application.get_env(:accrue, :pdf_adapter)
    original_branding = Application.get_env(:accrue, :branding)
    original_oban = Application.get_env(:accrue, Oban)
    original_pool = Application.get_env(:accrue, :chromic_pdf_pool_size)

    on_exit(fn ->
      clear_dedupe_keys()

      if is_nil(original_pdf),
        do: Application.delete_env(:accrue, :pdf_adapter),
        else: Application.put_env(:accrue, :pdf_adapter, original_pdf)

      if is_nil(original_branding),
        do: Application.delete_env(:accrue, :branding),
        else: Application.put_env(:accrue, :branding, original_branding)

      if is_nil(original_oban),
        do: Application.delete_env(:accrue, Oban),
        else: Application.put_env(:accrue, Oban, original_oban)

      if is_nil(original_pool),
        do: Application.delete_env(:accrue, :chromic_pdf_pool_size),
        else: Application.put_env(:accrue, :chromic_pdf_pool_size, original_pool)
    end)

    :ok
  end

  describe "warn_pdf_adapter_unavailable/0" do
    test "no warn when adapter is not ChromicPDF" do
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Null)

      log = capture_log(fn -> assert :ok = App.warn_pdf_adapter_unavailable() end)
      refute log =~ "pdf_adapter"
    end

    test "no warn in :test env even when ChromicPDF is absent" do
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)

      # Mix.env/0 returns :test inside the test suite — guard
      # silently returns :ok because the warning is prod-only.
      log = capture_log(fn -> assert :ok = App.warn_pdf_adapter_unavailable() end)
      refute log =~ "ChromicPDF"
    end
  end

  describe "warn_oban_queue_vs_pdf_pool/0" do
    test "no warn when queue concurrency ≤ pool size" do
      Application.put_env(:accrue, Oban, queues: [accrue_mailers: 3])
      Application.put_env(:accrue, :chromic_pdf_pool_size, 5)

      log = capture_log(fn -> assert :ok = App.warn_oban_queue_vs_pdf_pool() end)
      refute log =~ "accrue_mailers"
    end

    test "warns when queue concurrency > pool size" do
      Application.put_env(:accrue, Oban, queues: [accrue_mailers: 20])
      Application.put_env(:accrue, :chromic_pdf_pool_size, 3)

      log = capture_log(fn -> assert :ok = App.warn_oban_queue_vs_pdf_pool() end)
      assert log =~ "accrue_mailers"
      assert log =~ "20"
      assert log =~ "3"
    end

    test "dedupes via :persistent_term — second call silent" do
      Application.put_env(:accrue, Oban, queues: [accrue_mailers: 20])
      Application.put_env(:accrue, :chromic_pdf_pool_size, 3)

      assert :ok = App.warn_oban_queue_vs_pdf_pool()

      log = capture_log(fn -> assert :ok = App.warn_oban_queue_vs_pdf_pool() end)
      refute log =~ "accrue_mailers"
    end
  end

  describe "warn_company_address_locale_mismatch/0" do
    test "no warn when :company_address is set" do
      Application.put_env(:accrue, :branding, company_address: "123 Main St")

      log = capture_log(fn -> assert :ok = App.warn_company_address_locale_mismatch() end)
      refute log =~ "company_address"
    end

    test "silently skips when Repo is unreachable" do
      # In test env without a DB connection checkout this guard
      # catches the error and returns :ok. We don't assert on log
      # content — the point is: boot never crashes.
      Application.put_env(:accrue, :branding, [])
      assert :ok = App.warn_company_address_locale_mismatch()
    end
  end
end
