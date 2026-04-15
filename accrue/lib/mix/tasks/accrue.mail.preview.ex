defmodule Mix.Tasks.Accrue.Mail.Preview do
  @shortdoc "Render all Accrue email types to .accrue/previews/"
  @moduledoc """
  Renders every `Accrue.Emails.*` type with canned fixtures (D6-08).

  Writes outputs to `.accrue/previews/{type}.{html,txt,pdf}`.

  ## Options

    * `--only <csv>` — render only the listed types (default: all)
    * `--format <html|txt|pdf|both>` — emit specific formats
      (default: `both` — html + txt)

  ## Examples

      mix accrue.mail.preview
      mix accrue.mail.preview --only receipt,trial_ending
      mix accrue.mail.preview --only receipt --format html
      mix accrue.mail.preview --format pdf

  `.accrue/` is git-ignored by convention — see `accrue/.gitignore`.

  ## PDF rendering

  The `--format pdf` / `--format both` (with PDF included) path calls
  `Accrue.Billing.render_invoice_pdf/2` against the fixture invoice id.
  Since fixtures are pure data with no DB row, PDF rendering is
  best-effort: on any adapter error the task logs `skipped` and
  continues. Use this task as a template/visual sanity check, not as
  a production PDF smoke test.
  """

  use Mix.Task

  alias Accrue.Emails.Fixtures
  alias Accrue.Workers.Mailer, as: Worker

  @switches [only: :string, format: :string]
  @preview_dir ".accrue/previews"

  @impl Mix.Task
  def run(argv) do
    # Fixtures are pure data — no DB, no processor, no Oban. Load
    # compiled modules without starting the OTP application so the
    # task works against host apps that haven't finished wiring
    # :repo, :secret_key_base, etc.
    Mix.Task.run("loadpaths")
    Application.ensure_all_started(:mjml_eex)
    Application.ensure_all_started(:phoenix_html)

    {opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

    types = parse_only(Keyword.get(opts, :only))
    formats = parse_format(Keyword.get(opts, :format, "both"))

    File.mkdir_p!(@preview_dir)

    Enum.each(types, fn type ->
      fixture = fetch_fixture(type)
      module = Worker.template_for(type)

      if :html in formats do
        write(type, "html", safe_render(module, :render, fixture))
      end

      if :txt in formats do
        write(type, "txt", safe_render(module, :render_text, fixture))
      end

      if :pdf in formats do
        write_pdf(type, fixture)
      end
    end)

    Mix.shell().info(
      "Rendered #{length(types)} email preview(s) to #{@preview_dir}/"
    )
  end

  defp parse_only(nil), do: Map.keys(Fixtures.all())

  defp parse_only(csv) do
    known = Map.keys(Fixtures.all())

    csv
    |> String.split(",", trim: true)
    |> Enum.map(fn s ->
      try do
        String.to_existing_atom(s)
      rescue
        ArgumentError -> Mix.raise("Unknown email type: #{inspect(s)}")
      end
    end)
    |> tap(fn list ->
      unknown = list -- known

      if unknown != [] do
        Mix.raise("Unknown email type(s): #{inspect(unknown)}")
      end
    end)
  end

  defp parse_format("html"), do: [:html]
  defp parse_format("txt"), do: [:txt]
  defp parse_format("pdf"), do: [:pdf]
  defp parse_format("both"), do: [:html, :txt]
  defp parse_format(other), do: Mix.raise("Invalid --format: #{inspect(other)}")

  defp fetch_fixture(type) do
    case Map.fetch(Fixtures.all(), type) do
      {:ok, fixture} -> fixture
      :error -> Mix.raise("No fixture for email type #{inspect(type)}")
    end
  end

  # Templates pattern-match on different assign shapes. We try the raw
  # fixture first (which is `%{context: %{...}, subject: ..., preview: ...}`)
  # and fall back to passing `fixture.context` on `FunctionClauseError`.
  defp safe_render(module, fun, fixture) do
    try do
      apply(module, fun, [fixture])
    rescue
      FunctionClauseError -> apply(module, fun, [fixture.context])
      KeyError -> apply(module, fun, [fixture.context])
    end
  end

  defp write(type, ext, content) when is_binary(content) do
    path = Path.join(@preview_dir, "#{type}.#{ext}")
    File.write!(path, content)
    Mix.shell().info("  #{path}")
  end

  defp write_pdf(type, fixture) do
    invoice_id = get_in(fixture, [:context, :invoice, :id])
    locale = get_in(fixture, [:context, :locale])

    case Accrue.Billing.render_invoice_pdf(invoice_id, locale: locale) do
      {:ok, pdf} ->
        path = Path.join(@preview_dir, "#{type}.pdf")
        File.write!(path, pdf)
        Mix.shell().info("  #{path}")

      {:error, reason} ->
        Mix.shell().info("  skipped #{type}.pdf (#{inspect(reason)})")
    end
  end
end
