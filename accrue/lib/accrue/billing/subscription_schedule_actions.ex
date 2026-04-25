defmodule Accrue.Billing.SubscriptionScheduleActions do
  @moduledoc """
  Write surface for Stripe SubscriptionSchedules.

  Mirrors the `SubscriptionActions` shape: Repo.transact → Processor
  call → projection → local insert/update → event record, all inside
  a single transaction with deterministic idempotency keys.
  """

  require Logger

  alias Accrue.Actor
  alias Accrue.Billing.{Customer, SubscriptionSchedule, SubscriptionScheduleProjection}
  alias Accrue.{Events, Processor, Repo}
  alias Accrue.Processor.Idempotency

  @create_schema [
    end_behavior: [type: {:in, ["release", "cancel"]}, default: "release"],
    operation_id: [type: {:or, [:string, nil]}, default: nil],
    metadata: [type: {:or, [:map, nil]}, default: nil]
  ]

  @update_schema [
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @release_schema [
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @cancel_schema [
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  # ---------------------------------------------------------------------
  # subscribe_via_schedule/3
  # ---------------------------------------------------------------------

  @spec subscribe_via_schedule(term(), [map()], keyword()) ::
          {:ok, SubscriptionSchedule.t()} | {:error, term()}
  def subscribe_via_schedule(billable, phases, opts \\ [])

  def subscribe_via_schedule(%Customer{} = customer, phases, opts) when is_list(phases) do
    v = NimbleOptions.validate!(opts, @create_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem = Idempotency.key(:subscription_schedule_create, customer.id, op_id)

    params =
      %{
        customer: customer.processor_id,
        phases: phases,
        end_behavior: v[:end_behavior]
      }
      |> maybe_put_metadata(v[:metadata])

    Repo.transact(fn ->
      with {:ok, stripe_sched} <-
             Processor.__impl__().subscription_schedule_create(params, idempotency_key: idem),
           {:ok, attrs} <- SubscriptionScheduleProjection.decompose(stripe_sched),
           attrs = Map.put(attrs, :customer_id, customer.id),
           attrs = Map.put_new(attrs, :processor, processor_name()),
           {:ok, sched} <-
             %SubscriptionSchedule{}
             |> SubscriptionSchedule.changeset(attrs)
             |> Repo.insert(),
           {:ok, _} <-
             Events.record(%{
               type: "subscription_schedule.created",
               subject_type: "SubscriptionSchedule",
               subject_id: sched.id,
               data: %{phases_count: length(phases)}
             }) do
        {:ok, sched}
      end
    end)
  end

  def subscribe_via_schedule(billable, phases, opts) when is_list(phases) do
    with {:ok, customer} <- Accrue.Billing.customer(billable) do
      subscribe_via_schedule(customer, phases, opts)
    end
  end

  @spec subscribe_via_schedule!(term(), [map()], keyword()) :: SubscriptionSchedule.t()
  def subscribe_via_schedule!(billable, phases, opts \\ []) do
    unwrap!(subscribe_via_schedule(billable, phases, opts))
  end

  # ---------------------------------------------------------------------
  # update_schedule/3
  # ---------------------------------------------------------------------

  @spec update_schedule(SubscriptionSchedule.t(), map(), keyword()) ::
          {:ok, SubscriptionSchedule.t()} | {:error, term()}
  def update_schedule(%SubscriptionSchedule{} = sched, params, opts \\ []) when is_map(params) do
    v = NimbleOptions.validate!(opts, @update_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem = Idempotency.key(:subscription_schedule_update, sched.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_sched} <-
             Processor.__impl__().subscription_schedule_update(
               sched.processor_id,
               params,
               idempotency_key: idem
             ),
           {:ok, attrs} <- SubscriptionScheduleProjection.decompose(stripe_sched),
           {:ok, updated} <-
             sched |> SubscriptionSchedule.changeset(attrs) |> Repo.update(),
           {:ok, _} <-
             Events.record(%{
               type: "subscription_schedule.updated",
               subject_type: "SubscriptionSchedule",
               subject_id: updated.id,
               data: %{}
             }) do
        {:ok, updated}
      end
    end)
  end

  @spec update_schedule!(SubscriptionSchedule.t(), map(), keyword()) :: SubscriptionSchedule.t()
  def update_schedule!(sched, params, opts \\ []),
    do: unwrap!(update_schedule(sched, params, opts))

  # ---------------------------------------------------------------------
  # release_schedule/2
  # ---------------------------------------------------------------------

  @spec release_schedule(SubscriptionSchedule.t(), keyword()) ::
          {:ok, SubscriptionSchedule.t()} | {:error, term()}
  def release_schedule(%SubscriptionSchedule{} = sched, opts \\ []) do
    v = NimbleOptions.validate!(opts, @release_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem = Idempotency.key(:subscription_schedule_release, sched.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_sched} <-
             Processor.__impl__().subscription_schedule_release(
               sched.processor_id,
               idempotency_key: idem
             ),
           {:ok, attrs} <- SubscriptionScheduleProjection.decompose(stripe_sched),
           attrs = Map.put_new(attrs, :released_at, Accrue.Clock.utc_now()),
           {:ok, updated} <-
             sched |> SubscriptionSchedule.force_status_changeset(attrs) |> Repo.update(),
           {:ok, _} <-
             Events.record(%{
               type: "subscription_schedule.released",
               subject_type: "SubscriptionSchedule",
               subject_id: updated.id,
               data: %{}
             }) do
        {:ok, updated}
      end
    end)
  end

  @spec release_schedule!(SubscriptionSchedule.t(), keyword()) :: SubscriptionSchedule.t()
  def release_schedule!(sched, opts \\ []), do: unwrap!(release_schedule(sched, opts))

  # ---------------------------------------------------------------------
  # cancel_schedule/2
  # ---------------------------------------------------------------------

  @spec cancel_schedule(SubscriptionSchedule.t(), keyword()) ::
          {:ok, SubscriptionSchedule.t()} | {:error, term()}
  def cancel_schedule(%SubscriptionSchedule{} = sched, opts \\ []) do
    v = NimbleOptions.validate!(opts, @cancel_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem = Idempotency.key(:subscription_schedule_cancel, sched.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_sched} <-
             Processor.__impl__().subscription_schedule_cancel(
               sched.processor_id,
               idempotency_key: idem
             ),
           {:ok, attrs} <- SubscriptionScheduleProjection.decompose(stripe_sched),
           attrs = Map.put_new(attrs, :canceled_at, Accrue.Clock.utc_now()),
           {:ok, updated} <-
             sched |> SubscriptionSchedule.force_status_changeset(attrs) |> Repo.update(),
           {:ok, _} <-
             Events.record(%{
               type: "subscription_schedule.canceled",
               subject_type: "SubscriptionSchedule",
               subject_id: updated.id,
               data: %{}
             }) do
        {:ok, updated}
      end
    end)
  end

  @spec cancel_schedule!(SubscriptionSchedule.t(), keyword()) :: SubscriptionSchedule.t()
  def cancel_schedule!(sched, opts \\ []), do: unwrap!(cancel_schedule(sched, opts))

  # ---------------------------------------------------------------------
  # internals
  # ---------------------------------------------------------------------

  defp maybe_put_metadata(params, nil), do: params
  defp maybe_put_metadata(params, m) when is_map(m), do: Map.put(params, :metadata, m)

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp unwrap!({:ok, v}), do: v
  defp unwrap!({:error, err}) when is_exception(err), do: raise(err)

  defp unwrap!({:error, other}),
    do: raise("SubscriptionScheduleActions action failed: #{inspect(other)}")
end
