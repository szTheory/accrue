defmodule Accrue.Telemetry.BillingSpanCoverageTest do
  use ExUnit.Case, async: true

  @audited_exceptions %{
    __info__: "Elixir introspection helper",
    module_info: "Erlang introspection helper"
  }

  test "every public Billing context function is spanned or explicitly audited" do
    source = File.read!("lib/accrue/billing.ex")

    public_billing_functions =
      Accrue.Billing.__info__(:functions)
      |> Enum.reject(fn {name, _arity} -> Map.has_key?(@audited_exceptions, name) end)

    unaudited =
      Enum.reject(public_billing_functions, fn {name, _arity} ->
        spanned?(source, name) or Map.has_key?(@audited_exceptions, name)
      end)

    assert unaudited == [],
           "unaudited public Billing functions: #{inspect(unaudited)}; wrap each in Accrue.Telemetry.span/3 or add a reason to the audited exception map"
  end

  defp spanned?(source, name) do
    function_name = Atom.to_string(name)

    source =~ "Accrue.Telemetry.span" and
      (source =~ "def #{function_name}" or source =~ "defdelegate #{function_name}")
  end
end
