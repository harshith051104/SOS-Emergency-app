/// resilience_policies.dart
///
/// Storage and battery degradation policy enums for offline survivability management.

library;

enum StoragePolicy {
  normal,          // Standard JSON snapshot persistence
  lowStorage,      // GZIP compressed JSON snapshots, archived synced packets
  criticalStorage, // Compact telemetry & critical medical data only
}

enum BatteryPolicyState {
  normal,   // Battery > 50%: Standard telemetry and packet scheduler intervals
  low,      // Battery 20–50%: Double interval, reduced diagnostic polling
  critical, // Battery < 20%: Triple interval (bypassed during CRITICAL severity)
}
