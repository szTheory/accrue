defmodule Accrue.Test.Entitlements do
  @moduledoc """
  Small, provider-free entitlement fixtures for host application tests.

  These helpers insert only Accrue's normalized `Account` and `Grant` rows;
  they never call Stripe or Apple and never require provider credentials.
  The four common rendering states are available through `insert!/2`:

    * `:none`
    * `:stripe_active`
    * `:stripe_cancelled_but_entitled`
    * `:apple_active`

  Configure matching products in the host test environment:

      config :accrue,
        processor: Accrue.Processor.Fake,
        rails: [
          stripe: [
            source: :stripe,
            processor: Accrue.Processor.Fake,
            environments: [:production],
            default_environment: :production
          ],
          apple: [
            source: :apple,
            environments: [:production],
            default_environment: :production
          ]
        ],
        default_rail: :stripe,
        entitlements: [
          plans: [
            pro: [
              features: [:pro],
              limits: [seats: 1],
              products: [
                stripe: [production: ["price_test_pro"]],
                apple: [production: ["com.example.test.pro"]]
              ]
            ]
          ]
        ]

  `:stripe_cancelled_but_entitled` models cancellation at period end: the
  grant remains current and gets a future `expires_at`. Override that boundary
  with `:expires_at` when a test needs an exact timestamp.
  """

  alias Accrue.Entitlements.{Account, Grant}

  @scenarios [:none, :stripe_active, :stripe_cancelled_but_entitled, :apple_active]
  @default_period_seconds 30 * 24 * 60 * 60

  @type scenario ::
          :none | :stripe_active | :stripe_cancelled_but_entitled | :apple_active

  @type fixture :: %{account: Account.t(), grants: [Grant.t()]}

  @doc """
  Inserts one of the standard entitlement states through the configured Repo.

  Options include `:owner_type`, `:owner_id`, `:plan`, `:quantity`, `:now`,
  `:expires_at`, and rail-specific `:stripe_product_id` / `:apple_product_id`.
  """
  @spec insert!(scenario(), keyword()) :: fixture()
  def insert!(scenario, opts \\ []) when scenario in @scenarios and is_list(opts) do
    insert!(Keyword.get(opts, :repo, Accrue.Repo.repo()), scenario, opts)
  end

  @doc "Same as `insert!/2`, using an explicit Ecto Repo."
  @spec insert!(Ecto.Repo.t(), scenario(), keyword()) :: fixture()
  def insert!(repo, scenario, opts)
      when is_atom(repo) and scenario in @scenarios and is_list(opts) do
    suffix = Keyword.get_lazy(opts, :suffix, &unique_suffix/0)

    account =
      %Account{}
      |> Account.changeset(%{
        owner_type: Keyword.get(opts, :owner_type, "test_owner"),
        owner_id: Keyword.get(opts, :owner_id, "accrue-fixture-#{suffix}"),
        revision: Keyword.get(opts, :revision, 0)
      })
      |> repo.insert!()

    grants = insert_grants!(repo, account, scenario, suffix, opts)
    %{account: account, grants: grants}
  end

  defp insert_grants!(_repo, _account, :none, _suffix, _opts), do: []

  defp insert_grants!(repo, account, scenario, suffix, opts) do
    rail = rail(scenario)
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    effective_at = Keyword.get(opts, :effective_at, DateTime.add(now, -1, :second))
    expires_at = expiry(scenario, now, opts)
    product_id = product_id(rail, opts)
    plan = opts |> Keyword.get(:plan, :pro) |> to_string()

    grant =
      %Grant{}
      |> Grant.changeset(%{
        account_id: account.id,
        rail: rail,
        environment: Keyword.get(opts, :environment, :production),
        provider_lineage_id: "lineage_#{rail}_#{suffix}",
        provider_product_id: product_id,
        logical_plan: plan,
        source_item_id: "item_#{rail}_#{suffix}",
        quantity: Keyword.get(opts, :quantity, 1),
        provider_order: Keyword.get(opts, :provider_order, 1),
        account_revision: account.revision,
        effective_at: effective_at,
        expires_at: expires_at
      })
      |> repo.insert!()

    [grant]
  end

  defp rail(:apple_active), do: :apple
  defp rail(_stripe_scenario), do: :stripe

  defp expiry(:stripe_cancelled_but_entitled, now, opts) do
    Keyword.get(opts, :expires_at, DateTime.add(now, @default_period_seconds, :second))
  end

  defp expiry(_scenario, _now, opts), do: Keyword.get(opts, :expires_at)

  defp product_id(:stripe, opts),
    do: Keyword.get(opts, :stripe_product_id, "price_test_pro")

  defp product_id(:apple, opts),
    do: Keyword.get(opts, :apple_product_id, "com.example.test.pro")

  defp unique_suffix do
    System.unique_integer([:positive, :monotonic]) |> Integer.to_string(36)
  end
end
