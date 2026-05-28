# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AccrueHost.Repo.insert!(%AccrueHost.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Accrue.Events

now = Accrue.Clock.utc_now()
now_iso = DateTime.to_iso8601(now)

days_ago = fn days ->
  DateTime.add(now, -days * 86_400, :second)
end

# Insert deterministic Dunning events for 7d window (Recovered USD)
sub_7d = Ecto.UUID.generate()
anchor_7d = DateTime.to_iso8601(days_ago.(5))

Events.record(%{
  type: "dunning.campaign_started",
  subject_type: "Subscription",
  subject_id: sub_7d,
  data: %{campaign_anchor: anchor_7d},
  timestamp: days_ago.(5)
})

Events.record(%{
  type: "dunning.step_sent",
  subject_type: "Subscription",
  subject_id: sub_7d,
  data: %{campaign_anchor: anchor_7d},
  timestamp: days_ago.(4)
})

Events.record(%{
  type: "dunning.recovered",
  subject_type: "Subscription",
  subject_id: sub_7d,
  data: %{campaign_anchor: anchor_7d, mrr_value_cents: 12000, currency: "usd"},
  timestamp: days_ago.(3)
})

# Insert deterministic Dunning events for 30d window (Exhausted JPY)
sub_30d = Ecto.UUID.generate()
anchor_30d = DateTime.to_iso8601(days_ago.(25))

Events.record(%{
  type: "dunning.campaign_started",
  subject_type: "Subscription",
  subject_id: sub_30d,
  data: %{campaign_anchor: anchor_30d},
  timestamp: days_ago.(25)
})

Events.record(%{
  type: "dunning.exhausted",
  subject_type: "Subscription",
  subject_id: sub_30d,
  data: %{campaign_anchor: anchor_30d, mrr_value_cents: 30000, currency: "jpy"},
  timestamp: days_ago.(15)
})

# Insert deterministic Dunning events for Active (90d window)
sub_90d = Ecto.UUID.generate()
anchor_90d = DateTime.to_iso8601(days_ago.(60))

Events.record(%{
  type: "dunning.campaign_started",
  subject_type: "Subscription",
  subject_id: sub_90d,
  data: %{campaign_anchor: anchor_90d},
  timestamp: days_ago.(60)
})

Events.record(%{
  type: "dunning.step_sent",
  subject_type: "Subscription",
  subject_id: sub_90d,
  data: %{campaign_anchor: anchor_90d},
  timestamp: days_ago.(50)
})
