defmodule Accrue.Processor.StripeConnectContractTest do
  use ExUnit.Case, async: false

  alias Accrue.Processor.Stripe

  defmodule Transport do
    @behaviour LatticeStripe.Transport

    @impl true
    def request(request) do
      Agent.get_and_update(__MODULE__, fn %{responses: [response | rest], requests: requests} =
                                            state ->
        {{:ok, response}, %{state | responses: rest, requests: requests ++ [request]}}
      end)
    end
  end

  setup do
    prior_secret = Application.get_env(:accrue, :stripe_secret_key)
    Application.put_env(:accrue, :stripe_secret_key, "sk_test_connect_contract")

    {:ok, _pid} = Agent.start_link(fn -> %{responses: [], requests: []} end, name: Transport)

    on_exit(fn ->
      if prior_secret do
        Application.put_env(:accrue, :stripe_secret_key, prior_secret)
      else
        Application.delete_env(:accrue, :stripe_secret_key)
      end

      if Process.whereis(Transport), do: Agent.stop(Transport)
    end)

    :ok
  end

  test "connected-account CRUD delegates to Stripe's platform-scoped account API" do
    account = %{
      "id" => "acct_contract",
      "object" => "account",
      "type" => "express",
      "country" => "US",
      "charges_enabled" => false,
      "details_submitted" => false,
      "payouts_enabled" => false
    }

    put_responses([
      response(account),
      response(account),
      response(account),
      response(Map.put(account, "deleted", true)),
      response(account),
      response(%{
        "object" => "list",
        "url" => "/v1/accounts",
        "has_more" => false,
        "data" => [account]
      })
    ])

    opts = [transport: Transport]

    assert {:ok, %{id: "acct_contract"}} = Stripe.create_account(%{type: "express"}, opts)
    assert {:ok, %{id: "acct_contract"}} = Stripe.retrieve_account("acct_contract", opts)

    assert {:ok, %{id: "acct_contract"}} =
             Stripe.update_account("acct_contract", %{email: "owner@example.com"}, opts)

    assert {:ok, %{id: "acct_contract"}} = Stripe.delete_account("acct_contract", opts)

    assert {:ok, %{id: "acct_contract"}} =
             Stripe.reject_account("acct_contract", %{reason: "fraud"}, opts)

    assert {:ok,
            %{data: %LatticeStripe.List{data: [%LatticeStripe.Account{id: "acct_contract"}]}}} =
             Stripe.list_accounts(%{}, opts)

    assert Enum.map(requests(), fn request ->
             {request.method, URI.parse(request.url).path}
           end) == [
             {:post, "/v1/accounts"},
             {:get, "/v1/accounts/acct_contract"},
             {:post, "/v1/accounts/acct_contract"},
             {:delete, "/v1/accounts/acct_contract"},
             {:post, "/v1/accounts/acct_contract/reject"},
             {:get, "/v1/accounts"}
           ]

    refute Enum.any?(requests(), fn request ->
             Enum.any?(request.headers, fn {name, _value} ->
               String.downcase(name) == "stripe-account"
             end)
           end)
  end

  defp put_responses(responses) do
    Agent.update(Transport, &%{&1 | responses: responses})
  end

  defp requests do
    Agent.get(Transport, & &1.requests)
  end

  defp response(body) do
    %{
      status: 200,
      headers: [{"content-type", "application/json"}],
      body: Jason.encode!(body)
    }
  end
end
