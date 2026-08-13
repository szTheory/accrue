defmodule Accrue.Test.LiveProofFormatterTest do
  use ExUnit.Case, async: false

  alias Accrue.Test.LiveProofFormatter

  test "aggregates selected, passed, skipped, and failed events into a privacy-safe manifest" do
    path = Path.join(System.tmp_dir!(), "live-proof-#{System.unique_integer([:positive])}.json")
    on_exit(fn -> File.rm(path) end)

    {:ok, state} = LiveProofFormatter.init(path: path, now: fn -> ~U[2026-08-11 06:00:00Z] end)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: nil}}, state)

    {:noreply, state} =
      LiveProofFormatter.handle_cast({:test_finished, %{state: {:skipped, "no key"}}}, state)

    {:noreply, state} =
      LiveProofFormatter.handle_cast(
        {:test_finished, %{state: {:failed, "sk_test_secret provider payload"}}},
        state
      )

    {:noreply, _state} = LiveProofFormatter.handle_cast({:suite_finished, %{run: 1}}, state)

    manifest = path |> File.read!() |> Jason.decode!()

    assert manifest == %{
             "schema_version" => 1,
             "selected_count" => 3,
             "passed_count" => 1,
             "skipped_count" => 1,
             "failed_count" => 1,
             "started_at" => "2026-08-11T06:00:00Z",
             "finished_at" => "2026-08-11T06:00:00Z"
           }

    refute File.read!(path) =~ "sk_test_secret"
    refute File.read!(path) =~ "provider payload"
  end

  test "ignores ExUnit excluded events without changing aggregate counters" do
    {:ok, state} = LiveProofFormatter.init(now: fn -> ~U[2026-08-11 06:00:00Z] end)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: nil}}, state)

    {:noreply, state} =
      LiveProofFormatter.handle_cast(
        {:test_finished, %{state: {:excluded, "untagged fixture"}}},
        state
      )

    assert Map.take(state, [:selected_count, :passed_count, :skipped_count, :failed_count]) == %{
             selected_count: 1,
             passed_count: 1,
             skipped_count: 0,
             failed_count: 0
           }
  end

  test "replaces a prior manifest atomically" do
    path = Path.join(System.tmp_dir!(), "live-proof-#{System.unique_integer([:positive])}.json")
    File.write!(path, "stale")
    on_exit(fn -> File.rm(path) end)

    {:ok, state} = LiveProofFormatter.init(path: path, now: fn -> ~U[2026-08-11 06:00:00Z] end)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: nil}}, state)
    {:noreply, _state} = LiveProofFormatter.handle_cast({:suite_finished, %{}}, state)

    assert %{"selected_count" => 1, "passed_count" => 1} = path |> File.read!() |> Jason.decode!()
    assert [] == Path.wildcard("#{path}.tmp-*")
  end

  test "real tagged-only Mix selection writes proved aggregate evidence" do
    root = Path.expand("../../..", __DIR__)

    fixture =
      Path.join(__DIR__, "live_proof_selection_#{System.unique_integer([:positive])}_test.exs")

    manifest =
      Path.join(
        System.tmp_dir!(),
        "live-proof-selection-#{System.unique_integer([:positive])}.json"
      )

    record =
      Path.join(System.tmp_dir!(), "live-proof-record-#{System.unique_integer([:positive])}.json")

    on_exit(fn ->
      File.rm(fixture)
      File.rm(manifest)
      File.rm(record)
    end)

    File.write!(fixture, """
    defmodule Accrue.LiveProofSelectionTaggedFixture do
      use ExUnit.Case, async: true

      @moduletag :live_stripe
      test "selected fixture passes" do
        assert true
      end
    end

    defmodule Accrue.LiveProofSelectionExcludedFixture do
      use ExUnit.Case, async: true

      test "untagged fixture is excluded" do
        assert true
      end
    end
    """)

    {output, 0} =
      System.cmd("mix", ["test", fixture, "--only", "live_stripe"],
        cd: Path.join(root, "accrue"),
        env: [{"ACCRUE_PROVIDER_MANIFEST", manifest}],
        stderr_to_stdout: true
      )

    assert %{
             "selected_count" => 1,
             "passed_count" => 1,
             "skipped_count" => 0,
             "failed_count" => 0
           } = manifest |> File.read!() |> Jason.decode!()

    {_finalize_output, 0} =
      System.cmd(
        "node",
        [
          Path.join(root, "scripts/ci/provider_proof.mjs"),
          "--finalize",
          "--trigger",
          "workflow_dispatch",
          "--sha",
          "selection-proof-sha",
          "--policy",
          "required",
          "--raw-conclusion",
          "success",
          "--configured",
          "true",
          "--manifest",
          manifest,
          "--out",
          record
        ],
        stderr_to_stdout: true
      )

    assert %{"proof_state" => "proved"} = record |> File.read!() |> Jason.decode!()
    refute output =~ "selected fixture"
    refute output =~ "untagged fixture"
  end
end
