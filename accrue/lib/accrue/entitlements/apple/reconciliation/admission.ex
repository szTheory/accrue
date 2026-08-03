defmodule Accrue.Entitlements.Apple.Reconciliation.Admission do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Apple.{Admission, Intake, Lineage}

  # This is intentionally the only raw-provider admission path used by the
  # worker. A verified JWS must match the pre-bound lineage before Intake can
  # write an idempotent observation and project it.
  def admit_transaction(repo, lineage_id, environment, signed_transaction, config)
      when is_binary(signed_transaction) and is_list(config) do
    with %Lineage{} = lineage <- locked_lineage(repo, lineage_id, environment),
         %Account{} = account <- repo.get(Account, lineage.account_id),
         {:ok, evidence} <-
           Admission.admit_transaction(signed_transaction, environment, account, config,
             verification_time: :signed_date
           ),
         :ok <- bound_lineage?(lineage, evidence),
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
         %Intake.VerifiedEvidence{} = evidence
       ) do
    if evidence.original_transaction_id == original and evidence.app_account_token == account_id,
      do: :ok,
      else: :verification_failed
  end

  defp bound_lineage?(_, _), do: :verification_failed

  defp signed_transactions(value) when is_map(value) do
    direct = [Map.get(value, "signedTransactionInfo"), Map.get(value, :signed_transaction)]
    nested = value |> Map.values() |> Enum.flat_map(&signed_transactions/1)
    Enum.filter(direct ++ nested, &(is_binary(&1) and byte_size(&1) > 0))
  end

  defp signed_transactions(values) when is_list(values),
    do: Enum.flat_map(values, &signed_transactions/1)

  defp signed_transactions(_), do: []
end
