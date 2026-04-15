defmodule AccrueAdmin.TestRepo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :accrue_admin,
    adapter: Ecto.Adapters.Postgres
end
