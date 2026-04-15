defmodule Accrue.Plug.PutConnectedAccountTest do
  use Accrue.ConnectCase, async: true

  alias Accrue.Connect
  alias Accrue.Connect.Account
  alias Accrue.Plug.PutConnectedAccount

  # Stub tenancy module — lives inline so the test file is self-contained.
  defmodule Tenancy do
    @moduledoc false
    def from_assigns(%Plug.Conn{assigns: %{stripe_account: id}}), do: id
    def from_assigns(_conn), do: nil

    def from_value(value, _conn), do: value
  end

  defp conn(assigns \\ %{}) do
    %Plug.Conn{assigns: assigns}
  end

  describe "init/1" do
    test "raises ArgumentError without a :from option" do
      assert_raise ArgumentError, ~r/requires a `:from` MFA tuple/, fn ->
        PutConnectedAccount.init([])
      end
    end

    test "raises ArgumentError when :from is not an MFA tuple" do
      assert_raise ArgumentError, ~r/expected `:from` to be an MFA tuple/, fn ->
        PutConnectedAccount.init(from: "acct_raw_string")
      end
    end

    test "accepts a valid {Mod, :fun, args} tuple" do
      opts = PutConnectedAccount.init(from: {Tenancy, :from_assigns, []})
      assert Keyword.fetch!(opts, :from) == {Tenancy, :from_assigns, []}
    end
  end

  describe "call/2" do
    test "sets pdict when MFA returns a binary id" do
      opts = PutConnectedAccount.init(from: {Tenancy, :from_assigns, []})
      _ = PutConnectedAccount.call(conn(%{stripe_account: "acct_from_assigns"}), opts)

      assert Connect.current_account_id() == "acct_from_assigns"
    end

    test "sets pdict when MFA returns a %Account{} struct" do
      struct = %Account{stripe_account_id: "acct_from_struct"}

      opts = PutConnectedAccount.init(from: {Tenancy, :from_value, [struct]})
      _ = PutConnectedAccount.call(conn(), opts)

      assert Connect.current_account_id() == "acct_from_struct"
    end

    test "no-ops (leaves pdict untouched) when MFA returns nil" do
      opts = PutConnectedAccount.init(from: {Tenancy, :from_assigns, []})
      _ = PutConnectedAccount.call(conn(), opts)

      refute Connect.current_account_id()
    end

    test "raises ArgumentError on unexpected MFA return value" do
      opts = PutConnectedAccount.init(from: {Tenancy, :from_value, [{:weird, :tuple}]})

      assert_raise ArgumentError, ~r/unexpected value/, fn ->
        PutConnectedAccount.call(conn(), opts)
      end
    end
  end
end
