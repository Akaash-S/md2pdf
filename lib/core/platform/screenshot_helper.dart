import 'package:flutter/services.dart';

class ScreenshotHelper {
  static const _channel = MethodChannel('md_to_pdf/screenshot');

  static Future<void> setProtection(bool enabled) async {
    try {
      await _channel.invokeMethod('setProtection', enabled);
    } catch (_) {}
  }
}
