defmodule Mix.Tasks.Accrue.Entitlements.ReferenceScenarios do
  use Mix.Task

  @shortdoc "Write or check the deterministic entitlement capability matrix"

  alias Accrue.Entitlements.ReferenceScenarios.Markdown

  @impl Mix.Task
  def run(argv) do
    {options, _rest, invalid} =
      OptionParser.parse(argv, strict: [write: :boolean, check: :boolean, root: :string])

    if invalid != [] or (options[:write] && options[:check]) do
      Mix.raise(
        "usage: mix accrue.entitlements.reference_scenarios --write|--check [--root PATH]"
      )
    end

    root = options[:root] || File.cwd!() |> Path.dirname()

    cond do
      options[:write] -> Markdown.write(root)
      options[:check] -> check!(root)
      true -> Mix.raise("pass exactly one of --write or --check")
    end
  end

  defp check!(root) do
    case Markdown.check(root) do
      :ok ->
        Mix.shell().info("Reference scenario capability matrix is current.")

      {:error, reasons} ->
        Mix.raise(
          "Reference scenario capability matrix drifted:\n" <> Enum.join(List.wrap(reasons), "\n")
        )
    end
  end
end
