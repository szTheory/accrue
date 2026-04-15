defmodule Accrue.Test.FacadeTest do
  use ExUnit.Case, async: false

  @tag :facade_core
  test "use Accrue.Test imports setup helpers plus mail and PDF assertions" do
    assert_facade_compiles("""
    defmodule Accrue.Test.FacadeCoreProbe do
      use ExUnit.Case
      use Accrue.Test

      def imported_assertions do
        assert_email_sent(:receipt)
        assert_email_sent(:receipt, [])
        assert_pdf_rendered([])
      end
    end
    """)
  end

  @tag :facade_actions
  test "use Accrue.Test delegates advance_clock/2 and trigger_event/2" do
    assert_facade_compiles("""
    defmodule Accrue.Test.FacadeActionsProbe do
      use ExUnit.Case
      use Accrue.Test

      def calls(invoice) do
        [
          advance: advance_clock("30 days", processor: Accrue.Processor.Fake),
          trigger: trigger_event(:invoice_payment_failed, invoice)
        ]
      end
    end
    """)

    assert function_exported?(Accrue.Test.FacadeActionsProbe, :calls, 1)
  end

  @tag :facade_side_effects
  test "use Accrue.Test imports event assertions and refute/no-op companions" do
    assert_facade_compiles("""
    defmodule Accrue.Test.FacadeSideEffectsProbe do
      use ExUnit.Case
      use Accrue.Test

      def imported_event_assertions do
        assert_event_recorded(type: "subscription.created")
        refute_event_recorded(type: "subscription.deleted")
        assert_no_events_recorded(type: "invoice.voided")
      end
    end
    """)
  end

  defp assert_facade_compiles(source) do
    assert [{_module, _bytecode}] = Code.compile_string(source)
  end
end
