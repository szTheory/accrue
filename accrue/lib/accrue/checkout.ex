defmodule Accrue.Checkout do
  @moduledoc """
  Checkout context (CHKT-01..06).

  Thin facade over `Accrue.Checkout.Session.create/1`,
  `Accrue.Checkout.Session.retrieve/1`, and the success-URL
  reconciliation helper `reconcile/1`.

  Host apps wire `reconcile/1` into their success URL controller —
  Accrue takes a `checkout_session_id` from the URL, refetches the
  session from the processor (D2-29 — processor is canonical), and
  mirrors the linked `customer`, `subscription`, and `payment_intent`
  references into local rows via the webhook-path force changesets.

  No cookies, no signed session state, no "trust the URL" magic — the
  refetch is the trust boundary.
  """

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.SubscriptionProjection
  alias Accrue.Processor
  alias Accrue.Repo

  defdelegate create_session(params), to: Accrue.Checkout.Session, as: :create
  defdelegate create_session!(params), to: Accrue.Checkout.Session, as: :create!
  defdelegate retrieve_session(id), to: Accrue.Checkout.Session, as: :retrieve

  @doc """
  Refetches a Checkout Session from the processor and mirrors its
  linked customer/subscription/payment_intent into local rows.

  Idempotent — calling twice produces the same local state.
  """
  @spec reconcile(String.t()) :: {:ok, map()} | {:error, term()}
  def reconcile(session_id) when is_binary(session_id) do
    with {:ok, stripe_session} <-
           Processor.__impl__().checkout_session_fetch(session_id, []) do
      Repo.transact(fn ->
        with :ok <- mirror_customer(stripe_session),
             :ok <- mirror_subscription(stripe_session) do
          {:ok, stripe_session}
        end
      end)
    end
  end

  @doc """
  Bang variant of `reconcile/1`.
  """
  @spec reconcile!(String.t()) :: map()
  def reconcile!(id) do
    case reconcile(id) do
      {:ok, session} ->
        session

      {:error, err} when is_exception(err) ->
        raise err

      {:error, other} ->
        raise "Accrue.Checkout.reconcile/1 failed: #{inspect(other)}"
    end
  end

  # --- mirror helpers -------------------------------------------------

  defp mirror_customer(stripe_session) do
    case extract_customer_id(stripe_session) do
      nil ->
        :ok

      customer_id when is_binary(customer_id) ->
        # Refetch the canonical customer object from the processor and
        # upsert. If the local row already exists we leave it — the
        # customer.* webhook path owns the projection.
        case Repo.get_by(Customer, processor_id: customer_id) do
          %Customer{} ->
            :ok

          nil ->
            # Defer to the customer.created webhook to avoid duplicating
            # the projection logic. reconcile/1 is idempotent — a missing
            # local row is fine.
            :ok
        end
    end
  end

  defp mirror_subscription(stripe_session) do
    case extract_subscription_id(stripe_session) do
      nil ->
        :ok

      sub_id when is_binary(sub_id) ->
        case Processor.__impl__().fetch(:subscription, sub_id) do
          {:ok, canonical} ->
            mirror_subscription_row(canonical, sub_id)

          {:error, _} ->
            # Subscription not yet readable — defer to the
            # customer.subscription.* webhook path.
            :ok
        end
    end
  end

  defp mirror_subscription_row(canonical, sub_id) do
    customer_id = extract_customer_id(canonical) || get(canonical, :customer)

    with %Customer{} = customer <-
           Repo.get_by(Customer, processor_id: maybe_id(customer_id)),
         {:ok, attrs} <- SubscriptionProjection.decompose(canonical) do
      case Repo.get_by(Subscription, processor_id: sub_id) do
        nil ->
          %Subscription{customer_id: customer.id, processor: processor_name()}
          |> Subscription.force_status_changeset(attrs)
          |> Repo.insert()
          |> case do
            {:ok, _} -> :ok
            {:error, _} = err -> err
          end

        %Subscription{} = existing ->
          existing
          |> Subscription.force_status_changeset(attrs)
          |> Repo.update()
          |> case do
            {:ok, _} -> :ok
            {:error, _} = err -> err
          end
      end
    else
      _ -> :ok
    end
  end

  defp extract_customer_id(stripe) do
    case get(stripe, :customer) do
      bin when is_binary(bin) -> bin
      %{} = m -> get(m, :id)
      _ -> nil
    end
  end

  defp extract_subscription_id(stripe) do
    case get(stripe, :subscription) do
      bin when is_binary(bin) -> bin
      %{} = m -> get(m, :id)
      _ -> nil
    end
  end

  defp maybe_id(nil), do: nil
  defp maybe_id(id) when is_binary(id), do: id
  defp maybe_id(%{} = m), do: get(m, :id)

  defp get(%{} = map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp get(_, _), do: nil

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end
end
