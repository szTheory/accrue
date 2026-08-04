# Deferred items

- `examples/accrue_host && mix verify.full` fails in `AccrueHost.BillingFacadeTest` with the unique constraint `accrue_subscriptions_processor_processor_id_index` while creating a Fake-backed subscription. It is outside Plan 220-06's documentation/CI gate scope and was not modified.
