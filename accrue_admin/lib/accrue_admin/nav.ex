defmodule AccrueAdmin.Nav do
  @moduledoc false

  def items(mount_path, current_path) do
    org = org_slug(current_path)

    [
      %{label: "Home", href: nav_href(mount_path, "", org), eyebrow: "Overview"},
      %{label: "Customers", href: nav_href(mount_path, "/customers", org), eyebrow: "Directory"},
      %{
        label: "Subscriptions",
        href: nav_href(mount_path, "/subscriptions", org),
        eyebrow: "Lifecycle"
      },
      %{label: "Invoices", href: nav_href(mount_path, "/invoices", org), eyebrow: "Receivables"},
      %{label: "Charges", href: nav_href(mount_path, "/charges", org), eyebrow: "Payments"},
      %{label: "Webhooks", href: nav_href(mount_path, "/webhooks", org), eyebrow: "Pipeline"},
      %{label: "Event log", href: nav_href(mount_path, "/events", org), eyebrow: "Audit trail"},
      %{label: "Coupons", href: nav_href(mount_path, "/coupons", org), eyebrow: "Discounts"},
      %{
        label: "Promotion codes",
        href: nav_href(mount_path, "/promotion-codes", org),
        eyebrow: "Codes"
      },
      %{label: "Connect", href: nav_href(mount_path, "/connect", org), eyebrow: "Payouts"}
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
