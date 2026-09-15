defmodule Accrue.ReleaseBootRegressionTest do
  # Spawns a child OS process — never run concurrently with other tests that
  # mutate global state the child process might also touch (it doesn't, but
  # being explicit here matches the other env-mutating tests in this suite).
  use ExUnit.Case, async: false

  @moduletag :release_shape

  @moduledoc """
  Release-shaped regression test for the eager build-tool environment lookup
  defect. Runs `test/fixtures/release_boot_probe.exs` in a genuinely fresh
  child `elixir` process with the build-tool module removed from the code
  path, proving Accrue's auth boot path survives when the build-tool
  application is absent (as it is in a real OTP release).

  This is a merge-blocking gate per this project's executable-acceptance
  policy — not a human checkpoint.
  """

  test "auth boot path survives with the build-tool module undefined" do
    elixir_executable = System.find_executable("elixir")

    if is_nil(elixir_executable) do
      flunk("release-shaped regression test requires an `elixir` executable on PATH")
    end

    probe_path =
      Path.join([File.cwd!(), "test", "fixtures", "release_boot_probe.exs"])

    pa_args =
      File.cwd!()
      |> Path.join("_build/#{Mix.env()}/lib/*/ebin")
      |> Path.wildcard()
      |> Enum.map(&Path.expand/1)
      |> Enum.flat_map(&["-pa", &1])

    {output, status} =
      System.cmd(elixir_executable, pa_args ++ [probe_path], stderr_to_stdout: true)

    assert status == 0,
           "release boot probe exited #{status} (expected 0). Captured output:\n#{output}"

    assert output =~ "ALL_OK",
           "release boot probe did not print ALL_OK. Captured output:\n#{output}"
  end
end
