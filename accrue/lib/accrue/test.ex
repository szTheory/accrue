defmodule Accrue.Test do
  @moduledoc """
  Public test helper facade for host applications.

  `use Accrue.Test` imports the stable assertion helpers and action
  helpers intended for host `DataCase`/`ConnCase` modules.
  """

  defmacro __using__(_opts) do
    quote do
      import Accrue.Test
      import Accrue.Test.MailerAssertions
      import Accrue.Test.PdfAssertions
      import Accrue.Test.EventAssertions
    end
  end

  defdelegate advance_clock(subject, duration), to: Accrue.Test.Clock, as: :advance
  defdelegate trigger_event(type, subject), to: Accrue.Test.Webhooks, as: :trigger

  @doc """
  Configures Accrue to use the in-memory Fake processor for the current test.
  """
  @spec setup_fake_processor(keyword() | map()) :: :ok | {:ok, keyword()}
  def setup_fake_processor(context \\ []) do
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)
    setup_return(context, processor: Accrue.Processor.Fake)
  end

  @doc """
  Returns meter events captured by `Accrue.Processor.Fake` for `customer_or_id`
  (same argument shapes as `Accrue.Processor.Fake.meter_events_for/1`).

  Prefer asserting `%Accrue.Billing.MeterEvent{}` rows via `Ecto.Repo` first; use
  this helper when processor-shaped payloads matter.

  Raises `ArgumentError` unless `Accrue.Processor.__impl__()` is `Accrue.Processor.Fake`.

  ## Implementation

  single facade: delegates reads to `Accrue.Processor.Fake` so hosts discover the
  helper through `Accrue.Test` instead of importing the Fake module directly.
  """
  @spec meter_events_for(Accrue.Billing.Customer.t() | String.t()) :: [map()]
  def meter_events_for(customer_or_id) do
    adapter = Accrue.Processor.__impl__()

    if adapter != Accrue.Processor.Fake do
      raise ArgumentError,
            "meter_events_for/1 requires Accrue.Processor.Fake (got #{inspect(adapter)})"
    end

    Accrue.Processor.Fake.meter_events_for(customer_or_id)
  end

  @doc """
  Configures Accrue to capture mail deliveries through `Accrue.Mailer.Test`.
  """
  @spec setup_mailer_test(keyword() | map()) :: :ok | {:ok, keyword()}
  def setup_mailer_test(context \\ []) do
    Application.put_env(:accrue, :mailer, Accrue.Mailer.Test)
    setup_return(context, mailer: Accrue.Mailer.Test)
  end

  @doc """
  Configures Accrue to capture PDF renders through `Accrue.PDF.Test`.
  """
  @spec setup_pdf_test(keyword() | map()) :: :ok | {:ok, keyword()}
  def setup_pdf_test(context \\ []) do
    Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)
    setup_return(context, pdf_adapter: Accrue.PDF.Test)
  end

  defp setup_return(context, _values) when context in [[], %{}], do: :ok
  defp setup_return(context, values) when is_map(context), do: {:ok, values}
  defp setup_return(context, values) when is_list(context), do: {:ok, values}
end
