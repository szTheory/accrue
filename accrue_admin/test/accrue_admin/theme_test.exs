defmodule AccrueAdmin.ThemeTest do
  use AccrueAdmin.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Dev.ComponentRegistry
  alias AccrueAdmin.Storybook.RegistryStory

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
    assert script =~ "safeDecodeTheme"
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

  test "Phase 199 anti-fouc script treats malformed theme cookies as untrusted input" do
    assert %{"stored" => "dark", "theme" => "dark"} =
             run_anti_fouc_script("accrue_theme=%E0%A4%A", "dark")

    assert %{"stored" => "system", "theme" => "system"} =
             run_anti_fouc_script("accrue_theme=%E0%A4%A", "neon")
  end

  test "Phase 199 CSS fixed-shell source audit covers trap-creating properties" do
    app_css = File.read!(app_css_path())

    for token <- [
          "phase199-fixed-shell-audit: ax-overlay-shell",
          "phase199-fixed-shell-audit: ax-command-palette-wrapper",
          "phase199-fixed-shell-audit: ax-command-palette-backdrop",
          "phase199-fixed-shell-audit: ax-mobile-sidebar",
          "transform",
          "filter",
          "backdrop-filter",
          "contain",
          "perspective"
        ] do
      assert app_css =~ token
    end
  end

  test "Phase 200 Storybook enables color mode with the dark shim bridge" do
    assert AccrueAdmin.Dev.Storybook.config(:color_mode) == true

    assert AccrueAdmin.Dev.Storybook.config(:color_mode_sandbox_dark_class) ==
             "ax-theme-dark-shim"
  end

  test "Phase 200 Storybook dark shim mirrors every dark ax token from theme css" do
    theme_dark_tokens =
      theme_css_path()
      |> File.read!()
      |> css_block(~r/html\.accrue-admin\[data-theme="dark"\][^{]*\{(?<body>.*?)\}/s)
      |> ax_token_declarations()

    storybook_dark_tokens =
      storybook_css_path()
      |> File.read!()
      |> css_block(~r/\.psb-sandbox\.accrue-admin\.ax-theme-dark-shim\s*\{(?<body>.*?)\}/s)
      |> ax_token_declarations()

    assert Map.keys(theme_dark_tokens) != []

    for {token, declaration} <- theme_dark_tokens do
      assert storybook_dark_tokens[token] == declaration
    end
  end

  test "Phase 200 registry story variation ids are stable registry-derived slugs" do
    family = "button"

    expected_ids =
      family
      |> ComponentRegistry.variants_for()
      |> Enum.flat_map(fn entry ->
        entry
        |> Map.get(:specimens, [])
        |> Enum.with_index()
        |> Enum.map(fn {specimen, idx} ->
          RegistryStory.slug_id(family, entry.variant, specimen[:label], idx)
        end)
      end)

    actual_ids =
      family
      |> RegistryStory.variations_for()
      |> Enum.map(& &1.id)

    assert actual_ids == expected_ids
    assert Enum.uniq(actual_ids) == actual_ids

    assert Enum.all?(actual_ids, fn id ->
             id
             |> Atom.to_string()
             |> String.match?(~r/^button-[a-z0-9]+(?:-[a-z0-9]+)*-[0-9]+$/)
           end)
  end

  defp find_index(haystack, needle) do
    case :binary.match(haystack, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  defp run_anti_fouc_script(cookie, stored_value) do
    payload =
      Jason.encode!(%{
        cookie: cookie,
        script: AccrueAdmin.Layouts.anti_fouc_script(),
        stored: stored_value
      })
      |> Base.encode64()

    node = """
    const vm = require("node:vm");
    const input = JSON.parse(Buffer.from("#{payload}", "base64").toString("utf8"));
    const store = new Map();
    if (input.stored !== null) store.set("accrue_theme", input.stored);
    const sandbox = {
      document: {
        cookie: input.cookie,
        documentElement: { dataset: {} }
      },
      window: {
        localStorage: {
          getItem(key) {
            return store.has(key) ? store.get(key) : null;
          },
          setItem(key, value) {
            store.set(key, value);
          }
        }
      }
    };
    vm.runInNewContext(input.script, sandbox);
    process.stdout.write(JSON.stringify({
      theme: sandbox.document.documentElement.dataset.theme,
      stored: store.has("accrue_theme") ? store.get("accrue_theme") : null
    }));
    """

    {output, 0} = System.cmd("node", ["-e", node])
    Jason.decode!(output)
  end

  defp app_css_path do
    Path.expand("../../assets/css/app.css", __DIR__)
  end

  defp theme_css_path do
    Path.expand("../../assets/css/theme.css", __DIR__)
  end

  defp storybook_css_path do
    Path.expand("../../priv/static/storybook.css", __DIR__)
  end

  defp css_block(css, regex) do
    case Regex.named_captures(regex, css) do
      %{"body" => body} -> body
      _ -> flunk("expected CSS block matching #{inspect(regex)}")
    end
  end

  defp ax_token_declarations(block) do
    ~r/(--ax-[\w-]+):\s*([^;]+);/
    |> Regex.scan(block, capture: :all_but_first)
    |> Map.new(fn [token, value] -> {token, String.trim(value)} end)
  end
end
