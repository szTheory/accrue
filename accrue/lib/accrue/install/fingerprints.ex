defmodule Accrue.Install.Fingerprints do
  @moduledoc """
  No-clobber primitives for Accrue-generated host files.
  """

  @type write_result ::
          {:changed, Path.t(), String.t()}
          | {:skipped, Path.t(), String.t()}
          | {:skipped, Path.t(), String.t(), Path.t()}

  @marker "# accrue:generated"
  @fingerprint_prefix "# accrue:fingerprint:"
  @conflict_root ".accrue/conflicts"

  @doc false
  def marker, do: @marker

  @doc """
  Adds the Accrue generated marker and SHA256 fingerprint to rendered content.
  """
  @spec stamp(String.t()) :: String.t()
  def stamp(content) when is_binary(content) do
    body = strip_fingerprint(content)
    fingerprint = fingerprint(body)

    [@marker, "#{@fingerprint_prefix} #{fingerprint}", body]
    |> Enum.join("\n")
    |> ensure_trailing_newline()
  end

  @doc """
  Returns true when the on-disk file is still a pristine Accrue-generated file.
  """
  @spec pristine?(Path.t(), String.t() | nil) :: boolean()
  def pristine?(path, _new_content \\ nil) do
    File.exists?(path) and pristine_content?(File.read!(path))
  end

  @doc """
  Returns true when a generated file contains user edits.
  """
  @spec user_edited?(Path.t(), String.t() | nil) :: boolean()
  def user_edited?(path, _new_content \\ nil) do
    File.exists?(path) and generated?(File.read!(path)) and not pristine?(path)
  end

  @doc """
  Writes new files and updates pristine generated files; skips user-edited files.
  """
  @spec write(Path.t(), String.t(), keyword()) :: write_result()
  def write(path, content, opts \\ []) when is_binary(content) do
    stamped = stamp(content)

    cond do
      Keyword.get(opts, :dry_run, false) ->
        {:skipped, path, "dry-run"}

      not File.exists?(path) ->
        do_write(path, stamped)
        {:changed, path, "created"}

      pristine?(path) ->
        do_write(path, stamped)
        {:changed, path, "updated pristine"}

      user_edited?(path) ->
        skipped_with_conflict(path, "user-edited", stamped, opts)

      Keyword.get(opts, :force, false) ->
        do_write(path, stamped)
        {:changed, path, "overwrote unmarked"}

      true ->
        skipped_with_conflict(path, "exists", stamped, opts)
    end
  end

  @doc """
  Writes a template replacement artifact under `.accrue/conflicts/templates/`.
  """
  @spec write_template_conflict(Path.t(), String.t(), String.t()) :: Path.t()
  def write_template_conflict(path, reason, content)
      when is_binary(path) and is_binary(reason) and is_binary(content) do
    artifact_path = template_conflict_path(path)
    artifact_body = conflict_body(path, reason, content)

    File.mkdir_p!(Path.dirname(artifact_path))
    File.write!(artifact_path, artifact_body)
    artifact_path
  end

  @doc """
  Writes a patch snippet artifact under `.accrue/conflicts/patches/`.
  """
  @spec write_patch_conflict(Path.t(), String.t(), String.t()) :: Path.t()
  def write_patch_conflict(path, reason, snippet)
      when is_binary(path) and is_binary(reason) and is_binary(snippet) do
    artifact_path = patch_conflict_path(path)
    artifact_body = conflict_body(path, reason, snippet)

    File.mkdir_p!(Path.dirname(artifact_path))
    File.write!(artifact_path, artifact_body)
    artifact_path
  end

  @doc false
  def template_conflict_path(path) when is_binary(path),
    do: conflict_path("templates", path, ".new")

  @doc false
  def patch_conflict_path(path) when is_binary(path),
    do: conflict_path("patches", path, ".snippet")

  @doc """
  Redacts Stripe/API secret material before installer report output.
  """
  @spec redact(term()) :: String.t()
  def redact(value) do
    value
    |> inspect()
    |> String.replace(~r/sk_(test|live)_[A-Za-z0-9_=-]+/, "sk_\\1_[REDACTED]")
    |> String.replace(~r/whsec_[A-Za-z0-9_=-]+/, "whsec_[REDACTED]")
    |> String.replace(~r/([A-Z0-9_]*(?:SECRET|KEY)[A-Z0-9_]*=)[^\s,}]+/, "\\1[REDACTED]")
  end

  defp generated?(content), do: content =~ @marker

  defp skipped_with_conflict(path, reason, content, opts) do
    if Keyword.get(opts, :write_conflicts, false) do
      artifact_path = write_template_conflict(path, "skipped #{reason}", content)
      {:skipped, path, reason, artifact_path}
    else
      {:skipped, path, reason}
    end
  end

  defp conflict_path(kind, path, extension) do
    relative_path = Path.relative_to_cwd(path)
    Path.join([@conflict_root, kind, relative_path <> extension])
  end

  defp conflict_body(path, reason, content) do
    relative_path = Path.relative_to_cwd(path)

    [
      "target: #{relative_path}",
      "reason: #{reason}",
      "",
      ensure_trailing_newline(content)
    ]
    |> Enum.join("\n")
    |> ensure_trailing_newline()
  end

  defp pristine_content?(content) do
    with [_, saved] <-
           Regex.run(~r/#{Regex.escape(@fingerprint_prefix)}\s+([a-f0-9]{64})/, content) do
      fingerprint(strip_fingerprint(content)) == saved
    else
      _ -> false
    end
  end

  defp strip_fingerprint(content) do
    content
    |> String.split("\n")
    |> Enum.reject(&(&1 == @marker or String.starts_with?(&1, @fingerprint_prefix)))
    |> Enum.join("\n")
    |> String.trim_leading("\n")
    |> ensure_trailing_newline()
  end

  defp fingerprint(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  defp do_write(path, content) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end

  defp ensure_trailing_newline(content) do
    if String.ends_with?(content, "\n"), do: content, else: content <> "\n"
  end
end
