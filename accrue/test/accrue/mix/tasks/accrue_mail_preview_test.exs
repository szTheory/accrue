defmodule Mix.Tasks.Accrue.Mail.PreviewTest do
  @moduledoc """
  Plan 06-07 Task 2: `mix accrue.mail.preview` task renders every
  fixture to `.accrue/previews/*`.

  Filesystem side effects → `async: false` + explicit cleanup.
  """
  use ExUnit.Case, async: false

  @preview_dir ".accrue/previews"

  setup do
    File.rm_rf!(@preview_dir)
    on_exit(fn -> File.rm_rf!(@preview_dir) end)
    :ok
  end

  describe "run/1 default (no args)" do
    test "writes 13 .html + 13 .txt files" do
      Mix.Tasks.Accrue.Mail.Preview.run([])

      html_files = Path.wildcard("#{@preview_dir}/*.html")
      txt_files = Path.wildcard("#{@preview_dir}/*.txt")

      assert length(html_files) == 13
      assert length(txt_files) == 13
    end
  end

  describe "run/1 --only" do
    test "renders only the listed types" do
      Mix.Tasks.Accrue.Mail.Preview.run(["--only", "receipt,trial_ending"])

      assert File.exists?("#{@preview_dir}/receipt.html")
      assert File.exists?("#{@preview_dir}/receipt.txt")
      assert File.exists?("#{@preview_dir}/trial_ending.html")
      assert File.exists?("#{@preview_dir}/trial_ending.txt")

      refute File.exists?("#{@preview_dir}/payment_failed.html")
    end

    test "unknown type raises Mix.Error with a helpful message" do
      assert_raise Mix.Error, ~r/Unknown email type/, fn ->
        Mix.Tasks.Accrue.Mail.Preview.run(["--only", "definitely_not_a_type"])
      end
    end
  end

  describe "run/1 --format" do
    test "html only writes .html outputs" do
      Mix.Tasks.Accrue.Mail.Preview.run(["--only", "receipt", "--format", "html"])

      assert File.exists?("#{@preview_dir}/receipt.html")
      refute File.exists?("#{@preview_dir}/receipt.txt")
    end

    test "txt only writes .txt outputs" do
      Mix.Tasks.Accrue.Mail.Preview.run(["--only", "receipt", "--format", "txt"])

      assert File.exists?("#{@preview_dir}/receipt.txt")
      refute File.exists?("#{@preview_dir}/receipt.html")
    end

    test "invalid format raises" do
      assert_raise Mix.Error, ~r/Invalid --format/, fn ->
        Mix.Tasks.Accrue.Mail.Preview.run(["--format", "xml"])
      end
    end

    test "pdf format is best-effort — missing DB row logs skip, does not crash" do
      Mix.Tasks.Accrue.Mail.Preview.run(["--only", "receipt", "--format", "pdf"])
      # No PDF was produced (no invoice_id in :receipt fixture) — log
      # line captured the skip. Just verify no crash.
      assert true
    end
  end
end
