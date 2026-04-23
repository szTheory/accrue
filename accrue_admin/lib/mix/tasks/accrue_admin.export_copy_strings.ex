defmodule Mix.Tasks.AccrueAdmin.ExportCopyStrings do
  @shortdoc "Export allow-listed AccrueAdmin.Copy strings as JSON for VERIFY-01 anti-drift checks"

  @moduledoc """
  Writes UTF-8 JSON `{\"function_name\" => \"returned string\"}` for a fixed allowlist of
  0-arity `AccrueAdmin.Copy` functions (including `defdelegate` targets).

  ## Example

      mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json

  """

  use Mix.Task

  @requirements ["app.config"]

  @allowlist ~w(
    subscription_drill_related_card_title
    subscription_drill_related_region_aria_label
    subscription_drill_link_customer
    subscription_drill_link_invoices_for_customer
    subscription_drill_link_charges_for_customer
    subscription_drill_link_events_index
    subscription_breadcrumb_subscriptions
    subscription_detail_eyebrow
    subscription_proration_create
    subscriptions_index_empty_title
    connect_accounts_headline
    connect_accounts_table_empty_title
    connect_accounts_apply_filters
    connect_account_eyebrow
    connect_account_save_platform_fee_override
    invoice_detail_eyebrow
    invoice_open_pdf_button
    invoices_index_headline
    billing_events_heading_organization
    billing_events_table_empty_title
    billing_events_apply_filters
    coupon_index_headline
    promotion_codes_index_headline
  )a

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [out: :string], aliases: [o: :out])

    out_path =
      case opts[:out] do
        nil ->
          Mix.raise("mix accrue_admin.export_copy_strings requires --out PATH")

        path ->
          path
      end

    Mix.Task.run("compile")

    exports = AccrueAdmin.Copy.__info__(:functions)

    map =
      for name <- @allowlist,
          {^name, 0} <- exports,
          into: %{} do
        {Atom.to_string(name), apply(AccrueAdmin.Copy, name, [])}
      end

    File.mkdir_p!(Path.dirname(out_path))
    File.write!(out_path, Jason.encode!(map) <> "\n")
    Mix.shell().info("Wrote #{map_size(map)} copy strings to #{out_path}")
  end
end
