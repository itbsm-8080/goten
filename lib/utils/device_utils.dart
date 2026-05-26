import 'package:flutter/services.dart';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class DeviceUtils {
  static Future<String?> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        // Untuk Android, gunakan android_id
        const androidIdPlugin = AndroidId();
        final String? androidId = await androidIdPlugin.getId();
        return androidId;
      } else if (Platform.isIOS) {
        // Untuk iOS, gunakan device_info_plus
        final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } on PlatformException catch (e) {
      print('Failed to get device ID: ${e.message}');
      return null;
    }
    return null;
  }
}