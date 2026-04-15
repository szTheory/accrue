defmodule Accrue.Install.Fingerprints do
  @moduledoc """
  No-clobber primitives for Accrue-generated host files.
  """

  @marker "# accrue:generated"
  @fingerprint_prefix "# accrue:fingerprint:"

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
  @spec write(Path.t(), String.t(), keyword()) :: {:changed | :skipped, String.t()}
  def write(path, content, opts \\ []) when is_binary(content) do
    stamped = stamp(content)

    cond do
      Keyword.get(opts, :dry_run, false) ->
        {:skipped, "dry-run"}

      not File.exists?(path) ->
        do_write(path, stamped)
        {:changed, "created"}

      pristine?(path) ->
        do_write(path, stamped)
        {:changed, "updated pristine"}

      user_edited?(path) ->
        {:skipped, "user-edited"}

      Keyword.get(opts, :force, false) ->
        do_write(path, stamped)
        {:changed, "overwrote unmarked"}

      true ->
        {:skipped, "exists"}
    end
  end

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
