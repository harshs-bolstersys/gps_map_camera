import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncher {
  // URLs
  static const String rateUsUrl = 'https://apps.apple.com/app/id6761419194?action=write-review';

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
