defmodule Accrue.Entitlements.Apple.Reconciliation.Admission do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Apple.{Intake, Lineage}

  # This is intentionally the only raw-provider admission path used by the
  # worker. A verified JWS must match the pre-bound lineage before Intake can
  # write an idempotent observation and project it.
  def admit_transaction(repo, lineage_id, environment, signed_transaction, config)
      when is_binary(signed_transaction) and is_list(config) do
    with verifier when is_atom(verifier) <- Keyword.get(config, :verifier),
         verifier_config when not is_nil(verifier_config) <- Keyword.get(config, :verifier_config),
         {:ok, facts} <- verifier.verify_transaction(signed_transaction, verifier_config),
         %Lineage{} = lineage <- locked_lineage(repo, lineage_id, environment),
         :ok <- bound_lineage?(lineage, facts),
         %Account{} = account <- repo.get(Account, lineage.account_id),
         {:ok, evidence} <- evidence(facts, signed_transaction, environment, account, config),
         {:ok, _outcome} <-
           Intake.observe(account, evidence,
             repo: repo,
             suppress_reconciliation_enqueue: true
           ) do
      :ok
    else
      nil -> {:error, :config_invalid}
      false -> {:error, :verification_failed}
      {:error, _} = error -> error
      _ -> {:error, :verification_failed}
    end
  end

  def admit_transaction(_, _, _, _, _), do: {:error, :invalid_payload}

  def admit_status(repo, lineage_id, environment, status, config) when is_map(status) do
    status
    |> signed_transactions()
    |> Enum.reduce_while(:ok, fn signed_transaction, :ok ->
      case admit_transaction(repo, lineage_id, environment, signed_transaction, config) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  def admit_status(_, _, _, _, _), do: {:error, :invalid_payload}

  defp locked_lineage(repo, lineage_id, environment) do
    repo.one(
      from(lineage in Lineage,
        where: lineage.id == ^lineage_id and lineage.environment == ^environment,
        lock: "FOR UPDATE"
      )
    )
  end

  defp bound_lineage?(
         %Lineage{
           binding_state: :bound,
           account_id: account_id,
           original_transaction_id: original
         },
         facts
       ) do
    if facts["originalTransactionId"] == original and facts["appAccountToken"] == account_id,
      do: :ok,
      else: :verification_failed
  end

  defp bound_lineage?(_, _), do: :verification_failed

  defp evidence(facts, raw, environment, account, config) do
    with original when is_binary(original) and byte_size(original) in 1..255 <-
           facts["originalTransactionId"],
         transaction when is_binary(transaction) and byte_size(transaction) in 1..255 <-
           facts["transactionId"],
         product when is_binary(product) and byte_size(product) in 1..255 <- facts["productId"],
         %DateTime{} = signed_at <- apple_time(facts["signedDate"]),
         plan when not is_nil(plan) <- Keyword.get(config, :product_map, %{}) |> Map.get(product) do
      {:ok,
       %Intake.VerifiedEvidence{
         environment: environment,
         original_transaction_id: original,
         app_account_token: account.id,
         provider_event_id: "reconciliation:" <> transaction,
         provider_transaction_id: transaction,
         product_id: product,
         logical_plan: plan,
         lifecycle: lifecycle(facts),
         effective_at: signed_at,
         expires_at: apple_time(facts["expiresDate"]),
         signed_at: signed_at,
         evidence_digest: digest(raw),
         verifier_version: version(config, :verifier_version),
         config_version: version(config, :config_version)
       }}
    else
      _ -> {:error, :invalid_payload}
    end
  end

  defp lifecycle(%{"revocationDate" => value}) when not is_nil(value), do: :revoked

  defp lifecycle(facts),
    do: if(expired?(apple_time(facts["expiresDate"])), do: :expired, else: :active)

  defp expired?(%DateTime{} = datetime), do: DateTime.compare(datetime, DateTime.utc_now()) == :lt
  defp expired?(_), do: false

  defp apple_time(value) when is_integer(value),
    do: DateTime.from_unix(value, :millisecond) |> elem(1)

  defp apple_time(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} -> apple_time(number)
      _ -> nil
    end
  end

  defp apple_time(_), do: nil
  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  defp version(config, key), do: Keyword.get(config, key, "reconciliation-v1")

  defp signed_transactions(value) when is_map(value) do
    direct = [Map.get(value, "signedTransactionInfo"), Map.get(value, :signed_transaction)]
    nested = value |> Map.values() |> Enum.flat_map(&signed_transactions/1)
    Enum.filter(direct ++ nested, &(is_binary(&1) and byte_size(&1) > 0))
  end

  defp signed_transactions(values) when is_list(values),
    do: Enum.flat_map(values, &signed_transactions/1)

  defp signed_transactions(_), do: []
end
