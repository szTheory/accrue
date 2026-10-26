defmodule AccrueAdmin.EventPresentationTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.EventPresentation

  test "all registered lifecycle events have a readable label and supported family icon" do
    for type <- Map.keys(Accrue.Events.Schemas.all()) do
      presentation = EventPresentation.for(Atom.to_string(type))
      refute presentation.label in ["Billing event", "Event details unavailable"]
      assert presentation.icon in AccrueAdmin.Components.Icon.names()
    end
  end

  test "family cues are distinct and routine creation stays neutral" do
    customer = EventPresentation.for("customer.created")
    subscription = EventPresentation.for("subscription.created")
    refute customer.icon == subscription.icon
    assert subscription.icon == :document_plus
    refute subscription.icon == EventPresentation.for("subscription.resumed").icon
    assert customer.tone == :slate
    assert subscription.tone == :slate
    assert EventPresentation.for("dunning.campaign_started").icon == :recovery
    assert EventPresentation.for("connect.account.updated").icon == :connect
    assert EventPresentation.for("webhook.received").icon == :webhooks
  end

  test "only observed outcomes gain semantic color" do
    assert EventPresentation.for("charge.failed").tone == :amber
    assert EventPresentation.for("invoice.paid").tone == :moss
    assert EventPresentation.for("dunning.recovered").tone == :moss
    assert EventPresentation.for("charge.refunded").tone == :slate
    assert EventPresentation.for("admin.subscription.action.completed").tone == :slate

    assert EventPresentation.for("admin.webhook.replay.completed").label ==
             "Webhook replay result recorded"

    refute EventPresentation.for("subscription.trial_ended").label =~ "ended"
  end

  test "unknown and malformed types never acquire a fabricated meaning or success color" do
    for type <- ["charge.future_success", "provider.unknown", nil, "", :invalid] do
      presentation = EventPresentation.for(type)
      assert presentation.icon == :events
      assert presentation.family == :other
      assert presentation.tone == :slate
    end
  end
end
