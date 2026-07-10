defmodule AccrueAdmin.Nav do
  @moduledoc false

  def items(mount_path, current_path, attention_counts \\ %{}) do
    org = org_slug(current_path)

    invoice_badge = Map.get(attention_counts, :invoices, 0)
    recovery_badge = Map.get(attention_counts, :recovery, 0)
    developer_badge = Map.get(attention_counts, :developer, 0)

    # Grouped by the operator's mental model, not by internal module. Home stands
    # alone (group: nil → no label). Eyebrow sublabels dropped (Phase 169): they
    # added jargon without prediction value. Icons via AccrueAdmin.Components.Icon.
    # Phase 175-02 added :badge for sidebar attention counts. The :collapsible
    # field was removed (260621-nr8): all groups now render static, always-visible
    # link lists — no collapse toggles.
    [
      %{
        label: "Home",
        href: nav_href(mount_path, "", org),
        icon: :home,
        group: nil,
        badge: nil
      },
      %{
        label: "Customers",
        href: nav_href(mount_path, "/customers", org),
        icon: :users,
        group: "Billing",
        badge: nil
      },
      %{
        label: "Subscriptions",
        href: nav_href(mount_path, "/subscriptions", org),
        icon: :subscriptions,
        group: "Billing",
        badge: nil
      },
      %{
        label: "Invoices queue",
        href: nav_href(mount_path, "/invoices", org),
        icon: :invoices,
        group: "Billing",
        badge: if(invoice_badge > 0, do: invoice_badge, else: nil)
      },
      %{
        label: "Payments",
        href: nav_href(mount_path, "/payments", org),
        icon: :payments,
        group: "Billing",
        badge: nil
      },
      %{
        label: "Recovery",
        href: nav_href(mount_path, "/analytics/recovery", org),
        icon: :recovery,
        group: "Recovery",
        badge: if(recovery_badge > 0, do: recovery_badge, else: nil)
      },
      %{
        label: "Audit event log",
        href: nav_href(mount_path, "/events", org),
        icon: :events,
        group: "Audit",
        badge: nil
      },
      %{
        label: "Webhook events",
        href: nav_href(mount_path, "/webhooks", org),
        icon: :webhooks,
        group: "Developer",
        badge: if(developer_badge > 0, do: developer_badge, else: nil)
      },
      %{
        label: "Coupons",
        href: nav_href(mount_path, "/coupons", org),
        icon: :coupons,
        group: "Catalog",
        badge: nil
      },
      %{
        label: "Promotion codes",
        href: nav_href(mount_path, "/promotion-codes", org),
        icon: :promotions,
        group: "Catalog",
        badge: nil
      },
      %{
        label: "Connect",
        href: nav_href(mount_path, "/connect", org),
        icon: :connect,
        group: "Connect",
        badge: nil
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
