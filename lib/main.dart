// ignore_for_file: avoid_print, empty_catches

import 'package:backpackr/common_widgets/app_colors.dart';
import 'package:backpackr/provider/purchase_provider.dart';
import 'package:backpackr/screens/auth_screen/login_screen.dart';
import 'package:backpackr/screens/home_screen/home_screen.dart';
import 'package:backpackr/screens/intro_screen/intro_screen.dart';
import 'package:backpackr/services/app_flow_service.dart';
import 'package:backpackr/services/auth_service.dart';
import 'package:backpackr/services/notification_service.dart';
import 'package:backpackr/services/theme_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:backpackr/core/app_config.dart';

void setPortait() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
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

  // Initialize Theme Service
  await Get.putAsync(() => ThemeService().init());

  setPortait();
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return riverpod.ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            lazy: false,
            create: (_) => InAppPurchaseProvider(),
          ),
        ],
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Backpackr',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF131313),
            useMaterial3: true,
          ),
          themeMode: ThemeService.to.theme,
          navigatorKey: appNavigatorKey,
          home: const AppFlowWrapper(),
          routes: {
            '/intro': (context) => const IntroScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}

class AppFlowWrapper extends StatefulWidget {
  const AppFlowWrapper({super.key});

  @override
  State<AppFlowWrapper> createState() => _AppFlowWrapperState();
}

class _AppFlowWrapperState extends State<AppFlowWrapper> {
  final AppFlowService _appFlowService = AppFlowService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user authentication state changes, determine the appropriate screen
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in - always go to home screen
          // Business setup will be checked when user tries to create an invoice
          return const HomeScreen();
        } else {
          // User is not logged in - check if they've seen intro
          return FutureBuilder<bool>(
            future: _appFlowService.hasSeenIntro(),
            builder: (context, introSnapshot) {
              if (introSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (introSnapshot.data == true) {
                return const LoginScreen();
              } else {
                return const IntroScreen();
              }
            },
          );
        }
      },
    );
  }
}
