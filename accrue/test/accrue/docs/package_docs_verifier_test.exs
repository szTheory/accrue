defmodule Accrue.Docs.PackageDocsVerifierTest do
  use ExUnit.Case, async: true

  # Phase 63-01: First Hour + package README integrator copy is enforced by
  # scripts/ci/verify_package_docs.sh end-to-end; no new require_fixed needles were added there.

  @script_path "../scripts/ci/verify_package_docs.sh"

  test "package docs verifier succeeds" do
    {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
    accrue_version = extract_version!("accrue/mix.exs")
    accrue_admin_version = extract_version!("accrue_admin/mix.exs")

    assert status == 0

    assert output =~
             "package docs verified for accrue #{accrue_version}, accrue_admin #{accrue_admin_version}, and accrue_portal #{accrue_admin_version}"

    assert output =~ "README.md"
    assert output =~ "RELEASING.md"
    assert output =~ "First run"
    assert output =~ "15-TRUST-REVIEW.md"
    assert output =~ "STRIPE_TEST_SECRET_KEY"
    assert output =~ "CONTRIBUTING.md"
    assert output =~ "release-gate"
    assert output =~ "host-integration"
    assert output =~ "retain-on-failure"
    assert output =~ "only-on-failure"
    assert output =~ "quickstart"
  end

  test "package docs verifier rejects processor support drift in custom processor guidance" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_custom_processors =
      tmp_dir
      |> Path.join("accrue/guides/custom_processors.md")
      |> File.read!()
      |> String.replace("outside first-party support", "inside first-party support")

    File.write!(
      Path.join(tmp_dir, "accrue/guides/custom_processors.md"),
      drifted_custom_processors
    )

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "custom_processors.md"
    assert output =~ "outside first-party support"
  end

  test "package docs verifier rejects missing canonical verification labels" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_readme =
      tmp_dir
      |> Path.join("examples/accrue_host/README.md")
      |> File.read!()
      |> String.replace("mix verify.full", "mix verify all")

    File.write!(Path.join(tmp_dir, "examples/accrue_host/README.md"), drifted_readme)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "examples/accrue_host/README.md"
    assert output =~ "mix verify.full"
  end

  test "package docs verifier rejects missing release guidance invariants" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_releasing =
      tmp_dir
      |> Path.join("RELEASING.md")
      |> File.read!()
      |> String.replace("provider-parity checks", "optional checks")

    File.write!(Path.join(tmp_dir, "RELEASING.md"), drifted_releasing)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "RELEASING.md"
    assert output =~ "provider-parity checks"
  end

  test "package docs verifier rejects stale workflow and contributor wording" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_guide =
      tmp_dir
      |> Path.join("guides/testing-live-stripe.md")
      |> File.read!()
      |> String.replace(
        "`release-gate` and `host-integration`\nresults in the workflow summary",
        "`release-gate` results in the workflow summary and can be monitored alongside the primary `test` job"
      )

    File.write!(Path.join(tmp_dir, "guides/testing-live-stripe.md"), drifted_guide)

    drifted_contributing =
      tmp_dir
      |> Path.join("CONTRIBUTING.md")
      |> File.read!()
      |> String.replace(
        "Node.js for browser UAT in `examples/accrue_host`",
        "Node.js for browser UAT in `accrue_admin`"
      )

    File.write!(Path.join(tmp_dir, "CONTRIBUTING.md"), drifted_contributing)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"

    assert output =~ "host-integration" or output =~ "CONTRIBUTING.md",
           "expected live-stripe drift or CONTRIBUTING UAT wording to fail the verifier"
  end

  test "package docs verifier rejects missing trust review invariant" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_releasing =
      tmp_dir
      |> Path.join("RELEASING.md")
      |> File.read!()
      |> String.replace("15-TRUST-REVIEW.md", "trust-review.md")

    File.write!(Path.join(tmp_dir, "RELEASING.md"), drifted_releasing)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "15-TRUST-REVIEW.md"
  end

  test "package docs verifier rejects drift in retained artifact policy" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_config =
      tmp_dir
      |> Path.join("examples/accrue_host/playwright.config.js")
      |> File.read!()
      |> String.replace(~s(trace: "retain-on-failure"), ~s(trace: "on"))

    File.write!(Path.join(tmp_dir, "examples/accrue_host/playwright.config.js"), drifted_config)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "retain-on-failure"
  end

  test "package docs verifier rejects quickstart missing auth adapters link" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    drifted_quickstart =
      tmp_dir
      |> Path.join("accrue/guides/quickstart.md")
      |> File.read!()
      |> String.replace("auth_adapters.md", "")

    File.write!(Path.join(tmp_dir, "accrue/guides/quickstart.md"), drifted_quickstart)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "auth_adapters.md"
  end

  test "package docs verifier rejects unguarded breakpoint @media in app.css" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    original = File.read!(app_css_path)

    drifted =
      original <>
        "\n@media (min-width: 900px) { .ax-drift { display: block; } }\n"

    File.write!(app_css_path, drifted)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "app.css"
    assert output =~ "--ax-bp-"
  end

  test "package docs verifier rejects 'transition: all' in app.css" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    original = File.read!(app_css_path)

    drifted =
      original <>
        "\n.ax-drift { transition: all 180ms; }\n"

    File.write!(app_css_path, drifted)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "app.css"
    assert output =~ "transition: all"
  end

  test "package docs verifier rejects raw cubic-bezier() in app.css" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    original = File.read!(app_css_path)

    drifted =
      original <>
        "\n.ax-drift { transition: opacity cubic-bezier(0.4,0,1,1); }\n"

    File.write!(app_css_path, drifted)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "app.css"
    assert output =~ "cubic-bezier"
  end

  test "package docs verifier rejects raw ms duration literal in app.css" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    original = File.read!(app_css_path)

    drifted =
      original <>
        "\n.ax-drift { transition: opacity 200ms ease; }\n"

    File.write!(app_css_path, drifted)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "app.css"
    assert output =~ "ms"
  end

  test "package docs verifier rejects layout-thrash property in transition list in app.css" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    original = File.read!(app_css_path)

    drifted =
      original <>
        "\n.ax-drift { transition: height var(--ax-dur-2) ease; }\n"

    File.write!(app_css_path, drifted)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "app.css"
    assert output =~ "layout"
  end

  test "package docs verifier rejects Tailwind config files in accrue_admin assets" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    File.write!(
      Path.join(tmp_dir, "accrue_admin/assets/tailwind.config.js"),
      "module.exports = {}\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "tailwind.config.js"
  end

  test "package docs verifier rejects Tailwind --config in the asset build task" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    task_path = Path.join(tmp_dir, "accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex")
    original = File.read!(task_path)

    File.write!(
      task_path,
      String.replace(original, ~s("--minify"), ~s("--config", "tailwind.config.js", "--minify"),
        global: false
      )
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "--config"
  end

  test "package docs verifier rejects Tailwind directives in package CSS" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")

    File.write!(
      app_css_path,
      File.read!(app_css_path) <> "\n@tailwind components;\n.ax-drift { @apply flex; }\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "@tailwind" or output =~ "@apply"
  end

  test "package docs verifier rejects positive Tailwind authoring guidance while allowing the D-14 sentence" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    guide_path = Path.join(tmp_dir, "accrue_admin/guides/admin_ui.md")
    original = File.read!(guide_path)
    assert original =~ "Tailwind utilities are not an authoring path"
    File.write!(guide_path, original <> "\nAdd Tailwind utilities in HEEx for spacing.\n")

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "Tailwind authoring"
  end

  test "package docs verifier rejects z-index literals in package CSS" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    File.write!(app_css_path, File.read!(app_css_path) <> "\n.ax-drift { z-index: 999; }\n")

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "z-index literals"
  end

  test "package docs verifier rejects micro-stack z-index without ax-z-micro-stack annotation (D-10)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")

    # Inject a shell with isolation and an internal z-index: 0 WITHOUT the ax-z-micro-stack comment
    File.write!(
      app_css_path,
      File.read!(app_css_path) <>
        "\n.ax-drift-shell { isolation: isolate; }\n.ax-drift-backdrop { z-index: 0; }\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "z-index literals"
  end

  test "package docs verifier rejects micro-stack z-index without isolation on the shell (D-10)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")

    # Inject a z-index: 0 with ax-z-micro-stack annotation but NO isolation: isolate context
    File.write!(
      app_css_path,
      File.read!(app_css_path) <>
        "\n.ax-drift-backdrop { z-index: 0; /* ax-z-micro-stack: backdrop in unisolated context */ }\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "z-index literals"
  end

  test "package docs verifier rejects raw type declarations in package CSS" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    File.write!(app_css_path, File.read!(app_css_path) <> "\n.ax-drift { font-size: 13px; }\n")

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "raw type declarations"
  end

  test "package docs verifier rejects missing semantic role tokens" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    theme_path = Path.join(tmp_dir, "accrue_admin/assets/css/theme.css")

    File.write!(
      theme_path,
      String.replace(File.read!(theme_path), "--ax-focus-ring-offset: var(--ax-base);", "")
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "semantic role tokens"
    assert output =~ "--ax-focus-ring-offset"
  end

  test "package docs verifier rejects missing interactive role consumption in app.css" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")

    drifted =
      app_css_path
      |> File.read!()
      |> String.replace("var(--ax-interactive-hover)", "var(--ax-sunken)")
      |> String.replace("var(--ax-interactive-active)", "var(--ax-sunken)")
      |> String.replace("var(--ax-interactive-selected)", "var(--ax-sunken)")

    File.write!(app_css_path, drifted)

    assert File.read!(Path.join(tmp_dir, "accrue_admin/assets/css/theme.css")) =~
             "--ax-interactive-hover"

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "interactive role consumption"
  end

  test "package docs verifier rejects low semantic role contrast while token names remain present" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    theme_path = Path.join(tmp_dir, "accrue_admin/assets/css/theme.css")

    drifted =
      theme_path
      |> File.read!()
      |> String.replace("--ax-disabled-text: #5d6a73;", "--ax-disabled-text: #eef3f7;",
        global: false
      )
      |> String.replace("--ax-readonly-text: #5d6a73;", "--ax-readonly-text: #f1f5f8;",
        global: false
      )
      |> String.replace(
        "--ax-status-success-text: #2f6b4f;",
        "--ax-status-success-text: #e9f5ee;",
        global: false
      )
      |> String.replace(
        "--ax-status-danger-on-solid: #fff;",
        "--ax-status-danger-on-solid: #9b1c1c;",
        global: false
      )
      |> String.replace("--ax-focus-ring: #174ea6;", "--ax-focus-ring: #fafbfc;", global: false)
      |> String.replace("--ax-scrollbar-thumb: #5d6a73;", "--ax-scrollbar-thumb: #fff;",
        global: false
      )
      |> String.replace("--ax-interactive-hover: #eef3ff;", "--ax-interactive-hover: #111418;",
        global: false
      )

    File.write!(theme_path, drifted)

    assert File.read!(theme_path) =~ "--ax-disabled-text:"
    assert File.read!(theme_path) =~ "--ax-status-success-text:"

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "semantic role contrast" or output =~ "[foundation_contrast]"

    assert output =~ "disabled" or output =~ "readonly" or output =~ "status" or output =~ "focus" or
             output =~ "scrollbar" or output =~ "interactive"
  end

  test "package docs verifier rejects Stripe-only language in adoption-proof-matrix.md" do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "accrue-docs-verifier-apm-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    seed_tmp_dir!(tmp_dir)

    apm_path = Path.join(tmp_dir, "examples/accrue_host/docs/adoption-proof-matrix.md")
    original = File.read!(apm_path)
    File.write!(apm_path, original <> "This is Stripe-only content.\n")

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "adoption-proof-matrix.md"
  end

  test "entitlements docs reject renewed fetch_entitled ambiguity" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    guide_path = Path.join(tmp_dir, "accrue/guides/entitlements.md")

    File.write!(
      guide_path,
      File.read!(guide_path) <>
        "\nThe fetch_entitled/2 question stays deferred for a later Stripe-backed gate.\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "fetch_entitled/2"
  end

  test "entitlements docs reject reintroduced fetch_entitled predicate" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    admin_path = Path.join(tmp_dir, "accrue/lib/accrue/entitlements/admin.ex")
    File.mkdir_p!(Path.dirname(admin_path))

    File.write!(
      admin_path,
      """
      defmodule Accrue.Entitlements.Admin do
        def #{forbidden_fetch_name()}(_customer, _feature), do: {:ok, false}
      end
      """
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "fetch_entitled"
  end

  test "package docs verifier rejects stale lattice_stripe compatibility truth" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    claude_path = Path.join(tmp_dir, "CLAUDE.md")

    drifted =
      claude_path
      |> File.read!()
      |> String.replace("`~> 2.0`", "`~> 1.1`", global: false)

    File.write!(claude_path, drifted)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "CLAUDE.md"
    assert output =~ "lattice_stripe"
  end

  test "package docs verifier rejects deferred or gate-influencing Stripe-native sync wording" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    jtbd_path = Path.join(tmp_dir, "accrue/guides/jobs_to_be_done.md")

    File.write!(
      jtbd_path,
      File.read!(jtbd_path) <>
        "\nThe optional Stripe-native sync is deferred and can become the grant authority for gates.\n"
    )

    frontier_path = Path.join(tmp_dir, ".planning/research/JTBD-FRONTIER.md")

    File.write!(
      frontier_path,
      File.read!(frontier_path) <>
        "\nStripe-native entitlements are Accrue's source of truth for grant decisions.\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "Stripe-native"
    assert output =~ "grant" or output =~ "deferred"
  end

  test "package docs verifier rejects advisory sync authority inversion in support mirrors" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    entitlements_path = Path.join(tmp_dir, "accrue/guides/entitlements.md")

    File.write!(
      entitlements_path,
      File.read!(entitlements_path) <>
        "\nThe advisory Stripe cache changes `entitled?/2` and is authoritative for grant decisions.\n"
    )

    matrix_path = Path.join(tmp_dir, ".planning/processor-support-matrix.md")

    File.write!(
      matrix_path,
      File.read!(matrix_path) <>
        "\nStripe-native sync can displace local mapping as the grant source of truth.\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "advisory" or output =~ "grant"
  end

  test "package docs verifier rejects live-Stripe merge gate claims in adoption proof" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    proof_path = Path.join(tmp_dir, "examples/accrue_host/docs/adoption-proof-matrix.md")

    File.write!(
      proof_path,
      File.read!(proof_path) <>
        "\nLive Stripe entitlement refresh is the merge-blocking proof for advisory sync.\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "adoption-proof-matrix.md"
  end

  test "package docs verifier rejects missing supported Phase 213 since metadata" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    for relative_path <- [
          "accrue/lib/accrue/entitlements/stripe_sync.ex",
          "accrue/lib/accrue/processor.ex",
          "accrue/lib/accrue/processor/fake.ex"
        ] do
      path = Path.join(tmp_dir, relative_path)
      File.write!(path, String.replace(File.read!(path), ~s(  @doc since: "1.5.0"\n), ""))
    end

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ ~s(@doc since: "1.5.0")
  end

  test "package docs verifier rejects stale StripeSync since metadata" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    stripe_sync_path = Path.join(tmp_dir, "accrue/lib/accrue/entitlements/stripe_sync.ex")

    File.write!(
      stripe_sync_path,
      String.replace(
        File.read!(stripe_sync_path),
        ~s(@doc since: "1.5.0"),
        ~s(@doc since: "1.4.0"),
        global: false
      )
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "StripeSync.refresh/2"
    assert output =~ ~s(@doc since: "1.5.0")
  end

  test "package docs verifier rejects internal Phase 213 since metadata" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    stripe_sync_path = Path.join(tmp_dir, "accrue/lib/accrue/entitlements/stripe_sync.ex")

    File.write!(
      stripe_sync_path,
      String.replace(
        File.read!(stripe_sync_path),
        "  @doc false\n  @spec summary_for_customer",
        "  @doc false\n  @doc since: \"1.5.0\"\n  @spec summary_for_customer",
        global: false
      )
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "internal Phase 213 surface"
  end

  test "package docs verifier rejects stale StripeSync writer provenance" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    stripe_sync_path = Path.join(tmp_dir, "accrue/lib/accrue/entitlements/stripe_sync.ex")

    stale_writer_story =
      stripe_sync_path
      |> File.read!()
      |> String.replace(
        "`seam → billing`, never `gate → seam`. When a host enables\n  `stripe_native_sync: :advisory`, webhook handling and client-backed pull refresh write the same advisory `Accrue.Billing.EntitlementSummary` row through `Accrue.Entitlements.Reconcile`. The feature is off by default and diagnostic only; neither path can influence grants. Local plan→feature mapping remains the sole Accrue grant authority.",
        "`seam → billing read`, never `gate → seam`. Nothing under the gate path\n  references this module; it only reads through `Accrue.Repo`. The cache is\n  written exclusively by `Accrue.Webhook.DefaultHandler` when a host opts\n  into `config :accrue, :entitlements, stripe_native_sync: :advisory`.",
        global: false
      )

    File.write!(stripe_sync_path, stale_writer_story)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "accrue/lib/accrue/entitlements/stripe_sync.ex"
    assert output =~ "StripeSync writer provenance"
  end

  test "package docs verifier rejects a missing StripeSync public-prose shared reconciler" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    stripe_sync_path = Path.join(tmp_dir, "accrue/lib/accrue/entitlements/stripe_sync.ex")
    original = File.read!(stripe_sync_path)

    missing_public_reconciler =
      String.replace(
        original,
        "through `Accrue.Entitlements.Reconcile`.",
        "through the shared reconciler.",
        global: false
      )

    assert missing_public_reconciler != original
    refute missing_public_reconciler =~ "through `Accrue.Entitlements.Reconcile`."
    assert missing_public_reconciler =~ "alias Accrue.Entitlements.Reconcile"

    File.write!(stripe_sync_path, missing_public_reconciler)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "accrue/lib/accrue/entitlements/stripe_sync.ex"
    assert output =~ "StripeSync writer provenance"
    assert output =~ "missing shared reconciler"
  end

  test "package docs verifier rejects stale EntitlementSummary pagination truth" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    summary_path = Path.join(tmp_dir, "accrue/lib/accrue/billing/entitlement_summary.ex")

    stale_summary =
      summary_path
      |> File.read!()
      |> String.replace(
        "jsonb with the full payload. A client-backed pull refresh exhaustively\n  streams the customer's active entitlements before persisting its advisory\n  snapshot. Webhook summary snapshots can contain only the first reported\n  entitlements; `entitlements.has_more` records that known incompleteness.",
        "jsonb with the full payload (including the `entitlements.url` pagination\n  handle) for the deferred `lattice_stripe >= 1.2` paginated reconcile.",
        global: false
      )

    File.write!(summary_path, stale_summary)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "accrue/lib/accrue/billing/entitlement_summary.ex"
    assert output =~ "EntitlementSummary completeness"
  end

  test "package docs verifier rejects stale telemetry pagination truth" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    telemetry_path = Path.join(tmp_dir, "accrue/guides/telemetry.md")

    stale_telemetry =
      telemetry_path
      |> File.read!()
      |> String.replace(
        "Known-incomplete webhook advisory snapshot: `has_more: true` means only the first reported entitlements were received. Client-backed pull exhaustively streams active entitlements before persistence; neither path gates local access.",
        "Fires only when `has_more: true` — full pagination is deferred until `lattice_stripe >= 1.2`.",
        global: false
      )

    File.write!(telemetry_path, stale_telemetry)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "accrue/guides/telemetry.md"
    assert output =~ "telemetry completeness"
  end

  defp tmp_dir! do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    tmp_dir
  end

  defp run_verifier(tmp_dir) do
    System.cmd("bash", [@script_path],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}]
    )
  end

  defp forbidden_fetch_name, do: "fetch_" <> "entitled"

  defp copy_fixture!(relative_path, tmp_dir) do
    destination = Path.join(tmp_dir, relative_path)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
  end

  defp seed_tmp_dir!(tmp_dir) do
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/assets/css"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/assets"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/lib/accrue_admin/dev"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/lib/mix/tasks"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_portal"))
    File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host"))
    File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host/docs"))
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    copy_fixture!("README.md", tmp_dir)
    copy_fixture!("CLAUDE.md", tmp_dir)
    copy_fixture!("RELEASING.md", tmp_dir)
    copy_fixture!("CONTRIBUTING.md", tmp_dir)
    copy_fixture!(".planning/STRATEGY.md", tmp_dir)
    copy_fixture!(".planning/PROJECT.md", tmp_dir)
    copy_fixture!(".planning/processor-support-matrix.md", tmp_dir)
    copy_fixture!(".planning/research/JTBD-FRONTIER.md", tmp_dir)
    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue/README.md", tmp_dir)
    copy_fixture!("accrue/guides/custom_processors.md", tmp_dir)
    copy_fixture!("accrue/guides/dunning.md", tmp_dir)
    copy_fixture!("accrue/guides/entitlements.md", tmp_dir)
    copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
    copy_fixture!("accrue/guides/jobs_to_be_done.md", tmp_dir)
    copy_fixture!("accrue/guides/quickstart.md", tmp_dir)
    copy_fixture!("accrue/guides/production-readiness.md", tmp_dir)
    copy_fixture!("accrue/guides/telemetry.md", tmp_dir)
    copy_fixture!("accrue/lib/accrue/billing/entitlement_summary.ex", tmp_dir)
    copy_fixture!("accrue/guides/testing.md", tmp_dir)
    copy_fixture!("accrue/guides/troubleshooting.md", tmp_dir)
    copy_fixture!("accrue/guides/analytics.md", tmp_dir)
    copy_fixture!("accrue/lib/accrue/entitlements/admin.ex", tmp_dir)
    copy_fixture!("accrue/lib/accrue/entitlements/reconcile.ex", tmp_dir)
    copy_fixture!("accrue/lib/accrue/entitlements/stripe_sync.ex", tmp_dir)
    copy_fixture!("accrue/lib/accrue/entitlements/stripe_sync/refresh_worker.ex", tmp_dir)
    copy_fixture!("accrue/lib/accrue/processor.ex", tmp_dir)
    copy_fixture!("accrue/lib/accrue/processor/fake.ex", tmp_dir)
    copy_fixture!("accrue/lib/accrue/processor/stripe.ex", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/README.md", tmp_dir)
    copy_fixture!("accrue_admin/assets/css/app.css", tmp_dir)
    copy_fixture!("accrue_admin/assets/css/theme.css", tmp_dir)
    copy_fixture!("accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex", tmp_dir)
    copy_fixture!("accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex", tmp_dir)
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/guides"))
    copy_fixture!("accrue_admin/guides/admin_ui.md", tmp_dir)
    copy_fixture!("accrue_admin/guides/motion.md", tmp_dir)
    copy_fixture!("accrue_admin/guides/spec-overview.md", tmp_dir)
    copy_fixture!("accrue_admin/guides/spec-list.md", tmp_dir)
    copy_fixture!("accrue_admin/guides/spec-detail.md", tmp_dir)
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin/lib/accrue_admin"))
    copy_fixture!("accrue_admin/lib/accrue_admin/router.ex", tmp_dir)
    copy_fixture!("accrue_portal/mix.exs", tmp_dir)
    copy_fixture!("accrue_portal/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/playwright.config.js", tmp_dir)
    copy_fixture!("guides/testing-live-stripe.md", tmp_dir)
    copy_fixture!("scripts/ci/accrue_host_uat.sh", tmp_dir)
    copy_fixture!("scripts/ci/verify_foundation_contrast.mjs", tmp_dir)
    copy_fixture!("examples/accrue_host/docs/adoption-proof-matrix.md", tmp_dir)
  end

  test "package docs verifier rejects dynamic HEEx class expression with Tailwind utility (D-15 FND-04)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    # Inject a LiveView component file with a dynamic class={...} expression containing a
    # Tailwind utility (hidden). This tests the D-15 blind spot: the guard must scan not just
    # literal class="..." but also class={...} dynamic expressions.
    component_path = Path.join(tmp_dir, "accrue_admin/lib/accrue_admin/dev/drifted_component.ex")
    File.mkdir_p!(Path.dirname(component_path))

    File.write!(component_path, ~s"""
    defmodule AccrueAdmin.Dev.DriftedComponent do
      use Phoenix.LiveComponent

      def render(assigns) do
        ~H\"\"\"
        <span class={if @loading, do: "ax-spinner", else: "hidden"} aria-hidden="true"></span>
        \"\"\"
      end
    end
    """)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "Tailwind utility authoring"
  end

  test "package docs verifier rejects subtree-dark semantic contrast drift (FND-05 D-18/D-19)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    theme_path = Path.join(tmp_dir, "accrue_admin/assets/css/theme.css")

    # Drift a token in the subtree dark scope (html.accrue-admin [data-theme="dark"] /
    # .accrue-admin [data-theme="dark"]) so its contrast ratio fails in that scope.
    # Strategy: replace the --ax-disabled-text value in the subtree dark block to a
    # near-zero contrast color (#252e3c ≈ the disabled bg #202832 — both very dark).
    # The explicit dark block (html.accrue-admin[data-theme="dark"]) is unmodified so
    # only the subtreeDark scope check triggers the failure.
    original = File.read!(theme_path)

    # The subtree dark block is the second occurrence of --ax-disabled-text in theme.css.
    # Split on the known block opener to target only the subtree dark block.
    subtree_open =
      "html.accrue-admin [data-theme=\"dark\"],\n.accrue-admin [data-theme=\"dark\"] {"

    assert original =~ subtree_open,
           "subtree dark block opener not found in theme.css — update fixture anchor"

    # Replace --ax-disabled-text only within the subtree dark block by splitting on the opener
    [before_subtree, subtree_and_after] = String.split(original, subtree_open, parts: 2)

    drifted_subtree =
      String.replace(
        subtree_and_after,
        "--ax-disabled-text: #c0c9d2;",
        "--ax-disabled-text: #252e3c;",
        global: false
      )

    drifted = before_subtree <> subtree_open <> drifted_subtree

    File.write!(theme_path, drifted)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "contrast" or output =~ "[foundation_contrast]"
  end

  test "package docs verifier rejects per-page CSS overrides of primitive ax-* classes (CMP-05)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    # Inject a violating page-specific CSS file (NOT app.css / theme.css)
    page_css_dir = Path.join(tmp_dir, "accrue_admin/assets/css")
    File.mkdir_p!(page_css_dir)

    File.write!(
      Path.join(page_css_dir, "page-overrides.css"),
      ".ax-button { font-size: 1rem; }\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "CMP-05"
  end

  test "package docs verifier rejects raw inline style= on primitive ax-* elements (CMP-05)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    kitchen_path =
      Path.join(tmp_dir, "accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex")

    original = File.read!(kitchen_path)

    # Inject a style= attribute on an element that also carries ax-button (inside a ~H""" heredoc)
    drifted =
      String.replace(
        original,
        ~s(<Button.button variant="secondary" type="button">Primary action specimen</Button.button>),
        ~s(<button class="ax-button ax-button-primary" style="color: red;" type="button">Primary action</button>),
        global: false
      )

    File.write!(kitchen_path, drifted)

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "CMP-05"
  end

  test "package docs verifier rejects raw px spacing (RES-04 spacing-literal guard)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    # Append a violation to the seeded app.css so earlier guards (token consumption etc.) still pass.
    # Trailing newline is required: Guard A uses /([^\n]+)\n/g which skips lines without a terminating \n.
    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    File.write!(app_css_path, "\n.ax-foo { padding: 16px; }\n", [:append])

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "spacing-literal guard"
  end

  test "package docs verifier rejects :focus without :focus-visible (RES-04 focus-visible guard)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    # Append a violation to the seeded app.css so earlier guards (token consumption etc.) still pass
    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")
    File.write!(app_css_path, "\n.ax-bar:focus { outline: 2px solid red; }\n", [:append])

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "focus-visible guard"
  end

  test "package docs verifier rejects truncation without min-width:0 (RES-04 truncation guard)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    # Append a violation to the seeded app.css so earlier guards (token consumption etc.) still pass
    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")

    File.write!(app_css_path, "\n.ax-baz { overflow: hidden; text-overflow: ellipsis; }\n", [
      :append
    ])

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"
    assert output =~ "truncation without min-width"
  end

  # D-08 coupling (MEMORY: verify_package_docs ↔ test coupling): this mirror MUST stay in sync
  # with Guard D in verify_package_docs.sh. If Guard D's fail message changes, update the
  # `output =~ "empty-rail"` assertion below to match the new stable substring.
  test "package docs verifier rejects cursor:pointer on .ax-attention-rail--empty (Phase 194)" do
    tmp_dir = tmp_dir!()
    seed_tmp_dir!(tmp_dir)

    app_css_path = Path.join(tmp_dir, "accrue_admin/assets/css/app.css")

    File.write!(
      app_css_path,
      File.read!(app_css_path) <> "\n.ax-attention-rail--empty { cursor: pointer; }\n"
    )

    {output, status} = run_verifier(tmp_dir)

    assert status != 0
    assert output =~ "[verify_package_docs]"

    # match the stable substring from Guard D's fail message (SPEC-OVERVIEW non-interactive-empty-rail guard)
    assert output =~ "empty-rail"
  end

  defp extract_version!(relative_path) do
    "../../../../#{relative_path}"
    |> Path.expand(__DIR__)
    |> File.read!()
    |> then(fn content ->
      Regex.run(~r/@version "([^"]+)"/, content, capture: :all_but_first)
    end)
    |> case do
      [version] -> version
      _ -> flunk("could not parse @version from #{relative_path}")
    end
  end
end
