defmodule Accrue.Test.LiveProofFormatterTest do
  use ExUnit.Case, async: true

  alias Accrue.Test.LiveProofFormatter

  test "aggregates selected, passed, skipped, and failed events into a privacy-safe manifest" do
    path = Path.join(System.tmp_dir!(), "live-proof-#{System.unique_integer([:positive])}.json")
    on_exit(fn -> File.rm(path) end)

    state = LiveProofFormatter.init(path: path, now: fn -> ~U[2026-08-11 06:00:00Z] end)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: nil}}, state)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: {:skipped, "no key"}}}, state)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: {:failed, "sk_test_secret provider payload"}}}, state)
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

  test "replaces a prior manifest atomically" do
    path = Path.join(System.tmp_dir!(), "live-proof-#{System.unique_integer([:positive])}.json")
    File.write!(path, "stale")
    on_exit(fn -> File.rm(path) end)

    state = LiveProofFormatter.init(path: path, now: fn -> ~U[2026-08-11 06:00:00Z] end)
    {:noreply, state} = LiveProofFormatter.handle_cast({:test_finished, %{state: nil}}, state)
    {:noreply, _state} = LiveProofFormatter.handle_cast({:suite_finished, %{}}, state)

    assert %{"selected_count" => 1, "passed_count" => 1} = path |> File.read!() |> Jason.decode!()
    assert [] == Path.wildcard("#{path}.tmp-*")
  end
end
