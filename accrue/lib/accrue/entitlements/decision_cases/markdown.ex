defmodule Accrue.Entitlements.DecisionCases.Markdown do
  @moduledoc false

  alias Accrue.Entitlements.DecisionCases

  def render(cases) do
    rows =
      cases
      |> Enum.sort_by(& &1.id)
      |> Enum.map(fn case_data ->
        expected = case_data.expected

        "| `#{case_data.id}` | #{case_data.evidence.rail}/#{case_data.evidence.environment} | #{expected.disposition} | #{expected.eligibility} | #{expected.lease} | `#{expected.reason}` |"
      end)

    [
      "# v1.59 Entitlement Decision Contract",
      "",
      "This is a derived non-runtime contract. It formats the canonical data-only Elixir corpus; it is not a reducer or public entitlement API.",
      "",
      "Contract version: `#{DecisionCases.version()}`",
      "",
      "| Case ID | Qualified evidence | Source disposition | Purchase eligibility | Continuity | Support reason |",
      "| --- | --- | --- | --- | --- | --- |",
      rows,
      ""
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end
end

defmodule Accrue.Entitlements.DecisionCases.Export do
  @moduledoc false

  alias Accrue.Entitlements.DecisionCases
  alias Accrue.Entitlements.DecisionCases.Markdown

  @markdown_relative ".planning/research/v1.59-DECISION-TABLE.md"
  @json_relative "accrue/priv/entitlements/v1.59-decision-cases.json"

  def write(root), do: write_files(root, generated())

  def check(root) do
    generated()
    |> Enum.reduce([], fn {relative, contents}, drifted ->
      path = Path.join(root, relative)
      if File.read(path) == {:ok, contents}, do: drifted, else: [path | drifted]
    end)
    |> case do
      [] -> :ok
      paths -> {:error, Enum.reverse(paths)}
    end
  end

  def json(cases) do
    %{
      contract_version: DecisionCases.version(),
      cases: Enum.map(Enum.sort_by(cases, & &1.id), &to_map/1)
    }
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
  end

  defp generated do
    cases = DecisionCases.all()
    [{@markdown_relative, Markdown.render(cases)}, {@json_relative, json(cases)}]
  end

  defp write_files(root, files) do
    Enum.each(files, fn {relative, contents} ->
      path = Path.join(root, relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
    end)

    :ok
  end

  defp to_map(case_data) do
    %{
      id: case_data.id,
      contract_version: case_data.contract_version,
      evidence: Map.from_struct(case_data.evidence),
      prior: Map.from_struct(case_data.prior),
      ordering: Map.from_struct(case_data.ordering),
      expected: Map.from_struct(case_data.expected)
    }
  end
end
