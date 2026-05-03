defmodule Accrue.Repo.Migrations.AddBillingResolutionFieldsToMeterEventsAndRenewals do
  use Ecto.Migration

  def change do
    alter table(:accrue_meter_events) do
      add :meter_definition_id,
          references(:accrue_meter_definitions, type: :binary_id, on_delete: :nilify_all)

      add :metered_renewal_id,
          references(:accrue_metered_renewals, type: :binary_id, on_delete: :nilify_all)

      add :billing_status, :string
      add :billing_error, :string
    end

    create index(:accrue_meter_events, [:metered_renewal_id, :billing_status])
    create index(:accrue_meter_events, [:meter_definition_id])

    alter table(:accrue_metered_renewals) do
      add :invoice_id,
          references(:accrue_invoices, type: :binary_id, on_delete: :nilify_all)

      add :invoice_status, :string
      add :invoice_authored_at, :utc_datetime_usec
    end

    create index(:accrue_metered_renewals, [:invoice_id])
    create index(:accrue_metered_renewals, [:invoice_status])
  end
end
