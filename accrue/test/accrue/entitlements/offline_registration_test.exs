defmodule Accrue.Entitlements.OfflineRegistrationTest do
  use Accrue.RepoCase

  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Device
  alias Accrue.Entitlements.Offline
  alias Accrue.Entitlements.Offline.{Challenge, Issuance, Registration}
  alias Accrue.TestRepo

  @public_jwk %{
    "kty" => "EC",
    "crv" => "P-256",
    "x" => "f83OJ3D2xF4G7_PqMdzR1ym2PdwJvQhWqE5H9aQfT5s",
    "y" => "x_FEzRu9P7PZxqTQ7P3U-DxhPSe07uyRfrn41XPRP1Q"
  }

  test "bounded public JWK, challenge digests, and issuance ordering persist without secret material" do
    account = account!("durable-values")
    thumbprint = Device.thumbprint(@public_jwk)

    assert {:ok, device} =
             TestRepo.insert(
               Device.changeset(%Device{}, %{
                 account_id: account.id,
                 installation_id: "install-219-durable",
                 public_jwk: @public_jwk,
                 key_thumbprint: thumbprint,
                 state: :active,
                 registered_at: ~U[2026-08-03 04:00:00.000000Z],
                 last_accepted_revision: 0
               })
             )

    assert device.public_jwk == @public_jwk
    refute Map.has_key?(device.public_jwk, "d")

    assert {:ok, challenge} =
             TestRepo.insert(
               Challenge.changeset(%Challenge{}, %{
                 account_id: account.id,
                 installation_id: device.installation_id,
                 nonce_digest: digest("nonce-219"),
                 purpose: :registration,
                 expires_at: ~U[2026-08-03 04:05:00.000000Z],
                 idempotency_digest: digest("idempotency-219")
               })
             )

    assert challenge.nonce_digest == digest("nonce-219")
    refute inspect(challenge) =~ "nonce-219"

    assert {:ok, issuance} =
             TestRepo.insert(
               Issuance.changeset(%Issuance{}, %{
                 account_id: account.id,
                 device_id: device.id,
                 token_id_hash: digest("token-219"),
                 kid: "offline-v1",
                 revision: 7,
                 disposition: :allow,
                 issued_at: ~U[2026-08-03 04:00:00.000000Z],
                 fresh_until: ~U[2026-08-03 04:01:00.000000Z],
                 expires_at: ~U[2026-08-03 04:02:00.000000Z],
                 correlation_hash: digest("correlation-219")
               })
             )

    assert issuance.revision == 7
    assert issuance.disposition == :allow
  end

  test "changesets reject private, malformed, and unbounded public key material" do
    account = account!("key-validation")

    attrs = %{
      account_id: account.id,
      installation_id: "install-219-key-validation",
      public_jwk: @public_jwk,
      key_thumbprint: Device.thumbprint(@public_jwk),
      state: :active,
      registered_at: ~U[2026-08-03 04:00:00.000000Z],
      last_accepted_revision: 0
    }

    for invalid_jwk <- [
          Map.put(@public_jwk, "d", "private-key"),
          Map.delete(@public_jwk, "x"),
          Map.put(@public_jwk, "crv", "P-384"),
          Map.put(@public_jwk, "kid", "not-a-device-member"),
          Map.put(@public_jwk, "x", String.duplicate("x", 256))
        ] do
      refute Device.changeset(%Device{}, %{attrs | public_jwk: invalid_jwk}).valid?
    end

    refute Device.changeset(%Device{}, %{attrs | key_thumbprint: "client-supplied"}).valid?
  end

  test "database constraints protect challenge and issuance state from direct invalid writes" do
    account = account!("direct-constraints")
    device = device!(account, "install-219-direct")

    assert_check_violation(
      "accrue_entitlement_offline_challenges_purpose_check",
      """
      INSERT INTO billing.accrue_entitlement_offline_challenges
        (account_id, installation_id, nonce_digest, purpose, expires_at, inserted_at, updated_at)
      VALUES ($1::text::uuid, 'install-219-direct', $2, 'unexpected', NOW(), NOW(), NOW())
      """,
      [account.id, digest("challenge-direct")]
    )

    assert_check_violation(
      "accrue_entitlement_devices_public_jwk_check",
      "UPDATE billing.accrue_entitlement_devices SET public_jwk = $2::jsonb WHERE id = $1::text::uuid",
      [device.id, Jason.encode!(Map.put(@public_jwk, "d", "never-persist"))]
    )

    assert_check_violation(
      "accrue_entitlement_offline_issuances_time_order_check",
      """
      INSERT INTO billing.accrue_entitlement_offline_issuances
        (account_id, device_id, token_id_hash, kid, revision, disposition, issued_at, fresh_until,
         expires_at, inserted_at, updated_at)
      VALUES ($1::text::uuid, $2::text::uuid, $3, 'offline-v1', 0, 'allow', NOW(), NOW() - INTERVAL '1 second',
              NOW(), NOW(), NOW())
      """,
      [account.id, device.id, digest("issuance-direct")]
    )
  end

  test "nonce and token identities are unique within their durable account scope" do
    account = account!("uniqueness")

    attrs = %{
      account_id: account.id,
      installation_id: "install-219-unique",
      nonce_digest: digest("nonce-unique"),
      purpose: :registration,
      expires_at: ~U[2026-08-03 04:05:00.000000Z],
      idempotency_digest: digest("idempotency-unique")
    }

    assert {:ok, _} = TestRepo.insert(Challenge.changeset(%Challenge{}, attrs))
    assert {:error, duplicate} = TestRepo.insert(Challenge.changeset(%Challenge{}, attrs))
    assert %{nonce_digest: ["has already been taken"]} = errors_on(duplicate)
  end

  test "authorized proof-of-possession registration consumes one nonce and coalesces exact idempotent replay" do
    account = account!("proof-of-possession")
    device_key = JOSE.JWK.generate_key({:ec, "P-256"})

    public_jwk =
      device_key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

    authorize = fn %Account{id: account_id}, action ->
      account_id == account.id and action in [:offline_challenge, :offline_registration]
    end

    assert {:ok, %Challenge.Value{} = value} =
             Offline.challenge(account, "install-219-pop",
               authorize: authorize,
               now: ~U[2026-08-03 04:00:00Z]
             )

    idempotency_key = "idem-219-pop"

    request = %Registration.Request{
      installation_id: "install-219-pop",
      device_public_jwk: public_jwk,
      challenge_id: value.id,
      nonce: value.nonce,
      nonce_signature:
        sign(
          device_key,
          signing_input(account.id, "install-219-pop", value.id, value.nonce, idempotency_key)
        ),
      idempotency_key: idempotency_key
    }

    assert {:ok,
            %Registration.Result{state: :active, installation_id: "install-219-pop"} = result} =
             Offline.register_device(account, request,
               authorize: authorize,
               now: ~U[2026-08-03 04:01:00Z]
             )

    assert result.key_thumbprint == Device.thumbprint(public_jwk)

    assert %Challenge{consumed_at: %DateTime{}, nonce_digest: nonce_digest} =
             TestRepo.get!(Challenge, value.id)

    refute nonce_digest == value.nonce

    assert %Device{public_jwk: ^public_jwk} =
             TestRepo.get_by!(Device, account_id: account.id, installation_id: "install-219-pop")

    assert {:ok, ^result} =
             Offline.register_device(account, request,
               authorize: authorize,
               now: ~U[2026-08-03 04:01:00Z]
             )

    assert {:error, :unauthorized} =
             Offline.challenge(account, "install-219-unauthorized",
               authorize: fn _, _ -> false end
             )
  end

  test "installer copies the offline proof-state migration exactly once" do
    migration =
      Path.join([
        __DIR__,
        "../../../priv/repo/migrations/20260803040000_create_accrue_offline_proof_state.exs"
      ])

    assert File.exists?(migration)
    assert File.read!(migration) =~ "accrue_entitlement_offline_challenges"

    assert [^migration] =
             Path.wildcard(
               Path.join(
                 __DIR__,
                 "../../../priv/repo/migrations/*_create_accrue_offline_proof_state.exs"
               )
             )
  end

  defp account!(suffix) do
    {:ok, account} = Account.fetch_or_create(TestRepo, "user", "owner-219-#{suffix}")
    account
  end

  defp device!(account, installation_id) do
    {:ok, device} =
      TestRepo.insert(
        Device.changeset(%Device{}, %{
          account_id: account.id,
          installation_id: installation_id,
          public_jwk: @public_jwk,
          key_thumbprint: Device.thumbprint(@public_jwk),
          state: :active,
          registered_at: ~U[2026-08-03 04:00:00.000000Z],
          last_accepted_revision: 0
        })
      )

    device
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp errors_on(changeset),
    do: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)

  defp assert_check_violation(constraint, sql, params) do
    assert {:error, %Postgrex.Error{postgres: %{code: :check_violation, constraint: ^constraint}}} =
             TestRepo.transaction(fn ->
               case Ecto.Adapters.SQL.query(TestRepo, sql, params) do
                 {:error, error} -> TestRepo.rollback(error)
                 {:ok, _result} -> flunk("expected #{constraint} to reject direct write")
               end
             end)
  end

  defp signing_input(account_id, installation_id, challenge_id, nonce, idempotency_key) do
    digest = digest(idempotency_key)

    ["v1.59", "registration", account_id, installation_id, challenge_id, nonce, digest]
    |> Enum.map_join(fn value ->
      <<byte_size(value)::unsigned-big-integer-size(32), value::binary>>
    end)
  end

  defp sign(key, input) do
    {_, private_key} = JOSE.JWK.to_key(key)
    :public_key.sign(input, :sha256, private_key)
  end
end
