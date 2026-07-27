/// delivery_guarantee.dart
///
/// Domain entity defining delivery guarantee levels for queue items.

library;

enum DeliveryGuaranteeLevel {
  mustDeliver, // Emergency Packets, Disconnect Packets
  bestEffort,  // Timeline events
  lowPriority,  // Analytics
  optional,     // Debug logs
}
