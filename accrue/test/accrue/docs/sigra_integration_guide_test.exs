defmodule Accrue.Docs.SigraIntegrationGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/sigra_integration.md"

  test "Sigra guide surfaces non-Sigra escape hatch before dependency instructions" do
    guide = File.read!(@guide)

    assert guide =~ "Not using Sigra"
    assert guide =~ "auth_adapters.md"
    assert guide =~ "organization_billing.md"

    {idx_not_using, _} = :binary.match(guide, "Not using Sigra")
    {idx_dep, _} = :binary.match(guide, "## Add the dependency")

    assert idx_not_using < idx_dep,
           "expected 'Not using Sigra' before '## Add the dependency' so installers read the escape hatch first"
  end
end
