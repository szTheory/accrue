defmodule Accrue.Processor.StripeEntitlementsContractTest do
  use ExUnit.Case, async: false

  alias Accrue.Processor
  alias Accrue.Processor.Stripe

  defmodule EntitlementsTransport do
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
    prior_processor = Application.get_env(:accrue, :processor)
    prior_secret = Application.get_env(:accrue, :stripe_secret_key)

    Application.put_env(:accrue, :processor, Stripe)
    Application.put_env(:accrue, :stripe_secret_key, "sk_test_entitlements_contract")

    {:ok, _pid} =
      Agent.start_link(fn -> %{responses: [], requests: []} end, name: EntitlementsTransport)

    on_exit(fn ->
      if prior_processor do
        Application.put_env(:accrue, :processor, prior_processor)
      else
        Application.delete_env(:accrue, :processor)
      end

      if prior_secret do
        Application.put_env(:accrue, :stripe_secret_key, prior_secret)
      else
        Application.delete_env(:accrue, :stripe_secret_key)
      end

      if Process.whereis(EntitlementsTransport) do
        Agent.stop(EntitlementsTransport)
      end
    end)

    :ok
  end

  test "drains ActiveEntitlement.stream!/3 and projects webhook-compatible maps" do
    put_responses([
      list_response(
        [
          %{
            "id" => "ent_alpha",
            "object" => "entitlements.active_entitlement",
            "feature" => "feat_alpha",
            "lookup_key" => "alpha",
            "livemode" => false,
            "unused" => "not projected"
          }
        ],
        true
      ),
      list_response(
        [
          %{
            "id" => "ent_beta",
            "object" => "entitlements.active_entitlement",
            "feature" => "feat_beta",
            "lookup_key" => "beta",
            "livemode" => true
          }
        ],
        false
      )
    ])

    assert {:ok,
            [
              %{
                "id" => "ent_alpha",
                "object" => "entitlements.active_entitlement",
                "feature" => "feat_alpha",
                "lookup_key" => "alpha",
                "livemode" => false
              },
              %{
                "id" => "ent_beta",
                "object" => "entitlements.active_entitlement",
                "feature" => "feat_beta",
                "lookup_key" => "beta",
                "livemode" => true
              }
            ]} =
             Processor.list_active_entitlements("cus_contract", transport: EntitlementsTransport)

    assert [
             %{method: :get, _params: %{"customer" => "cus_contract", "limit" => "100"}},
             %{
               method: :get,
               _params: %{
                 "customer" => "cus_contract",
                 "limit" => "100",
                 "starting_after" => "ent_alpha"
               }
             }
           ] = requests()

    refute Enum.any?(requests(), fn request ->
             Enum.any?(request.headers, fn {name, _value} ->
               String.downcase(name) == "idempotency-key"
             end)
           end)
  end

  test "exposes the SDK-owned active entitlement list path through processor metadata" do
    assert Processor.active_entitlement_list_metadata() == %{
             list_path: "/v1/entitlements/active_entitlements"
           }
  end

  test "maps a page failure through ErrorMapper and does not return a partial success" do
    put_responses([
      list_response([entitlement("ent_partial", "partial")], true),
      error_response()
    ])

    assert {:error, %Accrue.RateLimitError{request_id: "req_rate"}} =
             Processor.list_active_entitlements("cus_contract",
               transport: EntitlementsTransport,
               max_retries: 0
             )

    assert length(requests()) == 2
  end

  defp put_responses(responses) do
    Agent.update(EntitlementsTransport, &%{&1 | responses: responses})
  end

  defp requests do
    Agent.get(EntitlementsTransport, & &1.requests)
  end

  defp list_response(data, has_more) do
    %{
      status: 200,
      headers: [{"content-type", "application/json"}],
      body:
        Jason.encode!(%{
          "object" => "list",
          "url" => "/v1/entitlements/active_entitlements",
          "has_more" => has_more,
          "data" => data
        })
    }
  end

  defp error_response do
    %{
      status: 429,
      headers: [{"content-type", "application/json"}, {"request-id", "req_rate"}],
      body:
        Jason.encode!(%{
          "error" => %{
            "type" => "rate_limit_error",
            "code" => "rate_limited",
            "message" => "Too many requests"
          }
        })
    }
  end

  defp entitlement(id, lookup_key) do
    %{
      "id" => id,
      "object" => "entitlements.active_entitlement",
      "feature" => "feat_" <> lookup_key,
      "lookup_key" => lookup_key,
      "livemode" => false
    }
  end
end
