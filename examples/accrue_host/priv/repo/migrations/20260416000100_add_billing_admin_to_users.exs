defmodule AccrueHost.Repo.Migrations.AddBillingAdminToUsers do
  use Ecto.Migration

  # Keep the filename and logical migration in place for upgrades where the
  # users table already exists. Fresh checkouts get the column from the auth
  # table creation migration that lands later in timestamp order.
  # add :billing_admin, :boolean
  def up do
    execute("""
    DO $$
    BEGIN
      IF to_regclass('public.users') IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'billing_admin'
      ) THEN
        ALTER TABLE users ADD COLUMN billing_admin boolean NOT NULL DEFAULT false;
      END IF;
    END
    $$;
    """)
  end

  def down do
    execute("""
    DO $$
    BEGIN
      IF to_regclass('public.users') IS NOT NULL AND EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'billing_admin'
      ) THEN
        ALTER TABLE users DROP COLUMN billing_admin;
      END IF;
    END
    $$;
    """)
  end
end
