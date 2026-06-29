defmodule AccrueAdmin.ThemeTest do
  use AccrueAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    branding = Application.get_env(:accrue, :branding)
    admin_branding = Application.get_env(:accrue, :admin_branding)

    on_exit(fn ->
      if is_nil(branding) do
        Application.delete_env(:accrue, :branding)
      else
        Application.put_env(:accrue, :branding, branding)
      end

      if is_nil(admin_branding) do
        Application.delete_env(:accrue, :admin_branding)
      else
        Application.put_env(:accrue, :admin_branding, admin_branding)
      end
    end)

    :ok
  end

  test "brand plug sanitizes theme cookie and resolves runtime brand values" do
    Application.put_env(:accrue, :branding,
      business_name: "Accrue Ops",
      from_email: "ops@example.com",
      support_email: "support@example.com",
      logo_url: "https://example.test/logo.svg",
      accent_color: "#5D79F6"
    )

    conn =
      build_conn()
      |> Plug.Conn.put_req_header("cookie", "accrue_theme=neon")
      |> AccrueAdmin.BrandPlug.call([])

    assert conn.assigns.accrue_admin_theme == "system"
    assert conn.assigns.accrue_admin_brand.app_name == "Accrue Ops"
    assert conn.assigns.accrue_admin_brand.logo_url == "https://example.test/logo.svg"
    assert conn.assigns.accrue_admin_brand.accent_hex == "#5D79F6"
    assert conn.assigns.accrue_admin_brand.accent_contrast_hex == "#FFFFFF"
  end

  test "brand plug can keep admin chrome separate from customer billing branding" do
    Application.put_env(:accrue, :branding,
      business_name: "CohortFlow",
      from_email: "billing@cohortflow.test",
      support_email: "support@cohortflow.test",
      accent_color: "#26785F"
    )

    Application.put_env(:accrue, :admin_branding,
      app_name: "Accrue Admin",
      accent_color: "#5D79F6"
    )

    conn =
      build_conn()
      |> AccrueAdmin.BrandPlug.call([])

    assert conn.assigns.accrue_admin_brand.app_name == "Accrue Admin"
    assert conn.assigns.accrue_admin_brand.logo_url == nil
    assert conn.assigns.accrue_admin_brand.accent_hex == "#5D79F6"
  end

  test "router session includes theme, brand, nonce, and brand stylesheet path" do
    Application.put_env(:accrue, :branding,
      business_name: "Accrue Ops",
      from_email: "ops@example.com",
      support_email: "support@example.com",
      logo_url: "https://example.test/logo.svg",
      accent_color: "#5D79F6"
    )

    conn =
      build_conn()
      |> Plug.Test.init_test_session(%{"admin_token" => "token-123"})
      |> Plug.Conn.put_req_header("cookie", "accrue_theme=dark")
      |> AccrueAdmin.CSPPlug.call([])
      |> AccrueAdmin.BrandPlug.call([])

    session = AccrueAdmin.Router.__session__(conn, [:admin_token], "/billing")

    assert session["admin_token"] == "token-123"
    assert session["accrue_admin"]["theme"] == "dark"

    assert session["accrue_admin"]["brand_css_path"] ==
             AccrueAdmin.Assets.hashed_path(:brand, "/billing")

    assert session["accrue_admin"]["csp_nonce"] == conn.assigns.accrue_admin_csp_nonce
    assert session["accrue_admin"]["brand"].app_name == "Accrue Ops"
  end

  test "root layout keeps anti-fouc ordering ahead of stylesheet loading" do
    html =
      render_component(&AccrueAdmin.Layouts.root/1, %{
        page_title: "Billing",
        theme: "system",
        csp_nonce: "nonce-123",
        brand: %{
          app_name: "Accrue Ops",
          logo_url: nil,
          accent_hex: "#5D79F6",
          accent_contrast_hex: "#FFFFFF"
        },
        brand_css_path: "/billing/assets/brand.css",
        assets_css_path: "/billing/assets/app.css",
        assets_js_path: "/billing/assets/app.js",
        inner_content: Phoenix.HTML.raw("<main>Shell</main>")
      })

    anti_fouc_index = find_index(html, "document.documentElement.dataset.theme")
    brand_css_index = find_index(html, ~s(href="/billing/assets/brand.css"))
    app_css_index = find_index(html, ~s(href="/billing/assets/app.css"))
    runtime_style_index = find_index(html, "--ax-accent: #5D79F6;")
    js_index = find_index(html, ~s(src="/billing/assets/app.js"))

    assert anti_fouc_index
    assert brand_css_index
    assert app_css_index
    assert runtime_style_index
    assert js_index
    assert anti_fouc_index < brand_css_index
    assert brand_css_index < app_css_index
    assert app_css_index < runtime_style_index
    assert runtime_style_index < js_index
  end

  test "Phase 199 anti-fouc script resolves cookie before localStorage using production key" do
    script = AccrueAdmin.Layouts.anti_fouc_script()

    assert script =~ ~s(const key = "accrue_theme";)
    assert script =~ "document.cookie"
    assert script =~ "window.localStorage.getItem(key)"
    refute script =~ "accrue_admin_theme"

    cookie_index = find_index(script, "allowed.has(cookieValue)")
    local_storage_index = find_index(script, "allowed.has(storedValue)")
    data_theme_index = find_index(script, "document.documentElement.dataset.theme = theme")
    persist_index = find_index(script, "window.localStorage.setItem(key, theme)")

    assert cookie_index
    assert local_storage_index
    assert data_theme_index
    assert persist_index
    assert cookie_index < local_storage_index
    assert local_storage_index < data_theme_index
    assert data_theme_index < persist_index
  end

  defp find_index(haystack, needle) do
    case :binary.match(haystack, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
