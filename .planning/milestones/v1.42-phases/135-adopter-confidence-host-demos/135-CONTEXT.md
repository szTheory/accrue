# Phase 135: Adopter Confidence - Host Demos (Metered & Checkout)

## Context
This phase focuses on increasing adopter confidence by demonstrating core billing features in the `examples/accrue_host` application. We are implementing demos for metered usage reporting and the checkout facade.

The example host currently demonstrates basic subscription management. We will extend it to show how easily a business process can report usage and how to use the checkout facade directly for one-off sessions.

## Decisions
- **D-135-01**: Add a `metered` plan to `AccrueHost.Billing.Plans` to provide a realistic target for usage reporting.
- **D-135-02**: Extend `AccrueHost.Billing` facade with `report_usage/3` and `create_checkout_session/2` to maintain the "host-owned facade" pattern.
- **D-135-03**: Integrate these demos into the existing `SubscriptionLive` view for centralized demonstration.
- **D-135-04**: For the Checkout demo, we will use `:hosted` mode as it's the simplest to demonstrate without additional client-side code.

## the agent's Discretion
- Implementation of the "Metered Feature" will be a "Simulate API Call" button that increments a dummy "api_calls" meter.
- The Checkout Session demo will create a session for the "Pro" plan and display the redirect URL (or a link to it).

## Out of Scope
- Full automated tax integration in the checkout demo (we'll keep it simple).
- Real processor integration (using `Fake` processor is sufficient for the demo).
