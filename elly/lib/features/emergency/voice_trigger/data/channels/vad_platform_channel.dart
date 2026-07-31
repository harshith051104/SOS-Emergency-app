/// vad_platform_channel.dart
///
/// MethodChannel and EventChannel bridge to Android VoiceVadForegroundService.

library;

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:elly/core/utils/app_logger.dart';

class VadPlatformChannel {
  const VadPlatformChannel();

  static const MethodChannel _methodChannel = MethodChannel('com.elly.elly/vad');
  static const EventChannel _eventChannel = EventChannel('com.elly.elly/vad_events');

  bool get isSupported => Platform.isAndroid;

  Future<bool> startService() async {
    if (!isSupported) {
      appLogger.info('VadPlatformChannel: VAD service unsupported on ${Platform.operatingSystem}');
      return false;
    }
    try {
      final success = await _methodChannel.invokeMethod<bool>('startService');
      appLogger.info('VadPlatformChannel: Service start requested -> success: $success');
      return success ?? false;
    } on PlatformException catch (e) {
      appLogger.error('VadPlatformChannel: Exception starting VAD service: ${e.message}');
      return false;
    }
  }

  Future<bool> stopService() async {
    if (!isSupported) return false;
    try {
      final success = await _methodChannel.invokeMethod<bool>('stopService');
      appLogger.info('VadPlatformChannel: Service stop requested -> success: $success');
      return success ?? false;
    } on PlatformException catch (e) {
      appLogger.error('VadPlatformChannel: Exception stopping VAD service: ${e.message}');
      return false;
    }
  }

  Future<bool> isServiceRunning() async {
    if (!isSupported) return false;
    try {
      final running = await _methodChannel.invokeMethod<bool>('isServiceRunning');
      return running ?? false;
    } catch (e) {
      return false;
    }
  }

  Stream<Map<String, dynamic>> vadEventStream() {
    if (!isSupported) {
      return const Stream.empty();
    }
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }
}
