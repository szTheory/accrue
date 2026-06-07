defmodule AccrueHost.BackgroundDataTest do
  use AccrueHost.DataCase

  setup do
    Application.put_env(:accrue, :env, :dev)

    Code.compiler_options(ignore_module_conflict: true)
    Code.eval_file("priv/repo/seeds.exs")
    Code.compiler_options(ignore_module_conflict: false)

    Application.put_env(:accrue, :env, :test)
    :ok
  end

  test "seeds generate bulk background accounts and events" do
    alias AccrueHost.Accounts.User
    alias AccrueHost.Accounts.Organization
    alias Accrue.Billing.Subscription
    alias Accrue.Events.Event

    users_count = Repo.aggregate(User, :count)
    assert users_count >= 100

    orgs_count = Repo.aggregate(Organization, :count)
    assert orgs_count >= 100

    subs_count = Repo.aggregate(Subscription, :count)
    assert subs_count >= 100

    events_count = Repo.aggregate(Event, :count)
    assert events_count >= 100

    import Ecto.Query

    # Ensure backdated data exists (at least 1 day old)
    now = DateTime.utc_now()
    one_day_ago = DateTime.add(now, -86_400, :second)

    old_events_count =
      Event
      |> where([e], e.inserted_at < ^one_day_ago)
      |> Repo.aggregate(:count)

    assert old_events_count > 0
  end
end
