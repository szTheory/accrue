defmodule AccrueHost.Repo do
  use Ecto.Repo,
    otp_app: :accrue_host,
    adapter: Ecto.Adapters.Postgres
end
