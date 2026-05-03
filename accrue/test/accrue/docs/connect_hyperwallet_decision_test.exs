defmodule Accrue.Docs.ConnectHyperwalletDecisionTest do
  use ExUnit.Case, async: true

  defp repo_root, do: Path.expand("../../../..", __DIR__)

  defp read!(path) do
    path
    |> Path.join(repo_root())
    |> File.read!()
  end

  test "connect guide points Braintree readers at the Hyperwallet decision boundary" do
    connect_guide = read!("accrue/guides/connect.md")
    decision_guide = read!("accrue/guides/connect-hyperwallet-decision.md")

    assert connect_guide =~ "Braintree recurring billing is incompatible with Marketplace"
    assert connect_guide =~ "Braintree pay-ins and Hyperwallet payouts are separate truths"
    assert connect_guide =~ "connect-hyperwallet-decision.md"

    assert decision_guide =~ "strategically out of bounds unless the project boundary changes"
    assert decision_guide =~ "reopening requires an explicit strategy change plus a new milestone"
    assert decision_guide =~ "Braintree pay-ins and Hyperwallet payouts are separate truths"
    assert decision_guide =~ "minimal seller onboarding + payouts only"
  end

  test "decision guide locks the no-go verdict, evidence, and narrow if-go contract" do
    decision_guide = read!("accrue/guides/connect-hyperwallet-decision.md")

    assert decision_guide =~ "Braintree recurring billing is incompatible with Marketplace"

    assert decision_guide =~
             "Hyperwallet is a separate payout program with separate webhook URLs, admin users, and API-credential recipients"

    assert decision_guide =~ "strategically out of bounds unless the project boundary changes"
    assert decision_guide =~ "reopening requires an explicit strategy change plus a new milestone"
    assert decision_guide =~ "Braintree pay-ins and Hyperwallet payouts are separate truths"
    assert decision_guide =~ "minimal seller onboarding + payouts only"
  end
end
