defmodule Accrue.Billing.MeteredChargeAttempts do
  @moduledoc """
  Replay-safe settlement state transitions for one metered renewal window.
  """

  alias Accrue.Billing.{MeteredChargeAttempt, MeteredRenewal, PaymentMethod}
  alias Accrue.Repo

  @retry_delay_seconds 3600

  @spec get(Ecto.UUID.t()) :: MeteredChargeAttempt.t() | nil
  def get(metered_renewal_id) when is_binary(metered_renewal_id) do
    Repo.get_by(MeteredChargeAttempt, metered_renewal_id: metered_renewal_id)
  end

  @spec ensure_attempt(MeteredRenewal.t(), String.t()) ::
          {:ok, MeteredChargeAttempt.t()} | {:error, term()}
  def ensure_attempt(%MeteredRenewal{} = renewal, subject_uuid) when is_binary(subject_uuid) do
    case get(renewal.id) do
      %MeteredChargeAttempt{} = attempt ->
        {:ok, attempt}

      nil ->
        %MeteredChargeAttempt{}
        |> MeteredChargeAttempt.changeset(%{
          metered_renewal_id: renewal.id,
          subject_uuid: subject_uuid,
          status: :pending,
          processor: renewal.processor
        })
        |> Repo.insert()
    end
  end

  @spec mark_paid(MeteredChargeAttempt.t(), map(), PaymentMethod.t() | nil) ::
          {:ok, MeteredChargeAttempt.t()} | {:error, term()}
  def mark_paid(%MeteredChargeAttempt{} = attempt, charge, payment_method) do
    update_attempt(attempt, %{
      status: :paid,
      processor_charge_id: charge[:id] || charge["id"],
      attempted_payment_method_id: payment_method_id(payment_method),
      retry_at: nil,
      paid_at: DateTime.utc_now(),
      failure_class: nil,
      failure_code: nil,
      failure_message: nil,
      data:
        merge_data(attempt.data, %{
          "charge_status" => charge[:status] || charge["status"],
          "currency" => charge[:currency] || charge["currency"]
        })
    })
  end

  @spec mark_retryable(MeteredChargeAttempt.t(), term(), PaymentMethod.t() | nil) ::
          {:ok, MeteredChargeAttempt.t()} | {:error, term()}
  def mark_retryable(%MeteredChargeAttempt{} = attempt, error, payment_method) do
    now = DateTime.utc_now()

    update_attempt(
      attempt,
      failure_attrs(attempt, error, payment_method, %{
        status: :retry_scheduled,
        retry_at: DateTime.add(now, @retry_delay_seconds, :second)
      })
    )
  end

  @spec mark_awaiting_payment_method(MeteredChargeAttempt.t(), term()) ::
          {:ok, MeteredChargeAttempt.t()} | {:error, term()}
  def mark_awaiting_payment_method(%MeteredChargeAttempt{} = attempt, error) do
    update_attempt(
      attempt,
      failure_attrs(attempt, error, nil, %{
        status: :awaiting_payment_method,
        retry_at: nil
      })
    )
  end

  @spec mark_failed_exhausted(MeteredChargeAttempt.t(), term(), PaymentMethod.t() | nil) ::
          {:ok, MeteredChargeAttempt.t()} | {:error, term()}
  def mark_failed_exhausted(%MeteredChargeAttempt{} = attempt, error, payment_method) do
    update_attempt(
      attempt,
      failure_attrs(attempt, error, payment_method, %{
        status: :failed_exhausted,
        retry_at: nil
      })
    )
  end

  defp update_attempt(%MeteredChargeAttempt{} = attempt, attrs) do
    attempt
    |> MeteredChargeAttempt.changeset(attrs)
    |> Repo.update()
  end

  defp failure_attrs(attempt, error, payment_method, attrs) do
    details = normalize_error(error)

    attrs
    |> Map.put(:attempted_payment_method_id, payment_method_id(payment_method))
    |> Map.put(:failure_class, details.failure_class)
    |> Map.put(:failure_code, details.failure_code)
    |> Map.put(:failure_message, details.failure_message)
    |> Map.put(:processor_charge_id, nil)
    |> maybe_preserve_original_failure(attempt, details, payment_method)
    |> Map.put(
      :data,
      merge_data(attempt.data, %{
        "last_error_class" => details.failure_class,
        "last_error_code" => details.failure_code,
        "last_error_message" => details.failure_message
      })
    )
  end

  defp maybe_preserve_original_failure(attrs, attempt, details, payment_method) do
    if is_nil(attempt.original_failure_class) do
      attrs
      |> Map.put(:original_failure_class, details.failure_class)
      |> Map.put(:original_failure_code, details.failure_code)
      |> Map.put(:original_failure_message, details.failure_message)
      |> Map.put(:original_failed_payment_method_id, payment_method_id(payment_method))
    else
      attrs
    end
  end

  defp normalize_error(%Accrue.Error.NoDefaultPaymentMethod{} = error) do
    %{
      failure_class: "payment_method_required",
      failure_code: nil,
      failure_message: Exception.message(error)
    }
  end

  defp normalize_error(%Accrue.CardError{} = error) do
    %{
      failure_class: "hard_decline",
      failure_code: error.decline_code || error.code,
      failure_message: Exception.message(error)
    }
  end

  defp normalize_error(%Accrue.APIError{} = error) do
    %{
      failure_class: "retryable",
      failure_code: error.code,
      failure_message: Exception.message(error)
    }
  end

  defp normalize_error(other) do
    %{
      failure_class: "retryable",
      failure_code: nil,
      failure_message: inspect(other)
    }
  end

  defp payment_method_id(%PaymentMethod{processor_id: processor_id}), do: processor_id
  defp payment_method_id(_), do: nil

  defp merge_data(existing, updates) when is_map(existing) do
    Map.merge(existing, updates)
  end

  defp merge_data(_, updates), do: updates
end
