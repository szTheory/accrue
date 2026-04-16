# accrue:generated
# accrue:fingerprint: 0328ed90901019d2f8a3e22b8df55bf9e5e95ce9113fe451195184901e3991a9
defmodule Accrue.Repo.Migrations.AddLocaleAndTimezoneToCustomers do
  @moduledoc """
  Phase 6 (06-01) — per-customer locale + timezone columns (D6-03).

  Both nullable; resolved via `Accrue.Workers.Mailer.enrich/2` precedence
  ladder (caller assigns > customer column > application default >
  hardcoded). No data backfill required — existing Phase 1-5 rows
  simply see NULL and fall through to the next ladder rung.

  Column sizes:

    * `preferred_locale` — varchar(35) — BCP-47 max practical length
      (e.g. `"az-Cyrl-AZ"`, `"zh-Hant-HK"`). No `validate_inclusion`
      in the schema: the library cannot know which locales the host's
      CLDR backend compiled in.
    * `preferred_timezone` — varchar(64) — IANA tz database max
      name length.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_customers) do
      add(:preferred_locale, :string, size: 35)
      add(:preferred_timezone, :string, size: 64)
    end
  end
end
