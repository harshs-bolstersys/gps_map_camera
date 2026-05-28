import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncher {
  // URLs
  static const String rateUsUrlIos = 'https://apps.apple.com/app/id6761419194?action=write-review';
  static const String rateUsUrlAndroid = 'https://play.google.com/store/apps/details?id=com.hkedgetech.gps_map_camera.gps_map_camera';
  static const String privacyPolicyUrl = 'https://sites.google.com/view/gps-cam/home';

  // Common launcher method
  static Future<void> launch(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch url: $e');
    }
  }
}
