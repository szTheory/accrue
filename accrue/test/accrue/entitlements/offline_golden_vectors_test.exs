defmodule Accrue.Entitlements.OfflineGoldenVectorsTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.OfflineGoldenVectorVerifier

  test "the checked-in signed corpus is a merge-blocking verifier contract" do
    assert {:ok, observations} = OfflineGoldenVectorVerifier.verify_fixture!()

    assert Enum.map(observations, & &1.id) == Enum.sort(Enum.map(observations, & &1.id))
    assert Enum.any?(observations, &(&1.id == "valid_allow" and &1.result == :accept))
    assert Enum.any?(observations, &(&1.id == "valid_signed_denial" and &1.cache == :deny))

    assert Map.new(observations, &{&1.id, {&1.result, &1.reason, &1.cache}}) == %{
             "deny_precedence" => {:accept, :ok, :deny},
             "fault_after_replace" => {:accept, :fault_after_replace, :deny},
             "fault_before_replace" => {:accept, :fault_before_replace, :deny},
             "older_iat" => {:reject, :iat, :deny},
             "rollback" => {:reject, :rollback, :deny},
             "stale_freshness" => {:reject, :freshness, :allow},
             "valid_allow" => {:accept, :ok, :allow},
             "valid_signed_denial" => {:accept, :ok, :deny},
             "wrong_device" => {:reject, :device, :allow},
             "wrong_key" => {:reject, :key, :allow},
             "wrong_signature" => {:reject, :signature, :allow}
           }

    Enum.each(observations, fn observation ->
      assert observation.result in [:accept, :reject]
      assert observation.reason in [:ok, :signature, :key, :device, :rollback, :iat, :freshness, :fault_before_replace, :fault_after_replace]
    end)
  end
end
