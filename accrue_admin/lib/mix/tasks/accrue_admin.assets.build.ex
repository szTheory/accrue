defmodule Mix.Tasks.AccrueAdmin.Assets.Build do
  @shortdoc "Rebuild the private AccrueAdmin asset bundle"
  @moduledoc """
  Rebuilds the package-local CSS and JS bundle committed under `priv/static/`.

  This task intentionally stays inside `accrue_admin/`:

    * reads source files from `assets/`
    * writes only `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js`
    * does not require host-app Tailwind or JS bootstrap changes

  ## Examples

      mix accrue_admin.assets.build
  """

  use Mix.Task

  @runner_env_key :accrue_admin_assets_build_runner
  @tailwind_version "tailwindcss@3.4.17"
  @esbuild_version "esbuild@0.25.3"

  defmodule Runner do
    @moduledoc false
    @callback run(String.t(), [String.t()], keyword()) :: {:ok, integer()} | {:error, term()}
  end

  defmodule ShellRunner do
    @moduledoc false
    @behaviour Runner

    @impl true
    def run(command, args, opts) do
      {_, status} =
        System.cmd(command, args,
          cd: Keyword.fetch!(opts, :cd),
          stderr_to_stdout: true,
          into: IO.stream(:stdio, :line)
        )

      {:ok, status}
    rescue
      error -> {:error, error}
    end
  end

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("loadpaths")

    root = File.cwd!()
    File.mkdir_p!(Path.join(root, "priv/static"))

    runner = Application.get_env(:accrue_admin, @runner_env_key, ShellRunner)

    run_step!(runner, "tailwind", "npx", tailwind_args(root), cd: root)
    run_step!(runner, "esbuild", "npx", esbuild_args(root), cd: root)

    Mix.shell().info("Rebuilt AccrueAdmin assets in priv/static/")
  end

  defp tailwind_args(root) do
    [
      "--yes",
      @tailwind_version,
      "--config",
      Path.join(root, "assets/tailwind.config.js"),
      "--input",
      Path.join(root, "assets/css/app.css"),
      "--output",
      Path.join(root, "priv/static/accrue_admin.css"),
      "--minify"
    ]
  end

  defp esbuild_args(root) do
    [
      "--yes",
      @esbuild_version,
      Path.join(root, "assets/js/app.js"),
      "--bundle",
      "--format=esm",
      "--minify",
      "--outfile=" <> Path.join(root, "priv/static/accrue_admin.js")
    ]
  end

  defp run_step!(runner, label, command, args, opts) do
    case runner.run(command, args, opts) do
      {:ok, 0} ->
        :ok

      {:ok, status} ->
        Mix.raise("#{label} build failed with exit status #{status}")

      {:error, reason} ->
        Mix.raise("#{label} build failed: #{Exception.message(reason)}")
    end
  end
end
