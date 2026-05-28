import 'dart:io';

class AdHelper {
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3773792846539205/6082018186';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3773792846539205/1768202803';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
