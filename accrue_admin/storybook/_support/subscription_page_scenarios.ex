unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(
    Path.expand("../../../dev_support/ui_scenarios/cadence_subscriptions.exs", __DIR__)
  )
end

defmodule AccrueAdmin.Storybook.SubscriptionPageScenarios do
  @moduledoc false

  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.Storybook.SubscriptionScenarios

  @scenarios [:active, :scheduled_cancellation, :incomplete_evidence]
  @attribution %{
    actor: "vendor billing support operator",
    job: "understand subscription state and choose a supported next action",
    input_source: "deterministic Cadence scenario facts",
    production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_page/1",
    proof_lane: "static whole-page render"
  }
  @allowed_attributes Map.keys(@attribution) ++ [:scenario]

  @doc "Lists the canonical whole subscription detail situations."
  def list, do: @scenarios

  @doc "Returns the page-level static-review attribution for a supported scenario."
  def attributes(scenario) when scenario in @scenarios do
    Map.put(@attribution, :scenario, scenario)
  end

  def attributes(scenario),
    do: raise(ArgumentError, "unsupported whole subscription page scenario: #{inspect(scenario)}")

  @doc "Builds production renderer assigns from validated facts without starting Repo."
  def assigns!(input) do
    scenario = scenario!(input)
    base = SubscriptionScenarios.assigns!(scenario)
    subscription = base.subscription
    customer = base.customer
    scope = base.current_owner_scope
    mount_path = base.admin_mount_path

    destination =
      ScopedPath.return_destination(
        mount_path,
        nil,
        scope,
        subscription.customer_id,
        "/subscriptions"
      )

    Map.merge(base, %{
      brand: default_brand(),
      current_path: ScopedPath.build(mount_path, "/subscriptions", scope),
      page_title: Copy.subscription_page_title(),
      theme: "system",
      active_organization_name:
        scope.organization_display_name || scope.organization_slug || "selected organization",
      return_path: destination.path,
      return_label: destination.label,
      related_items: related_items(subscription, mount_path, scope, destination.path),
      timeline_events: [],
      timeline_events_loaded?: true,
      raw_json_loaded?: false,
      proration_options: proration_options(),
      drawer_action_type: nil,
      pending_action: nil,
      dispatch_state: :idle,
      step_up_pending: false,
      step_up_challenge: nil,
      step_up_error: nil
    })
    |> Map.put(:customer, customer)
  end

  defp scenario!(scenario) when scenario in @scenarios, do: scenario

  defp scenario!(attributes) when is_map(attributes) do
    scenario = Map.fetch!(attributes, :scenario)
    expected = attributes(scenario)
    unknown = Map.keys(attributes) -- @allowed_attributes

    mismatch =
      Enum.find(expected, fn {key, value} ->
        Map.has_key?(attributes, key) and Map.get(attributes, key) != value
      end)

    cond do
      unknown != [] ->
        raise ArgumentError, "whole page input contains unsupported fields: #{inspect(unknown)}"

      mismatch ->
        raise ArgumentError, "whole page attribution does not match the static review contract"

      true ->
        scenario
    end
  end

  defp scenario!(input),
    do:
      raise(
        ArgumentError,
        "whole page input must be a supported scenario or attribution map: #{inspect(input)}"
      )

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end

  defp proration_options do
    [
      %{value: "create_prorations", label: Copy.subscription_proration_create()},
      %{value: "none", label: Copy.subscription_proration_none()},
      %{value: "always_invoice", label: Copy.subscription_proration_always_invoice()}
    ]
  end

  defp related_items(subscription, mount_path, scope, return_path) do
    customer_items =
      if subscription.customer do
        customer = subscription.customer
        label = customer.name || customer.email || customer.id

        [
          %{
            icon: :users,
            label: "Customer",
            value: label,
            href: ScopedPath.build(mount_path, "/customers/#{subscription.customer_id}", scope)
          }
        ]
      else
        []
      end

    invoice_scope =
      if scope.mode == :organization do
        "All open invoices for #{scope.organization_display_name || scope.organization_slug || "selected organization"}"
      else
        "All open invoices in global scope"
      end

    customer_items ++
      [
        %{
          icon: :invoices,
          label: "Open invoices for this customer",
          value: "Customer-wide results; open status",
          href:
            ScopedPath.build(mount_path, "/invoices", scope, %{
              "customer_id" => subscription.customer_id,
              "status" => "open",
              "return_to" => return_path
            })
        },
        %{
          icon: :invoices,
          label: invoice_scope,
          value: "All authorized open invoices",
          href:
            ScopedPath.build(mount_path, "/invoices", scope, %{
              "status" => "open",
              "return_to" => return_path
            })
        },
        %{
          icon: :payments,
          label: Copy.subscription_drill_link_charges_for_customer(),
          href:
            ScopedPath.build(mount_path, "/payments", scope, %{
              "customer_id" => subscription.customer_id,
              "return_to" => return_path
            })
        },
        %{
          icon: :events,
          label: Copy.subscription_drill_link_events_for_subscription(),
          value: "Filtered subscription event log with actor and source context",
          href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "Subscription",
              "subject_id" => subscription.id
            })
        },
        %{
          icon: :events,
          label: Copy.subscription_drill_link_events_index(),
          href: ScopedPath.build(mount_path, "/events", scope)
        }
      ]
  end
end
