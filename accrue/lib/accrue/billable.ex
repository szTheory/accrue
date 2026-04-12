defmodule Accrue.Billable do
  @moduledoc """
  One-line macro that makes any host schema billable.

  When a host schema calls `use Accrue.Billable`, it gains:

    1. A `has_one :accrue_customer` association scoped by `owner_type`
    2. A `__accrue__(:billable_type)` reflection callback
    3. A `customer/1` convenience that delegates to `Accrue.Billing.customer/1`

  ## Usage

      defmodule MyApp.User do
        use Ecto.Schema
        use Accrue.Billable

        schema "users" do
          field :email, :string
          timestamps()
        end
      end

  ## Rename safety

  By default, `billable_type` is derived from the last segment of the
  module name (`MyApp.User` becomes `"User"`). If you rename the module
  later, existing `accrue_customers` rows will have the OLD name in
  `owner_type`, causing a mismatch.

  Pin the type explicitly if there is any chance of renaming:

      use Accrue.Billable, billable_type: "User"

  Changing a module name without pinning `billable_type:` requires a data
  migration on `accrue_customers.owner_type`.

  ## Association notes

  The `has_one :accrue_customer` association uses `references: :id` and
  `foreign_key: :owner_id` with a `:where` clause filtering by
  `owner_type`. Because `accrue_customers.owner_id` is a `:string`
  column (to support integer, UUID, and ULID host PKs losslessly), the
  association works best with binary/UUID PKs. For integer PKs, the
  `Accrue.Billing` context handles the `to_string/1` coercion in its
  fetch/create path rather than relying on the association join.
  """

  @doc false
  defmacro __using__(opts) do
    billable_type =
      case Keyword.get(opts, :billable_type) do
        nil ->
          __CALLER__.module
          |> Module.split()
          |> List.last()

        type when is_binary(type) ->
          type
      end

    quote do
      @__accrue_billable_type__ unquote(billable_type)
      @before_compile Accrue.Billable

      @doc false
      def __accrue__(:billable_type), do: @__accrue_billable_type__
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    billable_type = Module.get_attribute(env.module, :__accrue_billable_type__)

    quote do
      Ecto.Schema.has_one(:accrue_customer, Accrue.Billing.Customer,
        foreign_key: :owner_id,
        references: :id,
        where: [owner_type: unquote(billable_type)]
      )

      @doc """
      Lazily fetches or creates the `Accrue.Billing.Customer` for this
      billable. Delegates to `Accrue.Billing.customer/1`.
      """
      @spec customer(struct()) :: {:ok, Accrue.Billing.Customer.t()} | {:error, term()}
      def customer(%__MODULE__{} = struct), do: Accrue.Billing.customer(struct)
    end
  end
end
