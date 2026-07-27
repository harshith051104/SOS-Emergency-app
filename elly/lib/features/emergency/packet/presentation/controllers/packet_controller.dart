/// packet_controller.dart
///
/// Riverpod controller driving the state of the Emergency Data Packet.
/// Integrates building status increments for compilation checks.

library;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/timeline_service.dart';
import '../../domain/entities/emergency_packet.dart';
import '../../domain/usecases/generate_packet_usecase.dart';

enum PacketStateStatus {
  loading,
  building,
  ready,
  failed,
  expired,
}

class EmergencyPacketState extends Equatable {
  const EmergencyPacketState({
    required this.status,
    this.packet,
    this.buildingProgress = 0,
    this.errorMessage,
  });

  final PacketStateStatus status;
  final EmergencyPacket? packet;
  final int buildingProgress;
  final String? errorMessage;

  EmergencyPacketState copyWith({
    PacketStateStatus? status,
    EmergencyPacket? packet,
    int? buildingProgress,
    String? errorMessage,
  }) {
    return EmergencyPacketState(
      status: status ?? this.status,
      packet: packet ?? this.packet,
      buildingProgress: buildingProgress ?? this.buildingProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, packet, buildingProgress, errorMessage];
}

class EmergencyPacketController extends StateNotifier<EmergencyPacketState> {
  EmergencyPacketController({
    required String sessionId,
    required GeneratePacketUseCase generatePacketUseCase,
    required TimelineService timelineService,
    bool autoStart = true,
  })  : _sessionId = sessionId,
        _generatePacketUseCase = generatePacketUseCase,
        _timelineService = timelineService,
        super(const EmergencyPacketState(status: PacketStateStatus.loading)) {
    if (autoStart) {
      // Defer compilation to after the first frame is fully flushed.
      // addPostFrameCallback guarantees execution after build+layout+paint+semantics.
      Future.microtask(() {
        if (mounted) _initCompilation();
      });
    }
  }

  final String _sessionId;
  final GeneratePacketUseCase _generatePacketUseCase;
  final TimelineService _timelineService;

  Future<void> _initCompilation() async {
    state = const EmergencyPacketState(status: PacketStateStatus.building);

    try {
      // Step-by-step pipeline compile delay so the M3 checklist renders dynamically
      for (var progress = 1; progress <= 6; progress++) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final currentProgress = progress;
        Future.microtask(() {
          if (mounted) state = state.copyWith(buildingProgress: currentProgress);
        });
      }

      // Reset the unified timeline log for clean compilation
      _timelineService.clear();

      final packet = await _generatePacketUseCase(
        id: 'EP-${_sessionId.replaceAll('#EL-', '')}',
        sessionId: _sessionId,
        type: 'Manual SOS',
      );

      Future.microtask(() {
        if (mounted) {
          state = state.copyWith(
            status: PacketStateStatus.ready,
            packet: packet,
            buildingProgress: 6,
          );
        }
      });
    } catch (e) {
      Future.microtask(() {
        if (mounted) {
          state = state.copyWith(
            status: PacketStateStatus.failed,
            errorMessage: e.toString(),
          );
        }
      });

    }
  }
}
