import 'package:flutter/services.dart';

abstract interface class HealthSettingsLauncher {
  Future<void> openHealthSettings();
}

class MethodChannelHealthSettingsLauncher implements HealthSettingsLauncher {
  const MethodChannelHealthSettingsLauncher();

  static const MethodChannel _channel = MethodChannel(
    'com.prana.health/settings',
  );

  @override
  Future<void> openHealthSettings() async {
    final opened =
        await _channel.invokeMethod<bool>('openHealthSettings') ?? false;

    if (!opened) {
      throw StateError('Health Connect settings could not be opened.');
    }
  }
}
