defmodule AccrueAdmin.Components.ThemePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias AccrueAdmin.Components.ThemePicker

  defp render(theme), do: render_component(&ThemePicker.theme_picker/1, %{theme: theme})

  test "renders a radiogroup with the three theme segments" do
    html = render("system")

    assert html =~ ~s(role="radiogroup")
    assert html =~ ~s(aria-label="Color theme")

    for value <- ~w(light dark system) do
      assert html =~ ~s(data-theme-target="#{value}")
    end

    # one button per option
    assert html |> String.split(~s(role="radio")) |> length() == 4
  end

  test "marks only the active theme as checked, with roving tabindex" do
    html = render("dark")

    # exactly one checked, two unchecked
    assert html |> String.split(~s(aria-checked="true")) |> length() == 2
    assert html |> String.split(~s(aria-checked="false")) |> length() == 3

    # roving tabindex: exactly one focusable (0), two removed (-1)
    assert html |> String.split(~s(tabindex="0")) |> length() == 2
    assert html |> String.split(~s(tabindex="-1")) |> length() == 3
  end

  test "each segment carries an accessible label (survives icon-only collapse)" do
    html = render("light")

    for label <- ~w(Light Dark System) do
      assert html =~ ~s(aria-label="#{label}")
    end
  end

  test "active segment gets the active class; others do not" do
    html = render("light")

    assert html =~ "ax-theme-picker-option-active"
    # exactly one active option
    assert html |> String.split("ax-theme-picker-option-active") |> length() == 2
  end

  test "Phase 199 theme hook persists the production accrue_theme key to cookie and localStorage" do
    source = theme_hook_source()

    assert source =~ ~s(export const THEME_COOKIE = "accrue_theme")
    assert source =~ "window.localStorage.setItem(THEME_COOKIE, value)"
    assert source =~ "document.cookie = `${THEME_COOKIE}="
    refute source =~ "accrue_admin_theme"
  end

  test "Phase 199 keyboard contract keeps theme picker as a single roving-tabindex radiogroup" do
    source = theme_hook_source()

    assert source =~ ~S|document.addEventListener("keydown", onThemeTargetKeydown, true)|
    assert source =~ ~S|querySelectorAll("[data-theme-target]")|
    assert source =~ ~S|candidate.setAttribute("aria-checked", String(isActive))|
    assert source =~ ~S|candidate.setAttribute("tabindex", isActive ? "0" : "-1")|
  end

  defp theme_hook_source do
    Path.expand("../../../assets/js/hooks/accrue_theme.js", __DIR__)
    |> File.read!()
  end
end
