/// queue_priority.dart
///
/// Domain entity defining queue scheduling priority tiers.

library;

enum QueuePriority {
  critical, // Packets, Disconnect alerts
  high,     // Current GPS updates
  medium,   // Timeline events
  low,      // Debug & analytics
}
