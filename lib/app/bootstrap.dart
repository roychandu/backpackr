// ignore_for_file: avoid_print, empty_catches

import 'package:backpackr/core/config/app_config.dart';
import 'package:backpackr/shared/services/local_storage_service.dart';
import 'package:backpackr/shared/services/notification_service.dart';
import 'package:backpackr/shared/services/theme_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

Future<void> bootstrap() async {
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env file loaded successfully");
    debugPrint("AWS URL: ${AppConfig.awsBaseUrl}");
    debugPrint("IAP ID: ${AppConfig.premiumProductId}");
  } catch (e) {
    print("❌ Error loading .env file: $e");
  }

  try {
    await Firebase.initializeApp();
    debugPrint("🔥 Firebase initialized");

    if (kReleaseMode) {
      FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.appAttest,
      );
    }
  } catch (e) {
    debugPrint("❌ Firebase init error: $e");
  }

  try {
    await NotificationService.initialize();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Error initializing notification service: $e');
  }

  await Get.putAsync(() => ThemeService().init());

  try {
    await LocalStorageService.init();
    debugPrint("📦 Local storage initialized");
  } catch (e) {
    debugPrint("❌ Local storage init error: $e");
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}
