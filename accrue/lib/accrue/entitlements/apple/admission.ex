defmodule Accrue.Entitlements.Apple.Admission do
  @moduledoc false

  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Apple.Intake

  @allowed_options [:environment]

  # This is the only conversion from opaque Apple bytes to the internal capability
  # consumed by Intake.  The verifier and mapping are host configuration, never
  # authority supplied by a purchase/restore caller.
  def observe_purchase_or_restore(%Account{} = account, signed_transaction, opts, config)
      when is_binary(signed_transaction) and is_list(opts) do
    with :ok <- valid_options?(opts),
         environment <- Keyword.get(opts, :environment, :production),
         {:ok, evidence} <-
           admit_transaction(signed_transaction, environment, account, config, opts) do
      Intake.observe(account, evidence)
    end
  end

  def observe_purchase_or_restore(_, _, _, _), do: {:error, :invalid_input}

  def admit_transaction(signed_transaction, environment, account, config, opts \\ [])

  def admit_transaction(
        signed_transaction,
        environment,
        %Account{} = account,
        config,
        _opts
      )
      when is_binary(signed_transaction) and environment in [:production, :sandbox] and
             is_list(config) do
    with verifier when is_atom(verifier) <- Keyword.get(config, :verifier),
         verifier_config when not is_nil(verifier_config) <- Keyword.get(config, :verifier_config),
         product_map when is_map(product_map) <- Keyword.get(config, :product_map),
         {:ok, facts} when is_map(facts) <-
           verifier.verify_transaction(signed_transaction, verifier_config),
         {:ok, evidence} <-
           evidence(facts, signed_transaction, environment, account, config, product_map) do
      {:ok, evidence}
    else
      nil -> {:error, :config_invalid}
      false -> {:error, :config_invalid}
      {:error, _} = error -> error
      _ -> {:error, :config_invalid}
    end
  end

  def admit_transaction(_, _, _, _, _), do: {:error, :invalid_input}

  defp valid_options?(opts) do
    if Keyword.keyword?(opts) and Enum.all?(Keyword.keys(opts), &(&1 in @allowed_options)),
      do: :ok,
      else: {:error, :invalid_input}
  end

  defp evidence(facts, raw, environment, _account, config, product_map) do
    with original when is_binary(original) and byte_size(original) in 1..255 <-
           facts["originalTransactionId"],
         transaction when is_binary(transaction) and byte_size(transaction) in 1..255 <-
           facts["transactionId"],
         product when is_binary(product) and byte_size(product) in 1..255 <- facts["productId"],
         token when is_nil(token) or (is_binary(token) and byte_size(token) in 1..255) <-
           facts["appAccountToken"],
         %DateTime{} = signed_at <- apple_time(facts["signedDate"]),
         plan when not is_nil(plan) <- Map.get(product_map, product) do
      {:ok,
       %Intake.VerifiedEvidence{
         environment: environment,
         original_transaction_id: original,
         app_account_token: token,
         provider_event_id: "purchase:" <> transaction,
         provider_transaction_id: transaction,
         product_id: product,
         logical_plan: plan,
         lifecycle: lifecycle(facts),
         effective_at: signed_at,
         expires_at: apple_time(facts["expiresDate"]),
         signed_at: signed_at,
         evidence_digest: :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower),
         verifier_version: Keyword.get(config, :verifier_version, "apple-v1"),
         config_version: Keyword.get(config, :config_version, "host-v1")
       }}
    else
      _ -> {:error, :invalid_payload}
    end
  end

  defp lifecycle(%{"revocationDate" => value}) when not is_nil(value), do: :revoked

  defp lifecycle(facts),
    do: if(expired?(apple_time(facts["expiresDate"])), do: :expired, else: :active)

  defp expired?(%DateTime{} = value), do: DateTime.compare(value, DateTime.utc_now()) == :lt
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
end
