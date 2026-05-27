defmodule AccrueAdmin.Components.FunnelChartTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.FunnelChart

  describe "funnel_chart/1" do
    test "renders all 4 counts in legend" do
      html =
        render_component(&FunnelChart.funnel_chart/1,
          entered: 10,
          recovered: 4,
          exhausted: 3,
          active: 3
        )

      assert html =~ "Recovery Funnel"
      assert html =~ "10"
      assert html =~ "4"
      assert html =~ "3"
      assert html =~ "3 currently in dunning"
    end

    test "renders proportional percentages" do
      html =
        render_component(&FunnelChart.funnel_chart/1,
          entered: 10,
          recovered: 4,
          exhausted: 3,
          active: 3
        )

      # 4/10 = 40%, 3/10 = 30%
      assert html =~ "40"
      assert html =~ "30"
    end

    test "guards against division-by-zero when entered: 0" do
      html =
        render_component(&FunnelChart.funnel_chart/1,
          entered: 0,
          recovered: 0,
          exhausted: 0,
          active: 0
        )

      assert html =~ "Entered"
      refute html =~ "NaN"
    end

    test "declares accessibility contract" do
      html =
        render_component(&FunnelChart.funnel_chart/1,
          entered: 10,
          recovered: 4,
          exhausted: 3,
          active: 3
        )

      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-labelledby="funnel-title funnel-desc")
      assert html =~ ~s(<title id="funnel-title">)
      assert html =~ ~s(<desc id="funnel-desc">)
    end

    test "renders Exhausted tooltip with yearly-plan worked example" do
      html =
        render_component(&FunnelChart.funnel_chart/1,
          entered: 10,
          recovered: 4,
          exhausted: 3,
          active: 3
        )

      assert html =~ "$120/yr"
      assert html =~ "$10/mo"
      assert html =~ "Exhausted MRR"
    end

    test "renders three tone-keyed rows: slate, moss, amber" do
      html =
        render_component(&FunnelChart.funnel_chart/1,
          entered: 10,
          recovered: 4,
          exhausted: 3,
          active: 3
        )

      assert html =~ "ax-funnel-row--slate"
      assert html =~ "ax-funnel-row--moss"
      assert html =~ "ax-funnel-row--amber"
    end
  end
end
