import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // AWS Configuration
  static String get awsBaseUrl =>
      dotenv.env['AWS_UPLOAD_BASE_URL'] ?? 'https://rest.yuvonglobe-app.info/';

  // In-App Purchase Configuration
  static String get premiumProductId => kDebugMode
      ? (dotenv.env['IAP_PREMIUM_TEST_ID'] ?? 'com.test.bet')
      : (dotenv.env['IAP_LIFETIME_PREMIUM_ID'] ?? 'com.birtansokullu.preglob');

  static String get trophiesProductIdTest =>
      dotenv.env['IAP_TROPHIES_TEST_ID'] ?? 'com.backpackr.10006';

  // Note: Firebase configuration is handled natively via google-services.json
  // and GoogleService-Info.plist which are kept local and ignored by Git.
}
