/// retention_policy.dart
///
/// Data retention rules entity governing disk storage cleanup.

library;

import 'package:equatable/equatable.dart';

class RetentionPolicy extends Equatable {
  const RetentionPolicy({
    this.maxCompletedSessionAge = const Duration(days: 30),
    this.maxPacketsPerSession = 500,
    this.autoPurgeOnStartup = true,
  });

  final Duration maxCompletedSessionAge;
  final int maxPacketsPerSession;
  final bool autoPurgeOnStartup;

  @override
  List<Object?> get props => [
        maxCompletedSessionAge,
        maxPacketsPerSession,
        autoPurgeOnStartup,
      ];
}
