/// vad_config.dart
///
/// Dynamic configuration entity for Voice Activity Detection engine parameters.

library;

import 'package:flutter/foundation.dart';

@immutable
class VadConfig {
  const VadConfig({
    this.speechThreshold = 0.5,
    this.frameLengthMs = 32,
    this.sampleRate = 16000,
    this.onsetFrames = 3,
    this.offsetFrames = 10,
    this.maxCpuLimitPercent = 2.0,
    this.maxRamLimitMb = 30.0,
  });

  final double speechThreshold;
  final int frameLengthMs;
  final int sampleRate;
  final int onsetFrames;
  final int offsetFrames;
  final double maxCpuLimitPercent;
  final double maxRamLimitMb;

  VadConfig copyWith({
    double? speechThreshold,
    int? frameLengthMs,
    int? sampleRate,
    int? onsetFrames,
    int? offsetFrames,
    double? maxCpuLimitPercent,
    double? maxRamLimitMb,
  }) {
    return VadConfig(
      speechThreshold: speechThreshold ?? this.speechThreshold,
      frameLengthMs: frameLengthMs ?? this.frameLengthMs,
      sampleRate: sampleRate ?? this.sampleRate,
      onsetFrames: onsetFrames ?? this.onsetFrames,
      offsetFrames: offsetFrames ?? this.offsetFrames,
      maxCpuLimitPercent: maxCpuLimitPercent ?? this.maxCpuLimitPercent,
      maxRamLimitMb: maxRamLimitMb ?? this.maxRamLimitMb,
    );
  }

  Map<String, dynamic> toJson() => {
        'speechThreshold': speechThreshold,
        'frameLengthMs': frameLengthMs,
        'sampleRate': sampleRate,
        'onsetFrames': onsetFrames,
        'offsetFrames': offsetFrames,
        'maxCpuLimitPercent': maxCpuLimitPercent,
        'maxRamLimitMb': maxRamLimitMb,
      };

  factory VadConfig.fromJson(Map<String, dynamic> json) {
    return VadConfig(
      speechThreshold: (json['speechThreshold'] as num?)?.toDouble() ?? 0.5,
      frameLengthMs: (json['frameLengthMs'] as num?)?.toInt() ?? 32,
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? 16000,
      onsetFrames: (json['onsetFrames'] as num?)?.toInt() ?? 3,
      offsetFrames: (json['offsetFrames'] as num?)?.toInt() ?? 10,
      maxCpuLimitPercent: (json['maxCpuLimitPercent'] as num?)?.toDouble() ?? 2.0,
      maxRamLimitMb: (json['maxRamLimitMb'] as num?)?.toDouble() ?? 30.0,
    );
  }
}
