import 'dart:io';

class AdHelper {
  // Real Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3773792846539205/6082018186';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3773792846539205/1768202803';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Real Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3773792846539205/6232995760';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3773792846539205/2335103030';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
