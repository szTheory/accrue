defmodule Accrue.BackendAutomationContractTest do
  use ExUnit.Case, async: true

  @moduledoc false

  @opt_in "automation_contract: backend-zero-human"
  @task ~r/<task\b[^>]*>[\s\S]*?<\/task>/
  @automated_verify ~r/<verify>\s*<automated>\s*\S.*?<\/automated>\s*<\/verify>/s

  test "Phase 217 is opted into zero-human backend automation" do
    assert :ok = validate(plan("217-01-PLAN.md"))
  end

  test "rejects tracer and human verification tasks for opted-in backend plans" do
    assert {:error, :tracer_task} = validate(fixture("<task type=\"tracer\">"))

    assert {:error, :human_verification_task} =
             validate(fixture("<task type=\"checkpoint:human-verify\">"))

    assert {:error, :checkpoint_task} =
             validate(fixture("<task type=\"checkpoint:human-action\">"))

    assert {:error, :human_verification_task} =
             validate(
               fixture(
                 "<task type=\"auto\"><human-check>approve</human-check><verify><automated>mix test</automated></verify></task>"
               )
             )
  end

  test "rejects an opted-in backend task without an automated verify block" do
    assert {:error, :missing_automated_verify} =
             validate(
               fixture("<task type=\"auto\"><verify><manual>click it</manual></verify></task>")
             )
  end

  test "rejects an opted-in backend plan with a manual-only task after a valid task" do
    assert {:error, :missing_automated_verify} =
             validate(
               fixture("""
               <task type="auto"><verify><automated>mix test</automated></verify></task>
               <task type="auto"><verify><manual>click it</manual></verify></task>
               """)
             )
  end

  defp validate(contents) do
    cond do
      not String.contains?(contents, @opt_in) ->
        :ok

      String.contains?(contents, "type=\"tracer\"") ->
        {:error, :tracer_task}

      String.contains?(contents, "type=\"checkpoint:human-verify\"") ->
        {:error, :human_verification_task}

      String.contains?(contents, "type=\"checkpoint:") ->
        {:error, :checkpoint_task}

      String.contains?(contents, "<human-check>") or String.contains?(contents, "why_human:") ->
        {:error, :human_verification_task}

      not tasks_have_automated_verify?(contents) ->
        {:error, :missing_automated_verify}

      true ->
        :ok
    end
  end

  defp plan(name) do
    Path.expand(
      "../../../.planning/milestones/v1.59-phases/217-canonical-projection-and-compatibility/#{name}",
      __DIR__
    )
    |> File.read!()
  end

  defp tasks_have_automated_verify?(contents) do
    contents
    |> then(&Regex.scan(@task, &1))
    |> Enum.all?(fn [task] -> Regex.match?(@automated_verify, task) end)
  end

  defp fixture(task), do: "---\n#{@opt_in}\n---\n#{task}"
end
