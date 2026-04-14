defmodule Accrue.Credo.NoRawStatusAccessTest do
  use Credo.Test.Case, async: true

  alias Accrue.Credo.NoRawStatusAccess

  test "flags == on subscription.status outside the Subscription module" do
    """
    defmodule MyApp.Foo do
      def ok?(sub), do: sub.status == :active
    end
    """
    |> to_source_file()
    |> run_check(NoRawStatusAccess)
    |> assert_issue()
  end

  test "flags membership checks on subscription.status" do
    """
    defmodule MyApp.Bar do
      def ok?(sub), do: sub.status in [:active, :trialing]
    end
    """
    |> to_source_file()
    |> run_check(NoRawStatusAccess)
    |> assert_issue()
  end

  test "allows predicate calls on Accrue.Billing.Subscription" do
    """
    defmodule MyApp.Baz do
      def ok?(sub), do: Accrue.Billing.Subscription.active?(sub)
    end
    """
    |> to_source_file()
    |> run_check(NoRawStatusAccess)
    |> refute_issues()
  end

  test "exempts the Accrue.Billing.Subscription module itself" do
    """
    defmodule Accrue.Billing.Subscription do
      def active?(sub), do: sub.status == :active
    end
    """
    |> to_source_file()
    |> run_check(NoRawStatusAccess)
    |> refute_issues()
  end
end
