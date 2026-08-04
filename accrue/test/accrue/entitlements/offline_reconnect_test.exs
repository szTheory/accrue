defmodule Accrue.Entitlements.OfflineReconnectTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Device, Observation, Projector}
  alias Accrue.Entitlements.Offline
  alias Accrue.Entitlements.Offline.{Issuance, Issuer}
  alias Accrue.TestRepo

  @now ~U[2026-08-04 01:00:00.000000Z]

  defmodule SigningProvider do
    @behaviour Accrue.Entitlements.Offline.KeyProvider

    @impl true
    def sign(payload, opts) do
      key = Keyword.fetch!(opts, :signing_key)
      header = %{"alg" => "ES256", "typ" => "accrue-entitlement-proof+jwt", "kid" => key["kid"]}

      {:ok,
       key
       |> JOSE.JWK.from()
       |> JOSE.JWS.sign(Jason.encode!(payload), header)
       |> JOSE.JWS.compact()
       |> elem(1)}
    end

    @impl true
    def public_keys(opts), do: {:ok, [Keyword.fetch!(opts, :public_key)]}
  end

  setup do
    original = Application.get_env(:accrue, :entitlements)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:offline_study],
          quotas: [downloads: 3],
          products: [stripe: [production: ["price_pro"]]]
        ]
      ]
    )

    on_exit(fn ->
      if original,
        do: Application.put_env(:accrue, :entitlements, original),
        else: Application.delete_env(:accrue, :entitlements)
    end)

    signing_key = test_key()

    public_key =
      signing_key
      |> Map.take(["kty", "crv", "kid", "x", "y"])
      |> Map.merge(%{"alg" => "ES256", "use" => "sig"})

    account = account!("issuer")
    device = device!(account, "install-219-issuer")

    %{account: account, device: device, signing_key: signing_key, public_key: public_key}
  end

  @tag :issuance
  test "locked canonical snapshot issues a self-verified allow and persists its retirement horizon",
       ctx do
    project_grant!(ctx.account)

    request = %Issuer.Request{account_id: ctx.account.id, device_id: ctx.device.id, now: @now}

    assert {:ok, result} =
             Offline.issue(ctx.account, request,
               repo: TestRepo,
               key_provider: SigningProvider,
               signing_key: ctx.signing_key,
               public_key: ctx.public_key,
               issuer: "accrue.test.offline",
               audience: "accrue-offline-client"
             )

    assert is_binary(result.compact)
    assert result.disposition == :allow
    assert result.revision == 1
    assert result.fresh_until == DateTime.add(@now, 30 * 24 * 60 * 60, :second)

    assert [%Issuance{kid: "accrue-v1.59-offline-test-only", disposition: :allow}] =
             TestRepo.all(Issuance)

    assert %{"accrue-v1.59-offline-test-only" => :never} =
             Issuance.retirement_requirements(TestRepo, @now)
  end

  @tag :issuance
  test "an empty locked snapshot returns a signed deny tombstone", ctx do
    request = %Issuer.Request{account_id: ctx.account.id, device_id: ctx.device.id, now: @now}

    assert {:ok, %{disposition: :deny, compact: compact}} =
             Offline.issue(ctx.account, request,
               repo: TestRepo,
               key_provider: SigningProvider,
               signing_key: ctx.signing_key,
               public_key: ctx.public_key,
               issuer: "accrue.test.offline",
               audience: "accrue-offline-client"
             )

    assert {:ok, %{state: :denied, reason: :signed_denial}} =
             Offline.verify(compact, verification_context(ctx))
  end

  defp account!(suffix) do
    {:ok, account} = Account.fetch_or_create(TestRepo, "test", "owner-219-#{suffix}")
    account
  end

  defp device!(account, installation_id) do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    public_jwk = key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

    {:ok, device} =
      TestRepo.insert(
        Device.changeset(%Device{}, %{
          account_id: account.id,
          installation_id: installation_id,
          public_jwk: public_jwk,
          key_thumbprint: Device.thumbprint(public_jwk),
          state: :active,
          registered_at: @now,
          last_accepted_revision: 0
        })
      )

    device
  end

  defp project_grant!(account) do
    {:ok, observation} =
      Observation.insert_idempotently(TestRepo, %{
        account_id: account.id,
        rail: :stripe,
        environment: :production,
        provider_event_id: "evt-219-issuer",
        provider_transaction_id: "txn-219-issuer",
        kind: "grant",
        provider_lineage_id: "lineage-219-issuer",
        provider_product_id: "price_pro",
        provider_order: 1,
        observed_at: @now,
        state: :qualified,
        retry_count: 0,
        metadata: %{},
        evidence_digest: String.duplicate("a", 64)
      })

    assert {:ok, _} = Projector.project(observation, logical_plan: :pro)
  end

  defp test_key do
    __DIR__
    |> Path.join("../../../priv/entitlements/v1.59-offline-test-key.jwk.json")
    |> File.read!()
    |> Jason.decode!()
  end

  defp verification_context(ctx) do
    %{
      issuer: "accrue.test.offline",
      audience: "accrue-offline-client",
      account_subject: ctx.account.id,
      installation_id: ctx.device.installation_id,
      device_thumbprint: ctx.device.key_thumbprint,
      now: DateTime.to_unix(@now),
      clock_high_water: %{revision: 0, iat: 0, fresh_until: 0},
      accepted_revision: 0,
      accepted_disposition: nil,
      accepted_iat: 0,
      accepted_fresh_until: 0,
      public_keys: [ctx.public_key]
    }
  end
end
