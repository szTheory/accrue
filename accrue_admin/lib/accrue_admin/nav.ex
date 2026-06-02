defmodule AccrueAdmin.Nav do
  @moduledoc false

  def items(mount_path, current_path) do
    org = org_slug(current_path)

    [
      %{label: "Home", href: nav_href(mount_path, "", org), eyebrow: "Triage", group: "Command"},
      %{
        label: "Customers",
        href: nav_href(mount_path, "/customers", org),
        eyebrow: "Account 360",
        group: "Investigate"
      },
      %{
        label: "Subscriptions",
        href: nav_href(mount_path, "/subscriptions", org),
        eyebrow: "Lifecycle",
        group: "Investigate"
      },
      %{
        label: "Invoices",
        href: nav_href(mount_path, "/invoices", org),
        eyebrow: "Receivables",
        group: "Revenue"
      },
      %{
        label: "Payments",
        href: nav_href(mount_path, "/charges", org),
        eyebrow: "Charges & refunds",
        group: "Revenue"
      },
      %{
        label: "Recovery",
        href: nav_href(mount_path, "/analytics/recovery", org),
        eyebrow: "Dunning",
        group: "Revenue"
      },
      %{
        label: "Webhooks",
        href: nav_href(mount_path, "/webhooks", org),
        eyebrow: "Pipeline",
        group: "Operations"
      },
      %{
        label: "Event log",
        href: nav_href(mount_path, "/events", org),
        eyebrow: "Audit trail",
        group: "Operations"
      },
      %{
        label: "Coupons",
        href: nav_href(mount_path, "/coupons", org),
        eyebrow: "Catalog",
        group: "Discounts"
      },
      %{
        label: "Promotion codes",
        href: nav_href(mount_path, "/promotion-codes", org),
        eyebrow: "Redemption",
        group: "Discounts"
      },
      %{
        label: "Connect",
        href: nav_href(mount_path, "/connect", org),
        eyebrow: "Payouts",
        group: "Platform"
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
