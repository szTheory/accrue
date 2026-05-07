defmodule Accrue.Processor.CapabilitiesTest do
  use ExUnit.Case, async: true

  alias Accrue.Processor
  alias Accrue.Processor.Capabilities

  defmodule HostedOnlyProcessor do
    def processor_name, do: "hosted_only"

    def capabilities do
      %{
        customer: %{
          create: true,
          retrieve: true
        },
        payment_method: %{
          vault_acquisition: true
        },
        checkout: %{
          create: true,
          fetch: true,
          hosted: true,
          embedded: false
        },
        subscription: %{
          fetch: true
        },
        invoice: %{
          lifecycle_webhook_projection: true
        },
        webhook: %{
          verify: true,
          parse: true
        }
      }
    end

    def checkout_session_create(params, _opts) do
      {:ok,
       %{
         "id" => "txn_hosted_123",
         "status" => "ready",
         "checkout" => %{"url" => "https://checkout.example/#{params["customer"]}"}
       }}
    end

    def checkout_session_fetch(id, _opts) do
      {:ok,
       %{
         "id" => id,
         "status" => "ready",
         "checkout" => %{"url" => "https://checkout.example/#{id}"}
       }}
    end
  end

  test "known adapters report the promoted and staged contract rows explicitly" do
    stripe_caps = Capabilities.for(Accrue.Processor.Stripe)
    braintree_caps = Capabilities.for(Accrue.Processor.Braintree)

    assert get_in(stripe_caps, [:payment_method, :vault_acquisition]) == true
    assert get_in(stripe_caps, [:payment_method, :list]) == true
    assert get_in(stripe_caps, [:subscription, :direct_create]) == true
    assert get_in(stripe_caps, [:subscription, :lifecycle_webhook_projection]) == true
    assert get_in(stripe_caps, [:invoice, :lifecycle_webhook_projection]) == true
    assert Capabilities.support_label([:customer, :update]) == "all first-party"

    assert get_in(braintree_caps, [:payment_method, :list]) == true
    assert get_in(braintree_caps, [:customer, :update]) == true
    assert get_in(braintree_caps, [:subscription, :update]) == true
    assert get_in(braintree_caps, [:subscription, :cancel_immediately]) == true
    assert get_in(braintree_caps, [:subscription, :cancel_at_period_end]) == false
    assert get_in(braintree_caps, [:subscription, :pause]) == false
    assert Capabilities.support_label([:subscription, :update]) == "staged first-party target"
    assert Capabilities.support_label([:subscription, :cancel]) == "staged first-party target"

    assert Capabilities.support_label([:subscription, :cancel_immediately]) ==
             "staged first-party target"
  end

  test "custom adapters only advertise the leaves they declare" do
    caps = Capabilities.for(HostedOnlyProcessor)

    assert get_in(caps, [:checkout, :hosted]) == true
    assert get_in(caps, [:checkout, :embedded]) == false
    assert Capabilities.supports?(caps, [:checkout, :hosted])
    refute Capabilities.supports?(caps, [:checkout, :embedded])
    refute Capabilities.supports?(caps, [:subscription, :direct_create])
  end

  test "processor facade exposes configured capability map" do
    previous = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :processor, HostedOnlyProcessor)

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :processor, previous)
      else
        Application.delete_env(:accrue, :processor)
      end
    end)

    assert Processor.name() == "hosted_only"
    assert Processor.supports?([:checkout, :hosted])
    refute Processor.supports?([:checkout, :embedded])
    assert Processor.support_label([:subscription, :direct_create]) == "all first-party"
    assert Processor.support_label([:payment_method, :list]) == "all first-party"
    refute Processor.first_party_supported?([:subscription, :direct_create])
    assert Processor.first_party_supported?([:customer, :create])
  end
end
