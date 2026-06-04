defmodule AccrueAdmin.EventLiveTest do
  @moduledoc false

  use AccrueAdmin.LiveCase, async: false

  # Wave 0 scaffold — EventLive does not exist yet (ships in Wave 3).
  # These tests are tagged :pending and will be un-tagged when Wave 3 lands.
  # They document the acceptance contract for IA-04 (detail screen threading).

  @tag :pending
  @tag :skip
  test "GET /events/:id renders EventLive detail" do
    # Wave 3 implementation required:
    # - Route /events/:id must be registered in the router.
    # - AccrueAdmin.Live.EventLive must exist.
    # - Mount must load the event by id scoped to current_owner_scope.
    # - Page title should reflect the event type.
    flunk("Wave 3 not yet implemented — remove @tag :pending and @tag :skip when EventLive ships")
  end

  @tag :pending
  @tag :skip
  test "EventLive Related card links to source webhook and affected entity" do
    # Wave 3 implementation required:
    # - EventLive render must include RelatedResources component.
    # - When caused_by_webhook_event_id is present, a link to /webhooks/:id must appear.
    # - subject_type + subject_id must produce a link to the correct detail screen.
    flunk("Wave 3 not yet implemented — remove @tag :pending and @tag :skip when EventLive ships")
  end
end
