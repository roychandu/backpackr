import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // AWS Configuration
  static String get awsBaseUrl => dotenv.env['AWS_UPLOAD_BASE_URL'] ?? 'https://rest.yuvonglobe-app.info/';

  // In-App Purchase Configuration
  static String get premiumProductId => kDebugMode 
      ? (dotenv.env['IAP_PREMIUM_TEST_ID'] ?? 'com.test.bet')
      : (dotenv.env['IAP_LIFETIME_PREMIUM_ID'] ?? 'com.birtansokullu.preglob');

  static String get trophiesProductIdTest => dotenv.env['IAP_TROPHIES_TEST_ID'] ?? 'com.backpackr.10006';

  // Firebase / Google Keys
  static String get googleApiKeyIos => dotenv.env['FIREBASE_API_KEY_IOS'] ?? '';
  static String get googleApiKeyAndroid => dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '';
  static String get googleProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? 'backpackr-a3499';
  static String get googleSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  // Utility to check if essential keys are missing
  static bool get hasMissingKeys {
    return googleApiKeyIos.isEmpty || googleApiKeyAndroid.isEmpty;
  }
}
