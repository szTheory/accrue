defmodule AccrueAdmin.Dev.ComponentRegistryTest do
  @moduledoc false

  # Uses LiveCase for both tests: test (a) needs DB sandbox for the LiveView mount;
  # test (b) uses render_component which doesn't need it, but sharing the case module
  # avoids splitting into two describe/module blocks.
  use AccrueAdmin.LiveCase, async: false

  # Required for ~H sigil used in render_component wrapping function (test b).
  use Phoenix.Component

  alias AccrueAdmin.Dev.ComponentRegistry
  alias AccrueAdmin.Components.Button

  # (a) Every registry variant appears in the rendered /dev/components page.
  #
  # Drift vector: if a section fails to render, or a registry entry has a wrong
  # ax_class, the variant-specific substring will be absent from the page HTML.
  test "every registry variant appears in the /dev/components page render", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/dev/components")

    for %{ax_class: ax_class} <- ComponentRegistry.entries() do
      # Split "ax-button ax-button-primary" → ["ax-button", "ax-button-primary"]
      # The second element is the variant-specific class that distinguishes this entry.
      [_base, variant_class] = String.split(ax_class, " ", parts: 2)

      assert html =~ variant_class,
             "registry variant #{inspect(ax_class)} — variant class #{inspect(variant_class)} " <>
               "was not found in the /dev/components page HTML"
    end
  end

  # (b) The registry Button ax_class set exactly matches Button component render outputs.
  #
  # Drift vector: a maintainer adds a 5th Button variant to button_variant_class/1 in
  # button.ex without adding a registry entry. The MapSet comparison fails in CI before
  # the PR merges, enforcing D-21 going forward.
  #
  # Includes the "danger" variant that was absent from the kitchen before DSY-03.
  test "button registry ax_class set exactly matches Button component render outputs for all 4 variants including danger" do
    registry_classes =
      ComponentRegistry.variants_for("button")
      |> MapSet.new(& &1.ax_class)

    component_classes =
      ["primary", "secondary", "ghost", "danger"]
      |> MapSet.new(fn variant ->
        html =
          render_component(fn assigns ->
            ~H"""
            <Button.button variant={assigns.variant} type="button">Label</Button.button>
            """
          end, %{variant: variant})

        extract_button_class(html)
      end)

    assert registry_classes == component_classes,
           """
           Button registry ax_class set does not match component render outputs.

           In registry but not rendered:
           #{MapSet.difference(registry_classes, component_classes) |> MapSet.to_list() |> Enum.join("\n")}

           Rendered but not in registry:
           #{MapSet.difference(component_classes, registry_classes) |> MapSet.to_list() |> Enum.join("\n")}
           """
  end

  # (c) token-validity: all tokens listed in the registry are defined in the design system.
  #
  # Reads theme.css and app.css at test time. Each token in each entry's `tokens` field must
  # appear as a substring in at least one of those files, OR be explicitly allowlisted below
  # (for tokens defined via the server-rendered style tag in layouts.ex rather than in a
  # static CSS file). A phantom token reintroduced into a future PR will cause this test to
  # fail before merge, enforcing D-21 going forward.
  #
  # known_in_layouts allowlist: --ax-accent and --ax-accent-readable are injected at runtime
  # via the <style> tag in AccrueAdmin.Layouts.root/1 (layouts.ex line ~82). They are real
  # tokens; they just cannot be grepped from static files.
  test "all tokens listed in ComponentRegistry.entries() are defined in the design system" do
    theme_css = File.read!(theme_css_path())
    app_css = File.read!(app_css_path())

    known_in_layouts = ["--ax-accent", "--ax-accent-readable"]

    phantom_tokens =
      for entry <- ComponentRegistry.entries(),
          token <- entry.tokens,
          token not in known_in_layouts,
          not String.contains?(theme_css, token),
          not String.contains?(app_css, token) do
        {entry.family, entry.variant, token}
      end

    assert phantom_tokens == [],
           """
           Found tokens in ComponentRegistry that are not defined in theme.css or app.css:

           #{Enum.map_join(phantom_tokens, "\n", fn {family, variant, token} -> "  #{family}/#{variant}: #{token}" end)}

           Fix: either correct the token name in component_registry.ex to match an actual
           CSS custom property, or add --ax-accent/--ax-accent-readable to known_in_layouts
           if the token is legitimately defined via the server-rendered style tag in layouts.ex.
           """
  end

  # Extract the full class string from the outermost ax-button bearing element.
  # Anchors on "ax-button" to skip any inner child elements (pitfall 5 from RESEARCH.md).
  # Calls flunk/1 with the raw html on no-match so silent false-positives are impossible.
  defp extract_button_class(html) do
    case Regex.run(~r/class="(ax-button[^"]+)"/, html) do
      [_, classes] ->
        classes |> String.split() |> Enum.join(" ")

      nil ->
        flunk(
          "extract_button_class/1: no class attribute starting with 'ax-button' found.\n" <>
            "Raw HTML:\n#{html}"
        )
    end
  end

  defp theme_css_path do
    Path.expand("../../../assets/css/theme.css", __DIR__)
  end

  defp app_css_path do
    Path.expand("../../../assets/css/app.css", __DIR__)
  end
end
