@_exported import AccrueOfflineClientCore

/// A local-path conformance consumer, not a second offline-client implementation.
///
/// The tracer deliberately re-exports the package facade so a host compiles against
/// the same `OfflineEntitlementClient` that is published from the standalone package.
/// Crosswake bridge and physical-device readiness remain outside this target.
public enum CrosswakeTracerConformance {}
