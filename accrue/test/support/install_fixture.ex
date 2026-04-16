defmodule Accrue.Test.InstallFixture do
  @moduledoc false

  import ExUnit.Assertions

  @doc """
  Creates a Phoenix-shaped temporary application fixture.
  """
  def tmp_app!(name) when is_atom(name) do
    root =
      Path.join(System.tmp_dir!(), "accrue_install_#{name}_#{System.unique_integer([:positive])}")

    File.rm_rf!(root)
    File.mkdir_p!(root)
    File.mkdir_p!(Path.join(root, "lib/my_app_web"))
    File.mkdir_p!(Path.join(root, "config"))
    File.mkdir_p!(Path.join(root, "test/support"))
    root
  end

  def write_mix_project!(root, deps) when is_list(deps) do
    dep_lines =
      deps
      |> Enum.map(&"      #{&1}")
      |> Enum.join(",\n")

    write!(root, "mix.exs", """
    defmodule MyApp.MixProject do
      use Mix.Project

      def project do
        [
          app: :my_app,
          version: "0.1.0",
          elixir: "~> 1.17",
          deps: deps()
        ]
      end

      def application, do: [extra_applications: [:logger]]

      defp deps do
        [
    #{dep_lines}
        ]
      end
    end
    """)
  end

  def write_router!(root, body \\ default_router()) do
    write!(root, "lib/my_app_web/router.ex", body)
  end

  def write_config!(root, body \\ "") do
    write!(root, "config/config.exs", body)
  end

  def read!(root, relative_path) do
    root
    |> Path.join(relative_path)
    |> File.read!()
  end

  def assert_contains!(root, relative_path, expected) do
    content = read!(root, relative_path)
    assert content =~ expected
    content
  end

  def refute_contains!(root, relative_path, rejected) do
    content = read!(root, relative_path)
    assert not String.contains?(content, rejected)
    content
  end

  def write!(root, relative_path, content) when is_binary(content) do
    path = Path.join(root, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end

  def cd_preserving_code_path!(root, fun) when is_function(fun, 0) do
    original_path = :code.get_path()

    try do
      File.cd!(root, fun)
    after
      restore_code_path(original_path)
    end
  end

  defp restore_code_path(original_path) do
    current_path = :code.get_path()

    Enum.each(current_path -- original_path, &:code.del_path/1)

    original_path
    |> Enum.reverse()
    |> Enum.each(&:code.add_patha/1)
  end

  def default_router do
    """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      pipeline :browser do
        plug :accepts, ["html"]
      end

      scope "/", MyAppWeb do
        pipe_through :browser
      end
    end
    """
  end
end
