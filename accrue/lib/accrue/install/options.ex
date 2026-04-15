defmodule Accrue.Install.Options do
  @moduledoc """
  Strict option parsing for `mix accrue.install`.

  Every installer product choice has a CLI flag so CI and scripted installs
  can run without prompts.
  """

  @type auto_boolean :: boolean() | :auto

  @type t :: %__MODULE__{
          billable: String.t() | nil,
          billing_context: String.t(),
          webhook_path: String.t(),
          admin_mount: String.t(),
          admin: auto_boolean(),
          sigra: auto_boolean(),
          dry_run: boolean(),
          manual: boolean(),
          force: boolean(),
          write_conflicts: boolean(),
          accept?: boolean()
        }

  defstruct billable: nil,
            billing_context: "MyApp.Billing",
            webhook_path: "/webhooks/stripe",
            admin_mount: "/billing",
            admin: :auto,
            sigra: :auto,
            dry_run: false,
            manual: false,
            force: false,
            write_conflicts: false,
            accept?: false

  @switches [
    billable: :string,
    billing_context: :string,
    webhook_path: :string,
    admin_mount: :string,
    admin: :boolean,
    sigra: :boolean,
    dry_run: :boolean,
    yes: :boolean,
    non_interactive: :boolean,
    manual: :boolean,
    force: :boolean,
    write_conflicts: :boolean
  ]

  @doc false
  def switches, do: @switches

  @doc """
  Parses installer argv, raising on unknown switches or positional args.
  """
  @spec parse!([String.t()]) :: t()
  def parse!(argv) when is_list(argv) do
    {opts, args, invalid} = OptionParser.parse(argv, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown accrue.install option(s): #{format_invalid(invalid)}")
    end

    if args != [] do
      Mix.raise("mix accrue.install does not accept positional arguments: #{inspect(args)}")
    end

    %__MODULE__{
      billable: opts[:billable],
      billing_context: Keyword.get(opts, :billing_context, "MyApp.Billing"),
      webhook_path: Keyword.get(opts, :webhook_path, "/webhooks/stripe"),
      admin_mount: Keyword.get(opts, :admin_mount, "/billing"),
      admin: Keyword.get(opts, :admin, :auto),
      sigra: Keyword.get(opts, :sigra, :auto),
      dry_run: opts[:dry_run] || false,
      manual: opts[:manual] || false,
      force: opts[:force] || false,
      write_conflicts: opts[:write_conflicts] || false,
      accept?: opts[:yes] || opts[:non_interactive] || false
    }
  end

  defp format_invalid(invalid) do
    invalid
    |> Enum.map(fn
      {switch, nil} -> to_string(switch)
      {switch, value} -> "#{switch}=#{value}"
    end)
    |> Enum.join(", ")
  end
end
