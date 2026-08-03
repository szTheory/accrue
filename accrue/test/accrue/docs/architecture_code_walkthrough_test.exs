defmodule Accrue.Docs.ArchitectureCodeWalkthroughTest do
  use ExUnit.Case, async: true

  @architecture_path Path.expand("../../../guides/architecture.md", __DIR__)
  @walkthrough_path Path.expand("../../../guides/code-walkthrough.md", __DIR__)
  @core_readme_path Path.expand("../../../README.md", __DIR__)
  @root_readme_path Path.expand("../../../../README.md", __DIR__)
  @docs_logo_path Path.expand("../../../priv/ex_doc/accrue-mark.svg", __DIR__)
  @docs_favicon_path Path.expand("../../../priv/ex_doc/favicon.svg", __DIR__)

  @architecture_headings [
    "Accrue in one picture",
    "Vocabulary for the trip",
    "Journey 1: The application asks billing to change",
    "Journey 2: The processor reports what happened",
    "The data model carries the architecture",
    "Cross-cutting mechanics",
    "How the sibling packages fit",
    "Module atlas",
    "Code-reading routes",
    "Changing Accrue safely",
    "Where to go next"
  ]

  test "ExDoc and both reading maps expose the guide pair" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)
    extras = Keyword.fetch!(docs, :extras)
    root_readme = File.read!(@root_readme_path)
    core_readme = File.read!(@core_readme_path)

    assert "guides/architecture.md" in extras,
           "expected the ExDoc extras wildcard to include guides/architecture.md"

    assert "guides/code-walkthrough.md" in extras,
           "expected the ExDoc extras wildcard to include guides/code-walkthrough.md"

    assert root_readme =~ "accrue/guides/architecture.md"
    assert root_readme =~ "accrue/guides/code-walkthrough.md"
    assert core_readme =~ "guides/architecture.md"
    assert core_readme =~ "guides/code-walkthrough.md"
  end

  test "ExDoc ships adaptive Accrue branding" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)

    assert Keyword.fetch!(docs, :logo) == "priv/ex_doc/accrue-mark.svg"
    assert Keyword.fetch!(docs, :favicon) == "priv/ex_doc/favicon.svg"

    for {label, path} <- [{"logo", @docs_logo_path}, {"favicon", @docs_favicon_path}] do
      asset = File.read!(path)

      assert asset =~ "Accrue", "expected the docs #{label} to identify the Accrue brand"

      assert asset =~ "prefers-color-scheme: dark",
             "expected the docs #{label} to remain visible in dark browser chrome"
    end
  end

  test "architecture keeps its teaching order, accessible diagrams, and parseable examples" do
    architecture = File.read!(@architecture_path)

    positions =
      Enum.map(@architecture_headings, fn heading ->
        case :binary.match(architecture, "## " <> heading) do
          {position, _length} -> position
          :nomatch -> flunk("architecture guide is missing the required H2: #{heading}")
        end
      end)

    assert positions == Enum.sort(positions),
           "architecture H2s must remain in the outside-in teaching order"

    assert count(architecture, ~r/^```mermaid$/m) == 4,
           "architecture must contain exactly four Mermaid diagrams"

    assert count(architecture, ~r/^  accTitle:/m) == 4,
           "every architecture diagram needs one Mermaid accTitle"

    assert count(architecture, ~r/^  accDescr:/m) == 4,
           "every architecture diagram needs one Mermaid accDescr"

    blocks = elixir_blocks(architecture)

    assert length(blocks) == 5,
           "architecture must keep exactly five tactically placed Elixir examples"

    assert_parseable!(blocks, "architecture")
  end

  test "walkthrough keeps a bounded set of parseable source excerpts" do
    blocks = @walkthrough_path |> File.read!() |> elixir_blocks()

    assert length(blocks) in 12..18,
           "code walkthrough must contain between 12 and 18 representative Elixir excerpts"

    assert length(blocks) == 18,
           "the current direct-subscribe walkthrough is intentionally locked to 18 excerpts"

    assert_parseable!(blocks, "code walkthrough")
  end

  test "guides link to each other without publishing repository reading paths" do
    architecture = File.read!(@architecture_path)
    walkthrough = File.read!(@walkthrough_path)

    assert architecture =~ "code-walkthrough.md"
    assert walkthrough =~ "architecture.md"

    Enum.each(
      [{"architecture", architecture}, {"code walkthrough", walkthrough}],
      fn {label, guide} ->
        refute Regex.match?(~r{github\.com/[^\s)]+/(?:blob|tree)/}, guide),
               "#{label} must use module pages rather than GitHub blob/tree links"

        refute Regex.match?(~r/#L\d+/, guide),
               "#{label} must not publish brittle source-line anchors"

        prose = Regex.replace(~r/\]\([^)]+\)/, guide, "]")

        refute Regex.match?(
                 ~r{(?:^|[\s`(])(?:lib|test|examples|\.planning|accrue|accrue_admin|accrue_portal)/},
                 prose
               ),
               "#{label} must use modules, not repository filesystem paths, as its reading interface"
      end
    )
  end

  test "walkthrough anchors remain present in current source" do
    walkthrough = File.read!(@walkthrough_path)

    anchors = [
      {
        "Billing.subscribe(billable, price_id, opts)",
        Path.expand(
          "../../../../examples/accrue_host/lib/accrue_host/billing.ex",
          __DIR__
        )
      },
      {
        "subscribe_sequence(price_id, quantity, opts)",
        Path.expand("../../../lib/accrue/billing/subscription_actions.ex", __DIR__)
      },
      {
        "Accrue.Webhook.Ingest.run(conn, :stripe, stripe_event, raw_body, endpoint)",
        Path.expand("../../../lib/accrue/webhook/plug.ex", __DIR__)
      },
      {
        "Processor.__impl__().fetch(:subscription, stripe_id)",
        Path.expand("../../../lib/accrue/webhook/default_handler.ex", __DIR__)
      },
      {
        "Query.entitling()",
        Path.expand("../../../lib/accrue/entitlements/resolver/local_map.ex", __DIR__)
      }
    ]

    Enum.each(anchors, fn {anchor, source_path} ->
      assert walkthrough =~ anchor,
             "code walkthrough lost its stable architectural anchor: #{anchor}"

      assert File.read!(source_path) =~ anchor,
             "source drifted from the walkthrough anchor #{anchor}; update source and guide together"
    end)
  end

  test "Mermaid hook is pinned, strict, navigation-aware, fallback-safe, and HTML-only" do
    docs = Mix.Project.config() |> Keyword.fetch!(:docs)
    callback = Keyword.fetch!(docs, :before_closing_body_tag)
    html = callback.(:html)

    assert html =~
             "https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.esm.min.mjs"

    assert html =~ ~s(securityLevel: "strict")
    assert html =~ ~s(startOnLoad: false)
    assert html =~ ~s|window.addEventListener("exdoc:loaded", scheduleMermaidRender)|
    assert html =~ ~s|document.querySelectorAll("pre > code.mermaid")|
    assert html =~ ~s(code.dataset.mermaidRendering = "true")
    assert html =~ "delete code.dataset.mermaidRendering"
    assert html =~ "console.warn"
    assert html =~ ~s|document.body.classList.contains("dark") ? "dark" : "default"|
    assert html =~ ~s|theme });|
    assert html =~ "new MutationObserver(scheduleMermaidRender)"
    assert html =~ "wrapper.dataset.mermaidSource = source"
    assert html =~ "renderExistingDiagram"

    render_position = position!(html, "await mermaid.render")
    replace_position = position!(html, "pre.replaceWith(wrapper)")

    assert render_position < replace_position,
           "Mermaid source fallback must remain in the DOM until rendering succeeds"

    assert callback.(:epub) == "", "EPUB output must not include the Mermaid loader"
    assert callback.(:markdown) == "", "non-HTML output must not include the Mermaid loader"
  end

  defp count(text, regex), do: length(Regex.scan(regex, text))

  defp elixir_blocks(markdown) do
    ~r/```elixir\n(.*?)```/s
    |> Regex.scan(markdown, capture: :all_but_first)
    |> List.flatten()
  end

  defp assert_parseable!(blocks, guide) do
    blocks
    |> Enum.with_index(1)
    |> Enum.each(fn {block, index} ->
      assert {:ok, _quoted} = Code.string_to_quoted(block),
             "#{guide} Elixir block #{index} must remain parseable"
    end)
  end

  defp position!(text, needle) do
    case :binary.match(text, needle) do
      {position, _length} -> position
      :nomatch -> flunk("Mermaid hook is missing required source: #{needle}")
    end
  end
end
