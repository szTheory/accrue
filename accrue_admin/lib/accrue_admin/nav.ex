defmodule AccrueAdmin.Nav do
  @moduledoc false

  def items(mount_path, current_path) do
    org = org_slug(current_path)

    # Grouped by the operator's mental model, not by internal module. Home stands
    # alone (group: nil → no label). Eyebrow sublabels dropped (Phase 169): they
    # added jargon without prediction value. Icons via AccrueAdmin.Components.Icon.
    [
      %{label: "Home", href: nav_href(mount_path, "", org), icon: :home, group: nil},
      %{
        label: "Customers",
        href: nav_href(mount_path, "/customers", org),
        icon: :users,
        group: "Billing"
      },
      %{
        label: "Subscriptions",
        href: nav_href(mount_path, "/subscriptions", org),
        icon: :subscriptions,
        group: "Billing"
      },
      %{
        label: "Invoices",
        href: nav_href(mount_path, "/invoices", org),
        icon: :invoices,
        group: "Billing"
      },
      %{
        label: "Payments",
        href: nav_href(mount_path, "/charges", org),
        icon: :payments,
        group: "Billing"
      },
      %{
        label: "Recovery",
        href: nav_href(mount_path, "/analytics/recovery", org),
        icon: :recovery,
        group: "Recovery"
      },
      %{
        label: "Webhooks",
        href: nav_href(mount_path, "/webhooks", org),
        icon: :webhooks,
        group: "Developer"
      },
      %{
        label: "Event log",
        href: nav_href(mount_path, "/events", org),
        icon: :events,
        group: "Developer"
      },
      %{
        label: "Coupons",
        href: nav_href(mount_path, "/coupons", org),
        icon: :coupons,
        group: "Catalog"
      },
      %{
        label: "Promotion codes",
        href: nav_href(mount_path, "/promotion-codes", org),
        icon: :promotions,
        group: "Catalog"
      },
      %{
        label: "Connect",
        href: nav_href(mount_path, "/connect", org),
        icon: :connect,
        group: "Connect"
      }
    ]
  end

  defp org_slug(current_path) do
    current_path
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> nil
      query -> query |> URI.decode_query() |> Map.get("org")
    end
  end

  defp nav_href(mount_path, suffix, slug) when is_binary(slug) and slug != "" do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp nav_href(mount_path, suffix, _slug), do: mount_path <> suffix
end
