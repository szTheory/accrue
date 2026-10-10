# Deferred Items

- Full `mix verify.full` ran 36 browser tests successfully and skipped 17; the unrelated Phase 234 journey test “served Admin journeys preserve scope, focus, reflow, theme and asset provenance” failed because the expected “Back to results” link was absent after related-subscription navigation. The route retained its `return_to` query parameter. Phase 234 is outside Plan 243-02 scope, so its existing navigation behavior remains unresolved.
