defmodule Mix.Tasks.Accrue.Entitlements.DecisionCases do
  use Mix.Task

  @shortdoc "Write or check deterministic entitlement decision-case fixtures"

  alias Accrue.Entitlements.DecisionCases.Export

  @impl Mix.Task
  def run(argv) do
    {options, _rest, invalid} =
      OptionParser.parse(argv, strict: [write: :boolean, check: :boolean, root: :string])

    if invalid != [] or (options[:write] && options[:check]) do
      Mix.raise("usage: mix accrue.entitlements.decision_cases --write|--check [--root PATH]")
    end

    root = options[:root] || File.cwd!() |> Path.dirname()

    cond do
      options[:write] -> Export.write(root)
      options[:check] -> check!(root)
      true -> Mix.raise("pass exactly one of --write or --check")
    end
  end

  defp check!(root) do
    case Export.check(root) do
      :ok -> Mix.shell().info("Decision-case fixtures are current.")
      {:error, paths} -> Mix.raise("Decision-case fixtures drifted:\n" <> Enum.join(paths, "\n"))
    end
  end
end
